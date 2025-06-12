import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/gemini_service.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';

class ChatTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ChatTab({super.key, this.onNavigateToTab});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();

  bool _isTyping = false;
  String? _sessionId;
  String? _currentUserId;
  List<ChatMessage> _messages = [];
  Timer? _timeUpdateTimer;
  bool _isLoadingHistory = false;
  Map<String, dynamic>? _currentActiveSession;
  static const String _sessionKeyPrefix = 'current_session_';
  static const String _sessionTimePrefix = 'session_time_';

  @override
  void initState() {
    super.initState();
    _initializeChat();
    _startTimeUpdateTimer();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timeUpdateTimer?.cancel();
    super.dispose();
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    _currentUserId = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      print('🔄 Initializing chat for user: $_currentUserId');

      // Step 1: Check for existing active session in database
      _currentActiveSession = await _databaseService.getCurrentActiveSession();

      if (_currentActiveSession != null) {
        // Continue existing active session
        _sessionId = _currentActiveSession!['session_id'];
        print('✅ Found active session: $_sessionId');
        await _loadSessionMessages();
      } else {
        // Check for stored session ID (fallback)
        final storedSessionId = await _getStoredSessionId();

        if (storedSessionId != null && await _isSessionStillValid(storedSessionId)) {
          // Continue with stored session
          _sessionId = storedSessionId;
          print('✅ Continuing with stored session: $_sessionId');
          await _loadSessionMessages();
        } else {
          // Start completely new session
          print('🚀 Starting new session');
          await _startNewSession();
        }
      }
    } catch (e) {
      print('❌ Error initializing chat: $e');
      // Fallback to new session
      await _startNewSession();
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<String?> _getStoredSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = prefs.getString('$_sessionKeyPrefix$_currentUserId');
      final sessionTime = prefs.getInt('$_sessionTimePrefix$_currentUserId');

      if (sessionId != null && sessionTime != null) {
        // Check if session is within last 24 hours
        final lastActivity = DateTime.fromMillisecondsSinceEpoch(sessionTime);
        final now = DateTime.now();

        if (now.difference(lastActivity).inHours < 24) {
          return sessionId;
        }
      }

      return null;
    } catch (e) {
      print('Error getting stored session: $e');
      return null;
    }
  }

  Future<void> _storeSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_sessionKeyPrefix$_currentUserId', sessionId);
      await prefs.setInt('$_sessionTimePrefix$_currentUserId', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error storing session: $e');
    }
  }

  Future<void> _clearStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_sessionKeyPrefix$_currentUserId');
      await prefs.remove('$_sessionTimePrefix$_currentUserId');
    } catch (e) {
      print('Error clearing stored session: $e');
    }
  }

  Future<bool> _isSessionStillValid(String sessionId) async {
    try {
      // Check if session exists in database and get its status
      final sessions = await _databaseService.getChatSessions(limit: 100);
      final session = sessions.firstWhere(
            (s) => s['session_id'] == sessionId,
        orElse: () => {},
      );

      // Session is valid if it exists and is active
      return session.isNotEmpty && session['status'] == 'active';
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  Future<void> _loadSessionMessages() async {
    try {
      if (_sessionId == null) return;

      print('📥 Loading messages for session: $_sessionId');
      final sessionMessages = await _databaseService.getSessionMessages(_sessionId!);

      if (sessionMessages.isNotEmpty) {
        setState(() {
          _messages = sessionMessages.map((msg) {
            final createdAt = DateTime.parse(msg['created_at']);
            final philippineTime = PhilippineTime.fromUtc(createdAt);

            return ChatMessage(
              text: msg['question'] ?? '',
              isBot: false,
              time: PhilippineTime.formatTime(philippineTime),
              philippineDateTime: philippineTime,
              category: 'User',
              chatId: msg['id'],
            );
          }).expand((userMsg) {
            // Find corresponding message for the answer
            final msgData = sessionMessages.firstWhere(
                  (m) => m['id'] == userMsg.chatId,
              orElse: () => <String, dynamic>{},
            );

            if (msgData.isNotEmpty) {
              final createdAt = DateTime.parse(msgData['created_at']);
              final philippineTime = PhilippineTime.fromUtc(createdAt);

              final botMsg = ChatMessage(
                text: msgData['answer'] ?? '',
                isBot: true,
                time: PhilippineTime.formatTime(philippineTime),
                philippineDateTime: philippineTime,
                category: msgData['category'] ?? 'General',
                confidenceScore: msgData['confidence_score']?.toDouble(),
                keywords: (msgData['metadata']?['keywords'] as List?)?.cast<String>(),
                recommendations: (msgData['metadata']?['recommendations'] as List?)?.cast<String>(),
                chatId: msgData['id'],
              );

              return [userMsg, botMsg];
            }
            return [userMsg];
          }).toList();
        });

        print('✅ Loaded ${_messages.length} messages');

        // Scroll to bottom after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        // Empty session, show welcome message
        print('📝 Empty session, showing welcome message');
        _addWelcomeMessage();
      }
    } catch (e) {
      print('❌ Error loading session messages: $e');
      _addWelcomeMessage();
    }
  }

  Future<void> _startNewSession() async {
    try {
      print('🚀 Starting new conversation session');

      // Use the enhanced database method to start new conversation
      _sessionId = await _databaseService.startNewConversation();

      // Store the new session ID locally
      await _storeSessionId(_sessionId!);

      // Update current active session
      _currentActiveSession = {
        'session_id': _sessionId,
        'status': 'active',
        'title': 'New Conversation',
        'total_messages': 0,
      };

      print('✅ New session created: $_sessionId');
      _addWelcomeMessage();
    } catch (e) {
      print('❌ Error starting new session: $e');
      // Fallback: generate session ID manually
      _sessionId = _databaseService.generateSessionId();
      await _storeSessionId(_sessionId!);
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcomeTime = PhilippineTime.now();
    setState(() {
      _messages = [
        ChatMessage(
          text: "Hello! I am LawBot, your AI legal assistant specialized in Philippine cybercrime laws. I can help you with questions about the Cybercrime Prevention Act, Data Privacy Act, online harassment, e-commerce fraud, and more. How can I assist you today?",
          isBot: true,
          time: PhilippineTime.formatTime(welcomeTime),
          philippineDateTime: welcomeTime,
          category: 'General',
          confidenceScore: 1.0,
          keywords: ['cybercrime', 'legal assistance', 'philippines'],
          recommendations: ['Ask about specific cybercrime concerns', 'Report online harassment', 'Learn about data privacy rights'],
        ),
      ];
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    final currentPhilippineTime = PhilippineTime.now();

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isBot: false,
        time: PhilippineTime.formatTime(currentPhilippineTime),
        philippineDateTime: currentPhilippineTime,
        category: 'User',
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Update session timestamp
    if (_sessionId != null) {
      await _storeSessionId(_sessionId!);
    }

    try {
      final chatHistory = await _databaseService.getChatHistoryForContext(
        sessionId: _sessionId,
        limit: 5,
      );

      final aiResponseData = await GeminiService.generateLegalResponse(userMessage, chatHistory);

      final aiResponse = aiResponseData['response'] as String;
      final category = aiResponseData['category'] as String;
      final confidenceScore = aiResponseData['confidence'] as double;
      final keywords = (aiResponseData['keywords'] as List?)?.cast<String>() ?? [];
      final recommendations = (aiResponseData['recommendations'] as List?)?.cast<String>() ?? [];

      final aiResponseTime = PhilippineTime.now();

      final aiMessage = ChatMessage(
        text: aiResponse,
        isBot: true,
        time: PhilippineTime.formatTime(aiResponseTime),
        philippineDateTime: aiResponseTime,
        category: category,
        confidenceScore: confidenceScore,
        keywords: keywords,
        recommendations: recommendations,
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });

      final chatId = await _databaseService.saveChatMessage(
        question: userMessage,
        answer: aiResponse,
        category: category,
        confidenceScore: confidenceScore,
        sessionId: _sessionId,
        keywords: keywords,
        recommendations: recommendations,
        metadata: {
          'response_time': aiResponseTime.millisecondsSinceEpoch - currentPhilippineTime.millisecondsSinceEpoch,
          'message_count': _messages.length,
          'user_type': _currentUserId!.startsWith('guest_') ? 'guest' : 'authenticated',
          'philippine_time': PhilippineTime.toPhilippineIsoString(currentPhilippineTime),
          'timezone': 'Asia/Manila',
          'user_local_time': PhilippineTime.formatDateTime(currentPhilippineTime),
        },
      );

      aiMessage.chatId = chatId;
      _scrollToBottom();
    } catch (e) {
      final errorTime = PhilippineTime.now();
      setState(() {
        _isTyping = false;
        _messages.add(ChatMessage(
          text: "I apologize, but I'm experiencing technical difficulties right now. Please try asking your question again in a moment. For urgent legal matters, please contact the PNP Anti-Cybercrime Group directly at (02) 8723-0401.",
          isBot: true,
          time: PhilippineTime.formatTime(errorTime),
          philippineDateTime: errorTime,
          category: 'Error',
          confidenceScore: 0.0,
        ));
      });
      _scrollToBottom();
      debugPrint('Error in chat: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    try {
      print('🧹 Starting new conversation...');

      setState(() {
        _isLoadingHistory = true;
      });

      // Clear stored session
      await _clearStoredSession();

      // Clear current messages
      setState(() {
        _messages.clear();
      });

      // Start new conversation (this will complete previous active sessions)
      await _startNewSession();

      print('✅ New conversation started successfully');
    } catch (e) {
      print('❌ Error clearing chat: $e');
      // Fallback
      setState(() {
        _messages.clear();
      });
      _addWelcomeMessage();
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  // Enhanced copy functionality
  Future<void> _copyMessage(ChatMessage message) async {
    try {
      await Clipboard.setData(ClipboardData(text: message.text));

      if (message.isBot) {
        // For bot messages, show what type of content was copied
        _showSnackBar(
          'Legal advice copied to clipboard!',
          Colors.green,
          icon: Icons.content_copy,
        );
      } else {
        // For user messages
        _showSnackBar(
          'Question copied to clipboard!',
          Colors.blue,
          icon: Icons.content_copy,
        );
      }
    } catch (e) {
      print('Error copying message: $e');
      _showSnackBar(
        'Failed to copy text. Please try again.',
        Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  // Enhanced copy functionality with full context
  Future<void> _copyMessageWithContext(ChatMessage message) async {
    try {
      String copyText = '';

      if (message.isBot) {
        // For bot messages, include the preceding question
        final userQuestionIndex = _messages.indexOf(message) - 1;
        if (userQuestionIndex >= 0 && !_messages[userQuestionIndex].isBot) {
          final userQuestion = _messages[userQuestionIndex].text;
          copyText = '''
📋 Q&A from LawBot

❓ Question:
$userQuestion

🤖 Answer:
${message.text}

📂 Category: ${message.category}
⏰ ${message.time}
📊 Confidence: ${message.confidenceScore != null ? '${(message.confidenceScore! * 100).round()}%' : 'N/A'}

---
Generated by LawBot - Philippine Cybercrime Legal Assistant
          ''';
        } else {
          copyText = '''
🤖 Legal Advice from LawBot

${message.text}

📂 Category: ${message.category}
⏰ ${message.time}
📊 Confidence: ${message.confidenceScore != null ? '${(message.confidenceScore! * 100).round()}%' : 'N/A'}

---
Generated by LawBot - Philippine Cybercrime Legal Assistant
          ''';
        }
      } else {
        // For user questions
        copyText = '''
❓ Legal Question

${message.text}

⏰ Asked at: ${message.time}

---
From LawBot Chat Session
        ''';
      }

      await Clipboard.setData(ClipboardData(text: copyText.trim()));

      _showSnackBar(
        message.isBot
            ? 'Full Q&A context copied to clipboard!'
            : 'Question with context copied to clipboard!',
        Colors.green,
        icon: Icons.content_copy,
      );
    } catch (e) {
      print('Error copying message with context: $e');
      _showSnackBar(
        'Failed to copy text. Please try again.',
        Colors.red,
        icon: Icons.error_outline,
      );
    }
  }

  // Enhanced bookmark functionality with session context
  Future<void> _bookmarkMessage(ChatMessage message) async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showSignInRequiredDialog();
      return;
    }

    try {
      // Check if already saved
      final isAlreadySaved = await _databaseService.isAdviceSaved(
        _messages[_messages.indexOf(message) - 1].text, // User question
        message.text, // Bot answer
      );

      if (isAlreadySaved) {
        _showSnackBar('This advice is already saved!', Colors.orange);
        return;
      }

      // Get the user question that preceded this bot response
      final userQuestionIndex = _messages.indexOf(message) - 1;
      if (userQuestionIndex >= 0 && !_messages[userQuestionIndex].isBot) {
        final userQuestion = _messages[userQuestionIndex].text;

        await _databaseService.saveAdvice(
          question: userQuestion,
          answer: message.text,
          category: message.category,
          tags: message.keywords,
          notes: 'Saved from conversation: ${_currentActiveSession?['title'] ?? 'Chat Session'}',
        );

        _showSnackBar('Legal advice saved to your bookmarks!', Colors.green);
      }
    } catch (e) {
      print('Error bookmarking message: $e');
      _showSnackBar('Failed to save advice. Please try again.', Colors.red);
    }
  }

  // Enhanced share functionality with session info
  Future<void> _shareMessage(ChatMessage message) async {
    try {
      // Get the user question that preceded this bot response
      final userQuestionIndex = _messages.indexOf(message) - 1;
      String shareText = '';

      if (userQuestionIndex >= 0 && !_messages[userQuestionIndex].isBot) {
        final userQuestion = _messages[userQuestionIndex].text;
        shareText = '''
📋 Legal Question & Answer from LawBot

❓ Question:
$userQuestion

🤖 LawBot Answer:
${message.text}

📂 Category: ${message.category}
⏰ ${message.time}
💬 Session: ${_currentActiveSession?['title'] ?? 'Chat Session'}

---
Generated by LawBot - Your AI Legal Assistant for Philippine Cybercrime Laws
        ''';
      } else {
        shareText = '''
🤖 Legal Advice from LawBot

${message.text}

📂 Category: ${message.category}
⏰ ${message.time}
💬 Session: ${_currentActiveSession?['title'] ?? 'Chat Session'}

---
Generated by LawBot - Your AI Legal Assistant for Philippine Cybercrime Laws
        ''';
      }

      await Share.share(
        shareText.trim(),
        subject: 'Legal Advice from LawBot',
      );
    } catch (e) {
      print('Error sharing message: $e');
      _showSnackBar('Failed to share message. Please try again.', Colors.red);
    }
  }

  void _showSignInRequiredDialog() {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.account_circle_outlined,
              color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              'Sign In Required',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          'You need to sign in to save legal advice to your bookmarks. This helps us keep your saved advice synced across all your devices.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/signin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color, {IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showChatOptions() {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Session Status Info (if active session exists)
            if (_currentActiveSession != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue[900]?.withOpacity(0.3)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: _currentActiveSession!['status'] == 'active'
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Session',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.blue[300] : Colors.blue[700],
                            ),
                          ),
                          Text(
                            _currentActiveSession!['title'] ?? 'Active Conversation',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Status: ${_currentActiveSession!['status']?.toString().toUpperCase() ?? 'ACTIVE'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded, color: Colors.blue),
              ),
              title: const Text('New Conversation'),
              subtitle: Text(
                  _currentActiveSession != null
                      ? 'Complete current session and start fresh'
                      : 'Start a fresh conversation'
              ),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.green),
              ),
              title: const Text('View Chat History'),
              subtitle: const Text('See previous conversations'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(2);
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.library_books_rounded, color: Colors.orange),
              ),
              title: const Text('Legal Resources'),
              subtitle: const Text('Browse legal documents and guides'),
              onTap: () {
                Navigator.pop(context);
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(1);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LawBot AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentActiveSession != null && _currentActiveSession!['status'] == 'active'
                              ? Colors.green
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _currentActiveSession != null
                              ? 'Active Session • ${PhilippineTime.getCurrentTimeString()}'
                              : 'Online • Philippine Time: ${PhilippineTime.getCurrentTimeString()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            onPressed: _showChatOptions,
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: _isLoadingHistory
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading conversation...'),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }
                final message = _messages[index];
                return ChatBubble(
                  message: message,
                  onCopy: () => _copyMessage(message),
                  onCopyWithContext: () => _copyMessageWithContext(message),
                  onBookmark: message.isBot ? () => _bookmarkMessage(message) : null,
                  onShare: message.isBot ? () => _shareMessage(message) : null,
                );
              },
            ),
          ),
          _buildMessageInput(isDark, languageProvider),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(isDark, 0),
                const SizedBox(width: 4),
                _buildDot(isDark, 1),
                const SizedBox(width: 4),
                _buildDot(isDark, 2),
                const SizedBox(width: 12),
                Text(
                  'LawBot is thinking...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(bool isDark, int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 600 + (index * 200)),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildMessageInput(bool isDark, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask about Philippine cybercrime laws...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  maxLines: null,
                  enabled: !_isTyping,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isTyping ? null : _sendMessage,
                  borderRadius: BorderRadius.circular(24),
                  child: Icon(
                    _isTyping ? Icons.hourglass_empty_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final String time;
  final DateTime philippineDateTime;
  final String category;
  final double? confidenceScore;
  final List<String>? keywords;
  final List<String>? recommendations;
  String? chatId;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.time,
    required this.philippineDateTime,
    required this.category,
    this.confidenceScore,
    this.keywords,
    this.recommendations,
    this.chatId,
  });

  String getRelativeTimeString() {
    return PhilippineTime.getRelativeTimeString(philippineDateTime);
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onCopy;
  final VoidCallback? onCopyWithContext;
  final VoidCallback? onBookmark;
  final VoidCallback? onShare;

  const ChatBubble({
    super.key,
    required this.message,
    this.onCopy,
    this.onCopyWithContext,
    this.onBookmark,
    this.onShare,
  });

  void _showCopyOptions(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Copy Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.content_copy, color: Colors.blue),
              ),
              title: Text(message.isBot ? 'Copy Response' : 'Copy Question'),
              subtitle: Text(message.isBot
                  ? 'Copy just the AI response text'
                  : 'Copy just your question text'),
              onTap: () {
                Navigator.pop(context);
                onCopy?.call();
              },
            ),

            if (onCopyWithContext != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.copy_all, color: Colors.green),
                ),
                title: Text(message.isBot ? 'Copy with Question' : 'Copy with Context'),
                subtitle: Text(message.isBot
                    ? 'Copy both question and answer with formatting'
                    : 'Copy question with timestamp and session info'),
                onTap: () {
                  Navigator.pop(context);
                  onCopyWithContext?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isBot
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.category != 'General' && message.category != 'User') ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                              : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        message.category,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.4,
                    ),
                  ),
                  if (message.recommendations != null && message.recommendations!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.blue[900] : Colors.blue[50])?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isDark ? Colors.blue[700] : Colors.blue[200])!,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 14,
                                color: isDark ? Colors.blue[300] : Colors.blue[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Recommendations:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...message.recommendations!.take(3).map((rec) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '• $rec',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.blue[200] : Colors.blue[800],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.getRelativeTimeString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      if (message.confidenceScore != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: message.confidenceScore! > 0.8
                              ? Colors.green
                              : message.confidenceScore! > 0.6
                              ? Colors.orange
                              : Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${(message.confidenceScore! * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                      const Spacer(),

                      // Copy button (always available)
                      InkWell(
                        onTap: () => _showCopyOptions(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.content_copy,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      if (message.isBot && onBookmark != null) ...[
                        InkWell(
                          onTap: onBookmark,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.bookmark_border_rounded,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (message.isBot && onShare != null)
                        InkWell(
                          onTap: onShare,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.share_outlined,
                              size: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.8,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.getRelativeTimeString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Copy button for user messages
                      InkWell(
                        onTap: () => _showCopyOptions(context),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.content_copy,
                            size: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}