import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/complaint_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/file_upload_widget.dart';
import '../utils/philippine_time.dart';

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

  CrimeType? _selectedCrimeType;
  final List<EvidenceFile> _evidenceFiles = [];
  bool _isSubmitting = false;
  DateTime? _selectedIncidentDateTime;

  @override
  void initState() {
    super.initState();
    // Add listeners for real-time credibility score updates
    _descriptionController.addListener(() => setState(() {}));
    _fullNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _phoneController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
          // For now, we'll use image picker for documents too
          // In production, you'd use file_picker package
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

    // Check for pattern alerts first
    final description = _descriptionController.text.trim().toLowerCase();
    
    // Mock pattern detection - check if any patterns are found
    bool hasPatterns = description.contains('facebook.com/john.smith.fake') || 
                      description.contains('john.smith.fake') ||
                      description.contains('+63 917 123 4567') || 
                      description.contains('09171234567') ||
                      description.contains('scammer@fake.com') || 
                      description.contains('fake-bank@gmail.com') ||
                      description.contains('fake-shopping.com') || 
                      description.contains('scam-deals.net');
    
    if (hasPatterns) {
      _checkForPatternAlerts();
    } else {
      // No patterns detected, proceed directly
      _originalSubmitComplaint();
    }
  }

  // Original submission logic moved here
  Future<void> _originalSubmitComplaint() async {
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
      // Create complaint object with required fields only
      final complaint = Complaint.create(
        userId: 'current_user_id', // TODO: Get from auth service
        crimeType: _selectedCrimeType!,
        description: _descriptionController.text.trim(),
        evidenceFiles: _evidenceFiles,
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        incidentDateTime: _selectedIncidentDateTime!,
      );

      // TODO: Submit to database service
      // await _databaseService.submitComplaint(complaint);

      // Show success dialog
      _showSuccessDialog();
      
    } catch (e) {
      _showErrorSnackBar('Failed to submit complaint: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
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
              'Your cybercrime complaint has been successfully submitted to PNP Anti-Cybercrime Group. You will receive updates on the investigation progress.',
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Report Credibility Meter
              _buildCredibilityMeter(),
              
              // Complaint Details Section
              _buildSectionCard(
                title: 'Complaint Details',
                icon: Icons.report_problem,
                children: [
                  // Crime Type Dropdown
                  Text(
                    'Crime Type *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CrimeType>(
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
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    items: CrimeType.values.map((crimeType) {
                      return DropdownMenuItem(
                        value: crimeType,
                        child: Text(crimeType.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCrimeType = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a crime type';
                      }
                      return null;
                    },
                  ),
                  
                  // Smart Evidence Guidance
                  if (_selectedCrimeType != null) ...[
                    const SizedBox(height: 16),
                    _buildSmartEvidenceGuidance(),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Description
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
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Incident Details Section
              _buildSectionCard(
                title: 'Incident Details',
                icon: Icons.event,
                children: [
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
              
              const SizedBox(height: 20),
              
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
              
              const SizedBox(height: 20),
              
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
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Submitting Complaint...'),
                          ],
                        )
                      : const Text(
                          'Submit Complaint',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
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


  /// Smart Evidence Guidance Feature - User Novelty 1
  Widget _buildSmartEvidenceGuidance() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final recommendations = _getEvidenceRecommendations(_selectedCrimeType!);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Smart Evidence Guidance',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                    ),
                    Text(
                      'Recommended evidence for ${_selectedCrimeType!.displayName}',
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
          const SizedBox(height: 12),
          ...recommendations.map((recommendation) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation['emoji'] ?? '',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation['text'] ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  /// Get evidence recommendations based on crime type
  List<Map<String, String>> _getEvidenceRecommendations(CrimeType crimeType) {
    List<Map<String, String>> recommendations = [];
    
    switch (crimeType) {
      // Financial & Economic Crimes
      case CrimeType.onlineShoppingScams:
      case CrimeType.onlineBankingFraud:
      case CrimeType.paymentGatewayFraud:
        recommendations = [
          {'emoji': '📸', 'text': 'Screenshots of product listings and seller profiles'},
          {'emoji': '💳', 'text': 'Payment confirmation receipts (bank transfer, credit card, e-wallet)'},
          {'emoji': '💬', 'text': 'Chat conversations with the seller/scammer'},
          {'emoji': '🔗', 'text': 'Links to scammer\'s social media or marketplace profiles'},
          {'emoji': '💰', 'text': 'Bank statements showing unauthorized transactions'},
        ];
        break;
      
      // Communication & Social Media Crimes  
      case CrimeType.phishing:
      case CrimeType.socialEngineering:
      case CrimeType.spamMessages:
        recommendations = [
          {'emoji': '📧', 'text': 'Full email headers showing sender information'},
          {'emoji': '🖼️', 'text': 'Screenshots of suspicious emails or websites'},
          {'emoji': '📱', 'text': 'SMS screenshots if received via text'},
          {'emoji': '🔗', 'text': 'URLs of fake websites (do not click, just copy link)'},
          {'emoji': '📅', 'text': 'Timestamp evidence showing when messages were received'},
        ];
        break;
      
      // Data & Privacy Crimes
      case CrimeType.identityTheft:
      case CrimeType.personalInformationTheft:
      case CrimeType.accountTakeover:
        recommendations = [
          {'emoji': '🆔', 'text': 'Copy of your valid government-issued ID'},
          {'emoji': '📄', 'text': 'Unauthorized account statements or credit reports'},
          {'emoji': '📧', 'text': 'Notifications from institutions about unknown accounts'},
          {'emoji': '📸', 'text': 'Screenshots of fake profiles using your information'},
          {'emoji': '🏦', 'text': 'Location logs showing unauthorized access attempts'},
        ];
        break;
      
      // Harassment & Exploitation
      case CrimeType.cyberbullying:
      case CrimeType.onlineHarassment:
      case CrimeType.cyberstalking:
        recommendations = [
          {'emoji': '💬', 'text': 'Screenshots of harassing messages or posts'},
          {'emoji': '👤', 'text': 'Profile information of the harasser'},
          {'emoji': '📅', 'text': 'Timeline documentation of incidents with exact dates/times'},
          {'emoji': '📱', 'text': 'Evidence from multiple platforms if applicable'},
          {'emoji': '📍', 'text': 'Location information if harassment occurred in specific places'},
        ];
        break;
      
      // Malware & System Attacks
      case CrimeType.ransomware:
      case CrimeType.virusAttacks:
      case CrimeType.spyware:
        recommendations = [
          {'emoji': '💻', 'text': 'Screenshots of ransom demands or error messages'},
          {'emoji': '📋', 'text': 'System logs or antivirus reports'},
          {'emoji': '📧', 'text': 'Suspicious emails that may have contained malware'},
          {'emoji': '💾', 'text': 'Backup of affected files (if safe to access)'},
          {'emoji': '⏰', 'text': 'Exact time when attack was discovered'},
        ];
        break;
      
      // Content-Related Crimes
      case CrimeType.copyrightInfringement:
      case CrimeType.illegalContentDistribution:
        recommendations = [
          {'emoji': '📄', 'text': 'Proof of your original content ownership'},
          {'emoji': '🔗', 'text': 'URLs where your content is being used illegally'},
          {'emoji': '📸', 'text': 'Screenshots showing unauthorized usage'},
          {'emoji': '⚖️', 'text': 'Copyright registration or trademark documents'},
          {'emoji': '📅', 'text': 'Original creation date and publication timeline'},
        ];
        break;
      
      // Default recommendations for other crime types
      default:
        recommendations = [
          {'emoji': '📸', 'text': 'Screenshots showing the incident or evidence'},
          {'emoji': '📋', 'text': 'Any relevant documentation or communications'},
          {'emoji': '🔗', 'text': 'URLs, links, or contact information of suspects'},
          {'emoji': '📱', 'text': 'Additional evidence from social media or other platforms'},
          {'emoji': '📅', 'text': 'Timeline of events with specific dates and times'},
        ];
    }
    
    // Add general recommendations for all crime types
    recommendations.addAll([
      {'emoji': '⏰', 'text': 'Provide exact date and time when incident occurred'},
      {'emoji': '📋', 'text': 'Include detailed description of what happened'},
    ]);
    
    return recommendations;
  }

  /// Report Credibility Meter - User Novelty 2
  Widget _buildCredibilityMeter() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final credibilityData = _calculateCredibilityScore();
    final score = credibilityData['score'] as int;
    final suggestions = credibilityData['suggestions'] as List<String>;
    
    Color scoreColor;
    String scoreLabel;
    
    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = 'Excellent';
    } else if (score >= 65) {
      scoreColor = Colors.orange;
      scoreLabel = 'Good';
    } else if (score >= 40) {
      scoreColor = Colors.amber;
      scoreLabel = 'Fair';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Needs Improvement';
    }
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.1),
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
              Icon(
                Icons.security,
                color: scoreColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Credibility Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '$score% Complete • $scoreLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: scoreColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Suggestions
          if (suggestions.isNotEmpty) ...[
            Text(
              'To improve your score:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestions.map((suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: TextStyle(
                      color: scoreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
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

  /// Calculate credibility score based on form completion
  Map<String, dynamic> _calculateCredibilityScore() {
    int score = 0;
    List<String> suggestions = [];
    
    // Crime Type Selection (10%)
    if (_selectedCrimeType != null) {
      score += 10;
    } else {
      suggestions.add('Select a crime type');
    }
    
    // Description Quality (25%)
    final description = _descriptionController.text.trim();
    if (description.isNotEmpty) {
      if (description.length >= 100) {
        score += 25; // Full points for detailed description
      } else if (description.length >= 50) {
        score += 15; // Partial points
        suggestions.add('Provide a more detailed description (at least 100 characters)');
      } else if (description.length >= 20) {
        score += 10; // Minimal points
        suggestions.add('Add more details to your incident description');
      } else {
        suggestions.add('Provide a detailed description of the incident');
      }
    } else {
      suggestions.add('Add an incident description');
    }
    
    // Evidence Files (35%)
    if (_evidenceFiles.isNotEmpty) {
      if (_evidenceFiles.length >= 3) {
        score += 35; // Full points for multiple evidence files
      } else if (_evidenceFiles.length >= 2) {
        score += 25; // Good evidence
        suggestions.add('Consider adding more evidence files for stronger case');
      } else {
        score += 15; // Minimal evidence
        suggestions.add('Add more evidence files (screenshots, documents, etc.)');
      }
    } else {
      suggestions.add('Upload evidence files to support your report');
    }
    
    // Required Contact Information (15%) - Now mandatory
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    
    int contactScore = 0;
    if (fullName.isNotEmpty) contactScore += 5;
    if (email.isNotEmpty && email.contains('@')) contactScore += 5;
    if (phone.isNotEmpty) contactScore += 5;
    
    score += contactScore;
    
    if (contactScore < 15) {
      if (fullName.isEmpty) suggestions.add('Full name is required');
      if (email.isEmpty) suggestions.add('Email address is required');
      if (phone.isEmpty) suggestions.add('Phone number is required');
    }
    
    // Incident Date/Time (15%) - Required
    if (_selectedIncidentDateTime != null) {
      score += 15;
    } else {
      suggestions.add('Select the date and time of incident');
    }
    
    return {
      'score': score > 100 ? 100 : score,
      'suggestions': suggestions.take(3).toList(), // Limit to top 3 suggestions
    };
  }

  /// Report Pattern Alerts - User Novelty 3
  void _checkForPatternAlerts() {
    final description = _descriptionController.text.trim().toLowerCase();
    
    // Mock pattern detection - in production this would check against a database
    List<Map<String, dynamic>> detectedPatterns = [];
    
    // Check for known scammer patterns
    if (description.contains('facebook.com/john.smith.fake') || 
        description.contains('john.smith.fake')) {
      detectedPatterns.add({
        'type': 'social_media',
        'priority': 'high',
        'count': 47,
        'timeframe': 'last 7 days',
        'message': 'This Facebook profile was reported by 47 users in the last 7 days',
        'icon': Icons.warning,
        'color': Colors.red,
      });
    }
    
    if (description.contains('+63 917 123 4567') || 
        description.contains('09171234567')) {
      detectedPatterns.add({
        'type': 'phone',
        'priority': 'medium',
        'count': 23,
        'timeframe': 'this month',
        'message': 'This phone number (+63 917 123 4567) has been reported 23 times this month',
        'icon': Icons.phone,
        'color': Colors.orange,
      });
    }
    
    if (description.contains('scammer@fake.com') || 
        description.contains('fake-bank@gmail.com')) {
      detectedPatterns.add({
        'type': 'email',
        'priority': 'high',
        'count': 15,
        'timeframe': 'last 2 weeks',
        'message': 'This email address is linked to 15 other fraud reports in the last 2 weeks',
        'icon': Icons.email,
        'color': Colors.red,
      });
    }
    
    if (description.contains('fake-shopping.com') || 
        description.contains('scam-deals.net')) {
      detectedPatterns.add({
        'type': 'website',
        'priority': 'urgent',
        'count': 89,
        'timeframe': 'last 30 days',
        'message': 'This website has been flagged in 89 phishing reports in the last 30 days',
        'icon': Icons.language,
        'color': Colors.red,
      });
    }
    
    // Show pattern alert dialog if patterns detected
    if (detectedPatterns.isNotEmpty) {
      _showPatternAlertDialog(detectedPatterns);
    }
  }

  void _showPatternAlertDialog(List<Map<String, dynamic>> patterns) {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.security,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ Pattern Alert',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'We detected that you may be reporting a known scammer or threat. This information has been reported by other users recently.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: patterns.length,
                  itemBuilder: (context, index) {
                    final pattern = patterns[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (pattern['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (pattern['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            pattern['icon'],
                            color: pattern['color'],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pattern['message'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: pattern['color'],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${pattern['priority'].toString().toUpperCase()} PRIORITY',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your report will be prioritized and may help protect others from similar threats.',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel Report',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _proceedWithSubmission();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Continue Report'),
          ),
        ],
      ),
    );
  }

  void _proceedWithSubmission() {
    // Continue with the original form submission logic
    _originalSubmitComplaint();
  }
}