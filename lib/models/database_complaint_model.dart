import 'dart:io';
import '../services/pnp_units_service.dart';

// Crime type that comes from database
class DatabaseCrimeType {
  final String name;
  final String category;
  final String categoryIcon;
  final PNPUnit assignedUnit;
  final List<PNPOfficer> availableOfficers;

  DatabaseCrimeType({
    required this.name,
    required this.category,
    required this.categoryIcon,
    required this.assignedUnit,
    required this.availableOfficers,
  });

  factory DatabaseCrimeType.fromCrimeTypeWithUnit(CrimeTypeWithUnit crimeTypeWithUnit) {
    return DatabaseCrimeType(
      name: crimeTypeWithUnit.crimeType,
      category: crimeTypeWithUnit.category,
      categoryIcon: crimeTypeWithUnit.categoryIcon,
      assignedUnit: crimeTypeWithUnit.unit,
      availableOfficers: crimeTypeWithUnit.availableOfficers,
    );
  }

  String get displayName => name;
  String get assignedUnitName => assignedUnit.unitName;
  String get assignedUnitCode => assignedUnit.unitCode;
  
  // Officers are available for user selection
  int get availableOfficerCount => availableOfficers.length;
  
  // Integration with dynamic field system
  String get categoryForFields => category;
  
  PNPOfficer? get recommendedOfficer {
    if (availableOfficers.isEmpty) return null;
    // Return officer with least active cases for recommendation
    availableOfficers.sort((a, b) => (a.activeCases ?? 0).compareTo(b.activeCases ?? 0));
    return availableOfficers.first;
  }
}

enum ComplaintStatus {
  pending('Pending', 'Your complaint has been received and is being reviewed'),
  underInvestigation('Under Investigation', 'PNP officers are actively investigating your complaint'),
  resolved('Resolved', 'Your complaint has been resolved'),
  dismissed('Dismissed', 'Your complaint has been dismissed'),
  requiresMoreInfo('Requires More Information', 'Additional information is needed to proceed');

  const ComplaintStatus(this.displayName, this.description);
  final String displayName;
  final String description;
}

class EvidenceFile {
  final String? id;
  final String fileName;
  final String filePath;
  final String fileType;
  final int fileSize;
  final DateTime uploadedAt;
  final String? downloadUrl;

  EvidenceFile({
    this.id,
    required this.fileName,
    required this.filePath,
    required this.fileType,
    required this.fileSize,
    required this.uploadedAt,
    this.downloadUrl,
  });

  factory EvidenceFile.fromFile(File file) {
    final fileName = file.path.split('/').last;
    final fileSize = file.lengthSync();
    final fileType = fileName.split('.').last.toLowerCase();
    
    return EvidenceFile(
      fileName: fileName,
      filePath: file.path,
      fileType: fileType,
      fileSize: fileSize,
      uploadedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'filePath': filePath,
      'fileType': fileType,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toIso8601String(),
      'downloadUrl': downloadUrl,
    };
  }

  factory EvidenceFile.fromJson(Map<String, dynamic> json) {
    return EvidenceFile(
      id: json['id'],
      fileName: json['fileName'],
      filePath: json['filePath'],
      fileType: json['fileType'],
      fileSize: json['fileSize'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
      downloadUrl: json['downloadUrl'],
    );
  }

  String get fileExtension => fileType.toUpperCase();
  
  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  bool get isImage => ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);
  bool get isVideo => ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'].contains(fileType);
  bool get isDocument => ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileType);
}

class DatabaseComplaint {
  final String? id;
  final String userId;
  final DatabaseCrimeType crimeType;
  final String? title;
  final String description;
  final List<EvidenceFile> evidenceFiles;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime incidentDateTime;
  final String? incidentLocation;
  final double? estimatedFinancialLoss;
  final ComplaintStatus status;
  final String priority;
  final int riskScore;
  final PNPUnit assignedUnit;
  final PNPOfficer? assignedOfficer;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? complaintNumber;
  final String? remarks;
  final List<StatusUpdate> statusHistory;

  DatabaseComplaint({
    this.id,
    required this.userId,
    required this.crimeType,
    this.title,
    required this.description,
    this.evidenceFiles = const [],
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.incidentDateTime,
    this.incidentLocation,
    this.estimatedFinancialLoss,
    this.status = ComplaintStatus.pending,
    this.priority = 'low',
    this.riskScore = 30,
    required this.assignedUnit,
    this.assignedOfficer,
    required this.createdAt,
    required this.updatedAt,
    this.complaintNumber,
    this.remarks,
    this.statusHistory = const [],
  });

  factory DatabaseComplaint.create({
    required String userId,
    required DatabaseCrimeType crimeType,
    required String description,
    List<EvidenceFile> evidenceFiles = const [],
    required String fullName,
    required String email,
    required String phoneNumber,
    required DateTime incidentDateTime,
    String? incidentLocation,
    double? estimatedFinancialLoss,
  }) {
    final now = DateTime.now();
    
    // Calculate priority and risk score
    final priority = _calculatePriority(crimeType.name, estimatedFinancialLoss);
    final riskScore = _calculateRiskScore(crimeType.name, estimatedFinancialLoss);
    
    return DatabaseComplaint(
      userId: userId,
      crimeType: crimeType,
      title: _generateTitle(crimeType.name, description),
      description: description,
      evidenceFiles: evidenceFiles,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      incidentDateTime: incidentDateTime,
      incidentLocation: incidentLocation,
      estimatedFinancialLoss: estimatedFinancialLoss,
      priority: priority,
      riskScore: riskScore,
      assignedUnit: crimeType.assignedUnit,
      assignedOfficer: null, // Officer assignment handled by admin
      createdAt: now,
      updatedAt: now,
      statusHistory: [
        StatusUpdate(
          status: ComplaintStatus.pending,
          timestamp: now,
          updatedBy: 'System',
          remarks: 'Complaint submitted successfully',
        )
      ],
    );
  }

  // Helper method to generate complaint title
  static String _generateTitle(String crimeTypeName, String description) {
    final words = description.split(' ').take(8);
    final title = words.join(' ');
    return title.length > 100 ? '${title.substring(0, 97)}...' : title;
  }

  // Helper method to calculate priority based on crime type and financial loss
  static String _calculatePriority(String crimeTypeName, double? financialLoss) {
    // High priority crimes (based on crime type name)
    final highPriorityCrimes = [
      'Cyberterrorism',
      'Government System Hacking',
      'Critical Infrastructure Attacks',
      'Child Sexual Abuse Material',
      'Ransomware',
      'Online Predatory Behavior',
    ];

    if (highPriorityCrimes.any((crime) => crimeTypeName.toLowerCase().contains(crime.toLowerCase()))) {
      return 'high';
    }

    // High priority based on financial loss
    if (financialLoss != null && financialLoss >= 100000) {
      return 'high';
    }

    // Medium priority crimes
    final mediumPriorityCrimes = [
      'Identity Theft',
      'Online Banking Fraud',
      'Credit Card Fraud',
      'Sextortion',
      'Data Breach',
      'Denial of Service Attacks',
    ];

    if (mediumPriorityCrimes.any((crime) => crimeTypeName.toLowerCase().contains(crime.toLowerCase()))) {
      return 'medium';
    }

    // Medium priority based on financial loss
    if (financialLoss != null && financialLoss >= 10000) {
      return 'medium';
    }

    return 'low';
  }

  // Helper method to calculate risk score
  static int _calculateRiskScore(String crimeTypeName, double? financialLoss) {
    int baseScore = 30;

    // High risk crimes
    final highRiskCrimes = [
      'Cyberterrorism',
      'Government System Hacking',
      'Critical Infrastructure Attacks',
      'Child Sexual Abuse Material',
      'Ransomware',
      'Online Predatory Behavior',
    ];

    final mediumRiskCrimes = [
      'Identity Theft',
      'Online Banking Fraud',
      'Credit Card Fraud',
      'Sextortion',
      'Data Breach',
      'Denial of Service Attacks',
    ];

    if (highRiskCrimes.any((crime) => crimeTypeName.toLowerCase().contains(crime.toLowerCase()))) {
      baseScore += 40;
    } else if (mediumRiskCrimes.any((crime) => crimeTypeName.toLowerCase().contains(crime.toLowerCase()))) {
      baseScore += 25;
    } else {
      baseScore += 10;
    }

    // Financial loss impact
    if (financialLoss != null) {
      if (financialLoss >= 1000000) {
        baseScore += 25;
      } else if (financialLoss >= 100000) {
        baseScore += 15;
      } else if (financialLoss >= 10000) {
        baseScore += 10;
      } else if (financialLoss >= 1000) {
        baseScore += 5;
      }
    }

    // Ensure score is between 0-100
    return baseScore.clamp(0, 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'crimeType': crimeType.name,
      'title': title,
      'description': description,
      'evidenceFiles': evidenceFiles.map((file) => file.toJson()).toList(),
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'incidentDateTime': incidentDateTime.toIso8601String(),
      'incidentLocation': incidentLocation,
      'estimatedFinancialLoss': estimatedFinancialLoss,
      'status': status.name,
      'priority': priority,
      'riskScore': riskScore,
      'assignedUnit': assignedUnit.unitName,
      'assignedOfficer': assignedOfficer?.displayName,
      'assignedOfficerId': assignedOfficer?.id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'complaintNumber': complaintNumber,
      'remarks': remarks,
      'statusHistory': statusHistory.map((update) => update.toJson()).toList(),
    };
  }

  DatabaseComplaint copyWith({
    String? id,
    String? userId,
    DatabaseCrimeType? crimeType,
    String? title,
    String? description,
    List<EvidenceFile>? evidenceFiles,
    String? fullName,
    String? email,
    String? phoneNumber,
    DateTime? incidentDateTime,
    String? incidentLocation,
    double? estimatedFinancialLoss,
    ComplaintStatus? status,
    String? priority,
    int? riskScore,
    PNPUnit? assignedUnit,
    PNPOfficer? assignedOfficer,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? complaintNumber,
    String? remarks,
    List<StatusUpdate>? statusHistory,
  }) {
    return DatabaseComplaint(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      crimeType: crimeType ?? this.crimeType,
      title: title ?? this.title,
      description: description ?? this.description,
      evidenceFiles: evidenceFiles ?? this.evidenceFiles,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      incidentDateTime: incidentDateTime ?? this.incidentDateTime,
      incidentLocation: incidentLocation ?? this.incidentLocation,
      estimatedFinancialLoss: estimatedFinancialLoss ?? this.estimatedFinancialLoss,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      riskScore: riskScore ?? this.riskScore,
      assignedUnit: assignedUnit ?? this.assignedUnit,
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      complaintNumber: complaintNumber ?? this.complaintNumber,
      remarks: remarks ?? this.remarks,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  bool get hasContactInfo => fullName.isNotEmpty && email.isNotEmpty && phoneNumber.isNotEmpty;
  bool get hasEvidence => evidenceFiles.isNotEmpty;
  
  String get statusDisplay => status.displayName;
  String get crimeTypeDisplay => crimeType.displayName;
  
  Duration get timeSinceCreated => DateTime.now().difference(createdAt);
  Duration get timeSinceUpdated => DateTime.now().difference(updatedAt);
}

class StatusUpdate {
  final ComplaintStatus status;
  final DateTime timestamp;
  final String updatedBy;
  final String? remarks;

  StatusUpdate({
    required this.status,
    required this.timestamp,
    required this.updatedBy,
    this.remarks,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'updatedBy': updatedBy,
      'remarks': remarks,
    };
  }

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      status: ComplaintStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      updatedBy: json['updatedBy'],
      remarks: json['remarks'],
    );
  }
}