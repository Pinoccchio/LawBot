// Dynamic field configuration for complaint forms based on crime categories
enum ComplaintField {
  // Core fields (always visible)
  crimeType,
  officer,
  description,
  incidentDateTime,
  fullName,
  email,
  phone,
  evidenceFiles,
  
  // Dynamic fields (category-specific)
  incidentLocation,
  platformWebsite,
  accountReference,
  financialLoss,
  suspectName,
  suspectRelationship,
  suspectContact,
  suspectDetails,
  
  // Category-specific new fields
  systemDetails,
  technicalInfo,
  vulnerabilityDetails,
  securityLevel,
  targetInfo,
  attackVector,
  contentDescription,
  impactAssessment,
}

class FieldConfiguration {
  final ComplaintField field;
  final String label;
  final String? hint;
  final String? description;
  final bool isRequired;
  final List<String> applicableCategories;

  const FieldConfiguration({
    required this.field,
    required this.label,
    this.hint,
    this.description,
    this.isRequired = false,
    required this.applicableCategories,
  });
}

class DynamicFieldConfig {
  // Define field configurations for each dynamic field
  static const Map<ComplaintField, FieldConfiguration> fieldConfigs = {
    // Location - relevant for most physical crime scenes
    ComplaintField.incidentLocation: FieldConfiguration(
      field: ComplaintField.incidentLocation,
      label: 'Incident Location',
      hint: 'Where did this incident occur?',
      description: 'Helps route your case to the correct regional PNP unit',
      applicableCategories: [
        'Communication & Social Media Crimes',
        'Financial & Economic Crimes',  
        'Data & Privacy Crimes',
        'Harassment & Exploitation',
        'Content-Related Crimes',
        'Government & Terrorism',
      ],
    ),

    // Platform/Website - digital crimes involving online platforms
    ComplaintField.platformWebsite: FieldConfiguration(
      field: ComplaintField.platformWebsite,
      label: 'Platform/Website Involved',
      hint: 'Facebook, Instagram, GCash, etc.',
      description: 'Digital platform where the crime occurred',
      applicableCategories: [
        'Communication & Social Media Crimes',
        'Financial & Economic Crimes',
        'Harassment & Exploitation', 
        'Content-Related Crimes',
      ],
    ),

    // Account/Reference Numbers - for trackable transactions
    ComplaintField.accountReference: FieldConfiguration(
      field: ComplaintField.accountReference,
      label: 'Account/Reference Number',
      hint: 'Transaction ID, account number, reference code',
      description: 'Helps investigators trace transactions and accounts',
      applicableCategories: [
        'Financial & Economic Crimes',
        'Data & Privacy Crimes',
        'Communication & Social Media Crimes',
      ],
    ),

    // Financial Loss - critical for economic crimes
    ComplaintField.financialLoss: FieldConfiguration(
      field: ComplaintField.financialLoss,
      label: 'Financial Loss Amount (₱)',
      hint: '0.00',
      description: 'Used to prioritize high-value cases',
      applicableCategories: [
        'Financial & Economic Crimes',
        'Communication & Social Media Crimes', // Scams
        'Content-Related Crimes', // Illegal sales
      ],
    ),

    // Suspect Name - personal crimes with known suspects
    ComplaintField.suspectName: FieldConfiguration(
      field: ComplaintField.suspectName,
      label: 'Suspect Name/Alias',
      hint: 'Real name, nickname, or username',
      description: 'Any identifying information about the suspect',
      applicableCategories: [
        'Harassment & Exploitation',
        'Communication & Social Media Crimes',
        'Financial & Economic Crimes',
        'Content-Related Crimes',
      ],
    ),

    // Suspect Relationship - important for harassment cases
    ComplaintField.suspectRelationship: FieldConfiguration(
      field: ComplaintField.suspectRelationship,
      label: 'Relationship to Suspect',
      description: 'Helps determine investigation approach',
      applicableCategories: [
        'Harassment & Exploitation',
        'Communication & Social Media Crimes',
        'Content-Related Crimes',
      ],
    ),

    // Suspect Contact - for tracing suspects
    ComplaintField.suspectContact: FieldConfiguration(
      field: ComplaintField.suspectContact,
      label: 'Suspect Contact Information',
      hint: 'Phone, email, social media handle',
      description: 'Any contact information for the suspect',
      applicableCategories: [
        'Harassment & Exploitation',
        'Communication & Social Media Crimes',
        'Financial & Economic Crimes',
        'Content-Related Crimes',
      ],
    ),

    // Suspect Details - additional suspect information
    ComplaintField.suspectDetails: FieldConfiguration(
      field: ComplaintField.suspectDetails,
      label: 'Additional Suspect Details',
      hint: 'Physical description, location, other details',
      description: 'Any other relevant information about the suspect',
      applicableCategories: [
        'Harassment & Exploitation',
        'Communication & Social Media Crimes',
        'Content-Related Crimes',
      ],
    ),

    // System Details - technical crimes
    ComplaintField.systemDetails: FieldConfiguration(
      field: ComplaintField.systemDetails,
      label: 'System/Device Details',
      hint: 'Operating system, device type, software affected',
      description: 'Technical details about affected systems',
      applicableCategories: [
        'Malware & System Attacks',
        'System Disruption & Sabotage',
        'Technical Exploitation',
      ],
    ),

    // Technical Info - detailed technical information
    ComplaintField.technicalInfo: FieldConfiguration(
      field: ComplaintField.technicalInfo,
      label: 'Technical Information',
      hint: 'Error messages, file names, network details',
      description: 'Technical details that may help investigation',
      applicableCategories: [
        'Malware & System Attacks',
        'System Disruption & Sabotage',
        'Technical Exploitation',
        'Data & Privacy Crimes',
      ],
    ),

    // Vulnerability Details - exploitation crimes
    ComplaintField.vulnerabilityDetails: FieldConfiguration(
      field: ComplaintField.vulnerabilityDetails,
      label: 'Vulnerability Details',
      hint: 'How the system was compromised',
      description: 'Information about security weaknesses exploited',
      applicableCategories: [
        'Technical Exploitation',
        'Data & Privacy Crimes',
        'System Disruption & Sabotage',
      ],
    ),

    // Security Level - government/sensitive crimes
    ComplaintField.securityLevel: FieldConfiguration(
      field: ComplaintField.securityLevel,
      label: 'Security Classification',
      hint: 'Public, Confidential, Restricted, etc.',
      description: 'Security level of affected systems or data',
      applicableCategories: [
        'Government & Terrorism',
        'Data & Privacy Crimes',
      ],
    ),

    // Target Information - targeted attacks
    ComplaintField.targetInfo: FieldConfiguration(
      field: ComplaintField.targetInfo,
      label: 'Target Information',
      hint: 'Who or what was targeted',
      description: 'Details about the target of the attack',
      applicableCategories: [
        'Targeted Attacks',
        'Government & Terrorism',
        'Technical Exploitation',
      ],
    ),

    // Attack Vector - how the attack was carried out
    ComplaintField.attackVector: FieldConfiguration(
      field: ComplaintField.attackVector,
      label: 'Attack Method/Vector',
      hint: 'How the attack was executed',
      description: 'The method used to carry out the attack',
      applicableCategories: [
        'Targeted Attacks',
        'Technical Exploitation',
        'System Disruption & Sabotage',
        'Malware & System Attacks',
      ],
    ),

    // Content Description - content-related crimes
    ComplaintField.contentDescription: FieldConfiguration(
      field: ComplaintField.contentDescription,
      label: 'Content Description',
      hint: 'Description of illegal content (no explicit details)',
      description: 'General description of the prohibited content',
      applicableCategories: [
        'Content-Related Crimes',
        'Harassment & Exploitation',
      ],
    ),

    // Impact Assessment - severity of the crime
    ComplaintField.impactAssessment: FieldConfiguration(
      field: ComplaintField.impactAssessment,
      label: 'Impact Assessment',
      hint: 'How has this affected you or your organization?',
      description: 'The impact and consequences of the incident',
      applicableCategories: [
        'Data & Privacy Crimes',
        'System Disruption & Sabotage',
        'Government & Terrorism',
        'Technical Exploitation',
        'Targeted Attacks',
      ],
    ),
  };

  // Get fields for a specific crime category
  static List<ComplaintField> getFieldsForCategory(String category) {
    final List<ComplaintField> categoryFields = [];
    
    // Always include core fields
    categoryFields.addAll([
      ComplaintField.crimeType,
      ComplaintField.officer,
      ComplaintField.description,
      ComplaintField.incidentDateTime,
      ComplaintField.fullName,
      ComplaintField.email,
      ComplaintField.phone,
      ComplaintField.evidenceFiles,
    ]);

    // Add category-specific fields
    for (final entry in fieldConfigs.entries) {
      if (entry.value.applicableCategories.contains(category)) {
        categoryFields.add(entry.key);
      }
    }

    return categoryFields;
  }

  // Get configuration for a specific field
  static FieldConfiguration? getFieldConfig(ComplaintField field) {
    return fieldConfigs[field];
  }

  // Check if a field should be visible for a category
  static bool isFieldVisible(ComplaintField field, String category) {
    // Core fields are always visible
    if (_coreFields.contains(field)) return true;
    
    // Check if dynamic field applies to this category
    final config = fieldConfigs[field];
    return config?.applicableCategories.contains(category) ?? false;
  }

  // Core fields that are always visible
  static const List<ComplaintField> _coreFields = [
    ComplaintField.crimeType,
    ComplaintField.officer,
    ComplaintField.description,
    ComplaintField.incidentDateTime,
    ComplaintField.fullName,
    ComplaintField.email,
    ComplaintField.phone,
    ComplaintField.evidenceFiles,
  ];

  // Get all available categories
  static List<String> getAllCategories() {
    return [
      'Communication & Social Media Crimes',
      'Financial & Economic Crimes',
      'Data & Privacy Crimes',
      'Malware & System Attacks',
      'Harassment & Exploitation',
      'Content-Related Crimes',
      'System Disruption & Sabotage',
      'Government & Terrorism',
      'Technical Exploitation',
      'Targeted Attacks',
    ];
  }
}