import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatternDetectionService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static bool _debugMode = true; // Set to false in production

  static void _debugLog(String message) {
    if (_debugMode) {
      print('🔍 [PatternDetection] $message');
    }
  }

  // Check for similar reports and known scammer patterns
  static Future<PatternAlert?> checkForPatterns(Map<String, dynamic> formData) async {
    final startTime = DateTime.now();
    _debugLog('🚀 Starting pattern detection analysis');
    
    try {
      final alerts = <PatternMatch>[];

      // Check for email patterns
      if (formData['suspectContact']?.contains('@') == true) {
        final emailMatches = await _checkEmailPattern(formData['suspectContact']);
        alerts.addAll(emailMatches);
      }

      // Check for phone number patterns
      final phonePattern = _extractPhoneNumber(formData['suspectContact'] ?? '');
      if (phonePattern != null) {
        final phoneMatches = await _checkPhonePattern(phonePattern);
        alerts.addAll(phoneMatches);
      }

      // Check for suspect name patterns
      if (formData['suspectName']?.isNotEmpty == true) {
        final nameMatches = await _checkSuspectNamePattern(formData['suspectName']);
        alerts.addAll(nameMatches);
      }

      // Check for platform/account patterns
      if (formData['platformWebsite']?.isNotEmpty == true) {
        final platformMatches = await _checkPlatformPattern(
          formData['platformWebsite'],
          formData['suspectName'] ?? '',
        );
        alerts.addAll(platformMatches);
      }

      // Check for URL patterns
      final urls = _extractUrls(formData['description'] ?? '');
      for (final url in urls) {
        final urlMatches = await _checkUrlPattern(url);
        alerts.addAll(urlMatches);
      }

      // Check for similar description patterns
      if (formData['description']?.isNotEmpty == true) {
        final descriptionMatches = await _checkDescriptionPattern(formData['description']);
        alerts.addAll(descriptionMatches);
      }

      // Check for cross-field combinations (comprehensive suspect validation)
      final crossFieldMatches = await _checkCrossFieldPatterns(formData);
      alerts.addAll(crossFieldMatches);

      // Return alert if patterns found
      if (alerts.isNotEmpty) {
        return PatternAlert(
          matches: alerts,
          severity: _calculateSeverity(alerts),
          recommendation: _generateRecommendation(alerts),
        );
      }

      return null;
    } catch (e) {
      print('Error checking patterns: $e');
      return null;
    }
  }

  static Future<List<PatternMatch>> _checkEmailPattern(String email) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select('id, suspect_contact, created_at, crime_type')
          .or('suspect_contact.ilike.%$email%,description.ilike.%$email%')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .limit(10);

      if ((response as List).isNotEmpty) {
        final complaintIds = response.map((r) => r['id'].toString()).toList();
        return [PatternMatch(
          type: PatternType.email,
          value: email,
          matchCount: response.length,
          recentCount: response.length,
          lastReported: DateTime.parse(response.first['created_at']),
          crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
          complaintIds: complaintIds,
        )];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<PatternMatch>> _checkPhonePattern(String phone) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      
      final response = await _supabase
          .from('complaints')
          .select('id, suspect_contact, phone_number, created_at, crime_type')
          .or('suspect_contact.ilike.%$cleanPhone%,phone_number.ilike.%$cleanPhone%,description.ilike.%$cleanPhone%')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .limit(10);

      if ((response as List).length >= 1) {
        final complaintIds = response.map((r) => r['id'].toString()).toList();
        return [PatternMatch(
          type: PatternType.phoneNumber,
          value: phone,
          matchCount: response.length,
          recentCount: response.length,
          lastReported: DateTime.parse(response.first['created_at']),
          crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
          complaintIds: complaintIds,
        )];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<PatternMatch>> _checkSuspectNamePattern(String suspectName) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select('id, suspect_name, created_at, crime_type')
          .ilike('suspect_name', '%$suspectName%')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .limit(10);

      if ((response as List).length >= 1) {
        final complaintIds = response.map((r) => r['id'].toString()).toList();
        return [PatternMatch(
          type: PatternType.suspectName,
          value: suspectName,
          matchCount: response.length,
          recentCount: response.length,
          lastReported: DateTime.parse(response.first['created_at']),
          crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
          complaintIds: complaintIds,
        )];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<PatternMatch>> _checkPlatformPattern(String platform, String suspectName) async {
    try {
      final matches = <PatternMatch>[];

      // Check platform + suspect name combination
      if (suspectName.isNotEmpty) {
        final response = await _supabase
            .from('complaints')
            .select('id, platform_website, suspect_name, created_at, crime_type')
            .ilike('platform_website', '%$platform%')
            .ilike('suspect_name', '%$suspectName%')
            .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
            .limit(10);

        if ((response as List).length >= 1) {
          final complaintIds = response.map((r) => r['id'].toString()).toList();
          matches.add(PatternMatch(
            type: PatternType.platformAccount,
            value: '$platform - $suspectName',
            matchCount: response.length,
            recentCount: response.length,
            lastReported: DateTime.parse(response.first['created_at']),
            crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
            complaintIds: complaintIds,
          ));
        }
      }

      return matches;
    } catch (e) {
      return [];
    }
  }

  static Future<List<PatternMatch>> _checkUrlPattern(String url) async {
    try {
      final response = await _supabase
          .from('complaints')
          .select('id, description, platform_website, created_at, crime_type')
          .or('description.ilike.%$url%,platform_website.ilike.%$url%')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .limit(10);

      if ((response as List).length >= 1) {
        final complaintIds = response.map((r) => r['id'].toString()).toList();
        return [PatternMatch(
          type: PatternType.website,
          value: url,
          matchCount: response.length,
          recentCount: response.length,
          lastReported: DateTime.parse(response.first['created_at']),
          crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
          complaintIds: complaintIds,
        )];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<PatternMatch>> _checkDescriptionPattern(String description) async {
    try {
      // Extract key phrases for similarity checking
      final keyPhrases = _extractKeyPhrases(description);
      final matches = <PatternMatch>[];

      for (final phrase in keyPhrases) {
        if (phrase.length > 15) { // Only check substantial phrases
          final response = await _supabase
              .from('complaints')
              .select('id, description, created_at, crime_type')
              .ilike('description', '%$phrase%')
              .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
              .limit(5);

          if ((response as List).length >= 1) {
            final complaintIds = response.map((r) => r['id'].toString()).toList();
            matches.add(PatternMatch(
              type: PatternType.similarDescription,
              value: phrase,
              matchCount: response.length,
              recentCount: response.length,
              lastReported: DateTime.parse(response.first['created_at']),
              crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
              complaintIds: complaintIds,
            ));
          }
        }
      }

      return matches;
    } catch (e) {
      return [];
    }
  }

  static Future<List<PatternMatch>> _checkCrossFieldPatterns(Map<String, dynamic> formData) async {
    try {
      final matches = <PatternMatch>[];
      final suspectName = formData['suspectName'] ?? '';
      final suspectContact = formData['suspectContact'] ?? '';
      final platformWebsite = formData['platformWebsite'] ?? '';
      
      // Skip if not enough data for cross-field validation
      if (suspectName.isEmpty && suspectContact.isEmpty && platformWebsite.isEmpty) {
        return matches;
      }

      // Build dynamic query conditions
      final List<String> conditions = [];
      final List<String> orConditions = [];
      
      if (suspectName.isNotEmpty) {
        orConditions.add('suspect_name.ilike.%$suspectName%');
      }
      
      if (suspectContact.isNotEmpty) {
        orConditions.add('suspect_contact.ilike.%$suspectContact%');
      }
      
      if (platformWebsite.isNotEmpty && suspectName.isNotEmpty) {
        orConditions.add('and(platform_website.ilike.%$platformWebsite%,suspect_name.ilike.%$suspectName%)');
      }

      if (orConditions.isEmpty) return matches;

      final response = await _supabase
          .from('complaints')
          .select('id, suspect_name, suspect_contact, platform_website, created_at, crime_type')
          .or(orConditions.join(','))
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String())
          .limit(15);

      if ((response as List).length >= 1) {
        // Create a combined match for cross-field validation
        final combinedValue = [
          if (suspectName.isNotEmpty) 'Name: $suspectName',
          if (suspectContact.isNotEmpty) 'Contact: $suspectContact',
          if (platformWebsite.isNotEmpty) 'Platform: $platformWebsite',
        ].join(' | ');

        final complaintIds = response.map((r) => r['id'].toString()).toList();
        matches.add(PatternMatch(
          type: PatternType.suspectCombination,
          value: combinedValue,
          matchCount: response.length,
          recentCount: response.length,
          lastReported: DateTime.parse(response.first['created_at']),
          crimeTypes: response.map((r) => r['crime_type'] as String).toList(),
          complaintIds: complaintIds,
        ));
      }

      return matches;
    } catch (e) {
      _debugLog('❌ Error in cross-field pattern check: $e');
      return [];
    }
  }

  static String? _extractPhoneNumber(String text) {
    final phoneRegex = RegExp(r'(\+63|0)[\d\s\-()]{10,}');
    final match = phoneRegex.firstMatch(text);
    return match?.group(0);
  }

  static List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+|www\.[^\s]+|\b[a-z]+\.[a-z]{2,}\b');
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  static List<String> _extractKeyPhrases(String description) {
    // Split into sentences and extract meaningful phrases
    final sentences = description.split(RegExp(r'[.!?]\s*'));
    final phrases = <String>[];
    
    for (final sentence in sentences) {
      if (sentence.trim().length > 20) {
        phrases.add(sentence.trim());
      }
    }
    
    return phrases;
  }

  static PatternSeverity _calculateSeverity(List<PatternMatch> matches) {
    // Deduplicate by complaint IDs to get unique report count
    final Set<String> uniqueComplaintIds = {};
    for (final match in matches) {
      uniqueComplaintIds.addAll(match.complaintIds);
    }
    
    final int uniqueReports = uniqueComplaintIds.length;
    
    if (uniqueReports >= 10) {
      return PatternSeverity.critical;
    } else if (uniqueReports >= 5) {
      return PatternSeverity.high;
    } else if (uniqueReports >= 3) {
      return PatternSeverity.medium;
    } else {
      return PatternSeverity.low;
    }
  }

  static String _generateRecommendation(List<PatternMatch> matches) {
    final severity = _calculateSeverity(matches);
    
    // Deduplicate by complaint IDs to get unique report count
    final Set<String> uniqueComplaintIds = {};
    for (final match in matches) {
      uniqueComplaintIds.addAll(match.complaintIds);
    }
    final int uniqueReports = uniqueComplaintIds.length;
    
    // Get most recent match for timeframe context
    final mostRecent = matches.first.lastReported;
    final difference = DateTime.now().difference(mostRecent);
    String timeContext = '';
    
    if (difference.inHours <= 24) {
      timeContext = ' in the last 24 hours';
    } else if (difference.inDays <= 7) {
      timeContext = ' this week';
    } else {
      timeContext = ' recently';
    }
    
    switch (severity) {
      case PatternSeverity.critical:
        return 'VERIFIED SCAMMER: This suspect has been reported $uniqueReports times$timeContext by other users. This helps strengthen your case and supports ongoing investigations.';
      case PatternSeverity.high:
        return 'PATTERN CONFIRMED: $uniqueReports similar reports found$timeContext. Your report adds valuable evidence to help catch this scammer and protect others.';
      case PatternSeverity.medium:
        if (uniqueReports == 1) {
          return 'PATTERN DETECTED: 1 similar report found$timeContext. Your report helps build a stronger case against this suspect.';
        } else {
          return 'PATTERN DETECTED: $uniqueReports similar reports found$timeContext. Thank you for helping build evidence against this scammer.';
        }
      case PatternSeverity.low:
        if (uniqueReports == 1) {
          return 'INFORMATION: 1 similar report exists$timeContext. Your report contributes to identifying potential scam patterns.';
        } else {
          return 'HELPFUL INFO: Your report adds to our database and helps identify scam patterns for better protection.';
        }
    }
  }

  // Store pattern data for future reference
  static Future<void> recordPatternData(Map<String, dynamic> complaintData) async {
    final startTime = DateTime.now();
    _debugLog('💾 Recording pattern data for complaint ${complaintData['id']}');
    
    try {
      // Extract identifiers for pattern tracking
      final identifiers = <String, dynamic>{};
      
      if (complaintData['suspectContact']?.isNotEmpty == true) {
        identifiers['suspect_contact'] = complaintData['suspectContact'];
      }
      
      if (complaintData['platformWebsite']?.isNotEmpty == true) {
        identifiers['platform'] = complaintData['platformWebsite'];
      }
      
      if (complaintData['suspectName']?.isNotEmpty == true) {
        identifiers['suspect_name'] = complaintData['suspectName'];
      }

      if (identifiers.isNotEmpty) {
        // Store in pattern tracking table
        await _supabase.from('scammer_patterns').insert({
          'complaint_id': complaintData['id'],
          'identifiers': identifiers,
          'crime_type': complaintData['crimeType'],
          'reported_at': DateTime.now().toIso8601String(),
        });

        final dbTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog('✅ Pattern data recorded in ${dbTime}ms (${identifiers.length} identifiers)');
      } else {
        _debugLog('ℹ️ No pattern identifiers found to record');
      }
    } catch (e) {
      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Failed to record pattern data after ${dbTime}ms: $e');
      // Silently handle error - pattern recording is not critical
    }
  }

  // Get trending scammer alerts for dashboard
  static Future<List<TrendingAlert>> getTrendingAlerts() async {
    final startTime = DateTime.now();
    _debugLog('🚀 Fetching trending scammer alerts');
    
    try {
      final response = await _supabase
          .from('complaints')
          .select('suspect_contact, platform_website, crime_type, created_at')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String())
          .order('created_at', ascending: false);

      // Process data to find trending patterns
      final patternCounts = <String, int>{};
      final patternData = <String, Map<String, dynamic>>{};
      
      for (final complaint in response as List) {
        final contact = complaint['suspect_contact'] as String?;
        if (contact?.isNotEmpty == true) {
          patternCounts[contact!] = (patternCounts[contact] ?? 0) + 1;
          patternData[contact] = {
            'identifier': contact,
            'type': 'Contact',
            'crimeType': complaint['crime_type'],
            'lastSeen': DateTime.parse(complaint['created_at']),
          };
        }
      }
      
      // Convert to TrendingAlert objects
      final patterns = <TrendingAlert>[];
      patternCounts.forEach((identifier, count) {
        if (count > 1) { // Only include patterns with multiple occurrences
          final data = patternData[identifier]!;
          patterns.add(TrendingAlert(
            identifier: data['identifier'],
            type: data['type'],
            count: count,
            crimeType: data['crimeType'],
            lastSeen: data['lastSeen'],
          ));
        }
      });

      // Return top trending alerts
      patterns.sort((a, b) => b.count.compareTo(a.count));
      
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('✅ Trending alerts retrieved in ${processingTime}ms (${patterns.length} patterns found)');
      
      return patterns.take(5).toList();
    } catch (e) {
      final processingTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Trending alerts failed after ${processingTime}ms: $e');
      return [];
    }
  }

  // Enable/disable debug mode
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
    _debugLog(enabled ? '🟢 Debug mode enabled' : '🔴 Debug mode disabled');
  }
}

class PatternAlert {
  final List<PatternMatch> matches;
  final PatternSeverity severity;
  final String recommendation;

  PatternAlert({
    required this.matches,
    required this.severity,
    required this.recommendation,
  });

  Color get severityColor {
    switch (severity) {
      case PatternSeverity.critical:
        return const Color(0xFFDC2626); // Red
      case PatternSeverity.high:
        return const Color(0xFFEA580C); // Orange
      case PatternSeverity.medium:
        return const Color(0xFFCA8A04); // Yellow
      case PatternSeverity.low:
        return const Color(0xFF16A34A); // Green
    }
  }

  IconData get severityIcon {
    switch (severity) {
      case PatternSeverity.critical:
        return Icons.verified;
      case PatternSeverity.high:
        return Icons.shield;
      case PatternSeverity.medium:
        return Icons.analytics;
      case PatternSeverity.low:
        return Icons.lightbulb;
    }
  }

  String get alertTitle {
    // Deduplicate by complaint IDs to get unique report count
    final Set<String> uniqueComplaintIds = {};
    for (final match in matches) {
      uniqueComplaintIds.addAll(match.complaintIds);
    }
    final int uniqueReports = uniqueComplaintIds.length;
    
    switch (severity) {
      case PatternSeverity.critical:
        return '✅ VERIFIED SCAMMER';
      case PatternSeverity.high:
        return '🎯 PATTERN CONFIRMED';
      case PatternSeverity.medium:
        if (uniqueReports == 1) {
          return '📋 PATTERN DETECTED';
        }
        return '📊 MULTIPLE REPORTS';
      case PatternSeverity.low:
        if (uniqueReports == 1) {
          return '💡 HELPFUL INFO';
        }
        return '📝 PATTERN INFO';
    }
  }
}

class PatternMatch {
  final PatternType type;
  final String value;
  final int matchCount;
  final int recentCount;
  final DateTime lastReported;
  final List<String> crimeTypes;
  final List<String> complaintIds; // Track unique complaint IDs

  PatternMatch({
    required this.type,
    required this.value,
    required this.matchCount,
    required this.recentCount,
    required this.lastReported,
    required this.crimeTypes,
    required this.complaintIds,
  });

  String get typeDisplay {
    switch (type) {
      case PatternType.email:
        return 'Email Address';
      case PatternType.phoneNumber:
        return 'Phone Number';
      case PatternType.suspectName:
        return 'Suspect Name';
      case PatternType.platformAccount:
        return 'Social Media Account';
      case PatternType.website:
        return 'Website/URL';
      case PatternType.similarDescription:
        return 'Similar Report';
      case PatternType.suspectCombination:
        return 'Suspect Information';
    }
  }

  String get matchDescription {
    final timeAgo = _getTimeAgo(lastReported);
    final difference = DateTime.now().difference(lastReported);
    
    // Dynamic timeframe based on recency
    String timeFrame;
    if (difference.inHours <= 24) {
      timeFrame = 'last 24 hours';
    } else if (difference.inDays <= 7) {
      timeFrame = 'last week';
    } else {
      timeFrame = 'last 30 days';
    }
    
    // Dynamic message based on count
    if (matchCount == 1) {
      return 'This ${typeDisplay.toLowerCase()} was reported by 1 other user in the $timeFrame (reported $timeAgo)';
    } else {
      return 'This ${typeDisplay.toLowerCase()} was reported by $matchCount others in the $timeFrame (last reported $timeAgo)';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    }
  }
}

class TrendingAlert {
  final String identifier;
  final String type; 
  final int count;
  final String crimeType;
  final DateTime lastSeen;

  const TrendingAlert({
    required this.identifier,
    required this.type,
    required this.count,
    required this.crimeType,
    required this.lastSeen,
  });
}

enum PatternType {
  email,
  phoneNumber,
  suspectName,
  platformAccount,
  website,
  similarDescription,
  suspectCombination,
}

enum PatternSeverity {
  low,
  medium,
  high,
  critical,
}