import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/philippine_time.dart';

class PNPUnitsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Expose Supabase client for other operations
  SupabaseClient get supabase => _supabase;

  // Get all active PNP units with their crime types
  Future<List<PNPUnit>> getAllUnits() async {
    try {
      final response = await _supabase
          .from('pnp_units')
          .select('''
            *,
            pnp_unit_crime_types(crime_type)
          ''')
          .eq('status', 'active')
          .order('unit_name');

      return (response as List).map((unit) => PNPUnit.fromJson(unit)).toList();
    } catch (e) {
      print('Error fetching PNP units: $e');
      return [];
    }
  }

  // Get crime types with their assigned units and officers
  Future<List<CrimeTypeWithUnit>> getCrimeTypesWithUnits() async {
    try {
      print('🔍 Fetching crime types with units...');
      
      // First, get all active units with their crime types (same as web app)
      final response = await _supabase
          .from('pnp_units')
          .select('''
            *,
            pnp_unit_crime_types(crime_type)
          ''')
          .eq('status', 'active')
          .order('unit_name');

      if (response == null || (response as List).isEmpty) {
        print('❌ No active PNP units found in database');
        return [];
      }

      print('✅ Found ${(response as List).length} active PNP units');

      List<CrimeTypeWithUnit> crimeTypes = [];
      
      // Process each unit and extract its crime types
      for (var unitData in response as List) {
        final unit = PNPUnit.fromJson(unitData);
        print('📋 Processing unit: ${unit.unitName} with ${unit.crimeTypes.length} crime types');
        
        // Get officers for this unit
        final officers = await getUnitOfficers(unit.id);
        print('👮 Found ${officers.length} active officers for ${unit.unitName}');
        
        // Create a CrimeTypeWithUnit for each crime type in this unit
        for (String crimeType in unit.crimeTypes) {
          crimeTypes.add(CrimeTypeWithUnit(
            crimeType: crimeType,
            unit: unit,
            availableOfficers: officers,
          ));
        }
      }

      print('✅ Total crime types found: ${crimeTypes.length}');
      return crimeTypes;
    } catch (e) {
      print('❌ Error fetching crime types with units: $e');
      return [];
    }
  }

  // Get officers for a specific unit
  Future<List<PNPOfficer>> getUnitOfficers(String unitId) async {
    try {
      final response = await _supabase
          .from('pnp_officer_profiles')
          .select('*')
          .eq('unit_id', unitId)
          .eq('status', 'active')
          .order('rank')
          .order('full_name');

      return (response as List).map((officer) => PNPOfficer.fromJson(officer)).toList();
    } catch (e) {
      print('Error fetching unit officers: $e');
      return [];
    }
  }

  // Get available officers for case assignment
  Future<List<PNPOfficer>> getAvailableOfficersForCrimeType(String crimeType) async {
    try {
      final response = await _supabase
          .from('pnp_unit_crime_types')
          .select('''
            pnp_units!inner(
              pnp_officer_profiles(
                id,
                full_name,
                badge_number,
                rank,
                status,
                active_cases,
                total_cases
              )
            )
          ''')
          .eq('crime_type', crimeType)
          .eq('pnp_units.status', 'active');

      List<PNPOfficer> officers = [];
      
      for (var item in response as List) {
        final unit = item['pnp_units'];
        final unitOfficers = (unit['pnp_officer_profiles'] as List? ?? [])
            .where((officer) => officer['status'] == 'active')
            .map((officer) => PNPOfficer.fromJson(officer))
            .toList();
        
        officers.addAll(unitOfficers);
      }

      // Sort by workload (officers with fewer active cases first)
      officers.sort((a, b) => (a.activeCases ?? 0).compareTo(b.activeCases ?? 0));
      
      return officers;
    } catch (e) {
      print('Error fetching available officers: $e');
      return [];
    }
  }
}

class PNPUnit {
  final String id;
  final String unitName;
  final String unitCode;
  final String category;
  final String description;
  final String region;
  final int maxOfficers;
  final int currentOfficers;
  final int activeCases;
  final int resolvedCases;
  final double successRate;
  final String status;
  final List<String> crimeTypes;
  final List<PNPOfficer> officers;
  final DateTime createdAt;
  final DateTime updatedAt;

  PNPUnit({
    required this.id,
    required this.unitName,
    required this.unitCode,
    required this.category,
    required this.description,
    required this.region,
    required this.maxOfficers,
    required this.currentOfficers,
    required this.activeCases,
    required this.resolvedCases,
    required this.successRate,
    required this.status,
    required this.crimeTypes,
    required this.officers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PNPUnit.fromJson(Map<String, dynamic> json) {
    // Extract crime types from the junction table
    List<String> crimeTypes = [];
    if (json['pnp_unit_crime_types'] != null) {
      crimeTypes = (json['pnp_unit_crime_types'] as List)
          .map((ct) => ct['crime_type'] as String)
          .toList();
    }

    // Extract officers if available
    List<PNPOfficer> officers = [];
    if (json['officers'] != null) {
      officers = (json['officers'] as List)
          .map((officer) => PNPOfficer.fromJson(officer))
          .toList();
    } else if (json['pnp_officer_profiles'] != null) {
      officers = (json['pnp_officer_profiles'] as List)
          .map((officer) => PNPOfficer.fromJson(officer))
          .toList();
    }

    return PNPUnit(
      id: json['id'],
      unitName: json['unit_name'],
      unitCode: json['unit_code'],
      category: json['category'],
      description: json['description'] ?? '',
      region: json['region'],
      maxOfficers: json['max_officers'] ?? 0,
      currentOfficers: json['current_officers'] ?? 0,
      activeCases: json['active_cases'] ?? 0,
      resolvedCases: json['resolved_cases'] ?? 0,
      successRate: (json['success_rate'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'active',
      crimeTypes: crimeTypes,
      officers: officers,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get categoryIcon {
    switch (category) {
      case 'Communication & Social Media Crimes':
        return '📱';
      case 'Financial & Economic Crimes':
        return '💰';
      case 'Data & Privacy Crimes':
        return '🔒';
      case 'Malware & System Attacks':
        return '💻';
      case 'Harassment & Exploitation':
        return '👥';
      case 'Content-Related Crimes':
        return '🚫';
      case 'System Disruption & Sabotage':
        return '⚡';
      case 'Government & Terrorism':
        return '🏛️';
      case 'Technical Exploitation':
        return '🔍';
      case 'Targeted Attacks':
        return '🎯';
      default:
        return '🚨';
    }
  }
}

class PNPOfficer {
  final String id;
  final String firebaseUid;
  final String email;
  final String fullName;
  final String? phoneNumber;
  final String badgeNumber;
  final String rank;
  final String unitId;
  final String region;
  final String status;
  final int? totalCases;
  final int? activeCases;
  final int? resolvedCases;
  final double? successRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PNPOfficer({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.fullName,
    this.phoneNumber,
    required this.badgeNumber,
    required this.rank,
    required this.unitId,
    required this.region,
    required this.status,
    this.totalCases,
    this.activeCases,
    this.resolvedCases,
    this.successRate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PNPOfficer.fromJson(Map<String, dynamic> json) {
    return PNPOfficer(
      id: json['id'],
      firebaseUid: json['firebase_uid'],
      email: json['email'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
      badgeNumber: json['badge_number'],
      rank: json['rank'],
      unitId: json['unit_id'],
      region: json['region'],
      status: json['status'] ?? 'active',
      totalCases: json['total_cases'],
      activeCases: json['active_cases'],
      resolvedCases: json['resolved_cases'],
      successRate: json['success_rate']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String get displayName => '$rank $fullName ($badgeNumber)';
  
  String get workloadDescription {
    final active = activeCases ?? 0;
    final total = totalCases ?? 0;
    if (active == 0) return 'Available';
    if (active <= 3) return 'Light workload ($active active cases)';
    if (active <= 7) return 'Moderate workload ($active active cases)';
    return 'Heavy workload ($active active cases)';
  }
}

class CrimeTypeWithUnit {
  final String crimeType;
  final PNPUnit unit;
  final List<PNPOfficer> availableOfficers;

  CrimeTypeWithUnit({
    required this.crimeType,
    required this.unit,
    required this.availableOfficers,
  });

  String get displayName => crimeType;
  String get assignedUnit => unit.unitName;
  String get unitCode => unit.unitCode;
  String get categoryIcon => unit.categoryIcon;
  String get category => unit.category;
  
  PNPOfficer? get recommendedOfficer {
    if (availableOfficers.isEmpty) return null;
    // Return officer with least active cases
    return availableOfficers.first;
  }
}