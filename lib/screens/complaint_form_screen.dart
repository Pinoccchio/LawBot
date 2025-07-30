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
  final _databaseService = DatabaseService();
  final _pnpUnitsService = PNPUnitsService();

  // Dynamic crime types from database
  List<DatabaseCrimeType> _availableCrimeTypes = [];
  DatabaseCrimeType? _selectedCrimeType;
  PNPOfficer? _selectedOfficer;
  String _officerAssignmentMode = 'auto'; // 'auto' or 'manual'
  
  final List<EvidenceFile> _evidenceFiles = [];
  bool _isSubmitting = false;
  bool _isLoadingCrimeTypes = true;
  DateTime? _selectedIncidentDateTime;
  String? _crimeTypesError;

  @override
  void initState() {
    super.initState();
    // Add listeners for real-time credibility score updates
    _descriptionController.addListener(() => setState(() {}));
    _fullNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
    
    // Load crime types from database
    _loadCrimeTypes();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
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

  // Handle crime type selection and reset officer selection
  void _onCrimeTypeSelected(DatabaseCrimeType? crimeType) {
    setState(() {
      _selectedCrimeType = crimeType;
      _selectedOfficer = null; // Reset officer selection
      _officerAssignmentMode = 'auto'; // Reset to auto-assignment
    });
  }

  // Handle officer assignment mode change
  void _onOfficerAssignmentModeChanged(String? mode) {
    setState(() {
      _officerAssignmentMode = mode ?? 'auto';
      if (_officerAssignmentMode == 'auto') {
        _selectedOfficer = _selectedCrimeType?.recommendedOfficer;
      } else {
        _selectedOfficer = null; // User will select manually
      }
    });
  }

  // Handle manual officer selection
  void _onOfficerSelected(PNPOfficer? officer) {
    setState(() {
      _selectedOfficer = officer;
    });
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
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCrimeType == null) {
      _showErrorSnackBar('Please select a crime type');
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
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Please sign in to submit a complaint');
        return;
      }

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
      );

      // Submit to database service (need to create this method)
      final complaintId = await _submitDatabaseComplaint(complaint);
      
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
        'status': 'Pending',
        'priority': complaint.priority,
        'risk_score': complaint.riskScore,
        'assigned_unit': complaint.assignedUnit.unitName,
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

      // Assign officer based on assignment mode
      if (_officerAssignmentMode == 'auto' && _selectedCrimeType!.recommendedOfficer != null) {
        await _pnpUnitsService.supabase.from('case_assignments').insert({
          'complaint_id': complaintId,
          'officer_id': _selectedCrimeType!.recommendedOfficer!.id,
          'assigned_by': 'System',
          'assignment_type': 'primary',
          'status': 'active',
          'notes': 'Auto-assigned based on crime type and officer availability',
          'created_at': PhilippineTime.toUtc(now).toIso8601String(),
        });
      } else if (_officerAssignmentMode == 'manual' && _selectedOfficer != null) {
        await _pnpUnitsService.supabase.from('case_assignments').insert({
          'complaint_id': complaintId,
          'officer_id': _selectedOfficer!.id,
          'assigned_by': 'User',
          'assignment_type': 'primary',
          'status': 'active',
          'notes': 'Manually selected by complainant during report submission',
          'created_at': PhilippineTime.toUtc(now).toIso8601String(),
        });
      }

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
              'Your cybercrime complaint has been successfully submitted and assigned to ${_selectedCrimeType?.assignedUnitName ?? 'PNP Anti-Cybercrime Group'}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
            if ((_officerAssignmentMode == 'auto' && _selectedCrimeType?.recommendedOfficer != null) || 
                (_officerAssignmentMode == 'manual' && _selectedOfficer != null)) ...[
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
                      _officerAssignmentMode == 'auto' ? 'Auto-Assigned Officer' : 'Selected Officer',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _officerAssignmentMode == 'auto' 
                          ? _selectedCrimeType!.recommendedOfficer!.displayName
                          : _selectedOfficer!.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      _officerAssignmentMode == 'auto' 
                          ? _selectedCrimeType!.recommendedOfficer!.workloadDescription
                          : _selectedOfficer!.workloadDescription,
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
                              'Officer Assignment',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Officer Assignment Mode Selection
                            Theme(
                              data: Theme.of(context).copyWith(
                                radioTheme: RadioThemeData(
                                  fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                    if (states.contains(MaterialState.selected)) {
                                      return const Color(0xFF2563EB); // Consistent blue
                                    }
                                    return isDark ? Colors.grey[600]! : Colors.grey[400]!;
                                  }),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _officerAssignmentMode == 'auto' 
                                          ? const Color(0xFF2563EB).withOpacity(0.05)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _officerAssignmentMode == 'auto' 
                                            ? const Color(0xFF2563EB).withOpacity(0.3)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: RadioListTile<String>(
                                      value: 'auto',
                                      groupValue: _officerAssignmentMode,
                                      onChanged: _onOfficerAssignmentModeChanged,
                                      title: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            size: 16,
                                            color: _officerAssignmentMode == 'auto' 
                                                ? const Color(0xFF2563EB)
                                                : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Auto-assign (Recommended)',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: _officerAssignmentMode == 'auto' 
                                                    ? FontWeight.w600 
                                                    : FontWeight.normal,
                                                color: _officerAssignmentMode == 'auto' 
                                                    ? const Color(0xFF2563EB)
                                                    : (isDark ? Colors.white : Colors.black),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(left: 22),
                                        child: Text(
                                          'System assigns the best available officer based on workload and expertise',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      dense: true,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: _officerAssignmentMode == 'manual' 
                                          ? const Color(0xFF2563EB).withOpacity(0.05)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _officerAssignmentMode == 'manual' 
                                            ? const Color(0xFF2563EB).withOpacity(0.3)
                                            : Colors.transparent,
                                      ),
                                    ),
                                    child: RadioListTile<String>(
                                      value: 'manual',
                                      groupValue: _officerAssignmentMode,
                                      onChanged: _selectedCrimeType!.availableOfficers.isNotEmpty 
                                          ? _onOfficerAssignmentModeChanged 
                                          : null,
                                      title: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_search,
                                            size: 16,
                                            color: _selectedCrimeType!.availableOfficers.isNotEmpty
                                                ? (_officerAssignmentMode == 'manual' 
                                                    ? const Color(0xFF2563EB)
                                                    : (isDark ? Colors.grey[400] : Colors.grey[600]))
                                                : (isDark ? Colors.grey[700] : Colors.grey[300]),
                                          ),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Text(
                                              'Choose specific officer',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: _officerAssignmentMode == 'manual' 
                                                    ? FontWeight.w600 
                                                    : FontWeight.normal,
                                                color: _selectedCrimeType!.availableOfficers.isNotEmpty
                                                    ? (_officerAssignmentMode == 'manual' 
                                                        ? const Color(0xFF2563EB)
                                                        : (isDark ? Colors.white : Colors.black))
                                                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(left: 22),
                                        child: Text(
                                          _selectedCrimeType!.availableOfficers.isNotEmpty
                                              ? 'Select from ${_selectedCrimeType!.availableOfficers.length} available officers'
                                              : 'No officers currently available for manual selection',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      dense: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Show officer selection dropdown when manual mode is selected
                            if (_officerAssignmentMode == 'manual' && _selectedCrimeType!.availableOfficers.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB).withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF2563EB).withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_search,
                                          size: 16,
                                          color: const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Choose Officer',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<PNPOfficer>(
                                      value: _selectedOfficer,
                                      hint: Text(
                                        'Select an officer from ${_selectedCrimeType!.availableOfficers.length} available',
                                        style: TextStyle(
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF2563EB).withOpacity(0.3),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF2563EB).withOpacity(0.3),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2563EB),
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: isDark 
                                            ? const Color(0xFF1E293B) 
                                            : Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                        fontSize: 14,
                                      ),
                                      isExpanded: true,
                                      menuMaxHeight: 250,
                                      selectedItemBuilder: (BuildContext context) {
                                        // This builder creates the display for the selected officer (when dropdown is closed)
                                        return _selectedCrimeType!.availableOfficers.map((officer) {
                                          return Container(
                                            alignment: Alignment.centerLeft,
                                            constraints: const BoxConstraints(maxWidth: 200),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 18,
                                                  height: 18,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF2563EB).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(9),
                                                  ),
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Color(0xFF2563EB),
                                                    size: 12,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    officer.displayName,
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
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
                                      items: _selectedCrimeType!.availableOfficers.map((officer) {
                                        Color workloadColor = Colors.green;
                                        if ((officer.activeCases ?? 0) > 7) {
                                          workloadColor = Colors.red;
                                        } else if ((officer.activeCases ?? 0) > 3) {
                                          workloadColor = Colors.orange;
                                        }
                                        
                                        return DropdownMenuItem(
                                          value: officer,
                                          child: Container(
                                            width: double.infinity,
                                            constraints: const BoxConstraints(maxWidth: 280),
                                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
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
                                                Flexible(
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
                                                        maxLines: 1,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Row(
                                                        mainAxisSize: MainAxisSize.min,
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
                                                          Flexible(
                                                            child: Text(
                                                              officer.workloadDescription,
                                                              style: TextStyle(
                                                                fontSize: 11,
                                                                color: workloadColor,
                                                                fontWeight: FontWeight.w500,
                                                              ),
                                                              overflow: TextOverflow.ellipsis,
                                                              maxLines: 1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: _onOfficerSelected,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            // Show current selection
                            if (_officerAssignmentMode == 'auto' && _selectedCrimeType!.recommendedOfficer != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.auto_awesome, color: Colors.green, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Auto-assigned: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.green[600],
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  _selectedCrimeType!.recommendedOfficer!.displayName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.green[700],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedCrimeType!.recommendedOfficer!.workloadDescription,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.green[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (_officerAssignmentMode == 'manual' && _selectedOfficer != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.person, color: Colors.blue, size: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Selected: ',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.blue[600],
                                                ),
                                              ),
                                              Flexible(
                                                child: Text(
                                                  _selectedOfficer!.displayName,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue[700],
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedOfficer!.workloadDescription,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.blue[600],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
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
}