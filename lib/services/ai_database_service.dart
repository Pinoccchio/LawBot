import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/complaint_model.dart';
import 'ai_risk_assessment_service.dart';

/// Service for integrating AI responses with database for caching and audit
class AIDatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static bool _debugMode = true; // Set to false in production

  static void _debugLog(String message) {
    if (_debugMode) {
      print('🔍 [AIDatabaseService] $message');
    }
  }

  /// Store AI risk assessment in database for audit
  static Future<void> storeRiskAssessment({
    required String complaintId,
    required AIRiskAssessment assessment,
    required String assessmentType,
    required int processingTimeMs,
    required Map<String, dynamic> inputData,
  }) async {
    final startTime = DateTime.now();
    _debugLog('💾 Storing AI risk assessment for complaint $complaintId');

    try {
      await _supabase.from('ai_risk_assessments').insert({
        'complaint_id': complaintId,
        'ai_risk_score': assessment.aiRiskScore,
        'ai_priority': assessment.aiPriority,
        'confidence_score': assessment.confidenceScore,
        'risk_factors': assessment.riskFactors,
        'urgency_indicators': assessment.urgencyIndicators,
        'reasoning': assessment.reasoning,
        'assessment_type': assessmentType,
        'model_version': 'gemini-2.0-flash',
        'input_data': inputData,
        'processing_time_ms': processingTimeMs,
        'created_at': assessment.assessedAt.toIso8601String(),
      });

      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('✅ Risk assessment stored in ${dbTime}ms');
    } catch (e) {
      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Failed to store risk assessment after ${dbTime}ms: $e');
      // Non-critical error - don't throw
    }
  }

  /// Check cache for existing AI assessment
  static Future<AIRiskAssessment?> getCachedAssessment({
    required CrimeType crimeType,
    required String description,
    required Map<String, dynamic> inputData,
  }) async {
    final startTime = DateTime.now();
    _debugLog('🔍 Checking cache for ${crimeType.displayName} assessment');

    try {
      // Generate cache key from input data
      final inputHash = _generateInputHash(inputData);
      final descriptionHash = _generateDescriptionHash(description);
      
      _debugLog('🔑 Cache keys - Input: ${inputHash.substring(0, 8)}..., Desc: ${descriptionHash.substring(0, 8)}...');

      final response = await _supabase
          .from('ai_assessment_cache')
          .select()
          .eq('input_hash', inputHash)
          .eq('crime_type', crimeType.name)
          .eq('description_hash', descriptionHash)
          .gt('expires_at', DateTime.now().toIso8601String())
          .single();

      if (response != null) {
        // Update cache hit counter and last used
        await _supabase
            .from('ai_assessment_cache')
            .update({
              'cache_hits': (response['cache_hits'] ?? 0) + 1,
              'last_used_at': DateTime.now().toIso8601String(),
            })
            .eq('id', response['id']);

        final dbTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog('✅ Cache HIT! Retrieved in ${dbTime}ms (${response['cache_hits'] + 1} hits)');

        return AIRiskAssessment(
          aiRiskScore: response['ai_risk_score'],
          aiPriority: response['ai_priority'],
          confidenceScore: response['confidence_score'],
          riskFactors: List<String>.from(response['risk_factors'] ?? []),
          urgencyIndicators: List<String>.from(response['urgency_indicators'] ?? []),
          reasoning: response['reasoning'] ?? '',
          assessedAt: DateTime.parse(response['created_at']),
        );
      }
    } catch (e) {
      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('🚫 Cache MISS after ${dbTime}ms: $e');
    }

    return null;
  }

  /// Store AI assessment in cache for future use
  static Future<void> cacheAssessment({
    required CrimeType crimeType,
    required String description,
    required Map<String, dynamic> inputData,
    required AIRiskAssessment assessment,
    Duration cacheDuration = const Duration(hours: 24),
  }) async {
    final startTime = DateTime.now();
    _debugLog('💾 Caching AI assessment for ${crimeType.displayName}');

    try {
      final inputHash = _generateInputHash(inputData);
      final descriptionHash = _generateDescriptionHash(description);
      final expiresAt = DateTime.now().add(cacheDuration);

      await _supabase.from('ai_assessment_cache').insert({
        'input_hash': inputHash,
        'crime_type': crimeType.name,
        'description_hash': descriptionHash,
        'ai_risk_score': assessment.aiRiskScore,
        'ai_priority': assessment.aiPriority,
        'confidence_score': assessment.confidenceScore,
        'risk_factors': assessment.riskFactors,
        'urgency_indicators': assessment.urgencyIndicators,
        'reasoning': assessment.reasoning,
        'expires_at': expiresAt.toIso8601String(),
        'cache_hits': 0,
        'model_version': 'gemini-2.0-flash',
        'assessment_type': 'full',
      });

      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('✅ Assessment cached in ${dbTime}ms (expires: ${expiresAt.toLocal()})');
    } catch (e) {
      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Failed to cache assessment after ${dbTime}ms: $e');
      // Non-critical error - don't throw
    }
  }

  /// Store evidence suggestions in database
  static Future<void> storeEvidenceGuidance({
    required CrimeType crimeType,
    required List<EvidenceGuidanceItem> items,
  }) async {
    final startTime = DateTime.now();
    _debugLog('💾 Storing ${items.length} evidence suggestions for ${crimeType.displayName}');

    try {
      final insertData = items.map((item) => {
        'crime_type': crimeType.name,
        'category': crimeType.category.name,
        'suggestion_type': 'evidence_guidance',
        'title': item.title,
        'description': item.description,
        'priority': item.priority.toLowerCase(),
        'icon': item.icon,
        'examples': item.examples,
        'is_active': true,
      }).toList();

      await _supabase.from('evidence_suggestions').insert(insertData);

      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('✅ Evidence suggestions stored in ${dbTime}ms');
    } catch (e) {
      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Failed to store evidence suggestions after ${dbTime}ms: $e');
      // Non-critical error - don't throw
    }
  }

  /// Retrieve cached evidence suggestions from database
  static Future<List<EvidenceGuidanceItem>?> getCachedEvidenceGuidance(CrimeType crimeType) async {
    final startTime = DateTime.now();
    _debugLog('🔍 Checking for cached evidence guidance: ${crimeType.displayName}');

    try {
      final response = await _supabase
          .from('evidence_suggestions')
          .select()
          .eq('crime_type', crimeType.name)
          .eq('is_active', true)
          .order('priority', ascending: false);

      if (response.isNotEmpty) {
        final items = (response as List).map((item) => EvidenceGuidanceItem(
          title: item['title'] ?? '',
          description: item['description'] ?? '',
          icon: item['icon'] ?? '📋',
          priority: item['priority'] ?? 'medium',
          examples: List<String>.from(item['examples'] ?? []),
        )).toList();

        final dbTime = DateTime.now().difference(startTime).inMilliseconds;
        _debugLog('✅ Retrieved ${items.length} cached evidence items in ${dbTime}ms');
        return items;
      }
    } catch (e) {
      final dbTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('🚫 No cached evidence guidance found after ${dbTime}ms: $e');
    }

    return null;
  }

  /// Clean up expired cache entries
  static Future<void> cleanupExpiredCache() async {
    final startTime = DateTime.now();
    _debugLog('🧹 Cleaning up expired cache entries');

    try {
      final result = await _supabase
          .from('ai_assessment_cache')
          .delete()
          .lt('expires_at', DateTime.now().toIso8601String());

      final cleanupTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('✅ Cache cleanup completed in ${cleanupTime}ms');
    } catch (e) {
      final cleanupTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Cache cleanup failed after ${cleanupTime}ms: $e');
    }
  }

  /// Get cache statistics for monitoring
  static Future<Map<String, dynamic>> getCacheStats() async {
    final startTime = DateTime.now();
    _debugLog('📊 Fetching cache statistics');

    try {
      // Get total entries count
      final totalEntriesResponse = await _supabase
          .from('ai_assessment_cache')
          .select('id')
          .count(CountOption.exact);

      final totalCount = totalEntriesResponse.count;

      // Get active entries count
      final activeEntriesResponse = await _supabase
          .from('ai_assessment_cache')
          .select('id')
          .gt('expires_at', DateTime.now().toIso8601String())
          .count(CountOption.exact);

      final activeCount = activeEntriesResponse.count;

      // Get hit statistics
      final hitStats = await _supabase
          .from('ai_assessment_cache')
          .select('cache_hits')
          .gt('expires_at', DateTime.now().toIso8601String());

      final totalHits = (hitStats as List).fold<int>(0, (sum, item) => sum + ((item['cache_hits'] ?? 0) as num).toInt());
      final avgHits = hitStats.isNotEmpty ? (totalHits / hitStats.length).round() : 0;

      final statsTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('📊 Cache stats retrieved in ${statsTime}ms');

      return {
        'total_entries': totalCount,
        'active_entries': activeCount,
        'expired_entries': totalCount - activeCount,
        'total_hits': totalHits,
        'average_hits': avgHits,
      };
    } catch (e) {
      final statsTime = DateTime.now().difference(startTime).inMilliseconds;
      _debugLog('❌ Failed to get cache stats after ${statsTime}ms: $e');
      return {};
    }
  }

  /// Generate hash for input data caching
  static String _generateInputHash(Map<String, dynamic> inputData) {
    // Create a consistent string from input data for hashing
    final sortedKeys = inputData.keys.toList()..sort();
    final consistentString = sortedKeys.map((key) => '$key:${inputData[key]}').join('|');
    
    final bytes = utf8.encode(consistentString);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate hash for description caching
  static String _generateDescriptionHash(String description) {
    // Normalize description and create hash
    final normalized = description.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Enable/disable debug mode
  static void setDebugMode(bool enabled) {
    _debugMode = enabled;
    _debugLog(enabled ? '🟢 Debug mode enabled' : '🔴 Debug mode disabled');
  }
}