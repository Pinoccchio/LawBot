import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/complaint_model.dart';
import '../models/dynamic_field_config.dart';
import '../services/complaint_service.dart';
import '../services/credibility_scorer_service.dart';
import '../services/evidence_guidance_service.dart';
import '../services/database_service.dart';
import '../providers/theme_provider.dart';

class EditComplaintScreen extends StatefulWidget {
  final Complaint complaint;

  const EditComplaintScreen({Key? key, required this.complaint}) : super(key: key);

  @override
  _EditComplaintScreenState createState() => _EditComplaintScreenState();
}

class _EditComplaintScreenState extends State<EditComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final ComplaintService _complaintService = ComplaintService();
  
  // Constants
  static const int maxEvidenceFiles = 5;
  
  bool _isLoading = false;
  late Map<String, dynamic> _formData;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _originalValues = {};
  final Set<String> _modifiedFields = {};
  
  // Dynamic fields based on crime type
  List<ComplaintField> _visibleFields = [];
  List<ComplaintField> _dynamicFields = [];
  
  List<EvidenceGuidanceItem> _evidenceSuggestions = [];
  double _credibilityScore = 0.0;
  List<String> _improvementSuggestions = [];
  
  final List<XFile> _newEvidenceFiles = [];
  final List<EvidenceFile> _existingEvidenceFiles = [];
  
  // Status History
  List<Map<String, dynamic>> _statusHistory = [];
  bool _isLoadingStatusHistory = true;

  @override
  void initState() {
    super.initState();
    
    // Get visible fields for this crime type's category
    _visibleFields = DynamicFieldConfig.getFieldsForCategory(widget.complaint.crimeType.categoryName);
    
    // Separate dynamic fields from core fields
    _dynamicFields = _visibleFields.where((field) => !_isCoreField(field)).toList();
    
    _initializeForm();
    _loadStatusHistory();
  }

  void _initializeForm() {
    // Initialize form data only for visible fields
    _formData = {};
    
    // Always include these core editable fields
    _formData['description'] = widget.complaint.description;
    
    // Add dynamic fields based on what's visible for this crime type
    for (final field in _dynamicFields) {
      final value = _getFieldValue(field);
      final key = _getFieldKey(field);
      if (key != null) {
        _formData[key] = value ?? '';
      }
    }
    
    // Store original values for comparison
    _originalValues.addAll(_formData);
    
    // Create controllers for text fields
    _formData.forEach((key, value) {
      _controllers[key] = TextEditingController(text: value.toString());
      _controllers[key]!.addListener(() => _onFieldChanged(key));
    });
    
    // Copy existing evidence files
    _existingEvidenceFiles.addAll(widget.complaint.evidenceFiles);
    
    // Get initial evidence suggestions
    _getEvidenceSuggestions();
    
    // Calculate initial credibility score
    _calculateCredibilityScore();
  }
  
  // Get field value from complaint
  String? _getFieldValue(ComplaintField field) {
    switch (field) {
      case ComplaintField.incidentLocation:
        return widget.complaint.incidentLocation;
      case ComplaintField.financialLoss:
        return widget.complaint.estimatedFinancialLoss?.toString();
      case ComplaintField.platformWebsite:
        return widget.complaint.platformWebsite;
      case ComplaintField.accountReference:
        return widget.complaint.accountReference;
      case ComplaintField.suspectName:
        return widget.complaint.suspectName;
      case ComplaintField.suspectRelationship:
        return widget.complaint.suspectRelationship;
      case ComplaintField.suspectContact:
        return widget.complaint.suspectContact;
      case ComplaintField.suspectDetails:
        return widget.complaint.suspectDetails;
      case ComplaintField.systemDetails:
        return widget.complaint.systemDetails;
      case ComplaintField.technicalInfo:
        return widget.complaint.technicalInfo;
      case ComplaintField.vulnerabilityDetails:
        return widget.complaint.vulnerabilityDetails;
      case ComplaintField.attackVector:
        return widget.complaint.attackVector;
      case ComplaintField.securityLevel:
        return widget.complaint.securityLevel;
      case ComplaintField.targetInfo:
        return widget.complaint.targetInfo;
      case ComplaintField.impactAssessment:
        return widget.complaint.impactAssessment;
      case ComplaintField.contentDescription:
        return widget.complaint.contentDescription;
      default:
        return null;
    }
  }
  
  // Get field key for form data
  String? _getFieldKey(ComplaintField field) {
    switch (field) {
      case ComplaintField.incidentLocation:
        return 'incident_location';
      case ComplaintField.financialLoss:
        return 'estimated_loss';
      case ComplaintField.platformWebsite:
        return 'platform_website';
      case ComplaintField.accountReference:
        return 'account_reference';
      case ComplaintField.suspectName:
        return 'suspect_name';
      case ComplaintField.suspectRelationship:
        return 'suspect_relationship';
      case ComplaintField.suspectContact:
        return 'suspect_contact';
      case ComplaintField.suspectDetails:
        return 'suspect_details';
      case ComplaintField.systemDetails:
        return 'system_details';
      case ComplaintField.technicalInfo:
        return 'technical_info';
      case ComplaintField.vulnerabilityDetails:
        return 'vulnerability_details';
      case ComplaintField.attackVector:
        return 'attack_vector';
      case ComplaintField.securityLevel:
        return 'security_level';
      case ComplaintField.targetInfo:
        return 'target_info';
      case ComplaintField.impactAssessment:
        return 'impact_assessment';
      case ComplaintField.contentDescription:
        return 'content_description';
      default:
        return null;
    }
  }
  
  bool _isCoreField(ComplaintField field) {
    return [
      ComplaintField.crimeType,
      ComplaintField.officer,
      ComplaintField.description,
      ComplaintField.incidentDateTime,
      ComplaintField.fullName,
      ComplaintField.email,
      ComplaintField.phone,
      ComplaintField.evidenceFiles,
    ].contains(field);
  }

  void _onFieldChanged(String fieldName) {
    // Skip field change processing for suspect_relationship dropdown
    // as it handles its own value updates
    if (fieldName == 'suspect_relationship' || fieldName == 'suspectRelationship') {
      // Recalculate credibility score when fields change
      _calculateCredibilityScore();
      return;
    }
    
    final currentValue = (_controllers[fieldName]?.text ?? '').trim();
    final originalValue = (_originalValues[fieldName]?.toString() ?? '').trim();
    
    if (currentValue != originalValue) {
      setState(() {
        _modifiedFields.add(fieldName);
        _formData[fieldName] = currentValue;
      });
    } else {
      setState(() {
        _modifiedFields.remove(fieldName);
      });
    }
    
    // Recalculate credibility score when fields change
    _calculateCredibilityScore();
  }

  Future<void> _getEvidenceSuggestions() async {
    try {
      final suggestions = await EvidenceGuidanceService.getEvidenceGuidance(
        widget.complaint.crimeType,
        description: _controllers['description']?.text ?? '',
      );
      setState(() {
        _evidenceSuggestions = suggestions;
      });
    } catch (e) {
      print('Error getting evidence suggestions: $e');
    }
  }

  Future<void> _calculateCredibilityScore() async {
    try {
      // Create form data from current values
      final formData = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        formData[key] = controller.text;
      });
      
      final result = await CredibilityScorer.calculateCredibilityScore(
        formData,
        widget.complaint.crimeType,
      );
      
      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _credibilityScore = result.overallScore / 100.0; // Convert to 0-1 range
          _improvementSuggestions = result.suggestions;
        });
      }
    } catch (e) {
      print('Error calculating credibility score: $e');
    }
  }

  Future<void> _loadStatusHistory() async {
    try {
      setState(() => _isLoadingStatusHistory = true);
      
      final DatabaseService databaseService = DatabaseService();
      final complaintId = widget.complaint.id ?? '';
      if (complaintId.isEmpty) {
        print('⚠️ Warning: Complaint ID is null or empty');
        setState(() => _isLoadingStatusHistory = false);
        return;
      }
      final history = await databaseService.getComplaintStatusHistory(complaintId);
      
      setState(() {
        _statusHistory = history;
        _isLoadingStatusHistory = false;
      });
      
      print('✅ Status history loaded: ${history.length} entries');
    } catch (e) {
      print('❌ Error loading status history: $e');
      setState(() => _isLoadingStatusHistory = false);
    }
  }

  Future<void> _pickEvidence() async {
    final ImagePicker picker = ImagePicker();
    
    // Check total evidence count
    if (_existingEvidenceFiles.length + _newEvidenceFiles.length >= maxEvidenceFiles) {
      _showErrorDialog('You can only upload up to $maxEvidenceFiles evidence files.');
      return;
    }
    
    // Show options for different file types using modern bottom sheet
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildEvidencePickerBottomSheet(),
    );

    if (result == null) return;

    XFile? file;
    
    switch (result) {
      case 'camera':
        file = await picker.pickImage(source: ImageSource.camera);
        break;
      case 'gallery':
        file = await picker.pickImage(source: ImageSource.gallery);
        break;
      case 'video':
        file = await picker.pickVideo(source: ImageSource.gallery);
        break;
    }
    
    if (file != null) {
      setState(() {
        _newEvidenceFiles.add(file!);
      });
    }
  }

  Widget _buildEvidencePickerBottomSheet() {
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
            'Select Evidence Type',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          _buildEvidenceOption(
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: 'Capture evidence with camera',
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          _buildEvidenceOption(
            icon: Icons.photo_library,
            title: 'Photo Gallery',
            subtitle: 'Select photos from gallery',
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
          _buildEvidenceOption(
            icon: Icons.videocam,
            title: 'Video',
            subtitle: 'Record video evidence',
            onTap: () => Navigator.pop(context, 'video'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceOption({
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_modifiedFields.isEmpty && _newEvidenceFiles.isEmpty) {
      _showErrorDialog('No changes have been made to update.');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Prepare update data with validation and trimming
      final Map<String, dynamic> updates = {};
      for (final field in _modifiedFields) {
        final value = _formData[field];
        // Validate suspect_relationship field to fix database constraint
        if (field == 'suspect_relationship' || field == 'suspectRelationship') {
          updates[field] = _validateSuspectRelationship(value);
        } else {
          // Trim extra spaces from text values
          if (value is String) {
            updates[field] = value.trim();
          } else {
            updates[field] = value;
          }
        }
      }
      
      // Call update service
      final result = await _complaintService.updateComplaint(
        complaintId: widget.complaint.id!,
        updates: updates,
        newEvidenceFiles: _newEvidenceFiles,
        updateReason: 'Citizen provided additional information',
        deviceInfo: {
          'platform': Platform.operatingSystem,
          'app_version': '1.0.0',
        },
      );
      
      if (result['success']) {
        // Show modern success dialog matching complaint form design
        await _showModernSuccessDialog();
      } else {
        _showErrorDialog(result['error'] ?? 'Failed to update complaint');
      }
    } catch (e) {
      _showErrorDialog('Error updating complaint: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showErrorDialog(String message) async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    await showDialog(
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
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Update Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showModernSuccessDialog() async {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    await showDialog(
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
              'Update Successful',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your complaint information has been successfully updated. ${_modifiedFields.isNotEmpty ? "${_modifiedFields.length} field(s) were modified." : ""} ${_newEvidenceFiles.isNotEmpty ? "${_newEvidenceFiles.length} new evidence file(s) were added." : ""}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            if (_modifiedFields.isNotEmpty) ...[
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
                      'Fields Updated',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modifiedFields.map((field) => field.replaceAll('_', ' ').toUpperCase()).join(', '),
                      textAlign: TextAlign.center,
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
                  Navigator.of(context).pop(true); // go back with success indicator
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Back to Complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    List<Widget> widgets = [];
    
    for (final field in _dynamicFields) {
      final fieldKey = _getFieldKey(field);
      if (fieldKey == null) continue;
      
      final config = DynamicFieldConfig.getFieldConfig(field);
      if (config == null) continue;
      
      // Special handling for suspect relationship dropdown
      if (field == ComplaintField.suspectRelationship) {
        final originalValue = _getFieldValue(field)?.toString() ?? 'Unknown';
        widgets.add(_buildDropdownComparison(fieldKey, config.label, originalValue));
      } else {
        // Regular text fields
        if (_controllers.containsKey(fieldKey)) {
          widgets.add(_buildFieldComparison(fieldKey, config.label));
        }
      }
    }
    
    return widgets;
  }

  Widget _buildFieldComparison(String fieldName, String label) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final controller = _controllers[fieldName];
    if (controller == null) return const SizedBox.shrink();
    
    final isModified = _modifiedFields.contains(fieldName);
    final originalValue = _originalValues[fieldName]?.toString() ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isModified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Modified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // Special handling for suspect relationship dropdown
        if (fieldName == 'suspect_relationship' || fieldName == 'suspectRelationship')
          _buildSuspectRelationshipDropdown(fieldName, isDark, isModified, originalValue)
        else
          TextFormField(
            controller: controller,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
            ),
            decoration: InputDecoration(
              hintText: fieldName == 'description' 
                  ? 'Provide additional details...' 
                  : 'Enter $label',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isModified 
                    ? Colors.orange.withOpacity(0.5)
                    : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isModified 
                    ? Colors.orange.withOpacity(0.5)
                    : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isModified ? Colors.orange : const Color(0xFF2563EB),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: isModified 
                ? Colors.orange.withOpacity(0.05) 
                : (isDark ? const Color(0xFF1E293B) : Colors.grey[50]),
          ),
          maxLines: fieldName == 'description' ? 5 : 1,
          validator: (value) {
            if (fieldName == 'description' && (value?.isEmpty ?? true)) {
              return 'Description is required';
            }
            return null;
          },
        ),
        if (isModified && originalValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Original: $originalValue',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSuspectRelationshipDropdown(String fieldName, bool isDark, bool isModified, String originalValue) {
    final validRelationships = [
      'Unknown',
      'Acquaintance',
      'Friend/Ex-friend',
      'Family Member',
      'Ex-partner/Romantic',
      'Colleague/Classmate',
      'Online Contact Only',
      'Complete Stranger'
    ];

    // Get current value, fallback to Unknown if invalid
    String currentValue = _formData[fieldName]?.toString() ?? 'Unknown';
    if (!validRelationships.contains(currentValue)) {
      currentValue = 'Unknown';
      _formData[fieldName] = currentValue;
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isModified 
              ? Colors.orange.withOpacity(0.5)
              : (isDark ? Colors.grey[600]! : Colors.grey[400]!),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isModified 
            ? Colors.orange.withOpacity(0.05) 
            : (isDark ? const Color(0xFF1E293B) : Colors.grey[50]),
      ),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        decoration: InputDecoration(
          hintText: 'Select relationship to suspect',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isModified ? Colors.orange : const Color(0xFF2563EB),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        items: validRelationships.map((String relationship) {
          return DropdownMenuItem<String>(
            value: relationship,
            child: Text(
              relationship,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _formData[fieldName] = newValue;
              if (newValue != originalValue) {
                _modifiedFields.add(fieldName);
              } else {
                _modifiedFields.remove(fieldName);
              }
            });
            _onFieldChanged(fieldName);
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select relationship to suspect';
          }
          return null;
        },
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
        ),
        icon: Icon(
          Icons.arrow_drop_down,
          color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
        ),
      ),
    );
  }

  Widget _buildDropdownComparison(String fieldName, String label, String originalValue) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final isModified = _modifiedFields.contains(fieldName);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isModified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, size: 14, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(
                      'Modified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _buildSuspectRelationshipDropdown(fieldName, isDark, isModified, originalValue),
        if (isModified && originalValue.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF374151) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  size: 16,
                  color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                ),
                const SizedBox(width: 6),
                Text(
                  'Original: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                  ),
                ),
                Expanded(
                  child: Text(
                    originalValue,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // Build section card matching the app design pattern
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
  }) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final effectiveIconColor = iconColor ?? const Color(0xFF2563EB);
    
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
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: effectiveIconColor,
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

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Update Complaint Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Information Card
                _buildSectionCard(
                  title: 'Update Request',
                  icon: Icons.info_outline,
                  iconColor: Colors.blue,
                  children: [
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
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  'Complaint #${widget.complaint.complaintNumber}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.pending_actions, size: 14, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          'Requires More Info',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'The investigating officer has requested additional information. Please update the relevant fields below.',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Modified fields indicator
                if (_modifiedFields.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          '${_modifiedFields.length} field(s) modified',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Basic Information Section
                _buildSectionCard(
                  title: 'Basic Information',
                  icon: Icons.description,
                  children: [
                    _buildFieldComparison('description', 'Description'),
                  ],
                ),
                
                // Dynamic Fields Section - Show only fields relevant to this crime type
                if (_dynamicFields.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSectionCard(
                    title: 'Additional Information',
                    icon: Icons.info,
                    iconColor: Colors.purple,
                    children: _buildDynamicFields(),
                  ),
                ],
                
                // Evidence Section
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Digital Evidence',
                  icon: Icons.attach_file,
                  iconColor: Colors.green,
                  children: [
                    // Existing evidence
                    if (_existingEvidenceFiles.isNotEmpty) ...[
                      Text(
                        'Existing Evidence:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._existingEvidenceFiles.map((file) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _getFileIcon(file.fileType),
                                color: Colors.green,
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
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Uploaded on ${file.uploadedAt.toString().split('.')[0]}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 16),
                    ],
                    
                    // New evidence
                    if (_newEvidenceFiles.isNotEmpty) ...[
                      Text(
                        'New Evidence to Upload:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._newEvidenceFiles.asMap().entries.map((entry) {
                        final index = entry.key;
                        final file = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.attach_file, color: Colors.blue),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  file.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _newEvidenceFiles.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Add evidence button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _pickEvidence,
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add New Evidence'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Evidence suggestions
                if (_evidenceSuggestions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Suggested Evidence:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._evidenceSuggestions.map((item) => Padding(
                          padding: const EdgeInsets.only(left: 28, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${item.title}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (item.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    item.description,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
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
                
                // Credibility Score
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Report Credibility Score',
                  icon: Icons.verified_user,
                  iconColor: _getCredibilityColor(),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getCredibilityColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getCredibilityColor().withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: _getCredibilityColor().withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(_credibilityScore * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _getCredibilityColor(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getCredibilityLevel(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getCredibilityColor(),
                                    ),
                                  ),
                                  Text(
                                    'Report Completeness',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_improvementSuggestions.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
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
                                  'Suggestions to Improve:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._improvementSuggestions.map((suggestion) => Padding(
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
                                        color: isDark ? Colors.orange[300] : Colors.orange[700],
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
                ),
                
                const SizedBox(height: 32),
                
                // Status History Section
                _buildSectionCard(
                  title: 'Status History & Officer Notes',
                  icon: Icons.history,
                  iconColor: Colors.indigo,
                  children: [
                    _buildStatusHistorySection(),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _modifiedFields.isNotEmpty || _newEvidenceFiles.isNotEmpty
                        ? _submitUpdate
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit Updates',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
      if (_isLoading)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
    ],
    );
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('video')) return Icons.videocam;
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    return Icons.attach_file;
  }

  Color _getCredibilityColor() {
    if (_credibilityScore >= 0.8) return Colors.green;
    if (_credibilityScore >= 0.6) return Colors.orange;
    return Colors.red;
  }
  
  String _getCredibilityLevel() {
    if (_credibilityScore >= 0.8) return 'Excellent';
    if (_credibilityScore >= 0.6) return 'Good';
    if (_credibilityScore >= 0.4) return 'Fair';
    return 'Needs Improvement';
  }

  Widget _buildStatusHistorySection() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    if (_isLoadingStatusHistory) {
      return Center(
        child: Column(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
              strokeWidth: 2,
            ),
            const SizedBox(height: 12),
            Text(
              'Loading status history...',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    if (_statusHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: isDark ? Colors.grey[500]! : Colors.grey[400]!,
            ),
            const SizedBox(height: 12),
            Text(
              'No Status Updates Yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300]! : Colors.grey[700]!,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status changes and officer notes will appear here',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Sort history by timestamp (newest first)
    final sortedHistory = List<Map<String, dynamic>>.from(_statusHistory)
      ..sort((a, b) {
        final aTimeStr = a['timestamp'] as String?;
        final bTimeStr = b['timestamp'] as String?;
        if (aTimeStr == null && bTimeStr == null) return 0;
        if (aTimeStr == null) return 1;
        if (bTimeStr == null) return -1;
        final aTime = DateTime.parse(aTimeStr);
        final bTime = DateTime.parse(bTimeStr);
        return bTime.compareTo(aTime);
      });
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.indigo, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This shows all status changes and officer notes for your case. Look for recent updates to understand what information is needed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.indigo[300]! : Colors.indigo[700]!,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...sortedHistory.asMap().entries.map((entry) {
          final index = entry.key;
          final history = entry.value;
          final isFirst = index == 0;
          final isLast = index == sortedHistory.length - 1;
          
          return _buildStatusHistoryItem(history, isDark, isFirst, isLast);
        }).toList(),
      ],
    );
  }

  Widget _buildStatusHistoryItem(Map<String, dynamic> history, bool isDark, bool isFirst, bool isLast) {
    final status = history['status'] ?? 'Unknown';
    final updatedBy = history['updated_by'] ?? 'System';
    final remarks = history['remarks'] ?? '';
    final timestampStr = history['timestamp'] as String?;
    final timestamp = timestampStr != null ? DateTime.parse(timestampStr) : DateTime.now();
    final timeAgo = _formatTimeAgo(timestamp);
    
    // Get status color
    Color statusColor = _getStatusColorByName(status);
    
    // Get status icon
    IconData statusIcon = _getStatusIconByName(status);
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor, width: 2),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFirst 
                    ? statusColor.withOpacity(0.5)
                    : (isDark ? Colors.grey[600] : Colors.grey[300])!,
                  width: isFirst ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark 
                      ? Colors.black.withOpacity(0.2) 
                      : Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status and officer info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              'Updated by $updatedBy',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey[400]! : Colors.grey[600]!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFirst)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'CURRENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400]! : Colors.grey[500]!,
                    ),
                  ),
                  // Officer remarks/notes
                  if (remarks.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.speaker_notes, size: 16, color: Colors.amber[700]!),
                              const SizedBox(width: 6),
                              Text(
                                'Officer Notes:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.amber[300]! : Colors.amber[700]!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remarks,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.amber[200]! : Colors.amber[800]!,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColorByName(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Assigned':
        return Colors.teal;
      case 'Under Investigation':
        return Colors.purple;
      case 'Requires More Information':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Dismissed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIconByName(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Assigned':
        return Icons.person_add;
      case 'Under Investigation':
        return Icons.search;
      case 'Requires More Information':
        return Icons.help_outline;
      case 'Resolved':
        return Icons.check_circle;
      case 'Dismissed':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String _validateSuspectRelationship(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'Unknown'; // Default valid value
    }
    
    // Convert to string and normalize
    final normalized = value.toString().trim();
    
    // Valid values matching the complaint form dropdown exactly
    final validRelationships = [
      'Unknown',
      'Acquaintance',
      'Friend/Ex-friend',
      'Family Member',
      'Ex-partner/Romantic',
      'Colleague/Classmate',
      'Online Contact Only',
      'Complete Stranger'
    ];
    
    // Check if the value matches any valid relationship (case insensitive)
    for (final valid in validRelationships) {
      if (normalized.toLowerCase() == valid.toLowerCase()) {
        return valid; // Return the properly formatted version
      }
    }
    
    // If no match found, return 'Unknown' as safe default
    print('⚠️ Invalid suspect_relationship value: "$normalized", defaulting to "Unknown"');
    return 'Unknown';
  }

  @override
  void dispose() {
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }
}