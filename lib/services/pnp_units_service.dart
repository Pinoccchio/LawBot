import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/philippine_time.dart';

class PNPUnitsService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Expose Supabase client for other operations
  SupabaseClient get supabase => _supabase;

  // Get all active PNP units with their crime types
  Future<List<PNPUnit>> getAllUnits() async {
    try {
      // First, get units without crime types join (safer approach)
      final response = await _supabase
          .from('pnp_units')
          .select('*')
          .eq('status', 'active')
          .order('unit_name');

      if (response == null || (response as List).isEmpty) {
        print('❌ No active PNP units found in database');
        return [];
      }

      print('✅ Found ${(response as List).length} active PNP units in Flutter app');

      // Get crime types separately for each unit (same pattern as web app)
      List<PNPUnit> unitsWithCrimeTypes = [];
      
      for (var unitData in response as List) {
        try {
          // Get crime types for this unit
          final crimeTypesResponse = await _supabase
              .from('pnp_unit_crime_types')
              .select('crime_type')
              .eq('unit_id', unitData['id']);

          // Extract crime types or use empty list if none found
          List<String> crimeTypes = [];
          if (crimeTypesResponse != null) {
            crimeTypes = (crimeTypesResponse as List)
                .map((ct) => ct['crime_type'] as String)
                .toList();
          }

          // Add crime types to unit data for PNPUnit.fromJson
          unitData['pnp_unit_crime_types'] = crimeTypes.map((ct) => {'crime_type': ct}).toList();
          
          unitsWithCrimeTypes.add(PNPUnit.fromJson(unitData));
        } catch (e) {
          print('⚠️ Error getting crime types for unit ${unitData['unit_name']}: $e');
          // Add unit without crime types
          unitData['pnp_unit_crime_types'] = [];
          unitsWithCrimeTypes.add(PNPUnit.fromJson(unitData));
        }
      }

      return unitsWithCrimeTypes;
    } catch (e) {
      print('❌ Error fetching PNP units: $e');
      return [];
    }
  }

  // Get crime types with their assigned units and officers (with urgency support)
  Future<List<CrimeTypeWithUnit>> getCrimeTypesWithUnits({bool isUrgentCase = false}) async {
    try {
      print('🔍 Fetching crime types with units...');
      
      // Use the safer getAllUnits() method which handles the JOIN properly
      final units = await getAllUnits();

      if (units.isEmpty) {
        print('❌ No active PNP units found in database');
        return [];
      }

      print('✅ Found ${units.length} active PNP units');

      List<CrimeTypeWithUnit> crimeTypes = [];
      
      // Process each unit and extract its crime types
      for (PNPUnit unit in units) {
        print('📋 Processing unit: ${unit.unitName} with ${unit.crimeTypes.length} crime types');
        
        // Get AVAILABLE officers for this unit with urgency consideration
        final officers = await getAvailableUnitOfficers(unit.id, isUrgent: isUrgentCase);
        print('👮 Found ${officers.length} officers for ${unit.unitName} (urgent: $isUrgentCase)');
        
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

  // Get AVAILABLE officers for a specific unit with availability filtering
  Future<List<PNPOfficer>> getAvailableUnitOfficers(String unitId, {bool isUrgent = false}) async {
    try {
      var query = _supabase
          .from('pnp_officer_profiles')
          .select('*')
          .eq('unit_id', unitId)
          .eq('status', 'active'); // Must be active status
      
      // Show ALL officers regardless of availability status
      // Filtering will be handled in the UI based on urgency and availability
      
      // Order by availability priority (available first, then busy) and then by name
      final response = await query.order('availability_status').order('full_name');

      final officers = (response as List).map((officer) => PNPOfficer.fromJson(officer)).toList();
      
      // Sort by availability priority (available first, then busy, then overloaded, then unavailable)
      officers.sort((a, b) {
        final aStatus = a.availabilityStatus ?? 'available';
        final bStatus = b.availabilityStatus ?? 'available';
        
        // Priority order: available (1), busy (2), overloaded (3), unavailable (4)
        int getPriority(String status) {
          switch (status) {
            case 'available': return 1;
            case 'busy': return 2;
            case 'overloaded': return 3;
            case 'unavailable': return 4;
            default: return 5;
          }
        }
        
        final aPriority = getPriority(aStatus);
        final bPriority = getPriority(bStatus);
        
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return a.fullName.compareTo(b.fullName);
      });
      
      print('👮‍♂️ Unit $unitId: ${officers.length} total officers shown (urgent: $isUrgent)');
      print('📊 Available: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'available').length}, Busy: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'busy').length}, Overloaded: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'overloaded').length}, Unavailable: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'unavailable').length}');
      
      return officers;
    } catch (e) {
      print('Error fetching available unit officers: $e');
      return [];
    }
  }

  // Get available officers for case assignment with availability filtering
  Future<List<PNPOfficer>> getAvailableOfficersForCrimeType(String crimeType, {bool isUrgent = false}) async {
    try {
      final response = await _supabase
          .from('pnp_unit_crime_types')
          .select('''
            pnp_units!inner(
              pnp_officer_profiles(
                id,
                firebase_uid,
                email,
                full_name,
                phone_number,
                badge_number,
                rank,
                unit_id,
                region,
                status,
                availability_status,
                total_cases,
                active_cases,
                resolved_cases,
                success_rate,
                created_at,
                updated_at
              )
            )
          ''')
          .eq('crime_type', crimeType)
          .eq('pnp_units.status', 'active');

      List<PNPOfficer> officers = [];
      
      for (var item in response as List) {
        final unit = item['pnp_units'];
        final unitOfficers = (unit['pnp_officer_profiles'] as List? ?? [])
            .where((officer) {
              // Must be active status (only filter by employment status)
              return officer['status'] == 'active';
            })
            .map((officer) => PNPOfficer.fromJson(officer))
            .toList();
        
        officers.addAll(unitOfficers);
      }

      // Sort by availability priority first, then by name
      officers.sort((a, b) {
        final aStatus = a.availabilityStatus ?? 'available';
        final bStatus = b.availabilityStatus ?? 'available';
        
        // Priority order: available (1), busy (2), overloaded (3), unavailable (4)
        int getPriority(String status) {
          switch (status) {
            case 'available': return 1;
            case 'busy': return 2;
            case 'overloaded': return 3;
            case 'unavailable': return 4;
            default: return 5;
          }
        }
        
        final aPriority = getPriority(aStatus);
        final bPriority = getPriority(bStatus);
        
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return a.fullName.compareTo(b.fullName);
      });
      
      print('🔍 Found ${officers.length} total officers for $crimeType crime type (urgent: $isUrgent)');
      print('📊 Available: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'available').length}, Busy: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'busy').length}, Overloaded: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'overloaded').length}, Unavailable: ${officers.where((o) => (o.availabilityStatus ?? 'available') == 'unavailable').length}');
      
      return officers;
    } catch (e) {
      print('Error fetching available officers: $e');
      return [];
    }
  }

  // Helper method to determine if case is urgent based on AI risk assessment
  static bool isUrgentCase({
    int? aiRiskScore,
    String? aiPriority,
    double? financialLoss,
    String? crimeType,
  }) {
    // Priority 1: AI risk assessment results
    if (aiRiskScore != null && aiRiskScore >= 70) {
      print('🚨 Case marked as URGENT: AI risk score $aiRiskScore >= 70');
      return true;
    }
    
    if (aiPriority != null && (aiPriority.toLowerCase() == 'high' || aiPriority.toLowerCase() == 'urgent')) {
      print('🚨 Case marked as URGENT: AI priority is $aiPriority');
      return true;
    }
    
    // Priority 2: Financial threshold (high financial loss cases)
    if (financialLoss != null && financialLoss >= 100000) { // ₱100,000 or more
      print('🚨 Case marked as URGENT: Financial loss ₱${financialLoss.toStringAsFixed(2)} >= ₱100,000');
      return true;
    }
    
    // Priority 3: Crime type analysis (high-impact crimes)
    if (crimeType != null) {
      final urgentCrimeTypes = [
        // Financial crimes with high impact
        'Identity Theft for Financial Gain',
        'Credit Card Fraud',
        'Online Banking Fraud',
        'Investment Scams',
        'Ransomware Attacks',
        // Safety-related crimes
        'Cyberstalking',
        'Online Threats and Intimidation',
        'Child Exploitation',
        'Human Trafficking via Online Platforms',
        // National security concerns
        'Government Website Defacement',
        'Critical Infrastructure Attacks',
        'Cyber Terrorism',
      ];
      
      if (urgentCrimeTypes.any((urgentType) => crimeType.toLowerCase().contains(urgentType.toLowerCase()))) {
        print('🚨 Case marked as URGENT: Crime type "$crimeType" is high-impact');
        return true;
      }
    }
    
    print('📄 Case marked as NORMAL priority');
    return false;
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

  // Implement equality and hashCode for proper dropdown functionality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PNPUnit) return false;
    
    return id == other.id && 
           unitName == other.unitName &&
           unitCode == other.unitCode;
  }

  @override
  int get hashCode => Object.hash(id, unitName, unitCode);
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
  final String? availabilityStatus;
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
    this.availabilityStatus,
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
      availabilityStatus: json['availability_status'] ?? 'available',
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
    
    // Use availability status if available
    if (availabilityStatus != null) {
      switch (availabilityStatus!) {
        case 'available':
          return 'Available ($active active cases)';
        case 'busy':
          return 'Busy ($active active cases)';
        case 'overloaded':
          return 'Overloaded ($active active cases)';
        case 'unavailable':
          return 'Unavailable';
        default:
          break;
      }
    }
    
    // Fallback to simple logic if availability status not available
    if (active == 0) return 'Available';
    if (active <= 3) return 'Light workload ($active active cases)';
    if (active <= 7) return 'Moderate workload ($active active cases)';
    return 'Heavy workload ($active active cases)';
  }
  
  bool get isAvailableForAssignment {
    return status == 'active' && 
           (availabilityStatus == 'available' || availabilityStatus == 'busy');
  }
  
  String get availabilityStatusDisplay {
    switch (availabilityStatus ?? 'available') {
      case 'available':
        return '🟢 Available';
      case 'busy':
        return '🟡 Busy';
      case 'overloaded':
        return '🔴 Overloaded';
      case 'unavailable':
        return '⚫ Unavailable';
      default:
        return '❓ Unknown';
    }
  }
  
  // Check if officer can be selected based on urgency and availability
  bool canBeSelected({required bool isUrgentCase}) {
    final availability = availabilityStatus ?? 'available';
    
    switch (availability) {
      case 'available':
        return true; // Always selectable
      case 'busy':
        return isUrgentCase; // Only selectable for urgent cases
      case 'overloaded':
      case 'unavailable':
        return false; // Never selectable
      default:
        return false;
    }
  }

  // Implement equality and hashCode for proper dropdown functionality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PNPOfficer) return false;
    
    return id == other.id && 
           firebaseUid == other.firebaseUid &&
           badgeNumber == other.badgeNumber;
  }

  @override
  int get hashCode => Object.hash(id, firebaseUid, badgeNumber);
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