import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../models/dynamic_field_config.dart';
import '../services/dynamic_field_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:math' as math;

class CredibilityScorer {
  static const String _apiKey = 'AIzaSyDyFbfNS8XwzcBtnpYY-5lovrTKH5-NXLM';
  static GenerativeModel? _model;
  static bool _debugMode = true; // Set to false in production
  
  static GenerativeModel get _getModel {
    if (_model == null) {
      _debugLog('🤖 Initializing CredibilityScorer with Gemini 2.0 Flash');
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.3, // Lower temperature for consistent scoring
          maxOutputTokens: 1000,
          topP: 0.8,
        ),
      );
      _debugLog('✅ CredibilityScorer initialized');
    }
    return _model!;
  }

  static void _debugLog(String message) {
    if (_debugMode) {
      print('🔍 [CredibilityScorer] $message');
    }
  }

  // Calculate overall credibility score for a complaint using AI
  static Future<CredibilityScore> calculateCredibilityScore(Map<String, dynamic> formData, CrimeType crimeType) async {
    final startTime = DateTime.now();
    _debugLog('🚀 Calculating AI credibility score for ${crimeType.displayName}');
    
    try {
      final aiScore = await _getAICredibilityScore(formData, crimeType);
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _debugLog('✅ AI credibility scoring completed in ${processingTime}ms');
      _debugLog('📊 Score: ${aiScore.overallScore}% (${aiScore.strengthLevel})');
      
      return aiScore;
    } catch (e) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ AI credibility scoring failed after ${processingTime}ms: $e');
      
      // Fallback to basic scoring if AI fails
      _debugLog('🔄 Using fallback credibility scoring');
      return _getFallbackCredibilityScore(formData, crimeType);
    }
  }

  // Synchronous method for backward compatibility - deprecated
  @deprecated
  static CredibilityScore calculateCredibilityScoreSync(Map<String, dynamic> formData, CrimeType crimeType) {
    _debugLog('⚠️ Using deprecated sync credibility scoring method');
    return _getFallbackCredibilityScore(formData, crimeType);
  }

  // AI-powered credibility assessment
  static Future<CredibilityScore> _getAICredibilityScore(Map<String, dynamic> formData, CrimeType crimeType) async {
    _debugLog('🎯 Building AI credibility assessment prompt');
    
    // Prepare form data summary (category-aware)
    final formSummary = _buildFormDataSummary(formData, crimeType);
    
    final prompt = '''
You are an expert cybercrime investigator for the Philippine National Police. Analyze the credibility and completeness of this cybercrime report and provide a detailed assessment.

**REPORT DETAILS:**
- Crime Type: ${crimeType.displayName}
- Category: ${crimeType.categoryName}
- Assigned Unit: ${crimeType.assignedUnit}

**FORM DATA ANALYSIS:**
$formSummary

**IMPORTANT SCORING INSTRUCTIONS:**
🔍 **CRITICAL**: Only evaluate fields that are RELEVANT to the "${crimeType.categoryName}" category.
- DO NOT penalize missing fields that are not applicable to ${crimeType.displayName}
- FOCUS ONLY on fields marked as "Relevant for ${crimeType.displayName}" in the analysis above
- IGNORE fields not listed under "CATEGORY-SPECIFIC FIELDS" section
- CORE FIELDS (name, email, phone, description, date, evidence) are always required

**ASSESSMENT TASK:**
Analyze this report's credibility and completeness across these key factors:

1. **Information Completeness** - Are the RELEVANT fields for ${crimeType.categoryName} filled adequately?
2. **Evidence Quality** - Is there sufficient evidence for investigating ${crimeType.displayName}?
3. **Report Consistency** - Are the details logical for this specific crime type?
4. **Category Relevance** - Does the provided information match what's needed for ${crimeType.displayName}?

**RESPONSE FORMAT:**
Respond with a JSON object in this exact format:
{
  "overall_score": 85,
  "strength_level": "Strong" or "Moderate" or "Weak" or "Critical",
  "factors": [
    {
      "name": "Information Completeness",
      "score": 90,
      "description": "Assessment focusing only on relevant fields for ${crimeType.categoryName}",
      "suggestions": ["Specific suggestions for ${crimeType.displayName}"]
    },
    {
      "name": "Category Relevance", 
      "score": 85,
      "description": "How well the information fits ${crimeType.displayName} requirements",
      "suggestions": ["Category-specific improvements"]
    }
  ],
  "key_suggestions": [
    "Priority improvements specific to ${crimeType.displayName}",
    "Focus on relevant evidence for this crime type"
  ],
  "confidence_level": 85
}

**SCORING GUIDELINES FOR ${crimeType.categoryName.toUpperCase()}:**
- 90-100: Excellent - All relevant fields complete, ready for ${crimeType.assignedUnit}
- 70-89: Good - Most relevant fields complete, minor gaps
- 50-69: Fair - Some relevant fields missing, needs improvement
- 30-49: Poor - Many relevant fields incomplete for ${crimeType.displayName}
- 0-29: Critical - Insufficient information for this crime type

**REQUIREMENTS:**
- Use Filipino/English mix naturally
- Focus ONLY on fields relevant to ${crimeType.categoryName}
- Consider what ${crimeType.assignedUnit} needs for investigation
- Be specific about missing RELEVANT information only
- Acknowledge that irrelevant fields should be ignored

**EXAMPLE:**
If this is Cyberbullying (Harassment & Exploitation), focus on suspect information, platform details, and harassment specifics.
Do NOT penalize for missing financial loss amounts or technical system details - those are irrelevant.

Analyze this ${crimeType.displayName} report now:''';

    _debugLog('📤 Sending credibility assessment prompt to Gemini AI (${prompt.length} characters)');
    
    final content = [Content.text(prompt)];
    final response = await _getModel.generateContent(content);
    final aiResponse = response.text;
    
    if (aiResponse == null || aiResponse.isEmpty) {
      throw 'Empty AI response';
    }
    
    _debugLog('📥 Received AI credibility response (${aiResponse.length} characters)');
    
    return _parseAICredibilityResponse(aiResponse, crimeType);
  }

  // Build a summary of form data for AI analysis (category-aware)
  static String _buildFormDataSummary(Map<String, dynamic> formData, CrimeType crimeType) {
    final List<String> summary = [];
    final categoryName = crimeType.categoryName;
    
    // Get visible fields for this crime category
    final visibleFields = DynamicFieldConfig.getFieldsForCategory(categoryName);
    
    _debugLog('🎯 Analyzing ${visibleFields.length} visible fields for category: $categoryName');
    
    // Basic Information (always included)
    summary.add('**BASIC INFORMATION:**');
    summary.add('- Full Name: ${_getFieldStatus(formData['fullName'])}');
    summary.add('- Email: ${_getFieldStatus(formData['email'])}');
    summary.add('- Phone: ${_getFieldStatus(formData['phoneNumber'])}');
    summary.add('- Incident Date: ${_getFieldStatus(formData['incidentDateTime']?.toString())}');
    
    // Description (always included)
    summary.add('\n**DESCRIPTION:**');
    final description = formData['description'] ?? '';
    if (description.isNotEmpty) {
      summary.add('- Length: ${description.length} characters');
      summary.add('- Content: "${description.length > 200 ? '${description.substring(0, 200)}...' : description}"');
    } else {
      summary.add('- Status: Empty/Missing (CRITICAL - Always Required)');
    }
    
    // Evidence Files (always included)
    summary.add('\n**EVIDENCE:**');
    final evidenceFiles = formData['evidenceFiles'] ?? [];
    if (evidenceFiles is List && evidenceFiles.isNotEmpty) {
      summary.add('- Files: ${evidenceFiles.length} evidence files attached');
    } else {
      summary.add('- Files: No evidence files attached');
    }
    
    // Category-specific fields analysis
    summary.add('\n**CATEGORY-SPECIFIC FIELDS FOR ${categoryName.toUpperCase()}:**');
    
    // Financial Information (only if visible for this category)
    if (visibleFields.contains(ComplaintField.financialLoss)) {
      if (formData['estimatedFinancialLoss'] != null) {
        summary.add('- Financial Loss: ₱${formData['estimatedFinancialLoss']} (Provided - Important for this crime type)');
      } else {
        summary.add('- Financial Loss: Not provided (Missing - Important for ${crimeType.displayName})');
      }
    }
    
    // Location (only if visible)
    if (visibleFields.contains(ComplaintField.incidentLocation)) {
      summary.add('- Location: ${_getFieldStatus(formData['incidentLocation'])}');
    }
    
    // Platform/Website (only if visible)
    if (visibleFields.contains(ComplaintField.platformWebsite)) {
      summary.add('- Platform/Website: ${_getFieldStatus(formData['platformWebsite'])}');
    }
    
    // Account Reference (only if visible)
    if (visibleFields.contains(ComplaintField.accountReference)) {
      summary.add('- Account Reference: ${_getFieldStatus(formData['accountReference'])}');
    }
    
    // Suspect Information (only if visible for this category)
    if (visibleFields.contains(ComplaintField.suspectName) || 
        visibleFields.contains(ComplaintField.suspectContact) || 
        visibleFields.contains(ComplaintField.suspectRelationship)) {
      summary.add('\n**SUSPECT INFORMATION (Relevant for ${crimeType.displayName}):**');
      
      if (visibleFields.contains(ComplaintField.suspectName)) {
        summary.add('- Name: ${_getFieldStatus(formData['suspectName'])}');
      }
      if (visibleFields.contains(ComplaintField.suspectContact)) {
        summary.add('- Contact: ${_getFieldStatus(formData['suspectContact'])}');
      }
      if (visibleFields.contains(ComplaintField.suspectRelationship)) {
        summary.add('- Relationship: ${formData['suspectRelationship'] ?? 'Not specified'}');
      }
      if (visibleFields.contains(ComplaintField.suspectDetails)) {
        summary.add('- Additional Details: ${_getFieldStatus(formData['suspectDetails'])}');
      }
    }
    
    // Technical Fields (only if visible)
    if (visibleFields.contains(ComplaintField.systemDetails) ||
        visibleFields.contains(ComplaintField.technicalInfo) ||
        visibleFields.contains(ComplaintField.attackVector)) {
      summary.add('\n**TECHNICAL INFORMATION (Relevant for ${crimeType.displayName}):**');
      
      if (visibleFields.contains(ComplaintField.systemDetails)) {
        summary.add('- System Details: ${_getFieldStatus(formData['systemDetails'])}');
      }
      if (visibleFields.contains(ComplaintField.technicalInfo)) {
        summary.add('- Technical Info: ${_getFieldStatus(formData['technicalInfo'])}');
      }
      if (visibleFields.contains(ComplaintField.attackVector)) {
        summary.add('- Attack Vector: ${_getFieldStatus(formData['attackVector'])}');
      }
    }
    
    // Additional category-specific fields
    if (visibleFields.contains(ComplaintField.contentDescription)) {
      summary.add('\n**CONTENT DETAILS:**');
      summary.add('- Content Description: ${_getFieldStatus(formData['contentDescription'])}');
    }
    
    if (visibleFields.contains(ComplaintField.impactAssessment)) {
      summary.add('- Impact Assessment: ${_getFieldStatus(formData['impactAssessment'])}');
    }
    
    // Add field relevance context
    summary.add('\n**FIELD ANALYSIS CONTEXT:**');
    summary.add('- Crime Category: ${categoryName}');
    summary.add('- Expected Fields: ${visibleFields.length} fields relevant for this crime type');
    summary.add('- Note: Only fields relevant to ${crimeType.displayName} should be considered for completeness scoring');
    
    return summary.join('\n');
  }

  static String _getFieldStatus(dynamic value) {
    if (value == null) return 'Not provided';
    if (value is String) {
      if (value.isEmpty) return 'Empty';
      return 'Provided (${value.length} chars)';
    }
    return 'Provided';
  }

  // Parse AI response into CredibilityScore object
  static CredibilityScore _parseAICredibilityResponse(String aiResponse, CrimeType crimeType) {
    _debugLog('🔧 Parsing AI credibility response');
    
    try {
      // Extract JSON from response
      String jsonStr = aiResponse.trim();
      if (jsonStr.contains('```json')) {
        final startIndex = jsonStr.indexOf('```json') + 7;
        final endIndex = jsonStr.lastIndexOf('```');
        if (endIndex > startIndex) {
          jsonStr = jsonStr.substring(startIndex, endIndex).trim();
        }
      } else if (jsonStr.contains('```')) {
        final startIndex = jsonStr.indexOf('```') + 3;
        final endIndex = jsonStr.lastIndexOf('```');
        if (endIndex > startIndex) {
          jsonStr = jsonStr.substring(startIndex, endIndex).trim();
        }
      }
      
      _debugLog('🔍 Extracted credibility JSON: ${jsonStr.substring(0, math.min(300, jsonStr.length))}...');
      
      final jsonData = json.decode(jsonStr);
      
      // Parse factors
      final List<dynamic> factorsData = jsonData['factors'] ?? [];
      final List<CredibilityFactor> factors = factorsData.map((factor) {
        return CredibilityFactor(
          name: factor['name'] ?? 'Assessment Factor',
          score: (factor['score'] ?? 50).toDouble() / 100.0,
          description: factor['description'] ?? 'AI assessment factor',
          suggestions: List<String>.from(factor['suggestions'] ?? []),
        );
      }).toList();
      
      // Parse suggestions
      final List<String> suggestions = List<String>.from(jsonData['key_suggestions'] ?? []);
      
      final credibilityScore = CredibilityScore(
        overallScore: jsonData['overall_score'] ?? 50,
        factors: factors,
        suggestions: suggestions,
        strengthLevel: jsonData['strength_level'] ?? 'Moderate',
      );
      
      _debugLog('✅ Successfully parsed credibility score: ${credibilityScore.overallScore}%');
      
      return credibilityScore;
    } catch (e) {
      _debugLog('❌ Failed to parse AI credibility response: $e');
      _debugLog('📝 Raw response: ${aiResponse.substring(0, math.min(500, aiResponse.length))}');
      
      // Return fallback with AI content
      return CredibilityScore(
        overallScore: 60,
        factors: [
          CredibilityFactor(
            name: 'AI Analysis',
            score: 0.6,
            description: aiResponse.length > 200 ? '${aiResponse.substring(0, 200)}...' : aiResponse,
            suggestions: ['Review report completeness', 'Add more evidence if available'],
          ),
        ],
        suggestions: ['AI analysis available but needs manual review'],
        strengthLevel: 'Moderate',
      );
    }
  }

  // Fallback credibility scoring when AI fails (category-aware)
  static CredibilityScore _getFallbackCredibilityScore(Map<String, dynamic> formData, CrimeType crimeType) {
    _debugLog('🔄 Generating fallback credibility score for ${crimeType.displayName}');
    
    final categoryName = crimeType.categoryName;
    final visibleFields = DynamicFieldConfig.getFieldsForCategory(categoryName);
    
    _debugLog('🎯 Fallback scoring using ${visibleFields.length} relevant fields for $categoryName');
    
    int score = 0;
    List<CredibilityFactor> factors = [];
    List<String> suggestions = [];
    
    // Core fields completeness (always required)
    int completedCoreFields = 0;
    int totalCoreFields = 6; // fullName, email, phone, description, incidentDateTime, crimeType
    
    if (formData['fullName']?.isNotEmpty == true) completedCoreFields++;
    if (formData['email']?.isNotEmpty == true) completedCoreFields++;
    if (formData['phoneNumber']?.isNotEmpty == true) completedCoreFields++;
    if (formData['description']?.isNotEmpty == true) completedCoreFields++;
    if (formData['incidentDateTime'] != null) completedCoreFields++;
    if (formData['crimeType'] != null) completedCoreFields++;
    
    // Category-specific fields completeness
    int completedCategoryFields = 0;
    int totalCategoryFields = 0;
    List<String> missingCategoryFields = [];
    
    // Check each category-specific field
    final Map<ComplaintField, String> fieldFormMapping = {
      ComplaintField.incidentLocation: 'incidentLocation',
      ComplaintField.platformWebsite: 'platformWebsite',
      ComplaintField.accountReference: 'accountReference',
      ComplaintField.financialLoss: 'estimatedFinancialLoss',
      ComplaintField.suspectName: 'suspectName',
      ComplaintField.suspectRelationship: 'suspectRelationship',
      ComplaintField.suspectContact: 'suspectContact',
      ComplaintField.suspectDetails: 'suspectDetails',
      ComplaintField.systemDetails: 'systemDetails',
      ComplaintField.technicalInfo: 'technicalInfo',
      ComplaintField.vulnerabilityDetails: 'vulnerabilityDetails',
      ComplaintField.securityLevel: 'securityLevel',
      ComplaintField.targetInfo: 'targetInfo',
      ComplaintField.attackVector: 'attackVector',
      ComplaintField.contentDescription: 'contentDescription',
      ComplaintField.impactAssessment: 'impactAssessment',
    };
    
    for (final field in visibleFields) {
      if (fieldFormMapping.containsKey(field)) {
        totalCategoryFields++;
        final formKey = fieldFormMapping[field]!;
        final value = formData[formKey];
        
        if (value != null && value.toString().trim().isNotEmpty) {
          completedCategoryFields++;
        } else {
          final config = DynamicFieldConfig.getFieldConfig(field);
          missingCategoryFields.add(config?.label ?? field.name);
        }
      }
    }
    
    // Calculate core completeness (70% weight)
    final coreCompleteness = completedCoreFields / totalCoreFields;
    final coreScore = (coreCompleteness * 70).round();
    
    // Calculate category completeness (30% weight)
    final categoryCompleteness = totalCategoryFields > 0 ? completedCategoryFields / totalCategoryFields : 1.0;
    final categoryScore = (categoryCompleteness * 30).round();
    
    score = coreScore + categoryScore;
    
    // Core fields factor
    factors.add(CredibilityFactor(
      name: 'Core Information',
      score: coreCompleteness,
      description: 'Completed $completedCoreFields out of $totalCoreFields essential fields',
      suggestions: completedCoreFields < totalCoreFields ? ['Complete all required personal and incident details'] : [],
    ));
    
    // Category-specific fields factor
    if (totalCategoryFields > 0) {
      factors.add(CredibilityFactor(
        name: '${crimeType.categoryName} Specific Fields',
        score: categoryCompleteness,
        description: 'Completed $completedCategoryFields out of $totalCategoryFields relevant fields for ${crimeType.displayName}',
        suggestions: missingCategoryFields.isNotEmpty 
          ? ['Add relevant details: ${missingCategoryFields.take(3).join(', ')}${missingCategoryFields.length > 3 ? ' and ${missingCategoryFields.length - 3} more' : ''}']
          : [],
      ));
    }
    
    // Evidence assessment
    final evidenceFiles = formData['evidenceFiles'] ?? [];
    if (evidenceFiles is List && evidenceFiles.isEmpty) {
      suggestions.add('Add evidence files to support your ${crimeType.displayName} report');
      score = math.max(30, score - 15); // Reduce score if no evidence, but less penalty than before
    } else if (evidenceFiles is List && evidenceFiles.isNotEmpty) {
      // Bonus for having evidence
      score = math.min(100, score + 5);
    }
    
    // Overall suggestions based on crime type
    if (completedCoreFields < totalCoreFields) {
      suggestions.add('Complete all required personal information');
    }
    
    if (missingCategoryFields.isNotEmpty) {
      suggestions.add('Provide ${crimeType.displayName}-specific details to help investigators');
    }
    
    // Determine strength level
    String strengthLevel = 'Critical';
    if (score >= 85) strengthLevel = 'Strong';
    else if (score >= 70) strengthLevel = 'Moderate';
    else if (score >= 50) strengthLevel = 'Fair';
    else if (score >= 30) strengthLevel = 'Weak';
    
    _debugLog('📊 Fallback score: $score% (Core: $coreScore%, Category: $categoryScore%, Level: $strengthLevel)');
    
    return CredibilityScore(
      overallScore: score,
      factors: factors,
      suggestions: suggestions,
      strengthLevel: strengthLevel,
    );
  }

  // Enable/disable debug mode
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
    _debugLog(enabled ? '🟢 Debug mode enabled' : '🔴 Debug mode disabled');
  }
}