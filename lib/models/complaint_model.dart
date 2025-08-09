import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ai_risk_assessment_service.dart';

enum CrimeType {
  // 📱 COMMUNICATION & SOCIAL MEDIA CRIMES - Cyber Crime Investigation Cell
  phishing('Phishing', CrimeCategory.communicationSocialMedia),
  socialEngineering(
      'Social Engineering', CrimeCategory.communicationSocialMedia),
  spamMessages('Spam Messages', CrimeCategory.communicationSocialMedia),
  fakeSocialMediaProfiles(
      'Fake Social Media Profiles', CrimeCategory.communicationSocialMedia),
  onlineImpersonation(
      'Online Impersonation', CrimeCategory.communicationSocialMedia),
  businessEmailCompromise(
      'Business Email Compromise', CrimeCategory.communicationSocialMedia),
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
  unauthorizedSystemAccess(
      'Unauthorized System Access', CrimeCategory.dataPrivacy),
  corporateEspionage('Corporate Espionage', CrimeCategory.dataPrivacy),
  governmentDataTheft('Government Data Theft', CrimeCategory.dataPrivacy),
  medicalRecordsTheft('Medical Records Theft', CrimeCategory.dataPrivacy),
  personalInformationTheft(
      'Personal Information Theft', CrimeCategory.dataPrivacy),
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
  onlinePredatoryBehavior(
      'Online Predatory Behavior', CrimeCategory.harassmentExploitation),
  doxxing('Doxxing', CrimeCategory.harassmentExploitation),
  hateSpeech('Hate Speech', CrimeCategory.harassmentExploitation),

  // 🚫 CONTENT-RELATED CRIMES - Special Investigation Team
  childSexualAbuseMaterial(
      'Child Sexual Abuse Material', CrimeCategory.contentRelated),
  illegalContentDistribution(
      'Illegal Content Distribution', CrimeCategory.contentRelated),
  copyrightInfringement('Copyright Infringement', CrimeCategory.contentRelated),
  softwarePiracy('Software Piracy', CrimeCategory.contentRelated),
  illegalOnlineGambling(
      'Illegal Online Gambling', CrimeCategory.contentRelated),
  onlineDrugTrafficking(
      'Online Drug Trafficking', CrimeCategory.contentRelated),
  illegalWeaponsSales('Illegal Weapons Sales', CrimeCategory.contentRelated),
  humanTrafficking('Human Trafficking', CrimeCategory.contentRelated),

  // ⚡ SYSTEM DISRUPTION & SABOTAGE - Critical Infrastructure Protection Unit
  denialOfServiceAttacks(
      'Denial of Service Attacks', CrimeCategory.systemDisruption),
  websiteDefacement('Website Defacement', CrimeCategory.systemDisruption),
  systemSabotage('System Sabotage', CrimeCategory.systemDisruption),
  networkIntrusion('Network Intrusion', CrimeCategory.systemDisruption),
  sqlInjection('SQL Injection', CrimeCategory.systemDisruption),
  crossSiteScripting('Cross-Site Scripting', CrimeCategory.systemDisruption),
  manInTheMiddleAttacks(
      'Man-in-the-Middle Attacks', CrimeCategory.systemDisruption),

  // 🏛️ GOVERNMENT & TERRORISM - National Security Cyber Division
  cyberterrorism('Cyberterrorism', CrimeCategory.governmentTerrorism),
  cyberWarfare('Cyber Warfare', CrimeCategory.governmentTerrorism),
  governmentSystemHacking(
      'Government System Hacking', CrimeCategory.governmentTerrorism),
  electionInterference(
      'Election Interference', CrimeCategory.governmentTerrorism),
  criticalInfrastructureAttacks(
      'Critical Infrastructure Attacks', CrimeCategory.governmentTerrorism),
  propagandaDistribution(
      'Propaganda Distribution', CrimeCategory.governmentTerrorism),
  stateSponsoredAttacks(
      'State-Sponsored Attacks', CrimeCategory.governmentTerrorism),

  // 🔍 TECHNICAL EXPLOITATION - Advanced Cyber Forensics Unit
  zeroDayExploits('Zero-Day Exploits', CrimeCategory.technicalExploitation),
  vulnerabilityExploitation(
      'Vulnerability Exploitation', CrimeCategory.technicalExploitation),
  backdoorCreation('Backdoor Creation', CrimeCategory.technicalExploitation),
  privilegeEscalation(
      'Privilege Escalation', CrimeCategory.technicalExploitation),
  codeInjection('Code Injection', CrimeCategory.technicalExploitation),
  bufferOverflowAttacks(
      'Buffer Overflow Attacks', CrimeCategory.technicalExploitation),

  // 🎯 TARGETED ATTACKS - Special Cyber Operations Unit
  advancedPersistentThreats(
      'Advanced Persistent Threats', CrimeCategory.targetedAttacks),
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

  // Integration with dynamic field system
  List<String> get applicableFieldCategories {
    return [categoryName];
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
  underInvestigation('Under Investigation',
      'PNP officers are actively investigating your complaint'),
  resolved('Resolved', 'Your complaint has been resolved'),
  dismissed('Dismissed', 'Your complaint has been dismissed'),
  requiresMoreInfo('Requires More Information',
      'Additional information is needed to proceed');

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

  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType);
  bool get isVideo =>
      ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'].contains(fileType);
  bool get isDocument =>
      ['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileType);
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

  // AI Assessment Fields
  final String? aiPriority; // AI-recommended priority
  final int? aiRiskScore; // AI-calculated risk score (0-100)
  final int? aiConfidenceScore; // AI confidence in assessment (0-100%)
  final List<String> riskFactors; // AI-identified risk factors
  final List<String> urgencyIndicators; // AI-detected urgency signals
  final DateTime? lastAiAssessment; // Timestamp of last AI evaluation
  final String? aiReasoning; // AI explanation/reasoning
  final AIRiskAssessment? aiAssessment; // Full AI assessment object

  // Dynamic fields from database
  final String? platformWebsite;
  final String? accountReference;
  final String? suspectName;
  final String? suspectRelationship;
  final String? suspectContact;
  final String? suspectDetails;
  final String? systemDetails;
  final String? technicalInfo;
  final String? vulnerabilityDetails;
  final String? attackVector;
  final String? securityLevel;
  final String? targetInfo;
  final String? impactAssessment;
  final String? contentDescription;

  // Complaint Editing Fields
  final DateTime? lastCitizenUpdate;
  final String? updateRequestMessage;
  final int totalUpdates;

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
    // AI Assessment Fields
    this.aiPriority,
    this.aiRiskScore,
    this.aiConfidenceScore,
    this.riskFactors = const [],
    this.urgencyIndicators = const [],
    this.lastAiAssessment,
    this.aiReasoning,
    this.aiAssessment,
    // Dynamic fields
    this.platformWebsite,
    this.accountReference,
    this.suspectName,
    this.suspectRelationship,
    this.suspectContact,
    this.suspectDetails,
    this.systemDetails,
    this.technicalInfo,
    this.vulnerabilityDetails,
    this.attackVector,
    this.securityLevel,
    this.targetInfo,
    this.impactAssessment,
    this.contentDescription,
    // Complaint Editing Fields
    this.lastCitizenUpdate,
    this.updateRequestMessage,
    this.totalUpdates = 0,
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
      // AI Assessment Fields
      'aiPriority': aiPriority,
      'aiRiskScore': aiRiskScore,
      'aiConfidenceScore': aiConfidenceScore,
      'riskFactors': riskFactors,
      'urgencyIndicators': urgencyIndicators,
      'lastAiAssessment': lastAiAssessment?.toIso8601String(),
      'aiReasoning': aiReasoning,
      // Dynamic fields
      'platformWebsite': platformWebsite,
      'accountReference': accountReference,
      'suspectName': suspectName,
      'suspectRelationship': suspectRelationship,
      'suspectContact': suspectContact,
      'suspectDetails': suspectDetails,
      'systemDetails': systemDetails,
      'technicalInfo': technicalInfo,
      'vulnerabilityDetails': vulnerabilityDetails,
      'attackVector': attackVector,
      'securityLevel': securityLevel,
      'targetInfo': targetInfo,
      'impactAssessment': impactAssessment,
      'contentDescription': contentDescription,
    };
  }

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'],
      userId: json['userId'],
      crimeType:
          CrimeType.values.firstWhere((e) => e.name == json['crimeType']),
      title: json['title'],
      description: json['description'],
      evidenceFiles: (json['evidenceFiles'] as List<dynamic>?)
              ?.map((file) => EvidenceFile.fromJson(file))
              .toList() ??
          [],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      incidentDateTime: DateTime.parse(json['incidentDateTime']),
      incidentLocation: json['incidentLocation'],
      estimatedFinancialLoss: json['estimatedFinancialLoss']?.toDouble(),
      status:
          ComplaintStatus.values.firstWhere((e) => e.name == json['status']),
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
              .toList() ??
          [],
      // AI Assessment Fields
      aiPriority: json['aiPriority'],
      aiRiskScore: json['aiRiskScore'],
      aiConfidenceScore: json['aiConfidenceScore'],
      riskFactors: List<String>.from(json['riskFactors'] ?? []),
      urgencyIndicators: List<String>.from(json['urgencyIndicators'] ?? []),
      lastAiAssessment: json['lastAiAssessment'] != null
          ? DateTime.parse(json['lastAiAssessment'])
          : null,
      aiReasoning: json['aiReasoning'],
      // Dynamic fields
      platformWebsite: json['platformWebsite'],
      accountReference: json['accountReference'],
      suspectName: json['suspectName'],
      suspectRelationship: json['suspectRelationship'],
      suspectContact: json['suspectContact'],
      suspectDetails: json['suspectDetails'],
      systemDetails: json['systemDetails'],
      technicalInfo: json['technicalInfo'],
      vulnerabilityDetails: json['vulnerabilityDetails'],
      attackVector: json['attackVector'],
      securityLevel: json['securityLevel'],
      targetInfo: json['targetInfo'],
      impactAssessment: json['impactAssessment'],
      contentDescription: json['contentDescription'],
      // Complaint Editing Fields
      lastCitizenUpdate: json['lastCitizenUpdate'] != null
          ? DateTime.parse(json['lastCitizenUpdate'])
          : null,
      updateRequestMessage: json['updateRequestMessage'],
      totalUpdates: json['totalUpdates'] ?? 0,
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
    // AI Assessment Fields
    String? aiPriority,
    int? aiRiskScore,
    int? aiConfidenceScore,
    List<String>? riskFactors,
    List<String>? urgencyIndicators,
    DateTime? lastAiAssessment,
    String? aiReasoning,
    AIRiskAssessment? aiAssessment,
    // Dynamic fields
    String? platformWebsite,
    String? accountReference,
    String? suspectName,
    String? suspectRelationship,
    String? suspectContact,
    String? suspectDetails,
    String? systemDetails,
    String? technicalInfo,
    String? vulnerabilityDetails,
    String? attackVector,
    String? securityLevel,
    String? targetInfo,
    String? impactAssessment,
    String? contentDescription,
    // Complaint Editing Fields
    DateTime? lastCitizenUpdate,
    String? updateRequestMessage,
    int? totalUpdates,
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
      estimatedFinancialLoss:
          estimatedFinancialLoss ?? this.estimatedFinancialLoss,
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
      // AI Assessment Fields
      aiPriority: aiPriority ?? this.aiPriority,
      aiRiskScore: aiRiskScore ?? this.aiRiskScore,
      aiConfidenceScore: aiConfidenceScore ?? this.aiConfidenceScore,
      riskFactors: riskFactors ?? this.riskFactors,
      urgencyIndicators: urgencyIndicators ?? this.urgencyIndicators,
      lastAiAssessment: lastAiAssessment ?? this.lastAiAssessment,
      aiReasoning: aiReasoning ?? this.aiReasoning,
      aiAssessment: aiAssessment ?? this.aiAssessment,
      // Dynamic fields
      platformWebsite: platformWebsite ?? this.platformWebsite,
      accountReference: accountReference ?? this.accountReference,
      suspectName: suspectName ?? this.suspectName,
      suspectRelationship: suspectRelationship ?? this.suspectRelationship,
      suspectContact: suspectContact ?? this.suspectContact,
      suspectDetails: suspectDetails ?? this.suspectDetails,
      systemDetails: systemDetails ?? this.systemDetails,
      technicalInfo: technicalInfo ?? this.technicalInfo,
      vulnerabilityDetails: vulnerabilityDetails ?? this.vulnerabilityDetails,
      attackVector: attackVector ?? this.attackVector,
      securityLevel: securityLevel ?? this.securityLevel,
      targetInfo: targetInfo ?? this.targetInfo,
      impactAssessment: impactAssessment ?? this.impactAssessment,
      contentDescription: contentDescription ?? this.contentDescription,
      // Complaint Editing Fields
      lastCitizenUpdate: lastCitizenUpdate ?? this.lastCitizenUpdate,
      updateRequestMessage: updateRequestMessage ?? this.updateRequestMessage,
      totalUpdates: totalUpdates ?? this.totalUpdates,
    );
  }

  bool get hasContactInfo =>
      fullName != null || email != null || phoneNumber != null;
  bool get hasEvidence => evidenceFiles.isNotEmpty;

  String get statusDisplay => status.displayName;
  String get crimeTypeDisplay => crimeType.displayName;

  Duration get timeSinceCreated => DateTime.now().difference(createdAt);
  Duration get timeSinceUpdated => DateTime.now().difference(updatedAt);

  // AI Assessment Helper Methods
  bool get hasAIAssessment => aiRiskScore != null && aiPriority != null;

  String get effectivePriority => aiPriority ?? priority;
  int get effectiveRiskScore => aiRiskScore ?? riskScore;

  // Complaint Editing Helper Methods
  bool get hasBeenUpdatedByCitizen => lastCitizenUpdate != null;
  bool get requiresMoreInfoAndUpdated => status == ComplaintStatus.requiresMoreInfo && hasBeenUpdatedByCitizen;
  
  String get updateStatusText {
    if (!hasBeenUpdatedByCitizen) return '';
    if (totalUpdates == 1) return '1 update';
    return '$totalUpdates updates';
  }
  
  String get timeSinceLastUpdate {
    if (lastCitizenUpdate == null) return '';
    final difference = DateTime.now().difference(lastCitizenUpdate!);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get prioritySource => aiPriority != null ? 'AI' : 'Rule-based';
  String get riskScoreSource => aiRiskScore != null ? 'AI' : 'Rule-based';

  Color get effectivePriorityColor {
    switch (effectivePriority.toLowerCase()) {
      case 'critical':
        return const Color(0xFF991B1B); // Red-800
      case 'high':
        return const Color(0xFFDC2626); // Red-600
      case 'medium':
        return const Color(0xFFF59E0B); // Amber-500
      case 'low':
        return const Color(0xFF10B981); // Emerald-500
      default:
        return const Color(0xFF6B7280); // Gray-500
    }
  }

  Color get effectiveRiskScoreColor {
    final score = effectiveRiskScore;
    if (score >= 80) return const Color(0xFFDC2626); // Red
    if (score >= 60) return const Color(0xFFF59E0B); // Amber
    if (score >= 40) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFF10B981); // Green
  }

  String get aiConfidenceLevel {
    if (aiConfidenceScore == null) return 'N/A';
    final confidence = aiConfidenceScore!;
    if (confidence >= 90) return 'Very High';
    if (confidence >= 80) return 'High';
    if (confidence >= 70) return 'Good';
    if (confidence >= 60) return 'Moderate';
    return 'Low';
  }

  String get formattedRiskFactors {
    if (riskFactors.isEmpty) return 'None identified';
    return riskFactors.map((factor) {
      return factor
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }).join(', ');
  }

  String get formattedUrgencyIndicators {
    if (urgencyIndicators.isEmpty) return 'None identified';
    return urgencyIndicators.map((indicator) {
      return indicator
          .replaceAll('_', ' ')
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }).join(', ');
  }

  bool get needsAIReassessment {
    if (lastAiAssessment == null) return true;
    final daysSinceAssessment =
        DateTime.now().difference(lastAiAssessment!).inDays;
    return daysSinceAssessment > 7; // Reassess if older than 7 days
  }

  /// Create updated complaint with AI assessment
  Complaint withAIAssessment(AIRiskAssessment assessment) {
    return copyWith(
      aiPriority: assessment.aiPriority,
      aiRiskScore: assessment.aiRiskScore,
      aiConfidenceScore: assessment.confidenceScore,
      riskFactors: assessment.riskFactors,
      urgencyIndicators: assessment.urgencyIndicators,
      lastAiAssessment: assessment.assessedAt,
      aiReasoning: assessment.reasoning,
      aiAssessment: assessment,
    );
  }
}

/// Evidence Guidance Item for AI-powered evidence suggestions
class EvidenceGuidanceItem {
  final String title;
  final String description;
  final String icon;
  final String priority;
  final List<String> examples;

  EvidenceGuidanceItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
    required this.examples,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'priority': priority,
      'examples': examples,
    };
  }

  factory EvidenceGuidanceItem.fromJson(Map<String, dynamic> json) {
    return EvidenceGuidanceItem(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '📋',
      priority: json['priority'] ?? 'medium',
      examples: List<String>.from(json['examples'] ?? []),
    );
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626); // Red
      case 'high':
        return const Color(0xFFEA580C); // Orange
      case 'medium':
        return const Color(0xFFCA8A04); // Yellow
      case 'low':
        return const Color(0xFF16A34A); // Green
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

/// Credibility Score for AI-powered report assessment
class CredibilityScore {
  final int overallScore;
  final List<CredibilityFactor> factors;
  final List<String> suggestions;
  final String strengthLevel;

  CredibilityScore({
    required this.overallScore,
    required this.factors,
    required this.suggestions,
    required this.strengthLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'factors': factors.map((f) => f.toJson()).toList(),
      'suggestions': suggestions,
      'strengthLevel': strengthLevel,
    };
  }

  factory CredibilityScore.fromJson(Map<String, dynamic> json) {
    return CredibilityScore(
      overallScore: json['overallScore'] ?? 50,
      factors: (json['factors'] as List<dynamic>?)
              ?.map((f) => CredibilityFactor.fromJson(f))
              .toList() ??
          [],
      suggestions: List<String>.from(json['suggestions'] ?? []),
      strengthLevel: json['strengthLevel'] ?? 'Moderate',
    );
  }

  Color get scoreColor {
    if (overallScore >= 80) return const Color(0xFF10B981); // Green
    if (overallScore >= 60) return const Color(0xFFF59E0B); // Amber
    if (overallScore >= 40) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFFDC2626); // Red
  }

  String get scoreDescription {
    if (overallScore >= 80) return 'Excellent';
    if (overallScore >= 60) return 'Good';
    if (overallScore >= 40) return 'Fair';
    return 'Needs Improvement';
  }

  IconData get scoreIcon {
    if (overallScore >= 80) return Icons.check_circle;
    if (overallScore >= 60) return Icons.thumb_up;
    if (overallScore >= 40) return Icons.info;
    return Icons.warning;
  }
}

/// Individual credibility factor assessment
class CredibilityFactor {
  final String name;
  final double score; // 0.0 to 1.0
  final String description;
  final List<String> suggestions;

  CredibilityFactor({
    required this.name,
    required this.score,
    required this.description,
    required this.suggestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'description': description,
      'suggestions': suggestions,
    };
  }

  factory CredibilityFactor.fromJson(Map<String, dynamic> json) {
    return CredibilityFactor(
      name: json['name'] ?? '',
      score: (json['score'] ?? 0.5).toDouble(),
      description: json['description'] ?? '',
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }

  int get scorePercentage => (score * 100).round();

  Color get scoreColor {
    if (score >= 0.8) return const Color(0xFF10B981); // Green
    if (score >= 0.6) return const Color(0xFFF59E0B); // Amber
    if (score >= 0.4) return const Color(0xFF3B82F6); // Blue
    return const Color(0xFFDC2626); // Red
  }

  Color get factorColor => scoreColor;

  int get percentage => scorePercentage;

  IconData get icon {
    switch (name.toLowerCase()) {
      case 'information completeness':
      case 'basic information':
        return Icons.assignment;
      case 'evidence quality':
      case 'evidence strength':
        return Icons.folder;
      case 'report consistency':
      case 'consistency':
        return Icons.check_circle_outline;
      case 'urgency indicators':
      case 'urgency':
        return Icons.priority_high;
      case 'suspect information':
      case 'suspect details':
        return Icons.person;
      case 'timeline accuracy':
      case 'timeline':
        return Icons.schedule;
      case 'financial impact':
      case 'financial':
        return Icons.attach_money;
      default:
        return Icons.assessment;
    }
  }

  String get iconString {
    switch (name.toLowerCase()) {
      case 'information completeness':
      case 'basic information':
        return '📋';
      case 'evidence quality':
      case 'evidence strength':
        return '📁';
      case 'report consistency':
      case 'consistency':
        return '✅';
      case 'urgency indicators':
      case 'urgency':
        return '⚠️';
      case 'suspect information':
      case 'suspect details':
        return '👤';
      case 'timeline accuracy':
      case 'timeline':
        return '⏰';
      case 'financial impact':
      case 'financial':
        return '💰';
      default:
        return '📊';
    }
  }
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
      status:
          ComplaintStatus.values.firstWhere((e) => e.name == json['status']),
      timestamp: DateTime.parse(json['timestamp']),
      updatedBy: json['updatedBy'],
      remarks: json['remarks'],
    );
  }
}
