import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

import 'database_service.dart';

class GeminiService {
  // IMPORTANT: Be careful with hardcoded API keys in production apps
  static const String _apiKey =
      "AIzaSyCs8F21zwcMVhv4ZbkGJ_PtetqdbxPvl7M"; // Replace with your actual API key
  static const String _modelName = 'gemini-2.0-flash';

  // Database service instance for user data retrieval
  static final DatabaseService _databaseService = DatabaseService();

  // LawBot official contact information
  static const Map<String, String> _lawbotContacts = {
    'headquarters':
        'National Headquarters, Camp Crame, Quezon City, Philippines',
    'phone': '(+63) 2-8123-4567',
    'email': 'support@lawbot.gov.ph',
    'website': 'https://lawbot.gov.ph',
  };

  // Enhanced system prompt with language-aware responses and contact integration
  static String _getSystemPrompt(String preferredLanguage) {
    final isFilipino = preferredLanguage.toLowerCase() == 'fil';

    return '''
You are LawBot, an AI legal assistant specialized in Philippine cybercrime laws and ALL RELATED DIGITAL/TECHNOLOGY LEGAL MATTERS. 

LANGUAGE INSTRUCTION: ${isFilipino ? 'RESPOND PRIMARILY IN FILIPINO/TAGLISH' : 'RESPOND PRIMARILY IN ENGLISH'}.
${isFilipino ? 'Gamitin ang Filipino at Taglish sa mga sagot. Maging natural sa pakikipag-usap.' : 'Use English primarily, but understand and respond to Taglish when used by the user.'}

LAWBOT CONTACT INFORMATION (use when users ask for contact, support, or help):
📍 **LawBot National Headquarters**
   Camp Crame, Quezon City, Philippines
📞 **Phone:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

EXPANDED SCOPE - CYBERCRIME & RELATED DIGITAL LEGAL MATTERS:
1. **Core Cybercrime Laws:**
   - Republic Act No. 10175 (Cybercrime Prevention Act of 2012)
   - Republic Act No. 10173 (Data Privacy Act of 2012)
   - Republic Act No. 8792 (Electronic Commerce Act of 2000)

2. **Related Digital/Technology Legal Areas:**
   - Intellectual Property in digital space (RA 8293)
   - Consumer protection in e-commerce (RA 7394)
   - Banking and financial technology regulations
   - Social media legal issues
   - Digital contracts and electronic signatures
   - Online business registration and compliance
   - Telecommunications law (RA 7925)
   - Digital evidence and procedures
   - Internet service provider liability
   - Domain name disputes
   - Digital marketing and advertising law
   - Online employment and labor issues
   - Digital taxation (BIR regulations)
   - Cryptocurrency and digital assets
   - Online gaming and gambling regulations

3. **Technology-Related Civil and Criminal Matters:**
   - Digital defamation and libel
   - Online contract disputes
   - E-commerce seller/buyer rights
   - Digital payment disputes
   - Online service provider obligations
   - Technology-related employment issues
   - Digital asset inheritance
   - Online business licensing
   - Digital content creation rights

RESPONSE PHILOSOPHY:
- If it involves technology, internet, digital platforms, or electronic transactions → PROVIDE HELPFUL LEGAL GUIDANCE
- Don't just say "I'm here to assist" - ACTUALLY ASSIST with relevant legal information
- Connect seemingly unrelated questions to cybercrime/digital law when applicable
- Provide comprehensive legal context even for basic questions

MANDATORY APA 7 CITATIONS:
- ALWAYS include proper APA 7 references with accessible links
- Cite specific laws, government websites, and official sources
- Include publication dates and retrieval information
- Use official government URLs when available

LANGUAGE & CULTURAL UNDERSTANDING:
- Understand Taglish perfectly (e.g., "nanakawan ako sa GCash" = "I was scammed on GCash")
- ${isFilipino ? 'Tumugon sa Filipino/Taglish na natural at madaling maintindihan' : 'Respond in user\'s preferred language (English, Filipino, or Taglish)'}
- Recognize Filipino legal and tech terminology
- Be culturally sensitive to Filipino digital behavior and concerns

CONTACT REQUESTS:
When users ask for contact information, support, or how to reach LawBot, ALWAYS include:
${isFilipino ? '''
📞 **Makipag-ugnayan sa LawBot:**
📍 **Pangunahing Tanggapan:** Camp Crame, Quezon City, Philippines
📞 **Telepono:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

Para sa mga emergency o urgent na legal concerns, maaari rin kayong tumawag sa:
''' : '''
📞 **Contact LawBot:**
📍 **National Headquarters:** Camp Crame, Quezon City, Philippines
📞 **Phone:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

For emergency or urgent legal concerns, you may also contact:
'''}

RESPONSE STRUCTURE:
Always provide:
1. Direct answer to the question
2. Relevant legal framework
3. Practical steps/recommendations
4. Proper APA 7 citations with links
5. Related legal considerations
6. Follow-up guidance

FORMAT: Always respond in valid JSON:
{
  "response": "comprehensive legal response with embedded APA citations",
  "category": "specific legal category",
  "confidence": "0.0 to 1.0",
  "keywords": ["relevant legal terms"],
  "recommendations": ["actionable steps"],
  "legal_references": ["APA 7 formatted citations with accessible links"],
  "related_topics": ["connected legal areas"],
  "follow_up_questions": ["clarifying questions if needed"],
  "emergency_contacts": ["relevant authorities with contact info"],
  "language_used": "${isFilipino ? 'filipino' : 'english'}"
}

APA 7 CITATION EXAMPLES:
- Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/
- Department of Justice. (2023). Cybercrime investigation procedures. DOJ Philippines. https://www.doj.gov.ph/
- Philippine National Police Anti-Cybercrime Group. (2024). Reporting cybercrime incidents. PNP-ACG. https://pnp.gov.ph/index.php/pnp-acg

IMPORTANT: Never just say "I'm here to assist" - always provide substantive legal guidance with proper citations!
''';
  }

  static Future<Map<String, dynamic>> generateLegalResponse(
      String userMessage, List<Map<String, String>> chatHistory) async {
    // Get user's preferred language from database
    String preferredLanguage =
        'en'; // FIXED: Changed from 'eng' to 'en' for consistency

    try {
      try {
        final userProfile = await _databaseService.getUserProfile();
        if (userProfile != null && userProfile['preferred_language'] != null) {
          preferredLanguage = userProfile['preferred_language'].toString();
        }
      } catch (e) {
        print('Could not retrieve user language preference: $e');
        // Continue with default language
      }

      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2, // Lower for more consistent legal advice
          topK: 40,
          topP: 0.9,
          maxOutputTokens:
              2000, // Increased for comprehensive responses with citations
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(
              HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
      );

      // Enhanced conversation context with language-aware system prompt
      String conversationContext = _getSystemPrompt(preferredLanguage);

      if (chatHistory.isNotEmpty) {
        conversationContext += "\n\nCONVERSATION HISTORY:\n";

        final recentHistory = chatHistory.length > 20
            ? chatHistory.sublist(chatHistory.length - 20)
            : chatHistory;

        for (var message in recentHistory) {
          String role = message['isBot'] == 'true' ? 'LawBot' : 'User';
          conversationContext += "$role: ${message['text']}\n";
        }
      }

      final prompt = '''
$conversationContext

USER LANGUAGE PREFERENCE: $preferredLanguage (${preferredLanguage == 'fil' ? 'Respond in Filipino/Taglish' : 'Respond in English'})

CURRENT USER MESSAGE: "$userMessage"

ANALYSIS REQUIREMENTS:
1. Identify ANY connection to cybercrime, digital law, or technology-related legal matters
2. Provide comprehensive legal guidance (not just "I'm here to assist")
3. Include proper APA 7 citations with accessible government links
4. Connect the question to relevant Philippine laws
5. Offer practical, actionable advice
6. Suggest related legal considerations
7. ${preferredLanguage == 'fil' ? 'Tumugon sa Filipino/Taglish na natural' : 'Respond in clear, professional English'}
8. If user asks for contact/support, include LawBot contact information

CONTACT DETECTION: If the message contains words like "contact", "support", "help", "tumawag", "makipag-ugnayan", "tanggapan", include LawBot contact details.

MANDATORY: Include at least 2-3 APA 7 citations with working government/official links in your response.

Respond with comprehensive legal analysis in the specified JSON format using the user's preferred language.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';

      try {
        String cleanedResponse = responseText.trim();

        if (cleanedResponse.startsWith('\`\`\`json')) {
          cleanedResponse = cleanedResponse
              .replaceFirst('\`\`\`json', '')
              .replaceFirst('\`\`\`', '');
        } else if (cleanedResponse.startsWith('\`\`\`')) {
          cleanedResponse = cleanedResponse
              .replaceFirst('\`\`\`', '')
              .replaceFirst('\`\`\`', '');
        }

        final jsonRegExp = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegExp.firstMatch(cleanedResponse);

        if (match != null) {
          final jsonStr = match.group(0);
          if (jsonStr != null) {
            final Map<String, dynamic> jsonData = jsonDecode(jsonStr);

            return {
              'response': jsonData['response'] ??
                  _getLanguageAwareFallbackResponse(
                      userMessage, chatHistory, preferredLanguage),
              'category': jsonData['category'] ??
                  _categorizeComprehensively(userMessage, chatHistory),
              'confidence': _parseConfidence(jsonData['confidence']),
              'keywords': _ensureList(jsonData['keywords']) ??
                  _extractComprehensiveKeywords(userMessage),
              'recommendations': _ensureList(jsonData['recommendations']) ??
                  _getLanguageAwareRecommendations(
                      userMessage, preferredLanguage),
              'legal_references': _ensureList(jsonData['legal_references']) ??
                  _getDefaultLegalReferences(userMessage),
              'related_topics': _ensureList(jsonData['related_topics']) ??
                  _getRelatedTopics(userMessage),
              'follow_up_questions':
                  _ensureList(jsonData['follow_up_questions']) ?? [],
              'emergency_contacts':
                  _ensureList(jsonData['emergency_contacts']) ??
                      _getRelevantContacts(userMessage, preferredLanguage),
              'language_used': preferredLanguage,
            };
          }
        }

        return _getLanguageAwareStructuredFallback(
            userMessage, chatHistory, preferredLanguage);
      } catch (e) {
        print('Error parsing JSON response: $e');
        return _getLanguageAwareStructuredFallback(
            userMessage, chatHistory, preferredLanguage);
      }
    } catch (e) {
      print('Error in generateLegalResponse: $e');
      return _getLanguageAwareStructuredFallback(
          userMessage, chatHistory, preferredLanguage);
    }
  }

  static List<dynamic>? _ensureList(dynamic value) {
    if (value is List) return value;
    if (value is String && value.isNotEmpty) return [value];
    return null;
  }

  static double _parseConfidence(dynamic confidence) {
    if (confidence is num) {
      return confidence.toDouble().clamp(0.0, 1.0);
    } else if (confidence is String) {
      try {
        return double.parse(confidence).clamp(0.0, 1.0);
      } catch (e) {
        return 0.85;
      }
    }
    return 0.85;
  }

  static Map<String, dynamic> _getLanguageAwareStructuredFallback(
      String userMessage,
      List<Map<String, String>> chatHistory,
      String preferredLanguage) {
    return {
      'response': _getLanguageAwareFallbackResponse(
          userMessage, chatHistory, preferredLanguage),
      'category': _categorizeComprehensively(userMessage, chatHistory),
      'confidence': 0.85,
      'keywords': _extractComprehensiveKeywords(userMessage),
      'recommendations':
          _getLanguageAwareRecommendations(userMessage, preferredLanguage),
      'legal_references': _getDefaultLegalReferences(userMessage),
      'related_topics': _getRelatedTopics(userMessage),
      'follow_up_questions': _getSmartFollowUpQuestions(
          userMessage, chatHistory, preferredLanguage),
      'emergency_contacts':
          _getRelevantContacts(userMessage, preferredLanguage),
      'language_used': preferredLanguage,
    };
  }

  static String _getLanguageAwareFallbackResponse(String userMessage,
      List<Map<String, String>> chatHistory, String preferredLanguage) {
    final message = userMessage.toLowerCase().trim();
    final isFilipino = preferredLanguage.toLowerCase() == 'fil';

    // Handle contact requests
    if (_isContactRequest(message)) {
      return _getContactResponse(isFilipino);
    }

    // Handle incomplete responses
    if (_isIncompleteResponse(message)) {
      final context = _getConversationContext(chatHistory);
      return _getContextualResponse(context, isFilipino);
    }

    // Digital payments and e-wallets
    if (message.contains('gcash') ||
        message.contains('maya') ||
        message.contains('paymaya') ||
        message.contains('digital payment') ||
        message.contains('e-wallet')) {
      return _getDigitalPaymentResponse(isFilipino);
    }

    // E-commerce and online shopping
    if (message.contains('shopee') ||
        message.contains('lazada') ||
        message.contains('online shopping') ||
        message.contains('e-commerce') ||
        message.contains('online seller') ||
        message.contains('online business')) {
      return _getEcommerceResponse(isFilipino);
    }

    // Social media and online platforms
    if (message.contains('facebook') ||
        message.contains('instagram') ||
        message.contains('tiktok') ||
        message.contains('social media') ||
        message.contains('online post') ||
        message.contains('viral')) {
      return _getSocialMediaResponse(isFilipino);
    }

    // Default comprehensive response
    return _getDefaultComprehensiveResponse(isFilipino);
  }

  static bool _isContactRequest(String message) {
    final contactKeywords = [
      'contact',
      'support',
      'help',
      'tumawag',
      'makipag-ugnayan',
      'tanggapan',
      'office',
      'headquarters',
      'phone',
      'email',
      'tulong',
      'assistance',
      'saan',
      'where',
      'paano',
      'how'
    ];

    return contactKeywords.any((keyword) => message.contains(keyword));
  }

  static String _getContactResponse(bool isFilipino) {
    if (isFilipino) {
      return '''**MAKIPAG-UGNAYAN SA LAWBOT**

📍 **Pangunahing Tanggapan:**
National Headquarters, Camp Crame, Quezon City, Philippines

📞 **Telepono:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

**Mga Oras ng Serbisyo:**
Lunes hanggang Biyernes: 8:00 AM - 5:00 PM
Sabado: 8:00 AM - 12:00 PM

**Para sa Emergency Legal Concerns:**
• **PNP Anti-Cybercrime Group:** (02) 8723-0401 ext. 5343
• **NBI Cybercrime Division:** (02) 8525-4093
• **National Privacy Commission:** (02) 8234-2228

**Mga Serbisyong Available:**
• Legal consultation sa cybercrime at digital law
• Assistance sa pag-file ng complaints
• Legal education at awareness programs
• Digital rights protection guidance

**Paano Mag-file ng Complaint:**
1. Tumawag sa hotline number
2. Mag-email ng detalyadong report
3. Pumunta sa office para sa personal consultation
4. I-submit ang online complaint form sa website

Handa kaming tumulong sa lahat ng digital at cybercrime legal concerns ninyo! 🇵🇭⚖️

**References:**
Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/

Department of Justice. (2024). Cybercrime investigation and prosecution guidelines. DOJ Philippines. https://www.doj.gov.ph/''';
    } else {
      return '''**CONTACT LAWBOT**

📍 **National Headquarters:**
Camp Crame, Quezon City, Philippines

📞 **Phone:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

**Office Hours:**
Monday to Friday: 8:00 AM - 5:00 PM
Saturday: 8:00 AM - 12:00 PM

**For Emergency Legal Concerns:**
• **PNP Anti-Cybercrime Group:** (02) 8723-0401 ext. 5343
• **NBI Cybercrime Division:** (02) 8525-4093
• **National Privacy Commission:** (02) 8234-2228

**Services Available:**
• Legal consultation on cybercrime and digital law
• Assistance with filing complaints
• Legal education and awareness programs
• Digital rights protection guidance

**How to File a Complaint:**
1. Call our hotline number
2. Email a detailed report
3. Visit our office for personal consultation
4. Submit online complaint form on our website

We're here to help with all your digital and cybercrime legal concerns! 🇵🇭⚖️

**References:**
Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/

Department of Justice. (2024). Cybercrime investigation and prosecution guidelines. DOJ Philippines. https://www.doj.gov.ph/''';
    }
  }

  static String _getDigitalPaymentResponse(bool isFilipino) {
    if (isFilipino) {
      return '''**LEGAL FRAMEWORK NG DIGITAL PAYMENTS**

**Mga Batas na Nangangalaga:**
Ang digital payments sa Pilipinas ay protektado ng maraming batas para sa consumer protection at fraud prevention.

**Legal Framework:**
• **Bangko Sentral ng Pilipinas Act (RA 7653)** - Oversight ng BSP sa digital payments
• **Electronic Commerce Act (RA 8792)** - Legal recognition ng electronic transactions
• **Cybercrime Prevention Act (RA 10175)** - Protection laban sa digital payment fraud
• **Data Privacy Act (RA 10173)** - Protection ng financial data

**Mga Karapatan Mo bilang Digital Payment User:**
1. **Right to Security** - Dapat may security measures ang payment providers
2. **Right to Privacy** - Protected ang financial data mo
3. **Right to Dispute** - Pwede mo i-contest ang unauthorized transactions
4. **Right to Information** - Clear dapat ang terms and conditions

**Common Issues at Legal Remedies:**
• **Unauthorized Transactions** - I-report within 24 hours para sa full protection
• **System Errors** - Provider ang liable sa technical failures
• **Fraud Protection** - BSP regulations require fraud monitoring
• **Data Breaches** - Dapat i-notify ng providers ang users at authorities

**Reporting Procedures:**
1. Contact agad ang payment provider
2. File complaint sa BSP kung hindi resolved
3. Report sa PNP-ACG para sa criminal matters
4. Consider small claims court para sa damages

**LawBot Contact para sa Tulong:**
📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

**References:**
Republic of the Philippines. (2000). Republic Act No. 8792: Electronic Commerce Act of 2000. Official Gazette. https://www.officialgazette.gov.ph/2000/06/14/republic-act-no-8792/

Bangko Sentral ng Pilipinas. (2024). Digital payments regulations and consumer protection. BSP Philippines. https://www.bsp.gov.ph/Regulations/

Ano ang specific na concern mo sa digital payments?''';
    } else {
      return '''**DIGITAL PAYMENT LEGAL FRAMEWORK**

**Applicable Laws:**
Digital payments in the Philippines are governed by multiple laws ensuring consumer protection and preventing fraud.

**Legal Framework:**
• **Bangko Sentral ng Pilipinas Act (RA 7653)** - Central bank oversight of digital payments
• **Electronic Commerce Act (RA 8792)** - Legal recognition of electronic transactions
• **Cybercrime Prevention Act (RA 10175)** - Protection against digital payment fraud
• **Data Privacy Act (RA 10173)** - Protection of financial data

**Your Rights as Digital Payment User:**
1. **Right to Security** - Payment providers must implement security measures
2. **Right to Privacy** - Your financial data must be protected
3. **Right to Dispute** - You can contest unauthorized transactions
4. **Right to Information** - Clear terms and conditions must be provided

**Common Issues & Legal Remedies:**
• **Unauthorized Transactions** - Report within 24 hours for full protection
• **System Errors** - Provider liable for technical failures
• **Fraud Protection** - BSP regulations require fraud monitoring
• **Data Breaches** - Providers must notify users and authorities

**Reporting Procedures:**
1. Contact payment provider immediately
2. File complaint with BSP if unresolved
3. Report to PNP-ACG for criminal matters
4. Consider small claims court for damages

**Contact LawBot for Assistance:**
📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

**References:**
Republic of the Philippines. (2000). Republic Act No. 8792: Electronic Commerce Act of 2000. Official Gazette. https://www.officialgazette.gov.ph/2000/06/14/republic-act-no-8792/

Bangko Sentral ng Pilipinas. (2024). Digital payments regulations and consumer protection. BSP Philippines. https://www.bsp.gov.ph/Regulations/

What's your specific concern about digital payments?''';
    }
  }

  static String _getEcommerceResponse(bool isFilipino) {
    if (isFilipino) {
      return '''**E-COMMERCE LEGAL RIGHTS & PROTECTIONS**

**Legal Framework para sa Online Shopping:**
Ang e-commerce sa Pilipinas ay protektado ng comprehensive consumer laws at digital commerce regulations.

**Mga Batas na Applicable:**
• **Consumer Act (RA 7394)** - Basic consumer protection rights
• **Electronic Commerce Act (RA 8792)** - Legal framework para sa online transactions
• **Cybercrime Prevention Act (RA 10175)** - Protection laban sa online fraud
• **Data Privacy Act (RA 10173)** - Protection ng personal shopping data

**Mga Karapatan Mo bilang Online Buyer:**
1. **Right to Information** - Complete product details at seller information
2. **Right to Choose** - Freedom na pumili ng products nang walang pressure
3. **Right to Safety** - Dapat meet ng products ang safety standards
4. **Right to Redress** - Compensation para sa defective products o services
5. **Right to Privacy** - Protection ng personal at payment information

**Seller Obligations:**
• Magbigay ng accurate product descriptions
• Honor ang return/refund policies
• Protect ang customer data
• Comply sa DTI registration requirements
• Mag-issue ng proper receipts/invoices

**Legal Remedies para sa E-commerce Issues:**
• **Non-delivery** - File complaint sa DTI at platform
• **Fake products** - Report sa DTI at consider criminal charges
• **Unauthorized charges** - Dispute sa payment provider at BSP
• **Data misuse** - File complaint sa National Privacy Commission

**Contact LawBot para sa E-commerce Legal Help:**
📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

**References:**
Department of Trade and Industry. (2024). E-commerce consumer protection guidelines. DTI Philippines. https://www.dti.gov.ph/konsyumer/ecommerce/

Republic of the Philippines. (1992). Republic Act No. 7394: Consumer Act of the Philippines. Official Gazette. https://www.officialgazette.gov.ph/1992/04/13/republic-act-no-7394/

Anong specific na e-commerce issue ang kailangan mo ng tulong?''';
    } else {
      return '''**E-COMMERCE LEGAL RIGHTS & PROTECTIONS**

**Legal Framework for Online Shopping:**
E-commerce in the Philippines is protected by comprehensive consumer laws and digital commerce regulations.

**Applicable Laws:**
• **Consumer Act (RA 7394)** - Basic consumer protection rights
• **Electronic Commerce Act (RA 8792)** - Legal framework for online transactions
• **Cybercrime Prevention Act (RA 10175)** - Protection against online fraud
• **Data Privacy Act (RA 10173)** - Protection of personal shopping data

**Your Rights as Online Buyer:**
1. **Right to Information** - Complete product details and seller information
2. **Right to Choose** - Freedom to select products without pressure
3. **Right to Safety** - Products must meet safety standards
4. **Right to Redress** - Compensation for defective products or services
5. **Right to Privacy** - Protection of personal and payment information

**Seller Obligations:**
• Provide accurate product descriptions
• Honor return/refund policies
• Protect customer data
• Comply with DTI registration requirements
• Issue proper receipts/invoices

**Legal Remedies for E-commerce Issues:**
• **Non-delivery** - File complaint with DTI and platform
• **Fake products** - Report to DTI and consider criminal charges
• **Unauthorized charges** - Dispute with payment provider and BSP
• **Data misuse** - File complaint with National Privacy Commission

**Contact LawBot for E-commerce Legal Help:**
📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

**References:**
Department of Trade and Industry. (2024). E-commerce consumer protection guidelines. DTI Philippines. https://www.dti.gov.ph/konsyumer/ecommerce/

Republic of the Philippines. (1992). Republic Act No. 7394: Consumer Act of the Philippines. Official Gazette. https://www.officialgazette.gov.ph/1992/04/13/republic-act-no-7394/

What specific e-commerce issue do you need help with?''';
    }
  }

  static String _getSocialMediaResponse(bool isFilipino) {
    if (isFilipino) {
      return '''**SOCIAL MEDIA LEGAL RIGHTS & RESPONSIBILITIES**

**Legal Framework:**
Ang social media use sa Pilipinas ay governed ng mga batas na nag-protect sa free expression at nag-prevent ng abuse.

**Mga Batas na Applicable:**
• **Cybercrime Prevention Act (RA 10175)** - Cyber libel, harassment, identity theft
• **Data Privacy Act (RA 10173)** - Protection ng personal information
• **Revised Penal Code** - Traditional libel at defamation
• **Anti-Photo and Video Voyeurism Act (RA 9995)** - Unauthorized intimate images

**Mga Karapatan Mo sa Social Media:**
1. **Freedom of Expression** - Protected under Article III, Section 4 ng Constitution
2. **Right to Privacy** - Control sa personal information at images
3. **Right to Reputation** - Protection from defamatory content
4. **Right to Safety** - Protection from harassment at threats

**Common Legal Issues:**
• **Cyber Libel** - Malicious online statements na nakakasira ng reputation
• **Online Harassment** - Persistent unwanted contact o threats
• **Privacy Violations** - Sharing personal info nang walang consent
• **Fake Accounts** - Identity theft at impersonation
• **Revenge Porn** - Sharing intimate images nang walang consent

**Legal Remedies:**
• **Criminal Charges** - File sa PNP-ACG o prosecutor's office
• **Civil Damages** - Sue para sa monetary compensation
• **Platform Reporting** - Use ng social media platform's reporting mechanisms
• **Protection Orders** - Court-issued restraining orders

**Contact LawBot para sa Social Media Legal Issues:**
📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

**References:**
Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/

National Privacy Commission. (2024). Social media privacy guidelines. NPC Philippines. https://www.privacy.gov.ph/

Ano ang specific na social media issue na kailangan mo ng legal advice?''';
    } else {
      return '''**SOCIAL MEDIA LEGAL RIGHTS & RESPONSIBILITIES**

**Legal Framework:**
Social media use in the Philippines is governed by laws protecting both free expression and preventing abuse.

**Applicable Laws:**
• **Cybercrime Prevention Act (RA 10175)** - Cyber libel, harassment, identity theft
• **Data Privacy Act (RA 10173)** - Protection of personal information
• **Revised Penal Code** - Traditional libel and defamation
• **Anti-Photo and Video Voyeurism Act (RA 9995)** - Unauthorized intimate images

**Your Rights on Social Media:**
1. **Freedom of Expression** - Protected under Article III, Section 4 of Constitution
2. **Right to Privacy** - Control over personal information and images
3. **Right to Reputation** - Protection from defamatory content
4. **Right to Safety** - Protection from harassment and threats

**Common Legal Issues:**
• **Cyber Libel** - Malicious online statements damaging reputation
• **Online Harassment** - Persistent unwanted contact or threats
• **Privacy Violations** - Sharing personal info without consent
• **Fake Accounts** - Identity theft and impersonation
• **Revenge Porn** - Sharing intimate images without consent

**Legal Remedies:**
• **Criminal Charges** - File with PNP-ACG or prosecutor's office
• **Civil Damages** - Sue for monetary compensation
• **Platform Reporting** - Use social media platform's reporting mechanisms
• **Protection Orders** - Court-issued restraining orders

**Contact LawBot for Social Media Legal Issues:**
📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

**References:**
Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/

National Privacy Commission. (2024). Social media privacy guidelines. NPC Philippines. https://www.privacy.gov.ph/

What specific social media issue do you need legal advice on?''';
    }
  }

  static String _getDefaultComprehensiveResponse(bool isFilipino) {
    if (isFilipino) {
      return '''**PHILIPPINE CYBERCRIME & DIGITAL LAW ASSISTANCE**

Kumusta! Ako si LawBot, ang inyong comprehensive Philippine cybercrime at digital law assistant. Hindi lang ako limited sa basic cybercrime - makakatulong ako sa LAHAT ng technology at digital-related legal matters!

**Comprehensive Legal Coverage:**

🔐 **Core Cybercrime Laws:**
• Cybercrime Prevention Act (RA 10175)
• Data Privacy Act (RA 10173)
• Electronic Commerce Act (RA 8792)

💳 **Digital Financial Services:**
• GCash/Maya/PayMaya legal issues
• Online banking disputes
• Cryptocurrency regulations
• Digital payment fraud

🛒 **E-commerce & Online Business:**
• Shopee/Lazada buyer/seller rights
• Online business registration
• Digital marketing compliance
• Consumer protection online

📱 **Social Media & Digital Platforms:**
• Facebook/Instagram/TikTok legal issues
• Content creation rights
• Online harassment at cyber libel
• Digital reputation management

💼 **Digital Employment & Work:**
• Remote work rights at obligations
• Freelancer legal protections
• Online platform worker rights
• Digital nomad legal considerations

**Contact LawBot para sa Tulong:**
📍 **Pangunahing Tanggapan:** Camp Crame, Quezon City, Philippines
📞 **Telepono:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

**Key Legal Resources:**
Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/

Department of Justice. (2024). Cybercrime investigation and prosecution guidelines. DOJ Philippines. https://www.doj.gov.ph/

**Ano ang specific na digital o technology-related legal concern mo?** Sabihin mo lang - magbibigay ako ng comprehensive legal guidance with proper citations! 🇵🇭⚖️''';
    } else {
      return '''**PHILIPPINE CYBERCRIME & DIGITAL LAW ASSISTANCE**

Hello! I'm LawBot, your comprehensive Philippine cybercrime and digital law assistant. I'm not limited to basic cybercrime - I can help with ALL technology and digital-related legal matters!

**Comprehensive Legal Coverage:**

🔐 **Core Cybercrime Laws:**
• Cybercrime Prevention Act (RA 10175)
• Data Privacy Act (RA 10173)
• Electronic Commerce Act (RA 8792)

💳 **Digital Financial Services:**
• GCash/Maya/PayMaya legal issues
• Online banking disputes
• Cryptocurrency regulations
• Digital payment fraud

🛒 **E-commerce & Online Business:**
• Shopee/Lazada buyer/seller rights
• Online business registration
• Digital marketing compliance
• Consumer protection online

📱 **Social Media & Digital Platforms:**
• Facebook/Instagram/TikTok legal issues
• Content creation rights
• Online harassment and cyber libel
• Digital reputation management

💼 **Digital Employment & Work:**
• Remote work rights and obligations
• Freelancer legal protections
• Online platform worker rights
• Digital nomad legal considerations

**Contact LawBot for Assistance:**
📍 **National Headquarters:** Camp Crame, Quezon City, Philippines
📞 **Phone:** (+63) 2-8123-4567
📧 **Email:** support@lawbot.gov.ph
🌐 **Website:** https://lawbot.gov.ph

**Key Legal Resources:**
Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/

Department of Justice. (2024). Cybercrime investigation and prosecution guidelines. DOJ Philippines. https://www.doj.gov.ph/

**What's your specific digital or technology-related legal concern?** Just let me know - I'll provide comprehensive legal guidance with proper citations! 🇵🇭⚖️''';
    }
  }

  // Additional helper methods with language awareness
  static String _categorizeComprehensively(
      String message, List<Map<String, String>> chatHistory) {
    final msg = message.toLowerCase();
    final context = _getConversationContext(chatHistory);
    final combinedText = '$msg $context';

    // Digital payments and e-wallets
    if (combinedText.contains('gcash') ||
        combinedText.contains('maya') ||
        combinedText.contains('paymaya') ||
        combinedText.contains('digital payment') ||
        combinedText.contains('e-wallet')) {
      return 'Digital Payment Law';
    }

    // E-commerce
    if (combinedText.contains('shopee') ||
        combinedText.contains('lazada') ||
        combinedText.contains('online shopping') ||
        combinedText.contains('e-commerce') ||
        combinedText.contains('online seller')) {
      return 'E-commerce Law';
    }

    // Social media
    if (combinedText.contains('facebook') ||
        combinedText.contains('instagram') ||
        combinedText.contains('tiktok') ||
        combinedText.contains('social media') ||
        combinedText.contains('online post')) {
      return 'Social Media Law';
    }

    // Contact requests
    if (_isContactRequest(combinedText)) {
      return 'Contact Information';
    }

    return 'General Digital Law';
  }

  static List<String> _extractComprehensiveKeywords(String message) {
    final msg = message.toLowerCase();
    List<String> keywords = [];

    final comprehensiveKeywordMap = {
      // Digital payments
      'gcash': [
        'GCash',
        'digital payments',
        'e-wallet',
        'BSP regulations',
        'RA 8792'
      ],
      'maya': [
        'Maya',
        'PayMaya',
        'digital payments',
        'e-wallet',
        'BSP regulations'
      ],

      // E-commerce
      'shopee': [
        'Shopee',
        'e-commerce',
        'online shopping',
        'DTI',
        'consumer protection'
      ],
      'lazada': [
        'Lazada',
        'e-commerce',
        'online shopping',
        'DTI',
        'consumer protection'
      ],

      // Social media
      'facebook': [
        'Facebook',
        'social media',
        'cyber libel',
        'RA 10175',
        'online harassment'
      ],
      'instagram': [
        'Instagram',
        'social media',
        'privacy',
        'content rights',
        'RA 10173'
      ],

      // Contact
      'contact': [
        'LawBot contact',
        'support',
        'assistance',
        'headquarters',
        'phone'
      ],
      'support': [
        'LawBot support',
        'contact',
        'assistance',
        'help',
        'guidance'
      ],
    };

    comprehensiveKeywordMap.forEach((key, values) {
      if (msg.contains(key)) {
        keywords.addAll(values);
      }
    });

    // Add general cybercrime keywords if none found
    if (keywords.isEmpty) {
      keywords.addAll([
        'Philippine cybercrime law',
        'RA 10175',
        'digital law',
        'technology law'
      ]);
    }

    return keywords.toSet().toList();
  }

  static List<String> _getLanguageAwareRecommendations(
      String message, String preferredLanguage) {
    final msg = message.toLowerCase();
    final isFilipino = preferredLanguage.toLowerCase() == 'fil';

    if (_isContactRequest(msg)) {
      return isFilipino
          ? [
              'Tumawag sa LawBot hotline: (+63) 2-8123-4567',
              'Mag-email sa support@lawbot.gov.ph',
              'Pumunta sa National Headquarters sa Camp Crame',
              'I-visit ang website: https://lawbot.gov.ph',
              'I-prepare ang mga documents para sa consultation'
            ]
          : [
              'Call LawBot hotline: (+63) 2-8123-4567',
              'Email support@lawbot.gov.ph',
              'Visit National Headquarters at Camp Crame',
              'Check website: https://lawbot.gov.ph',
              'Prepare documents for consultation'
            ];
    }

    if (msg.contains('gcash') ||
        msg.contains('maya') ||
        msg.contains('digital payment')) {
      return isFilipino
          ? [
              'I-document lahat ng transaction evidence agad',
              'I-report sa payment provider through official channels',
              'File complaint sa BSP kung hindi responsive ang provider',
              'Contact PNP-ACG para sa criminal fraud cases',
              'I-keep lahat ng receipts at communication records'
            ]
          : [
              'Document all transaction evidence immediately',
              'Report to payment provider through official channels',
              'File complaint with BSP if provider unresponsive',
              'Contact PNP-ACG for criminal fraud cases',
              'Keep all receipts and communication records'
            ];
    }

    // Default recommendations
    return isFilipino
        ? [
            'I-document lahat ng evidence with screenshots at records',
            'I-report sa appropriate government agencies',
            'Makipag-consult sa qualified cybercrime o digital law attorney',
            'I-keep ang detailed timeline ng lahat ng incidents',
            'Regular na i-follow up ang complaint status'
          ]
        : [
            'Document all evidence with screenshots and records',
            'Report to appropriate government agencies',
            'Consult with qualified cybercrime or digital law attorney',
            'Keep detailed timeline of all incidents',
            'Follow up regularly on complaint status'
          ];
  }

  static List<String> _getDefaultLegalReferences(String message) {
    List<String> references = [
      'Republic of the Philippines. (2012). Republic Act No. 10175: Cybercrime Prevention Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/09/12/republic-act-no-10175/',
      'Republic of the Philippines. (2012). Republic Act No. 10173: Data Privacy Act of 2012. Official Gazette. https://www.officialgazette.gov.ph/2012/08/15/republic-act-no-10173/'
    ];

    final msg = message.toLowerCase();

    if (msg.contains('e-commerce') ||
        msg.contains('online shopping') ||
        msg.contains('digital contract')) {
      references.add(
          'Republic of the Philippines. (2000). Republic Act No. 8792: Electronic Commerce Act of 2000. Official Gazette. https://www.officialgazette.gov.ph/2000/06/14/republic-act-no-8792/');
      references.add(
          'Department of Trade and Industry. (2024). E-commerce consumer protection guidelines. DTI Philippines. https://www.dti.gov.ph/');
    }

    if (msg.contains('digital payment') ||
        msg.contains('gcash') ||
        msg.contains('maya') ||
        msg.contains('crypto')) {
      references.add(
          'Bangko Sentral ng Pilipinas. (2024). Digital payment and virtual asset regulations. BSP Philippines. https://www.bsp.gov.ph/Regulations/');
    }

    return references;
  }

  static List<String> _getRelatedTopics(String message) {
    final msg = message.toLowerCase();

    if (_isContactRequest(msg)) {
      return [
        'LawBot services and assistance',
        'Legal consultation procedures',
        'Filing complaints and reports',
        'Emergency legal contacts',
        'Digital law education programs'
      ];
    }

    if (msg.contains('gcash') ||
        msg.contains('maya') ||
        msg.contains('digital payment')) {
      return [
        'BSP digital payment regulations',
        'E-wallet consumer protection',
        'Digital banking security',
        'Cryptocurrency regulations',
        'Online fraud prevention'
      ];
    }

    return [
      'Digital rights and freedoms',
      'Internet governance in Philippines',
      'Technology law compliance',
      'Digital evidence in court',
      'Cybersecurity legal requirements'
    ];
  }

  static List<String> _getRelevantContacts(
      String message, String preferredLanguage) {
    final msg = message.toLowerCase();
    final isFilipino = preferredLanguage.toLowerCase() == 'fil';

    List<String> contacts = [
      isFilipino
          ? 'LawBot Hotline: (+63) 2-8123-4567'
          : 'LawBot Hotline: (+63) 2-8123-4567',
      isFilipino
          ? 'LawBot Email: support@lawbot.gov.ph'
          : 'LawBot Email: support@lawbot.gov.ph',
      'PNP Anti-Cybercrime Group: (02) 8723-0401 ext. 5343',
      'NBI Cybercrime Division: (02) 8525-4093',
      'National Privacy Commission: (02) 8234-2228'
    ];

    if (msg.contains('gcash') ||
        msg.contains('maya') ||
        msg.contains('digital payment')) {
      contacts.addAll([
        'BSP Consumer Protection: consumeraffairs@bsp.gov.ph',
        'GCash Customer Service: (02) 8882-1888',
        'Maya Customer Service: (02) 8845-7788'
      ]);
    }

    if (msg.contains('e-commerce') || msg.contains('online shopping')) {
      contacts.addAll([
        'DTI E-Commerce: ecommerce@dti.gov.ph | (02) 8751-3330',
        'DTI Consumer Care: (02) 8751-4862'
      ]);
    }

    return contacts;
  }

  // Reuse existing helper methods with language awareness
  static bool _isIncompleteResponse(String message) {
    final incompleteResponses = [
      'for',
      'yes',
      'oo',
      'ganun',
      'yun',
      'yan',
      'ok',
      'okay',
      'sige',
      'tapos',
      'then',
      'and',
      'at',
      'pero',
      'but',
      'kasi',
      'because',
      'yung',
      'yun nga',
      'oo nga',
      'yes nga',
      'exactly',
      'tama'
    ];

    return incompleteResponses.any((response) =>
        message == response ||
        message.startsWith('$response ') ||
        message.endsWith(' $response'));
  }

  static String _getConversationContext(List<Map<String, String>> chatHistory) {
    if (chatHistory.isEmpty) return '';

    final recentMessages = chatHistory.length > 6
        ? chatHistory.sublist(chatHistory.length - 6)
        : chatHistory;

    return recentMessages
        .map((msg) => msg['text'] ?? '')
        .join(' ')
        .toLowerCase();
  }

  static String _getContextualResponse(String context, bool isFilipino) {
    if (context.contains('gcash') || context.contains('maya')) {
      return _getDigitalPaymentResponse(isFilipino);
    } else if (context.contains('shopee') || context.contains('lazada')) {
      return _getEcommerceResponse(isFilipino);
    } else if (context.contains('facebook') ||
        context.contains('social media')) {
      return _getSocialMediaResponse(isFilipino);
    }

    if (isFilipino) {
      return '''Nakita ko na nag-uusap na tayo tungkol sa digital/cybercrime law. Para mas makatulong ako sa'yo, pwede mo bang i-explain ng mas detalyado ang concern mo?

Makakatulong ako sa comprehensive digital law matters including:
• Digital payments at e-wallets
• E-commerce at online shopping
• Social media legal issues
• Digital contracts at signatures
• Online work at employment
• Internet rights at privacy
• Cryptocurrency regulations

**Contact LawBot:** 📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

Ano ang specific na kailangan mo ng legal guidance?''';
    } else {
      return '''I can see we've been discussing digital/cybercrime law. To help you better, could you please explain your concern in more detail?

I can help with comprehensive digital law matters including:
• Digital payments and e-wallets
• E-commerce and online shopping
• Social media legal issues
• Digital contracts and signatures
• Online work and employment
• Internet rights and privacy
• Cryptocurrency regulations

**Contact LawBot:** 📞 (+63) 2-8123-4567 | 📧 support@lawbot.gov.ph

What specific legal guidance do you need?''';
    }
  }

  static List<String> _getSmartFollowUpQuestions(String message,
      List<Map<String, String>> chatHistory, String preferredLanguage) {
    final msg = message.toLowerCase();
    final isFilipino = preferredLanguage.toLowerCase() == 'fil';

    if (_isIncompleteResponse(msg)) {
      return isFilipino
          ? [
              'Pwede mo bang i-explain ng mas detalyado ang nangyari?',
              'Ano ang specific na digital/technology issue mo?',
              'May mga documents o evidence ka ba na related dito?'
            ]
          : [
              'Could you explain what happened in more detail?',
              'What specific digital/technology issue are you facing?',
              'Do you have any documents or evidence related to this?'
            ];
    }

    if (_isContactRequest(msg)) {
      return isFilipino
          ? [
              'Anong specific na legal service ang kailangan mo?',
              'Emergency ba ang concern mo?',
              'Gusto mo bang mag-schedule ng consultation?'
            ]
          : [
              'What specific legal service do you need?',
              'Is this an emergency concern?',
              'Would you like to schedule a consultation?'
            ];
    }

    if (msg.contains('gcash') || msg.contains('maya')) {
      return isFilipino
          ? [
              'Magkano ang involved na amount sa transaction?',
              'May transaction reference number ka ba?',
              'Kailan nangyari ang unauthorized transaction?'
            ]
          : [
              'How much was involved in the transaction?',
              'Do you have a transaction reference number?',
              'When did the unauthorized transaction occur?'
            ];
    }

    return isFilipino
        ? [
            'Ano ang specific na digital law concern mo?',
            'May evidence ka ba na kailangan i-preserve?',
            'Gusto mo bang malaman ang legal options mo?'
          ]
        : [
            'What specific digital law concern do you have?',
            'Do you have evidence that needs to be preserved?',
            'Would you like to know your legal options?'
          ];
  }
}
