import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../models/complaint_model.dart';
import '../utils/philippine_time.dart';
import 'gemini_service.dart';
import 'ai_database_service.dart';

/// AI-powered risk assessment and priority calculation service
/// Uses Gemini 2.0 Flash for intelligent analysis of cybercrime reports
class AIRiskAssessmentService {
  // Use the same API key and model from GeminiService
  static const String _apiKey = "AIzaSyCs8F21zwcMVhv4ZbkGJ_PtetqdbxPvl7M";
  static const String _modelName = 'gemini-2.0-flash';
  static bool _debugMode = true; // Set to false in production
  
  static GenerativeModel? _model;

  static void _debugLog(String message) {
    if (_debugMode) {
      print('🔍 [AIRiskAssessment] $message');
    }
  }
  
  /// Initialize the AI model
  static GenerativeModel get _getModel {
    if (_model == null) {
      _debugLog('🤖 Initializing AI Risk Assessment model');
      _model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for more consistent results
          maxOutputTokens: 1000,
          topP: 0.8,
        ),
      );
      _debugLog('✅ AI Risk Assessment model initialized');
    }
    return _model!;
  }

  /// Perform comprehensive AI-powered risk assessment with database integration
  static Future<AIRiskAssessment> assessComplaint({
    required String description,
    required CrimeType crimeType,
    required List<EvidenceFile> evidenceFiles,
    required double? financialLoss,
    required Map<String, dynamic> suspectInfo,
    required DateTime incidentDate,
    String? incidentLocation,
    String? complaintId,
  }) async {
    final startTime = PhilippineTime.now();
    _debugLog('🚀 Starting AI risk assessment for ${crimeType.displayName}');
    
    // Prepare input data for caching
    final inputData = {
      'description': description,
      'crimeType': crimeType.name,
      'evidenceFilesCount': evidenceFiles.length,
      'financialLoss': financialLoss,
      'suspectInfo': suspectInfo,
      'incidentDate': incidentDate.toIso8601String(),
      'incidentLocation': incidentLocation,
    };
    
    try {
      // Check cache first
      _debugLog('🔍 Checking cache for existing assessment');
      final cachedAssessment = await AIDatabaseService.getCachedAssessment(
        crimeType: crimeType,
        description: description,
        inputData: inputData,
      );
      
      if (cachedAssessment != null) {
        final cacheTime = PhilippineTime.now().difference(startTime).inMilliseconds;
        _debugLog('⚡ Cache HIT! Assessment retrieved in ${cacheTime}ms');
        return cachedAssessment;
      }
      
      // Perform AI analysis if not cached
      _debugLog('🎯 Building analysis prompt');
      final prompt = _buildAnalysisPrompt(
        description: description,
        crimeType: crimeType,
        evidenceFiles: evidenceFiles,
        financialLoss: financialLoss,
        suspectInfo: suspectInfo,
        incidentDate: incidentDate,
        incidentLocation: incidentLocation,
      );

      _debugLog('📤 Sending prompt to Gemini AI (${prompt.length} characters)');
      
      // Get AI analysis
      final response = await _getModel.generateContent([Content.text(prompt)]);
      final aiAnalysis = response.text;

      if (aiAnalysis == null || aiAnalysis.isEmpty) {
        throw 'AI analysis failed - empty response';
      }

      _debugLog('📥 Received AI analysis (${aiAnalysis.length} characters)');

      // Parse AI response
      final assessment = _parseAIResponse(aiAnalysis, crimeType, financialLoss);
      
      final processingTime = PhilippineTime.now().difference(startTime).inMilliseconds;
      _debugLog('✅ AI Risk Assessment completed in ${processingTime}ms');
      _debugLog('📊 Results: Priority=${assessment.aiPriority}, Risk=${assessment.aiRiskScore}%, Confidence=${assessment.confidenceScore}%');
      
      // Store in database for audit (if complaint ID provided)
      if (complaintId != null) {
        _debugLog('💾 Storing assessment in database for audit');
        AIDatabaseService.storeRiskAssessment(
          complaintId: complaintId,
          assessment: assessment,
          assessmentType: 'full',
          processingTimeMs: processingTime,
          inputData: inputData,
        );
      }
      
      // Cache for future use
      _debugLog('💾 Caching assessment for future requests');
      AIDatabaseService.cacheAssessment(
        crimeType: crimeType,
        description: description,
        inputData: inputData,
        assessment: assessment,
      );
      
      return assessment;
    } catch (e) {
      final processingTime = PhilippineTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ AI Risk Assessment error after ${processingTime}ms: $e');
      
      // Fallback to rule-based calculation if AI fails
      _debugLog('🔄 Using fallback risk assessment');
      final fallbackAssessment = _createFallbackAssessment(crimeType, financialLoss);
      
      // Still store fallback in database if complaint ID provided
      if (complaintId != null) {
        AIDatabaseService.storeRiskAssessment(
          complaintId: complaintId,
          assessment: fallbackAssessment,
          assessmentType: 'fallback',
          processingTimeMs: processingTime,
          inputData: inputData,
        );
      }
      
      return fallbackAssessment;
    }
  }

  /// Build comprehensive analysis prompt for Gemini
  static String _buildAnalysisPrompt({
    required String description,
    required CrimeType crimeType,
    required List<EvidenceFile> evidenceFiles,
    required double? financialLoss,
    required Map<String, dynamic> suspectInfo,
    required DateTime incidentDate,
    String? incidentLocation,
  }) {
    final now = PhilippineTime.now();
    final daysSinceIncident = now.difference(incidentDate).inDays;
    
    return '''
You are an expert AI system specializing in Philippine cybercrime risk assessment and case prioritization. Analyze the following cybercrime report and provide a comprehensive risk assessment.

**CRIME REPORT DETAILS:**
Crime Type: ${crimeType.displayName} (Category: ${crimeType.categoryName})
Police Unit: ${crimeType.assignedUnit}

Description: "$description"

Financial Loss: ${financialLoss != null ? '₱${financialLoss.toStringAsFixed(2)}' : 'None reported'}

**INCIDENT TIMELINE:**
Incident Date: ${incidentDate.toString()}
Days Since Incident: $daysSinceIncident days
${incidentLocation != null ? 'Location: $incidentLocation' : ''}

**EVIDENCE ANALYSIS:**
Evidence Files Count: ${evidenceFiles.length}
Evidence Types: ${evidenceFiles.isEmpty ? 'None' : evidenceFiles.map((e) => '${e.fileType.toUpperCase()} (${e.fileSizeFormatted})').join(', ')}
Evidence Quality Score: ${_calculateEvidenceQuality(evidenceFiles)}

**SUSPECT INFORMATION:**
${_formatSuspectInfo(suspectInfo)}

**ANALYSIS INSTRUCTIONS:**
Provide a JSON response with the following structure:
{
  "aiRiskScore": [integer 0-100],
  "aiPriority": "[critical/high/medium/low]",
  "confidenceScore": [integer 0-100],
  "riskFactors": ["factor1", "factor2", "factor3"],
  "urgencyIndicators": ["indicator1", "indicator2"],
  "reasoning": "Detailed explanation in English and Filipino"
}

**ASSESSMENT CRITERIA:**
1. **Content Analysis**: Analyze description for urgency keywords, victim impact, threat persistence
2. **Crime Type Severity**: Consider inherent severity of ${crimeType.displayName} crimes
3. **Financial Impact**: Evaluate beyond just amount - consider victim profile, recovery likelihood
4. **Evidence Strength**: Assess evidence quality, quantity, and investigative value
5. **Suspect Profile**: Known vs unknown suspect, relationship to victim, sophistication level
6. **Timeline Urgency**: Ongoing vs past crime, evidence preservation needs
7. **Victim Vulnerability**: Consider age, profession, technical knowledge, multiple victims
8. **Investigation Complexity**: Technical requirements, international aspects, resource needs

**PRIORITY LEVELS:**
- CRITICAL (90-100): Immediate threat, ongoing crime, national security, children at risk
- HIGH (70-89): Significant financial loss, vulnerable victims, strong evidence, known suspects
- MEDIUM (40-69): Moderate impact, some urgency factors, decent evidence
- LOW (10-39): Minor impact, limited evidence, no urgency factors

**RISK FACTORS TO IDENTIFY:**
- "high_financial_loss", "vulnerable_victim", "ongoing_crime", "strong_evidence"
- "known_suspect", "multiple_victims", "technical_sophistication", "cross_border"
- "identity_theft_risk", "data_breach_scale", "reputation_damage", "business_impact"

**URGENCY INDICATORS:**
- "immediate_threat", "evidence_degradation", "suspect_flight_risk", "media_attention"
- "ongoing_victimization", "time_sensitive_evidence", "vulnerable_population"

Respond ONLY with valid JSON. Be thorough but concise in reasoning.
''';
  }

  /// Calculate evidence quality score
  static int _calculateEvidenceQuality(List<EvidenceFile> evidenceFiles) {
    if (evidenceFiles.isEmpty) return 0;
    
    int qualityScore = 0;
    
    // Base score for having evidence
    qualityScore += 20;
    
    // Score based on variety of evidence types
    final hasImages = evidenceFiles.any((e) => e.isImage);
    final hasVideos = evidenceFiles.any((e) => e.isVideo);
    final hasDocuments = evidenceFiles.any((e) => e.isDocument);
    
    if (hasImages) qualityScore += 15;
    if (hasVideos) qualityScore += 25; // Videos often more valuable
    if (hasDocuments) qualityScore += 20;
    
    // Score based on quantity (but with diminishing returns)
    final count = evidenceFiles.length;
    if (count >= 5) qualityScore += 20;
    else if (count >= 3) qualityScore += 15;
    else if (count >= 2) qualityScore += 10;
    
    // Score based on file sizes (larger files often more detailed)
    final avgSize = evidenceFiles.fold<int>(0, (sum, file) => sum + file.fileSize) / evidenceFiles.length;
    if (avgSize > 5 * 1024 * 1024) qualityScore += 15; // > 5MB
    else if (avgSize > 1024 * 1024) qualityScore += 10; // > 1MB
    
    return qualityScore.clamp(0, 100);
  }

  /// Format suspect information for analysis
  static String _formatSuspectInfo(Map<String, dynamic> suspectInfo) {
    final buffer = StringBuffer();
    
    final suspectName = suspectInfo['suspectName'] ?? '';
    final suspectRelationship = suspectInfo['suspectRelationship'] ?? '';
    final suspectContact = suspectInfo['suspectContact'] ?? '';
    final suspectDetails = suspectInfo['suspectDetails'] ?? '';
    
    if (suspectName.isNotEmpty) {
      buffer.writeln('Suspect Name: $suspectName');
    } else {
      buffer.writeln('Suspect: Unknown/Anonymous');
    }
    
    if (suspectRelationship.isNotEmpty) {
      buffer.writeln('Relationship to Victim: $suspectRelationship');
    }
    
    if (suspectContact.isNotEmpty) {
      buffer.writeln('Suspect Contact: $suspectContact');
    }
    
    if (suspectDetails.isNotEmpty) {
      buffer.writeln('Additional Details: $suspectDetails');
    }
    
    if (buffer.isEmpty) {
      buffer.writeln('No suspect information provided');
    }
    
    return buffer.toString();
  }

  /// Normalize AI priority to lowercase for database consistency
  static String _normalizePriority(String? priority) {
    final normalized = priority?.toLowerCase() ?? 'medium';
    // Validate against allowed values
    const validPriorities = ['critical', 'high', 'medium', 'low'];
    return validPriorities.contains(normalized) ? normalized : 'medium';
  }

  /// Parse AI response into structured assessment
  static AIRiskAssessment _parseAIResponse(String aiResponse, CrimeType crimeType, double? financialLoss) {
    try {
      // Extract JSON from response (handle markdown code blocks)
      String jsonStr = aiResponse.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();
      
      final Map<String, dynamic> parsed = json.decode(jsonStr);
      
      return AIRiskAssessment(
        aiRiskScore: (parsed['aiRiskScore'] as num?)?.toInt() ?? 50,
        aiPriority: _normalizePriority(parsed['aiPriority'] as String?),
        confidenceScore: (parsed['confidenceScore'] as num?)?.toInt() ?? 70,
        riskFactors: List<String>.from(parsed['riskFactors'] ?? []),
        urgencyIndicators: List<String>.from(parsed['urgencyIndicators'] ?? []),
        reasoning: parsed['reasoning'] as String? ?? 'AI analysis completed',
        assessedAt: PhilippineTime.now(),
      );
    } catch (e) {
      print('❌ Error parsing AI response: $e');
      print('Raw AI response: $aiResponse');
      
      // Create fallback with intelligent defaults
      return _createFallbackAssessment(crimeType, financialLoss);
    }
  }

  /// Create fallback assessment when AI fails
  static AIRiskAssessment _createFallbackAssessment(CrimeType crimeType, double? financialLoss) {
    // Use existing rule-based logic as fallback
    final riskScore = _calculateFallbackRiskScore(crimeType, financialLoss);
    final priority = _calculateFallbackPriority(crimeType, financialLoss);
    
    return AIRiskAssessment(
      aiRiskScore: riskScore,
      aiPriority: priority,
      confidenceScore: 60, // Lower confidence for fallback
      riskFactors: _getRuleBasedRiskFactors(crimeType, financialLoss),
      urgencyIndicators: _getRuleBasedUrgencyIndicators(crimeType),
      reasoning: 'Assessment based on rule-based analysis due to AI service unavailability. Crime type: ${crimeType.displayName}${financialLoss != null ? ', Financial loss: ₱${financialLoss.toStringAsFixed(2)}' : ''}',
      assessedAt: PhilippineTime.now(),
    );
  }

  /// Fallback risk score calculation
  static int _calculateFallbackRiskScore(CrimeType crimeType, double? financialLoss) {
    int baseScore = 30;

    final highRiskCrimes = [
      CrimeType.cyberterrorism,
      CrimeType.governmentSystemHacking,
      CrimeType.criticalInfrastructureAttacks,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
      CrimeType.onlinePredatoryBehavior,
    ];

    final mediumRiskCrimes = [
      CrimeType.identityTheft,
      CrimeType.onlineBankingFraud,
      CrimeType.creditCardFraud,
      CrimeType.sextortion,
      CrimeType.dataBreach,
      CrimeType.denialOfServiceAttacks,
    ];

    if (highRiskCrimes.contains(crimeType)) {
      baseScore += 40;
    } else if (mediumRiskCrimes.contains(crimeType)) {
      baseScore += 25;
    } else {
      baseScore += 10;
    }

    if (financialLoss != null) {
      if (financialLoss >= 1000000) {
        baseScore += 25;
      } else if (financialLoss >= 100000) {
        baseScore += 15;
      } else if (financialLoss >= 10000) {
        baseScore += 10;
      } else if (financialLoss >= 1000) {
        baseScore += 5;
      }
    }

    return baseScore.clamp(0, 100);
  }

  /// Fallback priority calculation
  static String _calculateFallbackPriority(CrimeType crimeType, double? financialLoss) {
    final highPriorityCrimes = [
      CrimeType.cyberterrorism,
      CrimeType.governmentSystemHacking,
      CrimeType.criticalInfrastructureAttacks,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
      CrimeType.onlinePredatoryBehavior,
    ];

    if (highPriorityCrimes.contains(crimeType)) {
      return 'high';
    }

    if (financialLoss != null && financialLoss >= 100000) {
      return 'high';
    }

    final mediumPriorityCrimes = [
      CrimeType.identityTheft,
      CrimeType.onlineBankingFraud,
      CrimeType.creditCardFraud,
      CrimeType.sextortion,
      CrimeType.dataBreach,
      CrimeType.denialOfServiceAttacks,
    ];

    if (mediumPriorityCrimes.contains(crimeType)) {
      return 'medium';
    }

    if (financialLoss != null && financialLoss >= 10000) {
      return 'medium';
    }

    return 'low';
  }

  /// Get rule-based risk factors
  static List<String> _getRuleBasedRiskFactors(CrimeType crimeType, double? financialLoss) {
    final factors = <String>[];
    
    if (financialLoss != null && financialLoss >= 100000) {
      factors.add('high_financial_loss');
    }
    
    final highRiskCrimes = [
      CrimeType.cyberterrorism,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
    ];
    
    if (highRiskCrimes.contains(crimeType)) {
      factors.add('high_severity_crime');
    }
    
    if (crimeType.category == CrimeCategory.harassmentExploitation) {
      factors.add('vulnerable_victim');
    }
    
    if (crimeType.category == CrimeCategory.governmentTerrorism) {
      factors.add('national_security');
    }
    
    return factors;
  }

  /// Get rule-based urgency indicators
  static List<String> _getRuleBasedUrgencyIndicators(CrimeType crimeType) {
    final indicators = <String>[];
    
    final urgentCrimes = [
      CrimeType.cyberterrorism,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.onlinePredatoryBehavior,
      CrimeType.ransomware,
    ];
    
    if (urgentCrimes.contains(crimeType)) {
      indicators.add('immediate_threat');
    }
    
    if (crimeType.category == CrimeCategory.malwareSystemAttacks) {
      indicators.add('ongoing_victimization');
    }
    
    return indicators;
  }

  /// Quick assessment for real-time form updates
  static Future<AIRiskAssessment> quickAssessment({
    required String description,
    required CrimeType crimeType,
    required double? financialLoss,
  }) async {
    try {
      // Simplified prompt for faster response
      final prompt = '''
Quick cybercrime risk assessment:
Crime: ${crimeType.displayName}
Description: "$description"
Loss: ${financialLoss != null ? '₱$financialLoss' : 'None'}

Provide brief JSON assessment:
{
  "aiRiskScore": [0-100],
  "aiPriority": "[critical/high/medium/low]",
  "confidenceScore": [0-100],
  "reasoning": "Brief explanation"
}
''';

      final response = await _getModel.generateContent([Content.text(prompt)]);
      final aiAnalysis = response.text;

      if (aiAnalysis != null && aiAnalysis.isNotEmpty) {
        return _parseQuickResponse(aiAnalysis, crimeType, financialLoss);
      }
    } catch (e) {
      print('❌ Quick AI assessment error: $e');
    }
    
    // Always fallback to rule-based for quick assessment
    return _createFallbackAssessment(crimeType, financialLoss);
  }

  /// Parse quick assessment response
  static AIRiskAssessment _parseQuickResponse(String aiResponse, CrimeType crimeType, double? financialLoss) {
    try {
      String jsonStr = aiResponse.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();
      
      final Map<String, dynamic> parsed = json.decode(jsonStr);
      
      return AIRiskAssessment(
        aiRiskScore: (parsed['aiRiskScore'] as num?)?.toInt() ?? 50,
        aiPriority: _normalizePriority(parsed['aiPriority'] as String?),
        confidenceScore: (parsed['confidenceScore'] as num?)?.toInt() ?? 70,
        riskFactors: [], // Empty for quick assessment
        urgencyIndicators: [], // Empty for quick assessment
        reasoning: parsed['reasoning'] as String? ?? 'Quick AI assessment',
        assessedAt: PhilippineTime.now(),
      );
    } catch (e) {
      return _createFallbackAssessment(crimeType, financialLoss);
    }
  }

  /// 🚀 NEW: AI-driven priority and risk scoring (replaces hard-coded calculations)
  /// This method provides intelligent, context-aware priority and risk assessment
  static Future<AIPriorityScoring> calculateAIPriorityAndRisk(
    Map<String, dynamic> formData,
    CrimeType crimeType,
  ) async {
    _debugLog('🎯 Starting AI-driven priority and risk calculation');
    
    try {
      // Build comprehensive prompt for AI analysis
      final prompt = _buildPriorityAssessmentPrompt(formData, crimeType);
      
      final model = _getModel;
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;
      
      if (responseText == null) {
        throw 'AI response was empty';
      }
      
      _debugLog('📨 AI Response received: ${responseText.length} characters');
      
      // Parse AI response
      final cleanedResponse = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      final parsed = json.decode(cleanedResponse);
      
      // Create AI priority scoring object
      final aiScoring = AIPriorityScoring(
        priority: _normalizePriority(parsed['priority'] as String?),
        riskScore: (parsed['riskScore'] as num?)?.toInt() ?? 50,
        aiPriority: _normalizePriority(parsed['aiPriority'] as String?),
        aiRiskScore: (parsed['aiRiskScore'] as num?)?.toInt() ?? 50,
        confidenceScore: (parsed['confidenceScore'] as num?)?.toInt() ?? 75,
        reasoning: parsed['reasoning'] as String? ?? 'AI-based assessment',
        riskFactors: List<String>.from(parsed['riskFactors'] ?? []),
        urgencyIndicators: List<String>.from(parsed['urgencyIndicators'] ?? []),
        assessedAt: PhilippineTime.now(),
      );
      
      _debugLog('✅ AI priority scoring completed: ${aiScoring.priority}/${aiScoring.riskScore}');
      return aiScoring;
      
    } catch (e) {
      _debugLog('❌ AI priority scoring failed: $e');
      return _createFallbackPriorityScoring(crimeType, formData);
    }
  }

  /// Build comprehensive prompt for AI priority assessment
  static String _buildPriorityAssessmentPrompt(Map<String, dynamic> formData, CrimeType crimeType) {
    return '''
You are an expert cybercrime analyst for the Philippine National Police. Analyze this cybercrime report and provide intelligent priority and risk scoring.

CYBERCRIME DETAILS:
- Crime Type: ${crimeType.displayName} (${crimeType.name})
- Category: ${crimeType.categoryName}
- Description: ${formData['description'] ?? 'No description'}
- Financial Loss: ₱${formData['estimatedFinancialLoss'] ?? 'None'}
- Incident Date: ${formData['incidentDateTime']?.toString() ?? 'Not specified'}
- Location: ${formData['incidentLocation'] ?? 'Not specified'}

SUSPECT INFORMATION:
- Name: ${formData['suspectName'] ?? 'Unknown'}
- Relationship: ${formData['suspectRelationship'] ?? 'Unknown'}
- Contact: ${formData['suspectContact'] ?? 'None'}
- Details: ${formData['suspectDetails'] ?? 'None'}

DIGITAL EVIDENCE:
- Platform/Website: ${formData['platformWebsite'] ?? 'None'}
- Account Reference: ${formData['accountReference'] ?? 'None'}
- Evidence Files: ${formData['evidenceFiles']?.length ?? 0} files

TECHNICAL DETAILS:
- System Details: ${formData['systemDetails'] ?? 'None'}
- Technical Info: ${formData['technicalInfo'] ?? 'None'}
- Attack Vector: ${formData['attackVector'] ?? 'None'}

ANALYSIS REQUIREMENTS:
1. Consider the full context, not just crime type and financial loss
2. Factor in evidence quality, suspect information, and urgency indicators
3. Consider threat patterns, escalation potential, and victim vulnerability
4. Evaluate immediate vs long-term risks
5. Consider resource allocation and investigative complexity

Please provide a comprehensive priority and risk assessment in the following JSON format:

{
  "priority": "low|medium|high",
  "riskScore": 0-100,
  "aiPriority": "low|medium|high|critical", 
  "aiRiskScore": 0-100,
  "confidenceScore": 0-100,
  "reasoning": "Detailed explanation in 2-3 sentences explaining the priority and risk assessment",
  "riskFactors": ["specific_risk_1", "specific_risk_2"],
  "urgencyIndicators": ["urgency_factor_1", "urgency_factor_2"]
}

SCORING GUIDELINES:
- Priority: Basic case urgency (low/medium/high)
- AI Priority: Enhanced urgency with critical option (low/medium/high/critical)
- Risk Score: Overall case complexity and threat level (0-100)
- AI Risk Score: Context-aware risk assessment (0-100)
- Confidence: How certain you are of this assessment (0-100)

Consider Philippine context, cybercrime trends, and investigative priorities.
''';
  }

  /// Intelligent fallback when AI fails (replaces hard-coded rules)
  static AIPriorityScoring _createFallbackPriorityScoring(CrimeType crimeType, Map<String, dynamic> formData) {
    _debugLog('⚠️ Using intelligent fallback priority scoring');
    
    // Smart fallbacks based on crime type and context
    String priority = 'medium';
    int riskScore = 50;
    String aiPriority = 'medium';
    int aiRiskScore = 50;
    List<String> riskFactors = ['ai_assessment_failed'];
    List<String> urgencyIndicators = [];
    
    // Context-aware adjustments (basic intelligence)
    final financialLoss = formData['estimatedFinancialLoss'] as double?;
    final hasEvidence = (formData['evidenceFiles'] as List?)?.isNotEmpty ?? false;
    final hasSuspectInfo = (formData['suspectName'] as String?)?.isNotEmpty ?? false;
    
    // Adjust based on financial impact
    if (financialLoss != null && financialLoss > 100000) {
      priority = 'high';
      aiPriority = 'high';
      riskScore = 80;
      aiRiskScore = 80;
      riskFactors.add('high_financial_loss');
    } else if (financialLoss != null && financialLoss > 10000) {
      riskScore = 65;
      aiRiskScore = 65;
      riskFactors.add('moderate_financial_loss');
    }
    
    // Adjust based on evidence and suspect info
    if (hasEvidence) {
      riskScore += 10;
      aiRiskScore += 10;
      riskFactors.add('evidence_available');
    }
    
    if (hasSuspectInfo) {
      urgencyIndicators.add('suspect_identified');
    }
    
    return AIPriorityScoring(
      priority: priority,
      riskScore: riskScore.clamp(0, 100),
      aiPriority: aiPriority,
      aiRiskScore: aiRiskScore.clamp(0, 100),
      confidenceScore: 60, // Lower confidence for fallback
      reasoning: 'Intelligent fallback assessment - AI service temporarily unavailable',
      riskFactors: riskFactors,
      urgencyIndicators: urgencyIndicators,
      assessedAt: PhilippineTime.now(),
    );
  }
}

/// AI Risk Assessment data model
class AIRiskAssessment {
  final int aiRiskScore;              // 0-100 AI-calculated risk
  final String aiPriority;            // 'critical', 'high', 'medium', 'low'  
  final int confidenceScore;          // AI confidence 0-100%
  final List<String> riskFactors;     // ["high_financial_loss", "known_suspect"]
  final List<String> urgencyIndicators; // ["immediate_threat", "ongoing_crime"]
  final String reasoning;             // AI explanation in Filipino/English
  final DateTime assessedAt;          // When assessment was performed

  AIRiskAssessment({
    required this.aiRiskScore,
    required this.aiPriority,
    required this.confidenceScore,
    required this.riskFactors,
    required this.urgencyIndicators,
    required this.reasoning,
    required this.assessedAt,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'aiRiskScore': aiRiskScore,
      'aiPriority': aiPriority,
      'confidenceScore': confidenceScore,
      'riskFactors': riskFactors,
      'urgencyIndicators': urgencyIndicators,
      'reasoning': reasoning,
      'assessedAt': assessedAt.toIso8601String(),
    };
  }

  /// Create from JSON (database retrieval)
  factory AIRiskAssessment.fromJson(Map<String, dynamic> json) {
    return AIRiskAssessment(
      aiRiskScore: json['aiRiskScore'] ?? 50,
      aiPriority: json['aiPriority'] ?? 'medium',
      confidenceScore: json['confidenceScore'] ?? 70,
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      urgencyIndicators: List<String>.from(json['urgencyIndicators'] ?? []),
      reasoning: json['reasoning'] ?? '',
      assessedAt: DateTime.parse(json['assessedAt'] ?? PhilippineTime.now().toIso8601String()),
    );
  }

  /// Get priority color for UI display
  Color get priorityColor {
    switch (aiPriority.toLowerCase()) {
      case 'critical':
        return const Color(0xFF991B1B); // Red-800
      case 'high':
        return const Color(0xFFDC2626); // Red-600
      case 'medium':
        return const Color(0xFFF59E0B); // Amber-500
      case 'low':
        return const Color(0xFF10B981); // Emerald-500
      default:
        return const Color(0xFF6B7280); // Gray-500
    }
  }

  /// Get risk score color for UI display
  Color get riskScoreColor {
    if (aiRiskScore >= 80) return const Color(0xFFDC2626); // Red
    if (aiRiskScore >= 60) return const Color(0xFFF59E0B); // Amber
    if (aiRiskScore >= 40) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF10B981); // Green
  }

  /// Get confidence level description
  String get confidenceLevel {
    if (confidenceScore >= 90) return 'Very High';
    if (confidenceScore >= 80) return 'High';
    if (confidenceScore >= 70) return 'Good';
    if (confidenceScore >= 60) return 'Moderate'; 
    return 'Low';
  }

  /// Format risk factors for display
  String get formattedRiskFactors {
    if (riskFactors.isEmpty) return 'None identified';
    return riskFactors.map((factor) {
      return factor.replaceAll('_', ' ').split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }).join(', ');
  }

  /// Format urgency indicators for display
  String get formattedUrgencyIndicators {
    if (urgencyIndicators.isEmpty) return 'None identified';
    return urgencyIndicators.map((indicator) {
      return indicator.replaceAll('_', ' ').split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }).join(', ');
  }

  // Enable/disable debug mode for AIRiskAssessmentService
  static void setDebugMode(bool enabled) {
    AIRiskAssessmentService._debugMode = enabled;
    AIRiskAssessmentService._debugLog(enabled ? '🟢 Debug mode enabled' : '🔴 Debug mode disabled');
  }
}

/// 🚀 NEW: AI Priority Scoring data model (replaces hard-coded calculations)
/// Focused specifically on priority and risk score calculation
class AIPriorityScoring {
  final String priority;              // Basic priority: 'low', 'medium', 'high'
  final int riskScore;               // Basic risk score: 0-100
  final String aiPriority;           // AI priority: 'low', 'medium', 'high', 'critical'
  final int aiRiskScore;             // AI risk score: 0-100
  final int confidenceScore;         // AI confidence: 0-100%
  final String reasoning;            // AI explanation
  final List<String> riskFactors;    // Identified risk factors
  final List<String> urgencyIndicators; // Urgency signals
  final DateTime assessedAt;         // Assessment timestamp

  AIPriorityScoring({
    required this.priority,
    required this.riskScore,
    required this.aiPriority,
    required this.aiRiskScore,
    required this.confidenceScore,
    required this.reasoning,
    required this.riskFactors,
    required this.urgencyIndicators,
    required this.assessedAt,
  });

  /// Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'priority': priority,
      'riskScore': riskScore,
      'aiPriority': aiPriority,
      'aiRiskScore': aiRiskScore,
      'confidenceScore': confidenceScore,
      'reasoning': reasoning,
      'riskFactors': riskFactors,
      'urgencyIndicators': urgencyIndicators,
      'assessedAt': assessedAt.toIso8601String(),
    };
  }

  /// Create from JSON (for database retrieval)
  factory AIPriorityScoring.fromJson(Map<String, dynamic> json) {
    return AIPriorityScoring(
      priority: json['priority'] ?? 'medium',
      riskScore: json['riskScore'] ?? 50,
      aiPriority: json['aiPriority'] ?? 'medium',
      aiRiskScore: json['aiRiskScore'] ?? 50,
      confidenceScore: json['confidenceScore'] ?? 75,
      reasoning: json['reasoning'] ?? '',
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      urgencyIndicators: List<String>.from(json['urgencyIndicators'] ?? []),
      assessedAt: DateTime.parse(json['assessedAt'] ?? PhilippineTime.now().toIso8601String()),
    );
  }

  /// Get priority color for UI display
  Color get priorityColor {
    switch (aiPriority.toLowerCase()) {
      case 'critical':
        return const Color(0xFF991B1B); // Red-800
      case 'high':
        return const Color(0xFFDC2626); // Red-600
      case 'medium':
        return const Color(0xFFF59E0B); // Amber-500
      case 'low':
        return const Color(0xFF10B981); // Emerald-500
      default:
        return const Color(0xFF6B7280); // Gray-500
    }
  }

  /// Get risk score color for UI display
  Color get riskScoreColor {
    if (aiRiskScore >= 80) return const Color(0xFFDC2626); // Red
    if (aiRiskScore >= 60) return const Color(0xFFF59E0B); // Amber
    if (aiRiskScore >= 40) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF10B981); // Green
  }

  @override
  String toString() {
    return 'AIPriorityScoring(priority: $priority, riskScore: $riskScore, aiPriority: $aiPriority, aiRiskScore: $aiRiskScore, confidence: $confidenceScore%)';
  }
}