import 'dart:io';

enum CrimeType {
  // 📱 COMMUNICATION & SOCIAL MEDIA CRIMES - Cyber Crime Investigation Cell
  phishing('Phishing', CrimeCategory.communicationSocialMedia),
  socialEngineering('Social Engineering', CrimeCategory.communicationSocialMedia),
  spamMessages('Spam Messages', CrimeCategory.communicationSocialMedia),
  fakeSocialMediaProfiles('Fake Social Media Profiles', CrimeCategory.communicationSocialMedia),
  onlineImpersonation('Online Impersonation', CrimeCategory.communicationSocialMedia),
  businessEmailCompromise('Business Email Compromise', CrimeCategory.communicationSocialMedia),
  smsFraud('SMS Fraud', CrimeCategory.communicationSocialMedia),
  
  // 💰 FINANCIAL & ECONOMIC CRIMES - Economic Offenses Wing
  onlineBankingFraud('Online Banking Fraud', CrimeCategory.financialEconomic),
  creditCardFraud('Credit Card Fraud', CrimeCategory.financialEconomic),
  investmentScams('Investment Scams', CrimeCategory.financialEconomic),
  cryptocurrencyFraud('Cryptocurrency Fraud', CrimeCategory.financialEconomic),
  onlineShoppingScams('Online Shopping Scams', CrimeCategory.financialEconomic),
  paymentGatewayFraud('Payment Gateway Fraud', CrimeCategory.financialEconomic),
  insuranceFraud('Insurance Fraud', CrimeCategory.financialEconomic),
  taxFraud('Tax Fraud', CrimeCategory.financialEconomic),
  moneyLaundering('Money Laundering', CrimeCategory.financialEconomic),
  
  // 🔒 DATA & PRIVACY CRIMES - Cyber Security Division
  identityTheft('Identity Theft', CrimeCategory.dataPrivacy),
  dataBreach('Data Breach', CrimeCategory.dataPrivacy),
  unauthorizedSystemAccess('Unauthorized System Access', CrimeCategory.dataPrivacy),
  corporateEspionage('Corporate Espionage', CrimeCategory.dataPrivacy),
  governmentDataTheft('Government Data Theft', CrimeCategory.dataPrivacy),
  medicalRecordsTheft('Medical Records Theft', CrimeCategory.dataPrivacy),
  personalInformationTheft('Personal Information Theft', CrimeCategory.dataPrivacy),
  accountTakeover('Account Takeover', CrimeCategory.dataPrivacy),
  
  // 💻 MALWARE & SYSTEM ATTACKS - Cyber Crime Technical Unit
  ransomware('Ransomware', CrimeCategory.malwareSystemAttacks),
  virusAttacks('Virus Attacks', CrimeCategory.malwareSystemAttacks),
  trojanHorses('Trojan Horses', CrimeCategory.malwareSystemAttacks),
  spyware('Spyware', CrimeCategory.malwareSystemAttacks),
  adware('Adware', CrimeCategory.malwareSystemAttacks),
  worms('Worms', CrimeCategory.malwareSystemAttacks),
  keyloggers('Keyloggers', CrimeCategory.malwareSystemAttacks),
  rootkits('Rootkits', CrimeCategory.malwareSystemAttacks),
  cryptojacking('Cryptojacking', CrimeCategory.malwareSystemAttacks),
  botnetAttacks('Botnet Attacks', CrimeCategory.malwareSystemAttacks),
  
  // 👥 HARASSMENT & EXPLOITATION - Cyber Crime Against Women and Children
  cyberstalking('Cyberstalking', CrimeCategory.harassmentExploitation),
  onlineHarassment('Online Harassment', CrimeCategory.harassmentExploitation),
  cyberbullying('Cyberbullying', CrimeCategory.harassmentExploitation),
  revengePorn('Revenge Porn', CrimeCategory.harassmentExploitation),
  sextortion('Sextortion', CrimeCategory.harassmentExploitation),
  onlinePredatoryBehavior('Online Predatory Behavior', CrimeCategory.harassmentExploitation),
  doxxing('Doxxing', CrimeCategory.harassmentExploitation),
  hateSpeech('Hate Speech', CrimeCategory.harassmentExploitation),
  
  // 🚫 CONTENT-RELATED CRIMES - Special Investigation Team
  childSexualAbuseMaterial('Child Sexual Abuse Material', CrimeCategory.contentRelated),
  illegalContentDistribution('Illegal Content Distribution', CrimeCategory.contentRelated),
  copyrightInfringement('Copyright Infringement', CrimeCategory.contentRelated),
  softwarePiracy('Software Piracy', CrimeCategory.contentRelated),
  illegalOnlineGambling('Illegal Online Gambling', CrimeCategory.contentRelated),
  onlineDrugTrafficking('Online Drug Trafficking', CrimeCategory.contentRelated),
  illegalWeaponsSales('Illegal Weapons Sales', CrimeCategory.contentRelated),
  humanTrafficking('Human Trafficking', CrimeCategory.contentRelated),
  
  // ⚡ SYSTEM DISRUPTION & SABOTAGE - Critical Infrastructure Protection Unit
  denialOfServiceAttacks('Denial of Service Attacks', CrimeCategory.systemDisruption),
  websiteDefacement('Website Defacement', CrimeCategory.systemDisruption),
  systemSabotage('System Sabotage', CrimeCategory.systemDisruption),
  networkIntrusion('Network Intrusion', CrimeCategory.systemDisruption),
  sqlInjection('SQL Injection', CrimeCategory.systemDisruption),
  crossSiteScripting('Cross-Site Scripting', CrimeCategory.systemDisruption),
  manInTheMiddleAttacks('Man-in-the-Middle Attacks', CrimeCategory.systemDisruption),
  
  // 🏛️ GOVERNMENT & TERRORISM - National Security Cyber Division
  cyberterrorism('Cyberterrorism', CrimeCategory.governmentTerrorism),
  cyberWarfare('Cyber Warfare', CrimeCategory.governmentTerrorism),
  governmentSystemHacking('Government System Hacking', CrimeCategory.governmentTerrorism),
  electionInterference('Election Interference', CrimeCategory.governmentTerrorism),
  criticalInfrastructureAttacks('Critical Infrastructure Attacks', CrimeCategory.governmentTerrorism),
  propagandaDistribution('Propaganda Distribution', CrimeCategory.governmentTerrorism),
  stateSponsoredAttacks('State-Sponsored Attacks', CrimeCategory.governmentTerrorism),
  
  // 🔍 TECHNICAL EXPLOITATION - Advanced Cyber Forensics Unit
  zeroDayExploits('Zero-Day Exploits', CrimeCategory.technicalExploitation),
  vulnerabilityExploitation('Vulnerability Exploitation', CrimeCategory.technicalExploitation),
  backdoorCreation('Backdoor Creation', CrimeCategory.technicalExploitation),
  privilegeEscalation('Privilege Escalation', CrimeCategory.technicalExploitation),
  codeInjection('Code Injection', CrimeCategory.technicalExploitation),
  bufferOverflowAttacks('Buffer Overflow Attacks', CrimeCategory.technicalExploitation),
  
  // 🎯 TARGETED ATTACKS - Special Cyber Operations Unit
  advancedPersistentThreats('Advanced Persistent Threats', CrimeCategory.targetedAttacks),
  spearPhishing('Spear Phishing', CrimeCategory.targetedAttacks),
  ceoFraud('CEO Fraud', CrimeCategory.targetedAttacks),
  supplyChainAttacks('Supply Chain Attacks', CrimeCategory.targetedAttacks),
  insiderThreats('Insider Threats', CrimeCategory.targetedAttacks);

  const CrimeType(this.displayName, this.category);
  final String displayName;
  final CrimeCategory category;
  
  String get assignedUnit {
    switch (category) {
      case CrimeCategory.communicationSocialMedia:
        return 'Cyber Crime Investigation Cell';
      case CrimeCategory.financialEconomic:
        return 'Economic Offenses Wing';
      case CrimeCategory.dataPrivacy:
        return 'Cyber Security Division';
      case CrimeCategory.malwareSystemAttacks:
        return 'Cyber Crime Technical Unit';
      case CrimeCategory.harassmentExploitation:
        return 'Cyber Crime Against Women and Children';
      case CrimeCategory.contentRelated:
        return 'Special Investigation Team';
      case CrimeCategory.systemDisruption:
        return 'Critical Infrastructure Protection Unit';
      case CrimeCategory.governmentTerrorism:
        return 'National Security Cyber Division';
      case CrimeCategory.technicalExploitation:
        return 'Advanced Cyber Forensics Unit';
      case CrimeCategory.targetedAttacks:
        return 'Special Cyber Operations Unit';
    }
  }
  
  String get categoryIcon {
    switch (category) {
      case CrimeCategory.communicationSocialMedia:
        return '📱';
      case CrimeCategory.financialEconomic:
        return '💰';
      case CrimeCategory.dataPrivacy:
        return '🔒';
      case CrimeCategory.malwareSystemAttacks:
        return '💻';
      case CrimeCategory.harassmentExploitation:
        return '👥';
      case CrimeCategory.contentRelated:
        return '🚫';
      case CrimeCategory.systemDisruption:
        return '⚡';
      case CrimeCategory.governmentTerrorism:
        return '🏛️';
      case CrimeCategory.technicalExploitation:
        return '🔍';
      case CrimeCategory.targetedAttacks:
        return '🎯';
    }
  }
  
  String get categoryName {
    switch (category) {
      case CrimeCategory.communicationSocialMedia:
        return 'Communication & Social Media Crimes';
      case CrimeCategory.financialEconomic:
        return 'Financial & Economic Crimes';
      case CrimeCategory.dataPrivacy:
        return 'Data & Privacy Crimes';
      case CrimeCategory.malwareSystemAttacks:
        return 'Malware & System Attacks';
      case CrimeCategory.harassmentExploitation:
        return 'Harassment & Exploitation';
      case CrimeCategory.contentRelated:
        return 'Content-Related Crimes';
      case CrimeCategory.systemDisruption:
        return 'System Disruption & Sabotage';
      case CrimeCategory.governmentTerrorism:
        return 'Government & Terrorism';
      case CrimeCategory.technicalExploitation:
        return 'Technical Exploitation';
      case CrimeCategory.targetedAttacks:
        return 'Targeted Attacks';
    }
  }
}

enum CrimeCategory {
  communicationSocialMedia,
  financialEconomic,
  dataPrivacy,
  malwareSystemAttacks,
  harassmentExploitation,
  contentRelated,
  systemDisruption,
  governmentTerrorism,
  technicalExploitation,
  targetedAttacks,
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

class Complaint {
  final String? id;
  final String userId;
  final CrimeType crimeType;
  final String? title; // Added to match web app
  final String description;
  final List<EvidenceFile> evidenceFiles;
  final String fullName;
  final String email;
  final String phoneNumber;
  final DateTime incidentDateTime;
  final String? incidentLocation;
  final double? estimatedFinancialLoss;
  final ComplaintStatus status;
  final String priority; // Added to match web app (high, medium, low)
  final int riskScore; // Added to match web app (0-100)
  final String? assignedUnit; // Added to match web app
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? complaintNumber;
  final String? assignedOfficer;
  final String? assignedOfficerId; // Added for proper officer tracking
  final String? remarks;
  final List<StatusUpdate> statusHistory;

  Complaint({
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
    this.assignedUnit,
    required this.createdAt,
    required this.updatedAt,
    this.complaintNumber,
    this.assignedOfficer,
    this.assignedOfficerId,
    this.remarks,
    this.statusHistory = const [],
  });

  factory Complaint.create({
    required String userId,
    required CrimeType crimeType,
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
    
    // Calculate priority and risk score based on crime type and financial loss
    final priority = _calculatePriority(crimeType, estimatedFinancialLoss);
    final riskScore = _calculateRiskScore(crimeType, estimatedFinancialLoss);
    
    return Complaint(
      userId: userId,
      crimeType: crimeType,
      title: _generateTitle(crimeType, description),
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
  static String _generateTitle(CrimeType crimeType, String description) {
    final words = description.split(' ').take(8);
    final title = words.join(' ');
    return title.length > 100 ? '${title.substring(0, 97)}...' : title;
  }

  // Helper method to calculate priority
  static String _calculatePriority(CrimeType crimeType, double? financialLoss) {
    // High priority crimes
    if ([
      CrimeType.cyberterrorism,
      CrimeType.governmentSystemHacking,
      CrimeType.criticalInfrastructureAttacks,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
      CrimeType.onlinePredatoryBehavior,
    ].contains(crimeType)) {
      return 'high';
    }

    // High priority based on financial loss
    if (financialLoss != null && financialLoss >= 100000) {
      return 'high';
    }

    // Medium priority crimes
    if ([
      CrimeType.identityTheft,
      CrimeType.onlineBankingFraud,
      CrimeType.creditCardFraud,
      CrimeType.sextortion,
      CrimeType.dataBreach,
      CrimeType.denialOfServiceAttacks,
    ].contains(crimeType)) {
      return 'medium';
    }

    // Medium priority based on financial loss
    if (financialLoss != null && financialLoss >= 10000) {
      return 'medium';
    }

    return 'low';
  }

  // Helper method to calculate risk score
  static int _calculateRiskScore(CrimeType crimeType, double? financialLoss) {
    int baseScore = 30;

    // Crime type multiplier
    final highRiskCrimes = [
      CrimeType.cyberterrorism,
      CrimeType.governmentSystemHacking,
      CrimeType.criticalInfrastructureAttacks,
      CrimeType.childSexualAbuseMaterial,
      CrimeType.ransomware,
      CrimeType.onlinePredatoryBehavior,
    ];

    final mediumRiskCrimes = [
      CrimeType.identityTheft,
      CrimeType.onlineBankingFraud,
      CrimeType.creditCardFraud,
      CrimeType.sextortion,
      CrimeType.dataBreach,
      CrimeType.denialOfServiceAttacks,
    ];

    if (highRiskCrimes.contains(crimeType)) {
      baseScore += 40;
    } else if (mediumRiskCrimes.contains(crimeType)) {
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
      'assignedUnit': assignedUnit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'complaintNumber': complaintNumber,
      'assignedOfficer': assignedOfficer,
      'assignedOfficerId': assignedOfficerId,
      'remarks': remarks,
      'statusHistory': statusHistory.map((update) => update.toJson()).toList(),
    };
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      userId: json['userId'],
      crimeType: CrimeType.values.firstWhere((e) => e.name == json['crimeType']),
      title: json['title'],
      description: json['description'],
      evidenceFiles: (json['evidenceFiles'] as List<dynamic>?)
          ?.map((file) => EvidenceFile.fromJson(file))
          .toList() ?? [],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      incidentDateTime: DateTime.parse(json['incidentDateTime']),
      incidentLocation: json['incidentLocation'],
      estimatedFinancialLoss: json['estimatedFinancialLoss']?.toDouble(),
      status: ComplaintStatus.values.firstWhere((e) => e.name == json['status']),
      priority: json['priority'] ?? 'low',
      riskScore: json['riskScore'] ?? 30,
      assignedUnit: json['assignedUnit'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      complaintNumber: json['complaintNumber'],
      assignedOfficer: json['assignedOfficer'],
      assignedOfficerId: json['assignedOfficerId'],
      remarks: json['remarks'],
      statusHistory: (json['statusHistory'] as List<dynamic>?)
          ?.map((update) => StatusUpdate.fromJson(update))
          .toList() ?? [],
    );
  }

  Complaint copyWith({
    String? id,
    String? userId,
    CrimeType? crimeType,
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
    String? assignedUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? complaintNumber,
    String? assignedOfficer,
    String? assignedOfficerId,
    String? remarks,
    List<StatusUpdate>? statusHistory,
  }) {
    return Complaint(
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      complaintNumber: complaintNumber ?? this.complaintNumber,
      assignedOfficer: assignedOfficer ?? this.assignedOfficer,
      assignedOfficerId: assignedOfficerId ?? this.assignedOfficerId,
      remarks: remarks ?? this.remarks,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  bool get hasContactInfo => fullName != null || email != null || phoneNumber != null;
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