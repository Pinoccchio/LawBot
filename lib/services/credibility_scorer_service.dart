import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
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
    
    // Prepare form data summary
    final formSummary = _buildFormDataSummary(formData);
    
    final prompt = '''
You are an expert cybercrime investigator for the Philippine National Police. Analyze the credibility and completeness of this cybercrime report and provide a detailed assessment.

**REPORT DETAILS:**
- Crime Type: ${crimeType.displayName}
- Category: ${crimeType.categoryName}
- Assigned Unit: ${crimeType.assignedUnit}

**FORM DATA ANALYSIS:**
$formSummary

**ASSESSMENT TASK:**
Analyze this report's credibility and completeness across these key factors:

1. **Information Completeness** - Are required fields filled out adequately?
2. **Evidence Quality** - Is there sufficient evidence for investigation?
3. **Report Consistency** - Are the details logical and consistent?
4. **Urgency Indicators** - Are there signs this needs immediate attention?

**RESPONSE FORMAT:**
Respond with a JSON object in this exact format:
{
  "overall_score": 85,
  "strength_level": "Strong" or "Moderate" or "Weak" or "Critical",
  "factors": [
    {
      "name": "Information Completeness",
      "score": 90,
      "description": "Detailed assessment in Filipino/English mix",
      "suggestions": ["Suggestion 1", "Suggestion 2"]
    }
  ],
  "key_suggestions": [
    "Priority improvement 1",
    "Priority improvement 2"
  ],
  "confidence_level": 85
}

**SCORING GUIDELINES:**
- 90-100: Excellent - Complete, credible, ready for investigation
- 70-89: Good - Minor improvements needed
- 50-69: Fair - Moderate improvements needed  
- 30-49: Poor - Major improvements needed
- 0-29: Critical - Significant issues, needs major revision

**REQUIREMENTS:**
- Use Filipino/English mix naturally
- Focus on practical investigation needs
- Consider Philippine cybercrime context
- Prioritize evidence that helps PNP investigators
- Be specific about what's missing or needed

Analyze this cybercrime report now:''';

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

  // Build a summary of form data for AI analysis
  static String _buildFormDataSummary(Map<String, dynamic> formData) {
    final List<String> summary = [];
    
    // Basic Information
    summary.add('**BASIC INFORMATION:**');
    summary.add('- Full Name: ${_getFieldStatus(formData['fullName'])}');
    summary.add('- Email: ${_getFieldStatus(formData['email'])}');
    summary.add('- Phone: ${_getFieldStatus(formData['phoneNumber'])}');
    summary.add('- Incident Date: ${_getFieldStatus(formData['incidentDateTime']?.toString())}');
    
    // Description
    summary.add('\n**DESCRIPTION:**');
    final description = formData['description'] ?? '';
    if (description.isNotEmpty) {
      summary.add('- Length: ${description.length} characters');
      summary.add('- Content: "${description.length > 200 ? '${description.substring(0, 200)}...' : description}"');
    } else {
      summary.add('- Status: Empty/Missing');
    }
    
    // Evidence Files
    summary.add('\n**EVIDENCE:**');
    final evidenceFiles = formData['evidenceFiles'] ?? [];
    if (evidenceFiles is List && evidenceFiles.isNotEmpty) {
      summary.add('- Files: ${evidenceFiles.length} evidence files attached');
    } else {
      summary.add('- Files: No evidence files attached');
    }
    
    // Financial Information
    if (formData['estimatedFinancialLoss'] != null) {
      summary.add('\n**FINANCIAL IMPACT:**');
      summary.add('- Loss Amount: ₱${formData['estimatedFinancialLoss']}');
    }
    
    // Suspect Information
    summary.add('\n**SUSPECT DETAILS:**');
    summary.add('- Name: ${_getFieldStatus(formData['suspectName'])}');
    summary.add('- Contact: ${_getFieldStatus(formData['suspectContact'])}');
    summary.add('- Relationship: ${formData['suspectRelationship'] ?? 'Unknown'}');
    
    // Platform/Technical Details
    if (formData['platformWebsite'] != null && formData['platformWebsite'].isNotEmpty) {
      summary.add('\n**PLATFORM/TECHNICAL:**');
      summary.add('- Platform: ${formData['platformWebsite']}');
      summary.add('- Account Reference: ${_getFieldStatus(formData['accountReference'])}');
    }
    
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

  // Fallback credibility scoring when AI fails
  static CredibilityScore _getFallbackCredibilityScore(Map<String, dynamic> formData, CrimeType crimeType) {
    _debugLog('🔄 Generating fallback credibility score');
    
    int score = 0;
    List<CredibilityFactor> factors = [];
    List<String> suggestions = [];
    
    // Basic completeness check
    int completedFields = 0;
    int totalFields = 6;
    
    if (formData['fullName']?.isNotEmpty == true) completedFields++;
    if (formData['email']?.isNotEmpty == true) completedFields++;
    if (formData['phoneNumber']?.isNotEmpty == true) completedFields++;
    if (formData['description']?.isNotEmpty == true) completedFields++;
    if (formData['incidentDateTime'] != null) completedFields++;
    if (formData['crimeType'] != null) completedFields++;
    
    final completeness = completedFields / totalFields;
    score = (completeness * 100).round();
    
    factors.add(CredibilityFactor(
      name: 'Basic Information',
      score: completeness,
      description: 'Completed $completedFields out of $totalFields required fields',
      suggestions: completedFields < totalFields ? ['Complete all required fields'] : [],
    ));
    
    if (completedFields < totalFields) {
      suggestions.add('Complete all required information fields');
    }
    
    final evidenceFiles = formData['evidenceFiles'] ?? [];
    if (evidenceFiles is List && evidenceFiles.isEmpty) {
      suggestions.add('Add evidence files to support your report');
      score = math.max(30, score - 20); // Reduce score if no evidence
    }
    
    String strengthLevel = 'Weak';
    if (score >= 80) strengthLevel = 'Strong';
    else if (score >= 60) strengthLevel = 'Moderate';
    else if (score >= 40) strengthLevel = 'Fair';
    
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