import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

class GeminiService {
  // IMPORTANT: Be careful with hardcoded API keys in production apps
  // This key will be visible in your app's binary and could be extracted
  static const String _apiKey = "AIzaSyCs8F21zwcMVhv4ZbkGJ_PtetqdbxPvl7M"; // Replace with your actual API key
  static const String _modelName = 'gemini-2.0-flash';

  // Philippine cybercrime law context for better responses
  static const String _systemPrompt = '''
You are LawBot, an AI legal assistant specialized in Philippine cybercrime laws. You have expertise in:

1. Republic Act No. 10175 (Cybercrime Prevention Act of 2012)
2. Republic Act No. 10173 (Data Privacy Act of 2012)
3. Philippine cybercrime enforcement agencies (PNP-ACG, NBI-CCD)
4. Cyber harassment, identity theft, e-commerce fraud, and online scams

Guidelines for responses:
- Provide accurate legal information based on Philippine laws
- Be helpful and professional
- Suggest proper reporting procedures when applicable
- Include relevant law sections and penalties when appropriate
- Be empathetic to users who may be victims of cybercrime
- Always recommend consulting with a lawyer for complex cases
- Keep responses concise but informative (max 500 words)
- Use both English and Filipino terms when helpful

Current conversation context: The user is asking about cybercrime-related legal matters in the Philippines.

Format your response as a valid JSON object with these properties:
{
  "response": "your detailed legal response here",
  "category": "one of: Cybercrime Prevention Act, Online Harassment, E-commerce Fraud, Identity Theft, Data Privacy, Unauthorized Access, General",
  "confidence": "number between 0.0 and 1.0",
  "keywords": ["array", "of", "relevant", "legal", "keywords"],
  "recommendations": ["array", "of", "actionable", "recommendations"]
}
''';

  static Future<Map<String, dynamic>> generateLegalResponse(
      String userMessage,
      List<Map<String, String>> chatHistory
      ) async {
    try {
      // Initialize the Gemini model
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      // Build conversation context
      String conversationContext = _systemPrompt;

      // Add recent chat history (last 3 exchanges)
      if (chatHistory.isNotEmpty) {
        conversationContext += "\n\nRecent conversation context:\n";
        final recentHistory = chatHistory.length > 6
            ? chatHistory.sublist(chatHistory.length - 6)
            : chatHistory;

        for (var message in recentHistory) {
          String role = message['isBot'] == 'true' ? 'LawBot' : 'User';
          conversationContext += "$role: ${message['text']}\n";
        }
      }

      // Create the prompt with context
      final prompt = '''
$conversationContext

Current user question: "$userMessage"

Please analyze this question about Philippine cybercrime law and provide a comprehensive legal response in the specified JSON format.
''';

      // Create content
      final content = [Content.text(prompt)];

      // Generate content
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';

      // Parse the JSON response
      try {
        // Extract JSON from the response text
        final jsonRegExp = RegExp(r'{[\s\S]*}');
        final match = jsonRegExp.firstMatch(responseText);

        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            final Map<String, dynamic> jsonData = jsonDecode(jsonStr);

            // Validate required fields and provide defaults
            return {
              'response': jsonData['response'] ?? _getFallbackResponse(userMessage),
              'category': jsonData['category'] ?? _categorizeMessage(userMessage),
              'confidence': _parseConfidence(jsonData['confidence']),
              'keywords': jsonData['keywords'] ?? [],
              'recommendations': jsonData['recommendations'] ?? [],
            };
          }
        }

        // If JSON parsing fails, return structured fallback
        return _getStructuredFallback(userMessage);

      } catch (e) {
        print('Error parsing JSON response: $e');
        print('Raw response: $responseText');
        return _getStructuredFallback(userMessage);
      }

    } catch (e) {
      print('Error in generateLegalResponse: $e');
      return _getStructuredFallback(userMessage);
    }
  }

  static double _parseConfidence(dynamic confidence) {
    if (confidence is num) {
      return confidence.toDouble().clamp(0.0, 1.0);
    } else if (confidence is String) {
      try {
        return double.parse(confidence).clamp(0.0, 1.0);
      } catch (e) {
        return 0.75; // Default confidence
      }
    }
    return 0.75; // Default confidence
  }

  static Map<String, dynamic> _getStructuredFallback(String userMessage) {
    return {
      'response': _getFallbackResponse(userMessage),
      'category': _categorizeMessage(userMessage),
      'confidence': 0.75,
      'keywords': _extractKeywords(userMessage),
      'recommendations': _getFallbackRecommendations(userMessage),
    };
  }

  static String _getFallbackResponse(String userMessage) {
    final message = userMessage.toLowerCase();

    if (message.contains('cybercrime') || message.contains('hack')) {
      return '''I understand you're asking about cybercrime. Under the Cybercrime Prevention Act of 2012 (RA 10175), various cyber offenses are covered including:

• Computer-related offenses (illegal access, data interference)
• Content-related offenses (cybersex, child pornography)
• Cyber libel and online harassment

For specific cases, I recommend:
1. Document all evidence
2. Report to PNP Anti-Cybercrime Group (PNP-ACG)
3. Contact NBI Cybercrime Division if needed
4. Consult with a cybercrime lawyer

What specific aspect would you like to know more about?''';
    }

    if (message.contains('scam') || message.contains('fraud')) {
      return '''Online scams and e-commerce fraud are serious crimes under Philippine law. Here's what you should do:

**Immediate Steps:**
1. Stop all transactions with the scammer
2. Screenshot all evidence (messages, receipts, profiles)
3. Report to your bank if money was involved

**Legal Reporting:**
• PNP Anti-Cybercrime Group: file a complaint
• DTI (Department of Trade and Industry): for e-commerce issues
• BSP (Bangko Sentral): for financial fraud

**Legal Basis:** RA 10175 covers online fraud with penalties of 6-12 years imprisonment plus fines.

Would you like specific guidance on filing a complaint?''';
    }

    if (message.contains('harassment') || message.contains('bully')) {
      return '''Online harassment and cyberbullying are punishable under RA 10175. This includes:

• Sending threatening messages
• Posting defamatory content
• Sharing private information without consent
• Creating fake profiles to harass

**Your Legal Options:**
1. File a complaint with PNP-ACG
2. Report to platform administrators
3. Consider filing cyber libel charges if applicable
4. Apply for protection orders if necessary

**Evidence Collection:**
• Screenshot all harassment
• Keep records of dates and times
• Preserve original messages

The penalties can include imprisonment and substantial fines. Would you like help with the reporting process?''';
    }

    return '''I'm here to help with Philippine cybercrime law questions. I can assist with:

• Cybercrime Prevention Act (RA 10175)
• Data Privacy Act (RA 10173)
• Online harassment and cyber libel
• E-commerce fraud and scams
• Identity theft protection
• Reporting procedures

Please feel free to ask about any specific cybercrime concerns you have. I'm here to provide accurate legal guidance based on Philippine laws.''';
  }

  static String _categorizeMessage(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('scam') || msg.contains('fraud') || msg.contains('fake seller')) {
      return 'E-commerce Fraud';
    } else if (msg.contains('harassment') || msg.contains('bully') || msg.contains('threat')) {
      return 'Online Harassment';
    } else if (msg.contains('hack') || msg.contains('unauthorized') || msg.contains('access')) {
      return 'Unauthorized Access';
    } else if (msg.contains('identity') || msg.contains('stolen account')) {
      return 'Identity Theft';
    } else if (msg.contains('privacy') || msg.contains('data') || msg.contains('personal information')) {
      return 'Data Privacy';
    } else if (msg.contains('cybercrime') || msg.contains('ra 10175')) {
      return 'Cybercrime Prevention Act';
    }

    return 'General';
  }

  static List<String> _extractKeywords(String message) {
    final msg = message.toLowerCase();
    List<String> keywords = [];

    final keywordMap = {
      'cybercrime': ['RA 10175', 'cybercrime', 'computer crimes'],
      'scam': ['fraud', 'scam', 'fake seller', 'online shopping'],
      'harassment': ['cyberbullying', 'threats', 'harassment', 'online abuse'],
      'hack': ['unauthorized access', 'hacking', 'data breach'],
      'identity': ['identity theft', 'account takeover', 'personal data'],
      'privacy': ['data privacy', 'RA 10173', 'personal information'],
    };

    keywordMap.forEach((key, values) {
      if (msg.contains(key)) {
        keywords.addAll(values);
      }
    });

    return keywords.isEmpty ? ['cybercrime law', 'philippines'] : keywords;
  }

  static List<String> _getFallbackRecommendations(String message) {
    final msg = message.toLowerCase();

    if (msg.contains('scam') || msg.contains('fraud')) {
      return [
        'Document all evidence immediately',
        'Report to PNP Anti-Cybercrime Group',
        'Contact your bank if money was involved',
        'File a complaint with DTI for e-commerce issues'
      ];
    } else if (msg.contains('harassment') || msg.contains('bully')) {
      return [
        'Screenshot all harassment messages',
        'Block the harasser on all platforms',
        'Report to PNP Anti-Cybercrime Group',
        'Consider filing cyber libel charges'
      ];
    } else if (msg.contains('hack')) {
      return [
        'Change all passwords immediately',
        'Enable two-factor authentication',
        'Report to NBI Cybercrime Division',
        'Monitor your accounts for suspicious activity'
      ];
    }

    return [
      'Consult with a cybercrime lawyer for complex cases',
      'Keep detailed records of all incidents',
      'Report to appropriate authorities (PNP-ACG or NBI-CCD)',
      'Seek legal advice for proper guidance'
    ];
  }
}