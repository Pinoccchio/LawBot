import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'ai_database_service.dart';

class EvidenceGuidanceService {
  static const String _apiKey = 'AIzaSyDyFbfNS8XwzcBtnpYY-5lovrTKH5-NXLM';
  static GenerativeModel? _model;
  static bool _debugMode = true; // Set to false in production
  
  static GenerativeModel get _getModel {
    if (_model == null) {
      _debugLog('🤖 Initializing EvidenceGuidanceService with Gemini 2.0 Flash');
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 1500,
          topP: 0.8,
        ),
      );
      _debugLog('✅ EvidenceGuidanceService initialized');
    }
    return _model!;
  }

  static void _debugLog(String message) {
    if (_debugMode) {
      print('🔍 [EvidenceGuidance] $message');
    }
  }

  // Get AI-powered evidence suggestions for a specific crime type with database integration
  static Future<List<EvidenceGuidanceItem>> getEvidenceGuidance(CrimeType crimeType, {String? description}) async {
    final startTime = DateTime.now();
    _debugLog('🚀 Getting AI evidence guidance for ${crimeType.displayName}');
    
    try {
      // Check for cached evidence guidance first
      _debugLog('🔍 Checking for cached evidence guidance');
      final cachedGuidance = await AIDatabaseService.getCachedEvidenceGuidance(crimeType);
      
      if (cachedGuidance != null && cachedGuidance.isNotEmpty) {
        final cacheTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog('⚡ Cache HIT! Evidence guidance retrieved in ${cacheTime}ms');
        return cachedGuidance;
      }
      
      // Generate AI suggestions if not cached
      final aiSuggestions = await _getAIEvidenceGuidance(crimeType, description ?? '');
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      
      _debugLog('✅ AI evidence guidance completed in ${processingTime}ms');
      _debugLog('📋 Generated ${aiSuggestions.length} evidence suggestions');
      
      // Store in database for future use
      _debugLog('💾 Storing evidence guidance in database');
      AIDatabaseService.storeEvidenceGuidance(
        crimeType: crimeType,
        items: aiSuggestions,
      );
      
      return aiSuggestions;
    } catch (e) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ AI evidence guidance failed after ${processingTime}ms: $e');
      
      // Fallback to basic guidance if AI fails
      _debugLog('🔄 Using fallback evidence guidance');
      return _getFallbackEvidenceGuidance(crimeType);
    }
  }

  // Synchronous method for backward compatibility - deprecated
  @deprecated
  static List<EvidenceGuidanceItem> getEvidenceGuidanceSync(CrimeType crimeType) {
    _debugLog('⚠️ Using deprecated sync method for ${crimeType.displayName}');
    return _getFallbackEvidenceGuidance(crimeType);
  }

  // AI-powered evidence guidance generation
  static Future<List<EvidenceGuidanceItem>> _getAIEvidenceGuidance(CrimeType crimeType, String description) async {
    _debugLog('🎯 Building AI prompt for ${crimeType.displayName}');
    
    final prompt = '''
You are an expert cybercrime investigator for the Philippine National Police. Generate specific evidence collection guidance for this cybercrime report:

**CRIME DETAILS:**
- Crime Type: ${crimeType.displayName}
- Category: ${crimeType.categoryName}
- Assigned Unit: ${crimeType.assignedUnit}
- Case Description: ${description.isNotEmpty ? description : 'No specific description provided'}

**INSTRUCTIONS:**
Generate exactly 4-6 evidence collection items in JSON format. Each item should be practical, actionable, and appropriate for Filipino context.

Use this exact JSON structure:
{
  "evidence_items": [
    {
      "title": "Evidence Title (Filipino/English mix)",
      "description": "Detailed collection instructions in Filipino/English",
      "icon": "📱 or 💰 or 🔒 etc.",
      "priority": "Critical" or "High" or "Medium" or "Low",
      "examples": ["Example 1", "Example 2", "Example 3"]
    }
  ]
}

**REQUIREMENTS:**
- Use Filipino/English mix naturally (like "I-screenshot ang conversation")
- Focus on digital evidence (screenshots, receipts, messages, profiles)
- Include specific platforms common in Philippines (GCash, Facebook, Messenger)
- Prioritize evidence that helps identify suspects and prove damages
- Make instructions clear for ordinary citizens to follow
- Include emergency evidence (time-sensitive items) as Critical priority

Generate practical, investigator-grade evidence guidance now:''';

    _debugLog('📤 Sending prompt to Gemini AI (${prompt.length} characters)');
    
    final content = [Content.text(prompt)];
    final response = await _getModel.generateContent(content);
    final aiResponse = response.text;
    
    if (aiResponse == null || aiResponse.isEmpty) {
      throw 'Empty AI response';
    }
    
    _debugLog('📥 Received AI response (${aiResponse.length} characters)');
    
    return _parseAIEvidenceResponse(aiResponse, crimeType);
  }

  // Parse AI response into EvidenceGuidanceItem objects
  static List<EvidenceGuidanceItem> _parseAIEvidenceResponse(String aiResponse, CrimeType crimeType) {
    _debugLog('🔧 Parsing AI response for evidence items');
    
    try {
      // Extract JSON from response (handle markdown code blocks)
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
      
      _debugLog('🔍 Extracted JSON: ${jsonStr.substring(0, math.min(200, jsonStr.length))}...');
      
      final jsonData = json.decode(jsonStr);
      final List<dynamic> evidenceItems = jsonData['evidence_items'];
      
      final List<EvidenceGuidanceItem> items = evidenceItems.map((item) {
        return EvidenceGuidanceItem(
          title: item['title'] ?? 'Evidence Item',
          description: item['description'] ?? 'Collect relevant evidence',
          icon: item['icon'] ?? '📋',
          priority: item['priority'] ?? 'Medium',
          examples: List<String>.from(item['examples'] ?? []),
        );
      }).toList();
      
      _debugLog('✅ Successfully parsed ${items.length} evidence items');
      
      return items;
    } catch (e) {
      _debugLog('❌ Failed to parse AI response: $e');
      _debugLog('📝 Raw response: ${aiResponse.substring(0, math.min(500, aiResponse.length))}');
      
      // Return fallback with AI content as description
      return [
        EvidenceGuidanceItem(
          title: 'AI-Generated Evidence Guidance',
          description: aiResponse.length > 300 ? '${aiResponse.substring(0, 300)}...' : aiResponse,
          icon: '🤖',
          priority: 'High',
          examples: [],
        ),
      ];
    }
  }

  // Get dynamic AI-powered suggestions (legacy method - now uses new AI system)
  static Future<String> getAISuggestions(CrimeType crimeType, String description) async {
    _debugLog('🔄 Using legacy getAISuggestions method - redirecting to new AI system');
    
    try {
      final evidenceItems = await _getAIEvidenceGuidance(crimeType, description);
      
      // Convert evidence items to string format
      final suggestions = evidenceItems.map((item) => 
        '${item.icon} ${item.title}: ${item.description}'
      ).join('\n\n');
      
      return suggestions.isNotEmpty ? suggestions : 'Unable to generate suggestions at this time.';
    } catch (e) {
      _debugLog('❌ Legacy method fallback: $e');
      return 'Para sa ${crimeType.displayName}, mag-collect ng screenshots, transaction records, at contact information ng suspected scammer.';
    }
  }

  // Fallback evidence guidance when AI fails
  static List<EvidenceGuidanceItem> _getFallbackEvidenceGuidance(CrimeType crimeType) {
    _debugLog('🔄 Generating fallback evidence guidance for ${crimeType.displayName}');
    
    return [
      EvidenceGuidanceItem(
        title: 'Screenshots at Messages',
        description: 'I-capture ang lahat ng conversations, messages, o communications sa suspected scammer',
        icon: '💬',
        priority: 'Critical',
        examples: ['Facebook Messenger', 'SMS screenshots', 'WhatsApp chats'],
      ),
      EvidenceGuidanceItem(
        title: 'Financial Records',
        description: 'I-screenshot ang lahat ng payment receipts, bank transfers, o money transfers',
        icon: '💰',
        priority: 'Critical',
        examples: ['GCash receipts', 'Bank transfer records', 'Payment confirmations'],
      ),
      EvidenceGuidanceItem(
        title: 'Suspect Information',
        description: 'I-collect ang profile information, contact details, at ibang identifying information',
        icon: '👤',
        priority: 'High',
        examples: ['Social media profiles', 'Phone numbers', 'Email addresses'],
      ),
    ];
  }

  // Enable/disable debug mode
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
    _debugLog(enabled ? '🟢 Debug mode enabled' : '🔴 Debug mode disabled');
  }
}