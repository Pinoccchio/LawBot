import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/database_complaint_model.dart';
import '../services/pnp_units_service.dart';
import '../providers/theme_provider.dart';
import '../utils/philippine_time.dart';
import '../services/database_service.dart';
import '../models/dynamic_field_config.dart';
import '../services/dynamic_field_service.dart';
import '../services/evidence_guidance_service.dart';
import '../services/credibility_scorer_service.dart';
import '../services/pattern_detection_service.dart';
import '../services/ai_risk_assessment_service.dart';
import '../models/complaint_model.dart' as ComplaintModels;
import '../models/complaint_model.dart' show EvidenceGuidanceItem, CredibilityScore;
import 'dart:async';

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController(); 
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _incidentLocationController = TextEditingController();
  final _platformWebsiteController = TextEditingController();
  final _accountReferenceController = TextEditingController();
  final _financialLossController = TextEditingController();
  final _suspectNameController = TextEditingController();
  final _suspectContactController = TextEditingController();
  final _suspectDetailsController = TextEditingController();
  
  // Additional dynamic field controllers
  final _systemDetailsController = TextEditingController();
  final _technicalInfoController = TextEditingController();
  final _vulnerabilityDetailsController = TextEditingController();
  final _securityLevelController = TextEditingController();
  final _targetInfoController = TextEditingController();
  final _attackVectorController = TextEditingController();
  final _contentDescriptionController = TextEditingController();
  final _impactAssessmentController = TextEditingController();
  final _databaseService = DatabaseService();
  final _pnpUnitsService = PNPUnitsService();

  // Dynamic crime types from database
  List<DatabaseCrimeType> _availableCrimeTypes = [];
  DatabaseCrimeType? _selectedCrimeType;
  DatabaseCrimeType? _previousCrimeType;
  PNPOfficer? _selectedOfficer;
  
  final List<EvidenceFile> _evidenceFiles = [];
  bool _isSubmitting = false;
  bool _isLoadingCrimeTypes = true;
  DateTime? _selectedIncidentDateTime;
  String? _crimeTypesError;
  String _selectedSuspectRelationship = 'Unknown';
  
  // New features state
  CredibilityScore? _currentCredibilityScore;
  PatternAlert? _currentPatternAlert;
  List<EvidenceGuidanceItem> _evidenceGuidance = [];
  bool _showCredibilityMeter = false;
  bool _showEvidenceGuidance = false;
  
  // AI Assessment state
  AIRiskAssessment? _currentAIAssessment;
  bool _isPerformingAIAssessment = false;
  Timer? _aiAssessmentTimer;
  String _lastAssessmentInput = '';
  bool _showAIInsights = false;
  
  // Debounce timers for heavy AI operations
  Timer? _credibilityDebounceTimer;
  Timer? _evidenceGuidanceDebounceTimer;
  Timer? _patternDetectionDebounceTimer;
  
  // AI Loading states
  bool _isLoadingCredibilityScore = false;
  bool _isLoadingEvidenceGuidance = false;
  bool _isLoadingPatternCheck = false;
  
  // Suspect relationship options
  final List<String> _suspectRelationshipOptions = [
    'Unknown',
    'Acquaintance',
    'Friend/Ex-friend',
    'Family Member',
    'Ex-partner/Romantic',
    'Colleague/Classmate',
    'Online Contact Only',
    'Complete Stranger',
  ];

  @override
  void initState() {
    super.initState();
    
    // AI services will initialize automatically when first used
    
    // Add listeners for real-time credibility score updates
    _descriptionController.addListener(_updateCredibilityScore);
    _fullNameController.addListener(_updateCredibilityScore);
    _emailController.addListener(_updateCredibilityScore);
    _phoneController.addListener(_updateCredibilityScore);
    _platformWebsiteController.addListener(_updateCredibilityScore);
    _financialLossController.addListener(_updateCredibilityScore);
    
    // Add missing controller listeners for comprehensive AI updates
    _incidentLocationController.addListener(_updateCredibilityScore);
    _accountReferenceController.addListener(_updateCredibilityScore);
    _suspectNameController.addListener(_updateCredibilityScore);
    _suspectDetailsController.addListener(_updateCredibilityScore);
    
    // Pattern detection listeners
    _suspectContactController.addListener(_checkForPatterns);
    _suspectNameController.addListener(_checkForPatterns);
    
    // Add listeners for real-time AI assessment
    _descriptionController.addListener(_triggerAIAssessment);
    _financialLossController.addListener(_triggerAIAssessment);
    
    // Load user profile data and crime types
    _loadUserProfile();
    _loadCrimeTypes();
  }

  @override
  void dispose() {
    // Cancel all AI timers
    _aiAssessmentTimer?.cancel();
    _credibilityDebounceTimer?.cancel();
    _evidenceGuidanceDebounceTimer?.cancel();
    _patternDetectionDebounceTimer?.cancel();
    
    _descriptionController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _incidentLocationController.dispose();
    _platformWebsiteController.dispose();
    _accountReferenceController.dispose();
    _financialLossController.dispose();
    _suspectNameController.dispose();
    _suspectContactController.dispose();
    _suspectDetailsController.dispose();
    _systemDetailsController.dispose();
    _technicalInfoController.dispose();
    _vulnerabilityDetailsController.dispose();
    _securityLevelController.dispose();
    _targetInfoController.dispose();
    _attackVectorController.dispose();
    _contentDescriptionController.dispose();
    _impactAssessmentController.dispose();
    super.dispose();
  }

  // Load crime types from database
  Future<void> _loadCrimeTypes() async {
    print('🔄 Loading crime types for complaint form...');
    setState(() {
      _isLoadingCrimeTypes = true;
      _crimeTypesError = null;
    });

    try {
      print('📡 Calling PNP Units Service...');
      final crimeTypesWithUnits = await _pnpUnitsService.getCrimeTypesWithUnits();
      
      print('📊 Received ${crimeTypesWithUnits.length} crime types from service');
      
      if (crimeTypesWithUnits.isEmpty) {
        print('❌ No crime types found - checking database directly...');
        
        // Debug: Check if there are any units in the database at all
        final allUnits = await _pnpUnitsService.getAllUnits();
        print('🔍 Total units in database: ${allUnits.length}');
        
        for (var unit in allUnits) {
          print('  - Unit: ${unit.unitName} (${unit.status}) - Crime types: ${unit.crimeTypes.length}');
        }
        
        setState(() {
          _crimeTypesError = 'No crime types available. Found ${allUnits.length} units in database. Please contact administrator.';
          _isLoadingCrimeTypes = false;
        });
        return;
      }

      final dynamicCrimeTypes = crimeTypesWithUnits
          .map((ctw) => DatabaseCrimeType.fromCrimeTypeWithUnit(ctw))
          .toList();

      // Sort by category and then by name
      dynamicCrimeTypes.sort((a, b) {
        final categoryComparison = a.category.compareTo(b.category);
        if (categoryComparison != 0) return categoryComparison;
        return a.name.compareTo(b.name);
      });

      print('✅ Successfully loaded ${dynamicCrimeTypes.length} crime types');
      
      // Debug: Print first few crime types
      for (int i = 0; i < (dynamicCrimeTypes.length > 5 ? 5 : dynamicCrimeTypes.length); i++) {
        final ct = dynamicCrimeTypes[i];
        print('  - ${ct.name} → ${ct.assignedUnitName} (${ct.availableOfficers.length} officers)');
      }

      setState(() {
        _availableCrimeTypes = dynamicCrimeTypes;
        _isLoadingCrimeTypes = false;
      });
    } catch (e) {
      print('❌ Error loading crime types: $e');
      setState(() {
        _crimeTypesError = 'Failed to load crime types: $e';
        _isLoadingCrimeTypes = false;
      });
    }
  }

  // Load user profile data and pre-fill form
  Future<void> _loadUserProfile() async {
    print('👤 Loading user profile for complaint form...');
    try {
      final userProfile = await _databaseService.getUserProfile();
      
      if (userProfile != null) {
        print('✅ User profile loaded successfully');
        
        // Pre-fill form fields with user data
        setState(() {
          _fullNameController.text = userProfile['full_name'] ?? '';
          _emailController.text = userProfile['email'] ?? '';
          _phoneController.text = userProfile['phone_number'] ?? '';
        });
        
        print('📝 Form pre-filled with user data: ${userProfile['full_name']}, ${userProfile['email']}, ${userProfile['phone_number']}');
      } else {
        print('⚠️ No user profile found');
      }
    } catch (e) {
      print('❌ Error loading user profile: $e');
      // Don't show error to user, just continue with empty form
    }
  }

  // Update evidence guidance using AI
  void _updateEvidenceGuidance(ComplaintModels.CrimeType crimeType) async {
    setState(() {
      _isLoadingEvidenceGuidance = true;
    });
    
    try {
      print('🔍 [ComplaintForm] Getting AI evidence guidance for ${crimeType.displayName}');
      final evidenceItems = await EvidenceGuidanceService.getEvidenceGuidance(
        crimeType, 
        description: _descriptionController.text,
      );
      
      if (mounted) {
        setState(() {
          _evidenceGuidance = evidenceItems;
          _isLoadingEvidenceGuidance = false;
        });
        print('✅ [ComplaintForm] Updated evidence guidance with ${evidenceItems.length} items');
      }
    } catch (e) {
      print('❌ [ComplaintForm] Error getting evidence guidance: $e');
      // Fallback to deprecated sync method
      if (mounted) {
        setState(() {
          _evidenceGuidance = EvidenceGuidanceService.getEvidenceGuidanceSync(crimeType);
          _isLoadingEvidenceGuidance = false;
        });
      }
    }
  }

  // Update credibility score based on current form data using AI (debounced)
  void _updateCredibilityScore() {
    // Cancel previous timer
    _credibilityDebounceTimer?.cancel();
    
    // Set up debounced timer (1.5 seconds for credibility score)
    _credibilityDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _performCredibilityScoreUpdate();
    });
  }

  void _performCredibilityScoreUpdate() async {
    if (_selectedCrimeType != null && mounted) {
      setState(() {
        _isLoadingCredibilityScore = true;
      });
      
      try {
        print('🔍 [ComplaintForm] Getting AI credibility score for ${_selectedCrimeType!.name}');
        final formData = _getFormData();
        final crimeType = ComplaintModels.CrimeType.values.firstWhere(
          (ct) => ct.displayName == _selectedCrimeType!.name,
          orElse: () => ComplaintModels.CrimeType.phishing,
        );
        
        final credibilityScore = await CredibilityScorer.calculateCredibilityScore(formData, crimeType);
        
        if (mounted) {
          setState(() {
            _currentCredibilityScore = credibilityScore;
            _showCredibilityMeter = true;
            _isLoadingCredibilityScore = false;
          });
          print('✅ [ComplaintForm] Updated credibility score: ${credibilityScore.overallScore}%');
        }
      } catch (e) {
        print('❌ [ComplaintForm] Error getting credibility score: $e');
        if (mounted) {
          setState(() {
            _isLoadingCredibilityScore = false;
          });
        }
        // Fallback to deprecated sync method
        if (mounted) {
          final formData = _getFormData();
          final crimeType = ComplaintModels.CrimeType.values.firstWhere(
            (ct) => ct.displayName == _selectedCrimeType!.name,
            orElse: () => ComplaintModels.CrimeType.phishing,
          );
          
          setState(() {
            _currentCredibilityScore = CredibilityScorer.calculateCredibilityScoreSync(formData, crimeType);
            _showCredibilityMeter = true;
            _isLoadingCredibilityScore = false;
          });
        }
      }
    }
  }

  // Check for scammer patterns
  void _checkForPatterns() async {
    if (_selectedCrimeType != null && mounted) {
      setState(() {
        _isLoadingPatternCheck = true;
      });
      
      try {
        final formData = _getFormData();
        final patternAlert = await PatternDetectionService.checkForPatterns(formData);
        
        if (mounted) {
          setState(() {
            _currentPatternAlert = patternAlert;
            _isLoadingPatternCheck = false;
          });
          
          if (patternAlert != null) {
            _showPatternAlert(patternAlert);
          }
        }
      } catch (e) {
        print('❌ [ComplaintForm] Error checking patterns: $e');
        if (mounted) {
          setState(() {
            _isLoadingPatternCheck = false;
          });
        }
      }
    }
  }

  // Get current form data for analysis
  Map<String, dynamic> _getFormData() {
    return {
      'fullName': _fullNameController.text,
      'email': _emailController.text,
      'phoneNumber': _phoneController.text,
      'description': _descriptionController.text,
      'incidentDateTime': _selectedIncidentDateTime,
      'estimatedFinancialLoss': double.tryParse(_financialLossController.text),
      'platformWebsite': _platformWebsiteController.text,
      'accountReference': _accountReferenceController.text,
      'suspectName': _suspectNameController.text,
      'suspectContact': _suspectContactController.text,
      'suspectDetails': _suspectDetailsController.text,
      'suspectRelationship': _selectedSuspectRelationship,
      'evidenceFiles': _evidenceFiles,
      'crimeType': _selectedCrimeType?.name,
    };
  }

  // =============================================
  // AI ASSESSMENT METHODS
  // =============================================

  /// Trigger comprehensive AI updates for all assessments
  void _triggerAllAIUpdates() {
    if (_selectedCrimeType == null || !mounted) return;
    
    print('🔄 Triggering comprehensive AI updates for all assessments');
    
    // Update all AI assessments
    _updateCredibilityScore();
    _triggerAIAssessment();
    _checkForPatterns();
    
    // Update evidence guidance if crime type is selected
    if (_selectedCrimeType != null) {
      final mappedCrimeType = ComplaintModels.CrimeType.values.firstWhere(
        (ct) => ct.displayName == _selectedCrimeType!.name,
        orElse: () => ComplaintModels.CrimeType.phishing,
      );
      _updateEvidenceGuidance(mappedCrimeType);
    }
  }

  /// Trigger AI assessment with debouncing
  void _triggerAIAssessment() {
    if (_selectedCrimeType == null || !mounted) return;
    
    final currentInput = '${_descriptionController.text}_${_financialLossController.text}_${_selectedCrimeType!.name}';
    
    // Skip if input hasn't changed significantly
    if (currentInput == _lastAssessmentInput) return;
    
    // Cancel previous timer
    _aiAssessmentTimer?.cancel();
    
    // Set up new debounced timer (2 seconds delay)
    _aiAssessmentTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _selectedCrimeType != null && _descriptionController.text.trim().length > 10) {
        _performQuickAIAssessment();
      }
    });
  }

  /// Perform quick AI assessment for real-time feedback
  void _performQuickAIAssessment() async {
    if (_isPerformingAIAssessment || !mounted) return;
    
    setState(() {
      _isPerformingAIAssessment = true;
    });

    try {
      final crimeType = ComplaintModels.CrimeType.values.firstWhere(
        (ct) => ct.displayName == _selectedCrimeType!.name,
        orElse: () => ComplaintModels.CrimeType.phishing,
      );

      final assessment = await _databaseService.performQuickAssessment(
        _descriptionController.text.trim(),
        crimeType,
        double.tryParse(_financialLossController.text),
      );

      if (assessment != null && mounted) {
        setState(() {
          _currentAIAssessment = assessment;
          _showAIInsights = true;
          _lastAssessmentInput = '${_descriptionController.text}_${_financialLossController.text}_${_selectedCrimeType!.name}';
        });
        
        print('🤖 AI Assessment completed: ${assessment.aiPriority} priority, ${assessment.aiRiskScore}% risk, ${assessment.confidenceScore}% confidence');
      }
    } catch (e) {
      print('⚠️ Quick AI assessment failed: $e');
      // Silently fail for real-time assessment
    } finally {
      if (mounted) {
        setState(() {
          _isPerformingAIAssessment = false;
        });
      }
    }
  }

  /// Toggle AI insights visibility
  void _toggleAIInsights() {
    setState(() {
      _showAIInsights = !_showAIInsights;
    });
  }

  // Show pattern alert dialog
  void _showPatternAlert(PatternAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(alert.severityIcon, color: alert.severityColor, size: 24),
            const SizedBox(width: 8),
            Text(alert.alertTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert.recommendation),
            const SizedBox(height: 16),
            ...alert.matches.map((match) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${match.typeDisplay}: ${match.matchDescription}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I Understand'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Report', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Handle crime type selection and manage dynamic fields
  void _onCrimeTypeSelected(DatabaseCrimeType? crimeType) {
    // Check if we need to update form state due to field changes
    final needsUpdate = DynamicFieldService.requiresFormUpdate(_previousCrimeType, crimeType);
    
    if (needsUpdate) {
      // Clear fields that are no longer visible
      final fieldsToClear = DynamicFieldService.getFieldsToClear(_previousCrimeType, crimeType);
      _clearFieldControllers(fieldsToClear);
    }
    
    setState(() {
      _previousCrimeType = _selectedCrimeType;
      _selectedCrimeType = crimeType;
      _selectedOfficer = null; // Reset officer selection when crime type changes
      
      // Update evidence guidance for new crime type
      if (crimeType != null) {
        final mappedCrimeType = ComplaintModels.CrimeType.values.firstWhere(
          (ct) => ct.displayName == crimeType.name,
          orElse: () => ComplaintModels.CrimeType.phishing,
        );
        _updateEvidenceGuidance(mappedCrimeType);
        _showEvidenceGuidance = true;
        
        // Update credibility score with new crime type
        _updateCredibilityScore();
      } else {
        _evidenceGuidance = [];
        _showEvidenceGuidance = false;
        _currentCredibilityScore = null;
        _showCredibilityMeter = false;
      }
    });
  }
  
  // Clear controllers for fields that are no longer visible
  void _clearFieldControllers(List<ComplaintField> fieldsToClear) {
    for (final field in fieldsToClear) {
      switch (field) {
        case ComplaintField.incidentLocation:
          _incidentLocationController.clear();
          break;
        case ComplaintField.platformWebsite:
          _platformWebsiteController.clear();
          break;
        case ComplaintField.accountReference:
          _accountReferenceController.clear();
          break;
        case ComplaintField.financialLoss:
          _financialLossController.clear();
          break;
        case ComplaintField.suspectName:
          _suspectNameController.clear();
          break;
        case ComplaintField.suspectRelationship:
          _selectedSuspectRelationship = 'Unknown';
          break;
        case ComplaintField.suspectContact:
          _suspectContactController.clear();
          break;
        case ComplaintField.suspectDetails:
          _suspectDetailsController.clear();
          break;
        case ComplaintField.systemDetails:
          _systemDetailsController.clear();
          break;
        case ComplaintField.technicalInfo:
          _technicalInfoController.clear();
          break;
        case ComplaintField.vulnerabilityDetails:
          _vulnerabilityDetailsController.clear();
          break;
        case ComplaintField.securityLevel:
          _securityLevelController.clear();
          break;
        case ComplaintField.targetInfo:
          _targetInfoController.clear();
          break;
        case ComplaintField.attackVector:
          _attackVectorController.clear();
          break;
        case ComplaintField.contentDescription:
          _contentDescriptionController.clear();
          break;
        case ComplaintField.impactAssessment:
          _impactAssessmentController.clear();
          break;
        default:
          break;
      }
    }
  }

  // Handle officer selection
  void _onOfficerSelected(PNPOfficer? officer) {
    setState(() {
      _selectedOfficer = officer;
    });
  }

  // Get color based on officer availability status
  Color _getAvailabilityStatusColor(String? availabilityStatus) {
    switch (availabilityStatus ?? 'available') {
      case 'available':
        return Colors.green;
      case 'busy':
        return Colors.orange;
      case 'overloaded':
        return Colors.red;
      case 'unavailable':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickFiles() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show options for different file types
      final result = await showModalBottomSheet<String>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => _buildFilePickerBottomSheet(),
      );

      if (result == null) return;

      List<XFile>? files = [];
      
      switch (result) {
        case 'camera':
          final XFile? photo = await picker.pickImage(source: ImageSource.camera);
          if (photo != null) files = [photo];
          break;
        case 'gallery':
          files = await picker.pickMultiImage();
          break;
        case 'video':
          final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
          if (video != null) files = [video];
          break;
        case 'documents':
          files = await picker.pickMultiImage();
          break;
      }

      if (files != null && files.isNotEmpty) {
        setState(() {
          for (final file in files!) {
            if (_evidenceFiles.length < 5) {
              final evidenceFile = EvidenceFile.fromFile(File(file.path));
              _evidenceFiles.add(evidenceFile);
            }
          }
        });
        
        // Trigger AI updates when evidence files are added
        print('📎 Evidence files added, triggering AI updates');
        _triggerAllAIUpdates();
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting files: $e');
    }
  }

  Widget _buildFilePickerBottomSheet() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
          Text(
            'Select Evidence Files',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildFileOption(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Capture evidence with camera',
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          _buildFileOption(
            icon: Icons.photo_library,
            title: 'Photo Gallery',
            subtitle: 'Select photos from gallery',
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          _buildFileOption(
            icon: Icons.videocam,
            title: 'Video',
            subtitle: 'Select video evidence',
            onTap: () => Navigator.pop(context, 'video'),
          ),
          _buildFileOption(
            icon: Icons.insert_drive_file,
            title: 'Documents',
            subtitle: 'PDF, DOC, TXT files',
            onTap: () => Navigator.pop(context, 'documents'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF2563EB)),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

  void _removeFile(int index) {
    setState(() {
      _evidenceFiles.removeAt(index);
    });
    // Trigger AI updates when evidence files are removed
    print('🗑️ Evidence file removed, triggering AI updates');
    _triggerAllAIUpdates();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCrimeType == null) {
      _showErrorSnackBar('Please select a crime type');
      return;
    }

    if (_selectedOfficer == null) {
      _showErrorSnackBar('Please select an investigating officer');
      return;
    }

    if (_selectedIncidentDateTime == null) {
      _showErrorSnackBar('Please select the date and time of incident');
      return;
    }

    // Validate required contact information
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Full name is required');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorSnackBar('Email address is required');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showErrorSnackBar('Phone number is required');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🔍 ===== DEBUGGING COMPLAINT SUBMISSION =====');
      
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Please sign in to submit a complaint');
        return;
      }
      
      print('👤 Current User: ${currentUser.uid}');

      // Parse optional financial loss for priority calculation
      double? financialLoss;
      if (_financialLossController.text.trim().isNotEmpty) {
        financialLoss = double.tryParse(_financialLossController.text.trim());
      }
      
      print('📋 ===== FORM DATA DEBUGGING =====');
      print('🏷️ Crime Type: ${_selectedCrimeType?.name} (${_selectedCrimeType?.displayName})');
      print('👮 Selected Officer: ${_selectedOfficer?.fullName} (ID: ${_selectedOfficer?.id})');
      print('🏢 Assigned Unit: ${_selectedCrimeType?.assignedUnit}');
      print('💰 Financial Loss: $financialLoss');
      print('📅 Incident Date: $_selectedIncidentDateTime');
      print('📝 Description Length: ${_descriptionController.text.trim().length}');
      print('📎 Evidence Files: ${_evidenceFiles.length}');
      
      print('📋 ===== DYNAMIC FIELDS DEBUGGING =====');
      print('🌐 Platform Website: "${_platformWebsiteController.text.trim()}"');
      print('📍 Incident Location: "${_incidentLocationController.text.trim()}"');
      print('🔢 Account Reference: "${_accountReferenceController.text.trim()}"');
      print('👤 Suspect Name: "${_suspectNameController.text.trim()}"');
      print('🔗 Suspect Relationship: "$_selectedSuspectRelationship"');
      print('📞 Suspect Contact: "${_suspectContactController.text.trim()}"');
      print('📄 Suspect Details: "${_suspectDetailsController.text.trim()}"');

      // Create dynamic complaint object
      final complaint = DatabaseComplaint.create(
        userId: currentUser.uid,
        crimeType: _selectedCrimeType!,
        description: _descriptionController.text.trim(),
        evidenceFiles: _evidenceFiles,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        incidentDateTime: _selectedIncidentDateTime!,
        incidentLocation: _incidentLocationController.text.trim().isNotEmpty 
            ? _incidentLocationController.text.trim() 
            : null,
        estimatedFinancialLoss: financialLoss,
        assignedOfficer: _selectedOfficer, // 🔧 FIXED: Pass selected officer
      );

      // Submit to database service (need to create this method)
      // Convert DatabaseComplaint to regular Complaint for AI submission
      final regularComplaint = ComplaintModels.Complaint(
        userId: complaint.userId,
        crimeType: ComplaintModels.CrimeType.values.firstWhere(
          (ct) => ct.displayName == complaint.crimeType.name,
          orElse: () => ComplaintModels.CrimeType.phishing,
        ),
        description: complaint.description,
        evidenceFiles: complaint.evidenceFiles.map((dbFile) => ComplaintModels.EvidenceFile(
          id: dbFile.id,
          fileName: dbFile.fileName,
          filePath: dbFile.filePath,
          fileType: dbFile.fileType,
          fileSize: dbFile.fileSize,
          uploadedAt: dbFile.uploadedAt,
          downloadUrl: dbFile.downloadUrl,
        )).toList(),
        fullName: complaint.fullName,
        email: complaint.email,
        phoneNumber: complaint.phoneNumber,
        incidentDateTime: complaint.incidentDateTime,
        incidentLocation: complaint.incidentLocation,
        estimatedFinancialLoss: complaint.estimatedFinancialLoss,
        createdAt: complaint.createdAt,
        updatedAt: complaint.updatedAt,
        suspectName: _suspectNameController.text.trim().isEmpty ? null : _suspectNameController.text.trim(),
        suspectRelationship: _selectedSuspectRelationship != 'Unknown' ? _selectedSuspectRelationship : null,
        suspectContact: _suspectContactController.text.trim().isEmpty ? null : _suspectContactController.text.trim(),
        suspectDetails: _suspectDetailsController.text.trim().isEmpty ? null : _suspectDetailsController.text.trim(),
        // 🔧 FIXED: Add ALL missing dynamic fields for ALL crime types and categories
        platformWebsite: _platformWebsiteController.text.trim().isEmpty ? null : _platformWebsiteController.text.trim(),
        accountReference: _accountReferenceController.text.trim().isEmpty ? null : _accountReferenceController.text.trim(),
        systemDetails: _systemDetailsController.text.trim().isEmpty ? null : _systemDetailsController.text.trim(),
        technicalInfo: _technicalInfoController.text.trim().isEmpty ? null : _technicalInfoController.text.trim(),
        vulnerabilityDetails: _vulnerabilityDetailsController.text.trim().isEmpty ? null : _vulnerabilityDetailsController.text.trim(),
        securityLevel: _securityLevelController.text.trim().isEmpty ? null : _securityLevelController.text.trim(),
        targetInfo: _targetInfoController.text.trim().isEmpty ? null : _targetInfoController.text.trim(),
        attackVector: _attackVectorController.text.trim().isEmpty ? null : _attackVectorController.text.trim(),
        contentDescription: _contentDescriptionController.text.trim().isEmpty ? null : _contentDescriptionController.text.trim(),
        impactAssessment: _impactAssessmentController.text.trim().isEmpty ? null : _impactAssessmentController.text.trim(),
        // 🔧 FIXED: Add officer assignment fields
        assignedOfficer: _selectedOfficer?.fullName,
        assignedOfficerId: _selectedOfficer?.id,
      );

      print('📋 ===== COMPLAINT OBJECT DEBUGGING =====');
      print('📝 Title: ${regularComplaint.title}');
      print('👤 Suspect Name: ${regularComplaint.suspectName}');
      print('🔗 Suspect Relationship: ${regularComplaint.suspectRelationship}');
      print('📞 Suspect Contact: ${regularComplaint.suspectContact}');
      print('📄 Suspect Details: ${regularComplaint.suspectDetails}');
      print('📍 Incident Location: ${regularComplaint.incidentLocation}');
      print('💰 Financial Loss: ${regularComplaint.estimatedFinancialLoss}');
      
      print('📋 ===== ALL DYNAMIC FIELDS DEBUGGING =====');
      print('🌐 Platform Website: ${regularComplaint.platformWebsite}');
      print('🔢 Account Reference: ${regularComplaint.accountReference}');
      print('💻 System Details: ${regularComplaint.systemDetails}');
      print('🔧 Technical Info: ${regularComplaint.technicalInfo}');
      print('🛡️ Vulnerability Details: ${regularComplaint.vulnerabilityDetails}');
      print('🔒 Security Level: ${regularComplaint.securityLevel}');
      print('🎯 Target Info: ${regularComplaint.targetInfo}');
      print('⚔️ Attack Vector: ${regularComplaint.attackVector}');
      print('📄 Content Description: ${regularComplaint.contentDescription}');
      print('📊 Impact Assessment: ${regularComplaint.impactAssessment}');
      
      print('👮 ===== OFFICER ASSIGNMENT =====');
      print('👮 Assigned Officer: ${regularComplaint.assignedOfficer}');
      print('👮 Assigned Officer ID: ${regularComplaint.assignedOfficerId}');
      
      print('🚀 ===== SUBMITTING WITH AI ASSESSMENT =====');
      // Submit with AI assessment
      final complaintId = await _databaseService.submitComplaintWithAI(regularComplaint);
      
      if (complaintId != null) {
        // Show success dialog with complaint ID and assigned officer info
        _showSuccessDialog(complaintId);
      } else {
        _showErrorSnackBar('Failed to submit complaint. Please try again.');
      }
      
    } catch (e) {
      _showErrorSnackBar('Failed to submit complaint: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // Submit dynamic complaint to database
  Future<String?> _submitDatabaseComplaint(DatabaseComplaint complaint) async {
    try {
      // Generate complaint number
      final now = PhilippineTime.now();
      final year = now.year;
      
      // Get the latest complaint number for this year
      final latestResponse = await _pnpUnitsService.supabase
          .from('complaints')
          .select('complaint_number')
          .like('complaint_number', 'CYB-$year-%')
          .order('created_at', ascending: false)
          .limit(1);

      int sequenceNumber = 1;
      if (latestResponse.isNotEmpty) {
        final latestNumber = latestResponse.first['complaint_number'] as String;
        final parts = latestNumber.split('-');
        if (parts.length == 3) {
          sequenceNumber = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      final complaintNumber = 'CYB-$year-${sequenceNumber.toString().padLeft(3, '0')}';

      // Prepare complaint data for database
      final complaintData = {
        'user_id': complaint.userId,
        'complaint_number': complaintNumber,
        'crime_type': complaint.crimeType.name,
        'title': complaint.title,
        'description': complaint.description,
        'full_name': complaint.fullName,
        'email': complaint.email,
        'phone_number': complaint.phoneNumber,
        'incident_date_time': complaint.incidentDateTime.toUtc().toIso8601String(),
        'incident_location': complaint.incidentLocation,
        'estimated_loss': complaint.estimatedFinancialLoss,
        
        // Dynamic fields
        'platform_website': _platformWebsiteController.text.trim().isNotEmpty 
            ? _platformWebsiteController.text.trim() 
            : null,
        'account_reference': _accountReferenceController.text.trim().isNotEmpty 
            ? _accountReferenceController.text.trim() 
            : null,
        'suspect_name': _suspectNameController.text.trim().isNotEmpty 
            ? _suspectNameController.text.trim() 
            : null,
        'suspect_relationship': _selectedSuspectRelationship != 'Unknown' 
            ? _selectedSuspectRelationship 
            : null,
        'suspect_contact': _suspectContactController.text.trim().isNotEmpty 
            ? _suspectContactController.text.trim() 
            : null,
        'suspect_details': _suspectDetailsController.text.trim().isNotEmpty 
            ? _suspectDetailsController.text.trim() 
            : null,
        'system_details': _systemDetailsController.text.trim().isNotEmpty 
            ? _systemDetailsController.text.trim() 
            : null,
        'technical_info': _technicalInfoController.text.trim().isNotEmpty 
            ? _technicalInfoController.text.trim() 
            : null,
        'vulnerability_details': _vulnerabilityDetailsController.text.trim().isNotEmpty 
            ? _vulnerabilityDetailsController.text.trim() 
            : null,
        'attack_vector': _attackVectorController.text.trim().isNotEmpty 
            ? _attackVectorController.text.trim() 
            : null,
        'security_level': _securityLevelController.text.trim().isNotEmpty 
            ? _securityLevelController.text.trim() 
            : null,
        'target_info': _targetInfoController.text.trim().isNotEmpty 
            ? _targetInfoController.text.trim() 
            : null,
        'impact_assessment': _impactAssessmentController.text.trim().isNotEmpty 
            ? _impactAssessmentController.text.trim() 
            : null,
        'content_description': _contentDescriptionController.text.trim().isNotEmpty 
            ? _contentDescriptionController.text.trim() 
            : null,
        
        // Status and priority
        'status': 'Pending',
        'priority': complaint.priority,
        'risk_score': complaint.riskScore,
        
        // Officer and unit assignment (FIXED: Now includes all required fields)
        'assigned_unit': complaint.assignedUnit.unitName,
        'unit_id': complaint.assignedUnit.id,
        'assigned_officer': _selectedOfficer?.fullName,
        'assigned_officer_id': _selectedOfficer?.id,
        
        // Timestamps
        'created_at': PhilippineTime.toUtc(now).toIso8601String(),
        'updated_at': PhilippineTime.toUtc(now).toIso8601String(),
      };

      // Insert complaint
      final response = await _pnpUnitsService.supabase
          .from('complaints')
          .insert(complaintData)
          .select('id')
          .single();

      final complaintId = response['id'] as String;

      // Assign the selected officer (required by complainant)
      await _pnpUnitsService.supabase.from('case_assignments').insert({
        'complaint_id': complaintId,
        'officer_id': _selectedOfficer!.id,
        'assigned_by': 'Complainant',
        'assignment_type': 'primary',
        'status': 'active',
        'notes': 'Officer selected by complainant during report submission',
        'created_at': PhilippineTime.toUtc(now).toIso8601String(),
      });

      // Upload evidence files if any
      if (complaint.evidenceFiles.isNotEmpty) {
        await _uploadEvidenceFiles(complaintId, complaint.evidenceFiles);
      }

      return complaintId;
    } catch (e) {
      print('Error submitting dynamic complaint: $e');
      throw 'Failed to submit complaint: $e';
    }
  }

  // Upload evidence files
  Future<void> _uploadEvidenceFiles(String complaintId, List<EvidenceFile> files) async {
    try {
      for (final evidenceFile in files) {
        final file = File(evidenceFile.filePath);
        final bytes = await file.readAsBytes();
        
        // Create unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${complaintId}_${timestamp}_${evidenceFile.fileName}';
        final filePath = 'evidence/$complaintId/$fileName';

        // Upload to Supabase Storage
        await _pnpUnitsService.supabase.storage
            .from('evidence-files')
            .uploadBinary(filePath, bytes);

        // Get public URL
        final publicUrl = _pnpUnitsService.supabase.storage
            .from('evidence-files')
            .getPublicUrl(filePath);

        // Save evidence file record
        await _pnpUnitsService.supabase.from('evidence_files').insert({
          'complaint_id': complaintId,
          'file_name': evidenceFile.fileName,
          'file_type': evidenceFile.fileType,
          'file_size': evidenceFile.fileSize,
          'file_path': filePath,
          'download_url': publicUrl,
          'uploaded_by': FirebaseAuth.instance.currentUser!.uid,
          'created_at': PhilippineTime.toUtc(PhilippineTime.now()).toIso8601String(),
        });
      }
    } catch (e) {
      print('Error uploading evidence files: $e');
      throw 'Failed to upload evidence files: $e';
    }
  }

  void _showSuccessDialog(String complaintId) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Complaint Submitted',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your cybercrime complaint has been successfully submitted to ${_selectedCrimeType?.assignedUnitName ?? 'PNP Anti-Cybercrime Group'}. Your selected officer will handle the investigation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            if (_selectedOfficer != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Assigned Officer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _selectedOfficer!.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      _selectedOfficer!.workloadDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close dialog
                  Navigator.of(context).pop(); // go back to reports
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back to Reports'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Text(
          'New Complaint',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF2563EB),
        ),
        actions: [
          if (_isLoadingCrimeTypes)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crime Type Section
              _buildSectionCard(
                title: 'Crime Type & Assignment',
                icon: Icons.report_problem,
                children: [
                  if (_isLoadingCrimeTypes)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading crime types from database...'),
                          ],
                        ),
                      ),
                    )
                  else if (_crimeTypesError != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _crimeTypesError!,
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadCrimeTypes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Text(
                      'Crime Type *',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<DatabaseCrimeType>(
                      value: _selectedCrimeType,
                      hint: Text(
                        'Select a cybercrime type',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: isDark 
                            ? const Color(0xFF1E293B) 
                            : Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      isExpanded: true,
                      menuMaxHeight: 300,
                      selectedItemBuilder: (BuildContext context) {
                        // This builder creates the display for the selected item (when dropdown is closed)
                        return _availableCrimeTypes.map((crimeType) {
                          return Container(
                            alignment: Alignment.centerLeft,
                            constraints: const BoxConstraints(maxWidth: 250),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Center(
                                    child: Text(
                                      crimeType.categoryIcon,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    crimeType.displayName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      items: _availableCrimeTypes.map((crimeType) {
                        return DropdownMenuItem(
                          value: crimeType,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2563EB).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          crimeType.categoryIcon,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        crimeType.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: Text(
                                    '${crimeType.assignedUnitName} (${crimeType.assignedUnit.unitCode})',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFF2563EB),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _onCrimeTypeSelected,
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a crime type';
                        }
                        return null;
                      },
                    ),
                    
                    // Show assigned unit info
                    if (_selectedCrimeType != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _selectedCrimeType!.categoryIcon, 
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Will be assigned to:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue[600],
                                        ),
                                      ),
                                      Text(
                                        _selectedCrimeType!.assignedUnitName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.blue[700],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      Text(
                                        'Unit Code: ${_selectedCrimeType!.assignedUnit.unitCode}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blue[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            Text(
                              'Select Investigating Officer *',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose your preferred investigating officer from the assigned unit',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Officer Selection Dropdown
                            if (_selectedCrimeType!.availableOfficers.isNotEmpty) ...[
                              DropdownButtonFormField<PNPOfficer>(
                                value: _selectedOfficer,
                                hint: Text(
                                  'Choose an officer (${_selectedCrimeType!.availableOfficers.length} available)',
                                  style: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: isDark 
                                      ? const Color(0xFF1E293B) 
                                      : Colors.grey[50],
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 14,
                                ),
                                isExpanded: true,
                                menuMaxHeight: 250,
                                items: _selectedCrimeType!.availableOfficers.map((officer) {
                                  Color workloadColor = _getAvailabilityStatusColor(officer.availabilityStatus);
                                  
                                  return DropdownMenuItem(
                                    value: officer,
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2563EB).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(
                                            Icons.person,
                                            color: const Color(0xFF2563EB),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                officer.displayName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: isDark ? Colors.white : Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: workloadColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      officer.workloadDescription,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: workloadColor,
                                                        fontWeight: FontWeight.w500,
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
                                  );
                                }).toList(),
                                onChanged: _onOfficerSelected,
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select an investigating officer';
                                  }
                                  return null;
                                },
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.red[700], size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'No officers available for this crime type. Please try again later or contact support.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.red[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Show selected officer info
                            if (_selectedOfficer != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.check, color: Colors.green, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Selected Officer: ${_selectedOfficer!.displayName}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green[700],
                                            ),
                                          ),
                                          Text(
                                            _selectedOfficer!.workloadDescription,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Evidence Guidance Section (Smart Evidence Guidance Feature)
              if (_showEvidenceGuidance && (_evidenceGuidance.isNotEmpty || _isLoadingEvidenceGuidance))
                _buildEvidenceGuidanceCard(),
              
              if (_showEvidenceGuidance && (_evidenceGuidance.isNotEmpty || _isLoadingEvidenceGuidance))
                const SizedBox(height: 24),
              
              // Description Section
              _buildSectionCard(
                title: 'Incident Details',
                icon: Icons.description,
                children: [
                  Text(
                    'Description of Incident *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Provide a detailed description of the incident...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? const Color(0xFF1E293B) 
                          : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please provide a description of the incident';
                      }
                      if (value.trim().length < 20) {
                        return 'Please provide a more detailed description (at least 20 characters)';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Date and Time of Incident
                  Text(
                    'Date and Time of Incident *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDateTimePicker(isDark),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Dynamic Fields Section - fields change based on selected crime type
              ..._buildDynamicSections(isDark),
              
              const SizedBox(height: 24),
              
              // Digital Evidence Section
              _buildSectionCard(
                title: 'Digital Evidence',
                icon: Icons.attach_file,
                children: [
                  if (_evidenceFiles.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isDark 
                            ? const Color(0xFF1E293B).withOpacity(0.5)
                            : Colors.grey[50],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No files selected',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _pickFiles,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Accepted formats: images, videos, documents (max 5 files, 25MB total)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Show uploaded files
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _evidenceFiles.length,
                      itemBuilder: (context, index) {
                        final file = _evidenceFiles[index];
                        return _buildFileCard(file, index);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_evidenceFiles.length < 5)
                      OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add),
                        label: const Text('Add More Files'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          foregroundColor: const Color(0xFF2563EB),
                        ),
                      ),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Contact Information Section
              _buildSectionCard(
                title: 'Contact Information *',
                icon: Icons.contact_phone,
                children: [
                  // Full Name
                  TextFormField(
                    controller: _fullNameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Full Name *',
                      hintText: 'e.g., Juan Dela Cruz',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? const Color(0xFF1E293B) 
                          : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().split(' ').length < 2) {
                        return 'Please enter your first and last name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Email Address *',
                      hintText: 'e.g., juan.delacruz@example.com',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? const Color(0xFF1E293B) 
                          : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Phone Number *',
                      hintText: 'e.g., +63 9XX XXX XXXX',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark 
                          ? const Color(0xFF1E293B) 
                          : Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your phone number';
                      }
                      // Basic Philippines phone number validation
                      if (!RegExp(r'^(\+63|0)?[9]\d{9}$').hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
                        return 'Please enter a valid Philippine phone number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // AI Risk Assessment Section
              if (_showAIInsights && (_currentAIAssessment != null || _isPerformingAIAssessment))
                _buildAIInsightsCard(),
              
              if (_showAIInsights && (_currentAIAssessment != null || _isPerformingAIAssessment))
                const SizedBox(height: 24),
              
              // Credibility Meter Section (Report Credibility Meter Feature)
              if (_showCredibilityMeter && (_currentCredibilityScore != null || _isLoadingCredibilityScore))
                _buildCredibilityMeterCard(),
              
              if (_showCredibilityMeter && (_currentCredibilityScore != null || _isLoadingCredibilityScore))
                const SizedBox(height: 24),
              
              // Submit Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2563EB),
                      const Color(0xFF3B82F6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: (_isSubmitting || _isLoadingCrimeTypes) ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Submitting Complaint...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Submit Complaint',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Privacy notice
              Center(
                child: Text(
                  'Your information will be handled confidentially according to PNP data privacy policies',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build dynamic field widget based on field type and configuration
  Widget? _buildDynamicField(ComplaintField field, bool isDark) {
    // Check if field should be visible for current crime type
    if (!DynamicFieldService.isFieldVisible(field, _selectedCrimeType)) {
      return null;
    }

    final config = DynamicFieldService.getFieldConfig(field);
    final label = DynamicFieldService.getFieldLabel(field);
    final hint = DynamicFieldService.getFieldHint(field);
    final description = DynamicFieldService.getFieldDescription(field);

    // Return appropriate widget based on field type
    switch (field) {
      case ComplaintField.incidentLocation:
        return _buildTextFormField(
          controller: _incidentLocationController,
          label: label,
          hint: hint ?? 'Where did this occur? (e.g., Manila, Online platform, etc.)',
          icon: Icons.location_on_outlined,
          isDark: isDark,
          description: description,
        );
      case ComplaintField.platformWebsite:
        return _buildTextFormField(
          controller: _platformWebsiteController,
          label: label,
          hint: hint ?? 'Platform or website involved (e.g., Facebook, GCash, etc.)',
          icon: Icons.language_outlined,
          isDark: isDark,
          description: description,
        );
      case ComplaintField.accountReference:
        return _buildTextFormField(
          controller: _accountReferenceController,
          label: label,
          hint: hint ?? 'Account, transaction, or reference number (if any)',
          icon: Icons.numbers_outlined,
          isDark: isDark,
          description: description,
        );
      case ComplaintField.financialLoss:
        return _buildFinancialLossField(isDark, description);
      case ComplaintField.suspectName:
        return _buildTextFormField(
          controller: _suspectNameController,
          label: label,
          hint: hint ?? 'Real name, nickname, or username',
          icon: Icons.person_outline,
          isDark: isDark,
          description: description,
        );
      case ComplaintField.suspectRelationship:
        return _buildSuspectRelationshipField(isDark, description);
      case ComplaintField.suspectContact:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextFormField(
              controller: _suspectContactController,
              label: label,
              hint: hint ?? 'Phone, email, social media handle',
              icon: Icons.contact_phone_outlined,
              isDark: isDark,
              description: description,
            ),
            if (_isLoadingPatternCheck)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🔍 Checking for similar scammer patterns...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case ComplaintField.suspectDetails:
        return _buildTextAreaField(
          controller: _suspectDetailsController,
          label: label,
          hint: hint ?? 'Physical description, location, other details',
          icon: Icons.description_outlined,
          isDark: isDark,
          description: description,
          maxLines: 3,
        );
      case ComplaintField.systemDetails:
        return _buildTextAreaField(
          controller: _systemDetailsController,
          label: label,
          hint: hint ?? 'Operating system, device type, software affected',
          icon: Icons.computer_outlined,
          isDark: isDark,
          description: description,
          maxLines: 3,
        );
      case ComplaintField.technicalInfo:
        return _buildTextAreaField(
          controller: _technicalInfoController,
          label: label,
          hint: hint ?? 'Error messages, file names, network details',
          icon: Icons.code_outlined,
          isDark: isDark,
          description: description,
          maxLines: 4,
        );
      case ComplaintField.vulnerabilityDetails:
        return _buildTextAreaField(
          controller: _vulnerabilityDetailsController,
          label: label,
          hint: hint ?? 'How the system was compromised',
          icon: Icons.shield_outlined,
          isDark: isDark,
          description: description,
          maxLines: 3,
        );
      case ComplaintField.securityLevel:
        return _buildTextFormField(
          controller: _securityLevelController,
          label: label,
          hint: hint ?? 'Public, Confidential, Restricted, etc.',
          icon: Icons.security_outlined,
          isDark: isDark,
          description: description,
        );
      case ComplaintField.targetInfo:
        return _buildTextAreaField(
          controller: _targetInfoController,
          label: label,
          hint: hint ?? 'Who or what was targeted',
          icon: Icons.gps_fixed_outlined,
          isDark: isDark,
          description: description,
          maxLines: 3,
        );
      case ComplaintField.attackVector:
        return _buildTextAreaField(
          controller: _attackVectorController,
          label: label,
          hint: hint ?? 'How the attack was executed',
          icon: Icons.track_changes_outlined,
          isDark: isDark,
          description: description,
          maxLines: 3,
        );
      case ComplaintField.contentDescription:
        return _buildTextAreaField(
          controller: _contentDescriptionController,
          label: label,
          hint: hint ?? 'Description of illegal content (no explicit details)',
          icon: Icons.report_outlined,
          isDark: isDark,
          description: description,
          maxLines: 3,
        );
      case ComplaintField.impactAssessment:
        return _buildTextAreaField(
          controller: _impactAssessmentController,
          label: label,
          hint: hint ?? 'How has this affected you or your organization?',
          icon: Icons.assessment_outlined,
          isDark: isDark,
          description: description,
          maxLines: 4,
        );
      default:
        return null;
    }
  }

  // Build standard text form field
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    required bool isDark,
    String? description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.grey[50],
            prefixIcon: icon != null ? Icon(
              icon,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ) : null,
          ),
        ),
      ],
    );
  }

  // Build text area field (multiline)
  Widget _buildTextAreaField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    required bool isDark,
    String? description,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.grey[50],
            prefixIcon: icon != null ? Icon(
              icon,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ) : null,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  // Build financial loss field with currency formatting
  Widget _buildFinancialLossField(bool isDark, String? description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _financialLossController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            labelText: 'Financial Loss Amount (₱)',
            hintText: '0.00',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.grey[50],
            prefixIcon: Icon(
              Icons.attach_money_outlined,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            prefixText: '₱ ',
            prefixStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // Build suspect relationship dropdown field
  Widget _buildSuspectRelationshipField(bool isDark, String? description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
        ],
        DropdownButtonFormField<String>(
          value: _selectedSuspectRelationship,
          decoration: InputDecoration(
            labelText: 'Relationship to Suspect',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: isDark 
                ? const Color(0xFF1E293B) 
                : Colors.grey[50],
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          items: _suspectRelationshipOptions.map((relationship) {
            return DropdownMenuItem<String>(
              value: relationship,
              child: Text(relationship),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedSuspectRelationship = newValue;
              });
              // Trigger AI updates when suspect relationship changes
              print('👥 Suspect relationship updated, triggering AI updates');
              _triggerAllAIUpdates();  
            }
          },
        ),
      ],
    );
  }

  // Build dynamic sections based on selected crime type
  List<Widget> _buildDynamicSections(bool isDark) {
    if (_selectedCrimeType == null) {
      // Show instruction when no crime type is selected
      return [
        _buildSectionCard(
          title: 'Select Crime Type First',
          icon: Icons.info_outline,
          children: [
            Text(
              'Please select a crime type above to see relevant fields for your report.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ];
    }

    // Get visible fields for selected crime type
    final visibleFields = DynamicFieldService.getVisibleFields(_selectedCrimeType);
    final dynamicFields = visibleFields.where((field) => !_isCoreField(field)).toList();
    
    if (dynamicFields.isEmpty) {
      return [];
    }

    // Group fields by category for better organization
    final Map<String, List<ComplaintField>> fieldGroups = _groupFieldsByCategory(dynamicFields);
    final List<Widget> sections = [];

    for (final entry in fieldGroups.entries) {
      final groupName = entry.key;
      final groupFields = entry.value;
      
      final List<Widget> fieldWidgets = [];
      
      for (int i = 0; i < groupFields.length; i++) {
        final field = groupFields[i];
        final fieldWidget = _buildDynamicField(field, isDark);
        
        if (fieldWidget != null) {
          fieldWidgets.add(fieldWidget);
          if (i < groupFields.length - 1) {
            fieldWidgets.add(const SizedBox(height: 16));
          }
        }
      }

      if (fieldWidgets.isNotEmpty) {
        sections.add(
          _buildSectionCard(
            title: groupName,
            icon: _getGroupIcon(groupName),
            children: [
              if (groupName != 'General Information') ...[
                Text(
                  _getGroupDescription(groupName, _selectedCrimeType!.categoryForFields),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ...fieldWidgets,
            ],
          ),
        );
      }
    }

    return sections;
  }

  // Check if a field is a core field (always visible)
  bool _isCoreField(ComplaintField field) {
    switch (field) {
      case ComplaintField.crimeType:
      case ComplaintField.officer:
      case ComplaintField.description:
      case ComplaintField.incidentDateTime:
      case ComplaintField.fullName:
      case ComplaintField.email:
      case ComplaintField.phone:
      case ComplaintField.evidenceFiles:
        return true;
      default:
        return false;
    }
  }

  // Group fields by logical categories for UI organization
  Map<String, List<ComplaintField>> _groupFieldsByCategory(List<ComplaintField> fields) {
    final Map<String, List<ComplaintField>> groups = {};

    for (final field in fields) {
      String groupName;
      
      switch (field) {
        case ComplaintField.incidentLocation:
        case ComplaintField.platformWebsite:
        case ComplaintField.accountReference:
        case ComplaintField.financialLoss:
          groupName = 'General Information';
          break;
        case ComplaintField.suspectName:
        case ComplaintField.suspectRelationship:
        case ComplaintField.suspectContact:
        case ComplaintField.suspectDetails:
          groupName = 'Suspect Information';
          break;
        case ComplaintField.systemDetails:
        case ComplaintField.technicalInfo:
        case ComplaintField.vulnerabilityDetails:
        case ComplaintField.attackVector:
          groupName = 'Technical Details';
          break;
        case ComplaintField.securityLevel:
        case ComplaintField.targetInfo:
        case ComplaintField.impactAssessment:
          groupName = 'Security & Impact Assessment';
          break;
        case ComplaintField.contentDescription:
          groupName = 'Content Information';
          break;
        default:
          groupName = 'Additional Details';
          break;
      }

      groups.putIfAbsent(groupName, () => []);
      groups[groupName]!.add(field);
    }

    return groups;
  }

  // Get icon for field group
  IconData _getGroupIcon(String groupName) {
    switch (groupName) {
      case 'General Information':
        return Icons.info_outline;
      case 'Suspect Information':
        return Icons.person_search_outlined;
      case 'Technical Details':
        return Icons.computer_outlined;
      case 'Security & Impact Assessment':
        return Icons.security_outlined;
      case 'Content Information':
        return Icons.report_outlined;
      default:
        return Icons.more_horiz_outlined;
    }
  }

  // Get description for field group
  String _getGroupDescription(String groupName, String crimeCategory) {
    switch (groupName) {
      case 'Suspect Information':
        return 'Information about the person or entity responsible for this crime';
      case 'Technical Details':
        return 'Technical information that will help investigators understand how the attack was carried out';
      case 'Security & Impact Assessment':
        return 'Security classification and impact details for proper case prioritization';
      case 'Content Information':
        return 'Description of illegal content (provide general details only, no explicit descriptions)';
      default:
        return 'Additional details specific to ${crimeCategory.toLowerCase()} to help with the investigation';
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFileCard(EvidenceFile file, int index) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF374151) 
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: _getFileTypeColor(file.fileType),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${file.fileExtension} • ${file.fileSizeFormatted}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeFile(index),
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFileTypeIcon(String fileType) {
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType)) {
      return Icons.image;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'].contains(fileType)) {
      return Icons.videocam;
    } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileType)) {
      return Icons.description;
    }
    return Icons.attach_file;
  }

  Color _getFileTypeColor(String fileType) {
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(fileType)) {
      return Colors.green;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv'].contains(fileType)) {
      return Colors.purple;
    } else if (['pdf', 'doc', 'docx', 'txt', 'rtf'].contains(fileType)) {
      return Colors.red;
    }
    return Colors.blue;
  }

  /// Date and Time Picker Widget
  Widget _buildDateTimePicker(bool isDark) {
    return InkWell(
      onTap: () async {
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedIncidentDateTime ?? DateTime.now().subtract(const Duration(days: 1)),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(primary: const Color(0xFF3B82F6))
                    : ColorScheme.light(primary: const Color(0xFF2563EB)),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.fromDateTime(_selectedIncidentDateTime ?? DateTime.now()),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: isDark
                      ? ColorScheme.dark(primary: const Color(0xFF3B82F6))
                      : ColorScheme.light(primary: const Color(0xFF2563EB)),
                ),
                child: child!,
              );
            },
          );

          if (pickedTime != null) {
            setState(() {
              _selectedIncidentDateTime = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );
            });
            // Trigger AI updates when date/time is selected
            print('📅 Incident date/time updated, triggering AI updates');
            _triggerAllAIUpdates();
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedIncidentDateTime != null
                    ? '${PhilippineTime.formatChatHistoryTime(_selectedIncidentDateTime!.toIso8601String())}'
                    : 'Select date and time of incident',
                style: TextStyle(
                  color: _selectedIncidentDateTime != null
                      ? (isDark ? Colors.white : Colors.black)
                      : (isDark ? Colors.grey[400] : Colors.grey[600]),
                  fontSize: 16,
                ),
              ),
            ),
            if (_selectedIncidentDateTime == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build Evidence Guidance Card (Smart Evidence Guidance Feature)
  Widget _buildEvidenceGuidanceCard() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return _buildSectionCard(
      title: '💡 Smart Evidence Guidance',
      icon: Icons.lightbulb,
      children: [
        // Loading indicator
        if (_isLoadingEvidenceGuidance)
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🤖 AI is analyzing your case type to provide smart evidence recommendations...',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFF2563EB),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Based on your selected crime type "${_selectedCrimeType?.name}", here are the recommended evidence types that will strengthen your report:',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
          const SizedBox(height: 16),
          ...(_evidenceGuidance.map((guidance) => _buildEvidenceGuidanceItem(guidance, isDark)).toList()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tip: Mas maraming evidence files, mas mataas ang credibility score ng report mo!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvidenceGuidanceItem(EvidenceGuidanceItem guidance, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: guidance.priorityColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                guidance.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  guidance.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: guidance.priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  guidance.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: guidance.priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            guidance.description,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          if (guidance.examples.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Examples:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            ...guidance.examples.map((example) => Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 12,
                      color: guidance.priorityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  // Build Credibility Meter Card (Report Credibility Meter Feature)
  Widget _buildCredibilityMeterCard() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return _buildSectionCard(
      title: '📊 Report Credibility Score',
      icon: Icons.analytics,
      children: [
        // Loading indicator
        if (_isLoadingCredibilityScore)
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🤖 AI is analyzing the credibility and completeness of your report...',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else if (_currentCredibilityScore != null) ...[
          // Display the credibility score
          _buildCredibilityScoreContent(_currentCredibilityScore!, isDark),
        ],
      ],
    );
  }

  // Build the actual credibility score content
  Widget _buildCredibilityScoreContent(CredibilityScore score, bool isDark) {
    return Column(
      children: [
        // Overall Score Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                score.scoreColor.withOpacity(0.1),
                score.scoreColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: score.scoreColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    score.scoreIcon,
                    color: score.scoreColor,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${score.overallScore}%',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: score.scoreColor,
                        ),
                      ),
                      Text(
                        score.strengthLevel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: score.scoreColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                score.scoreDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Individual Factors
        Text(
          'Score Breakdown:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        
        ...score.factors.map((factor) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    factor.iconString,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      factor.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    '${factor.percentage}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: factor.factorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: factor.score,
                backgroundColor: (isDark ? Colors.grey[600] : Colors.grey[300]),
                valueColor: AlwaysStoppedAnimation<Color>(factor.factorColor),
              ),
              const SizedBox(height: 8),
              Text(
                factor.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        )).toList(),
        
        // Improvement Suggestions
        if (score.suggestions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Suggestions to Improve Your Report:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...score.suggestions.map((suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_right,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Build AI Risk Assessment Insights Card
  Widget _buildAIInsightsCard() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return _buildSectionCard(
      title: '🤖 AI Risk Assessment',
      icon: Icons.psychology,
      children: [
        // Loading indicator
        if (_isPerformingAIAssessment)
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '🤖 AI is performing intelligent risk assessment and priority analysis...',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        
        // Assessment Results
        else if (_currentAIAssessment != null) ...[
          _buildAIAssessmentContent(_currentAIAssessment!, isDark),
        ],
      ],
    );
  }

  // Build AI Assessment Content
  Widget _buildAIAssessmentContent(AIRiskAssessment assessment, bool isDark) {
    return Column(
      children: [
        // Priority and Risk Score Display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                assessment.priorityColor.withOpacity(0.1),
                assessment.riskScoreColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: assessment.priorityColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Priority Section
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.priority_high,
                      color: assessment.priorityColor,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessment.aiPriority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: assessment.priorityColor,
                      ),
                    ),
                    Text(
                      'Priority',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: 1,
                height: 50,
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
              
              // Risk Score Section
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: assessment.riskScoreColor,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${assessment.aiRiskScore}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: assessment.riskScoreColor,
                      ),
                    ),
                    Text(
                      'Risk Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              Container(
                width: 1,
                height: 50,
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
              
              // Confidence Section
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      Icons.verified,
                      color: assessment.confidenceScore >= 80 
                          ? Colors.green 
                          : assessment.confidenceScore >= 60 
                              ? Colors.orange 
                              : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${assessment.confidenceScore}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: assessment.confidenceScore >= 80 
                            ? Colors.green 
                            : assessment.confidenceScore >= 60 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                    Text(
                      'Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // AI Reasoning
        if (assessment.reasoning.isNotEmpty) ...[
          Text(
            'AI Analysis:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              assessment.reasoning,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Risk Factors
        if (assessment.riskFactors.isNotEmpty) ...[
          Text(
            'Risk Factors:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assessment.riskFactors.map((factor) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    factor.replaceAll('_', ' ').split(' ')
                        .map((word) => word[0].toUpperCase() + word.substring(1))
                        .join(' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // Urgency Indicators
        if (assessment.urgencyIndicators.isNotEmpty) ...[
          Text(
            'Urgency Indicators:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: assessment.urgencyIndicators.map((indicator) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    indicator.replaceAll('_', ' ').split(' ')
                        .map((word) => word[0].toUpperCase() + word.substring(1))
                        .join(' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }
}