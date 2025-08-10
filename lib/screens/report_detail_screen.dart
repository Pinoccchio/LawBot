import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../models/complaint_model.dart';
import '../providers/theme_provider.dart';
import '../utils/philippine_time.dart';
import '../services/complaint_service.dart';
import '../services/file_download_service.dart';
import 'edit_complaint_screen.dart';

class ReportDetailScreen extends StatefulWidget {
  final Complaint complaint;

  const ReportDetailScreen({super.key, required this.complaint});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final StreamController<double> _downloadProgressController = StreamController<double>.broadcast();
  Complaint? _completeComplaint;
  bool _isLoadingDetails = false;
  String? _loadingError;
  List<Map<String, dynamic>> _updateHistory = [];

  @override
  void initState() {
    super.initState();
    _loadCompleteComplaintDetails();
  }

  @override
  void dispose() {
    _downloadProgressController.close();
    super.dispose();
  }

  Future<void> _loadCompleteComplaintDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _loadingError = null;
    });

    try {
      final complaintId = widget.complaint.id;
      if (complaintId == null) {
        setState(() {
          _completeComplaint = widget.complaint; // Fallback to original
          _isLoadingDetails = false;
          _loadingError = 'Complaint ID is missing';
        });
        return;
      }

      print('🔄 Loading complete complaint details with status history for: $complaintId');
      
      final completeComplaint = await _complaintService.getComplaintWithDetails(complaintId);
      
      if (completeComplaint != null) {
        // Load update history
        final updateHistory = await _complaintService.getComplaintUpdateHistory(complaintId);
        
        setState(() {
          _completeComplaint = completeComplaint;
          _updateHistory = updateHistory;
          _isLoadingDetails = false;
        });
        print('✅ Successfully loaded complaint with ${completeComplaint.statusHistory.length} status updates and ${updateHistory.length} field updates');
      } else {
        setState(() {
          _completeComplaint = displayComplaint; // Fallback to original
          _isLoadingDetails = false;
          _loadingError = 'Could not load complete details';
        });
        print('⚠️ Could not load complete complaint details, using original data');
      }
    } catch (e) {
      print('❌ Error loading complete complaint details: $e');
      setState(() {
        _completeComplaint = displayComplaint; // Fallback to original
        _isLoadingDetails = false;
        _loadingError = 'Error loading details: $e';
      });
    }
  }

  // Get the complaint to display (complete or fallback to original)
  Complaint get displayComplaint => _completeComplaint ?? widget.complaint;


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
          'Report Details',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF2563EB),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Loading Error Banner
                if (_loadingError != null) 
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loadingError!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Enhanced Header Card with Priority & Risk
                _buildEnhancedHeaderCard(isDark),
            
            const SizedBox(height: 16),
            
            // AI Assessment Card
            if (_hasAiAssessment())
              _buildAiAssessmentCard(isDark),
            
            if (_hasAiAssessment())
              const SizedBox(height: 16),
            
            // Investigation Team Card
            if (_hasInvestigationInfo())
              _buildInvestigationTeamCard(isDark),
            
            const SizedBox(height: 16),
            
            // Description Card
            _buildDescriptionCard(isDark),
            
            const SizedBox(height: 16),
            
            // Dynamic Fields Cards (based on crime category)
            ..._buildDynamicFieldsCards(isDark),
            
            // Evidence Card
            if (displayComplaint.hasEvidence) ...[
              const SizedBox(height: 16),
              _buildEvidenceCard(isDark),
            ],
            
            // Contact Information Card
            if (displayComplaint.hasContactInfo) ...[
              const SizedBox(height: 16),
              _buildContactCard(isDark),
            ],
            
            // Status Timeline Card
            const SizedBox(height: 16),
            _buildStatusTimelineCard(isDark),
            
            // Update History Card (if complaint has been updated)
            if (_hasUpdateHistory()) ...[
              const SizedBox(height: 16),
              _buildUpdateHistoryCard(isDark),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      
      // Loading Overlay
      if (_isLoadingDetails)
        Container(
          color: isDark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.7),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading complete details...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildEnhancedHeaderCard(bool isDark) {
    final statusColor = _getStatusColor(displayComplaint.status);
    // Use AI priority if available, fallback to regular priority
    final effectivePriority = displayComplaint.aiPriority ?? displayComplaint.priority;
    final priorityColor = _getPriorityColor(effectivePriority);
    final isAiAssessed = displayComplaint.aiPriority != null;
    
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
          // Enhanced Header Row with Priority and Risk
          Row(
            children: [
              // Crime Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayComplaint.crimeType.categoryIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayComplaint.crimeTypeDisplay,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Priority Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isAiAssessed) ...[
                      Icon(
                        Icons.psychology,
                        size: 10,
                        color: priorityColor,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Icon(
                      _getPriorityIcon(effectivePriority),
                      size: 12,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      effectivePriority.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: priorityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Risk Score and Status Row
          Row(
            children: [
              // Enhanced Risk Score with AI indication
              _buildEnhancedRiskCard(),
              const Spacer(),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayComplaint.statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Complaint Number
          if (displayComplaint.complaintNumber != null) ...[
            Text(
              'Complaint Number',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayComplaint.complaintNumber ?? 'N/A',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Dates Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PhilippineTime.formatDateTime(
                        PhilippineTime.fromUtc(displayComplaint.createdAt)
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PhilippineTime.formatDateTime(
                        PhilippineTime.fromUtc(displayComplaint.updatedAt)
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Update Information Button when status is "Requires More Information"
          if (displayComplaint.status == ComplaintStatus.requiresMoreInfo) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Import the edit screen at the top of the file
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditComplaintScreen(
                        complaint: displayComplaint,
                      ),
                    ),
                  );
                  
                  // Refresh the complaint details if updated
                  if (result == true) {
                    _loadCompleteComplaintDetails();
                  }
                },
                icon: const Icon(Icons.edit_note),
                label: const Text('Update Information'),
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
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    final statusColor = _getStatusColor(displayComplaint.status);
    
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
          // Status and Crime Type Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayComplaint.crimeTypeDisplay,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayComplaint.statusDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Complaint Number
          if (displayComplaint.complaintNumber != null) ...[
            Text(
              'Complaint Number',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayComplaint.complaintNumber ?? 'N/A',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Dates
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submitted',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PhilippineTime.formatDateTime(
                        PhilippineTime.fromUtc(displayComplaint.createdAt)
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Updated',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      PhilippineTime.formatDateTime(
                        PhilippineTime.fromUtc(displayComplaint.updatedAt)
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(bool isDark) {
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
                child: const Icon(
                  Icons.description,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Incident Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayComplaint.description,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[200] : const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(bool isDark) {
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_file,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Digital Evidence',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                '${displayComplaint.evidenceFiles.length} file${displayComplaint.evidenceFiles.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayComplaint.evidenceFiles.length,
            itemBuilder: (context, index) {
              final file = displayComplaint.evidenceFiles[index];
              return _buildEvidenceFileItem(file, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceFileItem(EvidenceFile file, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF374151) 
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey[600]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail or icon
          _buildFileThumbnail(file, isDark),
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
            onPressed: () {
              _showFilePreview(file);
            },
            icon: Icon(
              Icons.visibility,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            tooltip: 'View file',
          ),
          IconButton(
            onPressed: () {
              _downloadFile(file);
            },
            icon: Icon(
              Icons.download,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            tooltip: 'Download file',
          ),
        ],
      ),
    );
  }

  Widget _buildFileThumbnail(EvidenceFile file, bool isDark) {
    // For images, show actual thumbnail
    if (file.isImage) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7),
          child: file.downloadUrl != null && file.downloadUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: file.downloadUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: _getFileTypeColor(file.fileType).withOpacity(0.1),
                    child: Icon(
                      Icons.image,
                      color: _getFileTypeColor(file.fileType),
                      size: 20,
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    // Try local file
                    if (File(file.filePath).existsSync()) {
                      return Image.file(
                        File(file.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: _getFileTypeColor(file.fileType).withOpacity(0.1),
                            child: Icon(
                              Icons.broken_image,
                              color: _getFileTypeColor(file.fileType),
                              size: 20,
                            ),
                          );
                        },
                      );
                    }
                    return Container(
                      color: _getFileTypeColor(file.fileType).withOpacity(0.1),
                      child: Icon(
                        Icons.broken_image,
                        color: _getFileTypeColor(file.fileType),
                        size: 20,
                      ),
                    );
                  },
                )
              : File(file.filePath).existsSync()
                  ? Image.file(
                      File(file.filePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _getFileTypeColor(file.fileType).withOpacity(0.1),
                          child: Icon(
                            Icons.broken_image,
                            color: _getFileTypeColor(file.fileType),
                            size: 20,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: _getFileTypeColor(file.fileType).withOpacity(0.1),
                      child: Icon(
                        Icons.image,
                        color: _getFileTypeColor(file.fileType),
                        size: 20,
                      ),
                    ),
        ),
      );
    } 
    // For videos, show play icon overlay
    else if (file.isVideo) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getFileTypeColor(file.fileType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.videocam,
              color: _getFileTypeColor(file.fileType).withOpacity(0.3),
              size: 30,
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getFileTypeColor(file.fileType),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      );
    }
    // For other files, show icon
    else {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: _getFileTypeColor(file.fileType).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Icon(
          _getFileTypeIcon(file.fileType),
          color: _getFileTypeColor(file.fileType),
          size: 24,
        ),
      );
    }
  }

  Widget _buildContactCard(bool isDark) {
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_phone,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayComplaint.fullName != null) ...[
            _buildContactItem(
              label: 'Full Name',
              value: displayComplaint.fullName ?? 'N/A',
              icon: Icons.person,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (displayComplaint.email != null) ...[
            _buildContactItem(
              label: 'Email Address',
              value: displayComplaint.email ?? 'N/A',
              icon: Icons.email,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (displayComplaint.phoneNumber != null) ...[
            _buildContactItem(
              label: 'Phone Number',
              value: displayComplaint.phoneNumber ?? 'N/A',
              icon: Icons.phone,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTimelineCard(bool isDark) {
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Status Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayComplaint.statusHistory.length,
            itemBuilder: (context, index) {
              final statusUpdate = displayComplaint.statusHistory[index];
              final isLast = index == displayComplaint.statusHistory.length - 1;
              return _buildTimelineItem(statusUpdate, isLast, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(StatusUpdate statusUpdate, bool isLast, bool isDark) {
    final statusColor = _getStatusColor(statusUpdate.status);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDark ? Colors.grey[600] : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusUpdate.status.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Updated by ${statusUpdate.updatedBy}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                PhilippineTime.formatDateTime(
                  PhilippineTime.fromUtc(statusUpdate.timestamp)
                ),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (statusUpdate.remarks != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusUpdate.remarks!,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[200] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
              if (!isLast) const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  void _showFilePreview(EvidenceFile file) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getFileTypeColor(file.fileType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getFileTypeIcon(file.fileType),
                        color: _getFileTypeColor(file.fileType),
                        size: 16,
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
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: _buildFileContent(file, isDark),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[50],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadFile(file),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    if (file.downloadUrl != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _openFileExternally(file),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileContent(EvidenceFile file, bool isDark) {
    if (file.isImage) {
      return _buildImagePreview(file, isDark);
    } else if (file.isDocument) {
      return _buildDocumentPreview(file, isDark);
    } else if (file.isVideo) {
      return _buildVideoPreview(file, isDark);
    } else {
      return _buildGenericFilePreview(file, isDark);
    }
  }

  Widget _buildImagePreview(EvidenceFile file, bool isDark) {
    // Try to load from download URL first (Supabase storage)
    if (file.downloadUrl != null && file.downloadUrl!.isNotEmpty) {
      return Container(
        constraints: const BoxConstraints(
          maxHeight: 400,
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: file.downloadUrl!,
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      'Loading image...',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              errorWidget: (context, url, error) {
                print('Error loading image from URL: $url');
                print('Error details: $error');
                // Try local file as fallback
                if (File(file.filePath).existsSync()) {
                  return Image.file(
                    File(file.filePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildFileError('Could not load image', isDark);
                    },
                  );
                }
                return _buildFileError('Could not load image from server', isDark);
              },
            ),
          ),
        ),
      );
    } 
    // Try to load from local file path
    else if (File(file.filePath).existsSync()) {
      return Container(
        constraints: const BoxConstraints(
          maxHeight: 400,
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(file.filePath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildFileError('Could not load image', isDark);
              },
            ),
          ),
        ),
      );
    } else {
      return _buildFileError('Image file not found', isDark);
    }
  }

  Widget _buildDocumentPreview(EvidenceFile file, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: _getFileTypeColor(file.fileType),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            file.fileName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Document preview not available',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Download" or "Open" to view the document',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(EvidenceFile file, bool isDark) {
    return _VideoPlayerWidget(
      file: file,
      isDark: isDark,
    );
  }

  Widget _buildGenericFilePreview(EvidenceFile file, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.fileType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: _getFileTypeColor(file.fileType),
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            file.fileName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'File type: ${file.fileExtension}',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Size: ${file.fileSizeFormatted}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Uploaded: ${PhilippineTime.formatSpecificTime(file.uploadedAt.toIso8601String())}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileError(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _downloadFile(EvidenceFile file) async {
    try {
      String? localPath;
      
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.5),
        builder: (BuildContext context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : const Color(0xFF2563EB).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with gradient background
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title with emoji
                  Text(
                    '📥 Downloading File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // File name with icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getFileTypeIcon(file.fileType),
                        size: 16,
                        color: _getFileTypeColor(file.fileType),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          file.fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress indicator with custom color
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Progress details
                  StreamBuilder<double>(
                    stream: _downloadProgressController.stream,
                    builder: (context, snapshot) {
                      final progress = snapshot.data ?? 0.0;
                      return Column(
                        children: [
                          // Progress bar with gradient
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF2563EB),
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Progress percentage
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Download from URL if available
      if (file.downloadUrl != null && file.downloadUrl!.isNotEmpty) {
        // Extract bucket name and path from the download URL
        // Format: https://xxx.supabase.co/storage/v1/object/public/evidence-files/complaint_id/filename
        final uri = Uri.parse(file.downloadUrl!);
        final pathSegments = uri.pathSegments;
        
        if (pathSegments.contains('evidence-files')) {
          // This is a Supabase storage URL
          final bucketIndex = pathSegments.indexOf('evidence-files');
          final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
          
          localPath = await FileDownloadService.downloadFromSupabase(
            bucketName: 'evidence-files',
            path: filePath,
            fileName: file.fileName,
            onProgress: (received, total) {
              if (total != -1) {
                _downloadProgressController.add(received / total);
              }
            },
          );
        } else {
          // Regular URL download
          localPath = await FileDownloadService.downloadFile(
            url: file.downloadUrl!,
            fileName: file.fileName,
            onProgress: (received, total) {
              if (total != -1) {
                _downloadProgressController.add(received / total);
              }
            },
          );
        }
      }
      // Try local file if no download URL
      else if (File(file.filePath).existsSync()) {
        localPath = file.filePath;
      }

      Navigator.of(context).pop(); // Close progress dialog

      if (localPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.fileName} downloaded successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () {
                if (localPath != null) {
                  FileDownloadService.openFile(localPath);
                }
              },
            ),
          ),
        );
      } else {
        throw 'Failed to download file';
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close progress dialog if still open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFileExternally(EvidenceFile file) async {
    try {
      // First check if file exists locally
      if (File(file.filePath).existsSync()) {
        final opened = await FileDownloadService.openFile(file.filePath);
        if (opened) {
          return;
        }
      }

      // If local file doesn't exist, try to download and open
      if (file.downloadUrl != null && file.downloadUrl!.isNotEmpty) {
        // Show progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (BuildContext context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                        : [Colors.white, const Color(0xFFF8FAFC)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withOpacity(0.3)
                          : const Color(0xFF2563EB).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with gradient background
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF10B981), Color(0xFF34D399)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.folder_open_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title with emoji
                    Text(
                      '📂 Opening File',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // File name with icon
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getFileTypeIcon(file.fileType),
                          size: 16,
                          color: _getFileTypeColor(file.fileType),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            file.fileName,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress indicator with custom color
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          const Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress details
                    StreamBuilder<double>(
                      stream: _downloadProgressController.stream,
                      builder: (context, snapshot) {
                        final progress = snapshot.data ?? 0.0;
                        return Column(
                          children: [
                            // Progress bar with gradient
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.transparent,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    const Color(0xFF10B981),
                                  ),
                                  minHeight: 8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Progress percentage
                            Text(
                              progress > 0 
                                  ? '${(progress * 100).toStringAsFixed(0)}%'
                                  : 'Preparing...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );

        final opened = await FileDownloadService.openFileFromUrl(
          url: file.downloadUrl!,
          fileName: file.fileName,
          onProgress: (received, total) {
            if (total != -1) {
              _downloadProgressController.add(received / total);
            }
          },
        );

        Navigator.of(context).pop(); // Close progress dialog

        if (!opened) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open file in external application'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close progress dialog if still open
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return Colors.orange;
      case ComplaintStatus.underInvestigation:
        return Colors.purple;
      case ComplaintStatus.resolved:
        return Colors.green;
      case ComplaintStatus.dismissed:
        return Colors.red;
      case ComplaintStatus.requiresMoreInfo:
        return Colors.blue;
    }
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

  // New methods for enhanced functionality
  bool _hasInvestigationInfo() {
    return displayComplaint.assignedUnit != null ||
           displayComplaint.assignedOfficer != null ||
           displayComplaint.assignedOfficerId != null;
  }

  Widget _buildInvestigationTeamCard(bool isDark) {
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
                child: const Icon(
                  Icons.shield,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Investigation Team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Assigned Unit
          if (displayComplaint.assignedUnit != null) ...[
            _buildInfoRow(
              icon: Icons.security,
              label: 'PNP Unit',
              value: displayComplaint.assignedUnit ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          // Assigned Officer
          if (displayComplaint.assignedOfficer != null) ...[
            _buildInfoRow(
              icon: Icons.person_2,
              label: 'Assigned Officer',
              value: displayComplaint.assignedOfficer ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          // Officer ID
          if (displayComplaint.assignedOfficerId != null) ...[
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Officer ID',
              value: displayComplaint.assignedOfficerId ?? 'N/A',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFieldsCards(bool isDark) {
    final List<Widget> cards = [];
    
    // Debug logging for dynamic fields
    print('🔍 Dynamic Fields Debug for complaint ${displayComplaint.complaintNumber ?? 'N/A'}:');
    print('   Platform Website: "${displayComplaint.platformWebsite}" (${displayComplaint.platformWebsite?.isNotEmpty ?? false})');
    print('   Suspect Name: "${displayComplaint.suspectName}" (${displayComplaint.suspectName?.isNotEmpty ?? false})');
    print('   Account Reference: "${displayComplaint.accountReference}" (${displayComplaint.accountReference?.isNotEmpty ?? false})');
    print('   Incident Location: "${displayComplaint.incidentLocation}" (${displayComplaint.incidentLocation?.isNotEmpty ?? false})');
    print('   Has Location/Platform Fields: ${_hasLocationPlatformFields()}');
    print('   Has Financial Fields: ${_hasFinancialFields()}');
    print('   Has Suspect Fields: ${_hasSuspectFields()}');
    print('   Has Technical Fields: ${_hasTechnicalFields()}');
    
    // Financial Information Card
    if (_hasFinancialFields()) {
      cards.add(_buildFinancialCard(isDark));
      cards.add(const SizedBox(height: 16));
    }
    
    // Suspect Information Card
    if (_hasSuspectFields()) {
      cards.add(_buildSuspectCard(isDark));
      cards.add(const SizedBox(height: 16));
    }
    
    // Technical Information Card
    if (_hasTechnicalFields()) {
      cards.add(_buildTechnicalCard(isDark));
      cards.add(const SizedBox(height: 16));
    }
    
    // Location & Platform Card
    if (_hasLocationPlatformFields()) {
      cards.add(_buildLocationPlatformCard(isDark));
      cards.add(const SizedBox(height: 16));
    }
    
    return cards;
  }

  bool _hasFinancialFields() {
    return (displayComplaint.estimatedFinancialLoss != null && displayComplaint.estimatedFinancialLoss! > 0) ||
           (displayComplaint.accountReference != null && displayComplaint.accountReference!.isNotEmpty);
  }

  bool _hasSuspectFields() {
    return (displayComplaint.suspectName != null && displayComplaint.suspectName!.isNotEmpty) ||
           (displayComplaint.suspectRelationship != null && displayComplaint.suspectRelationship!.isNotEmpty) ||
           (displayComplaint.suspectContact != null && displayComplaint.suspectContact!.isNotEmpty) ||
           (displayComplaint.suspectDetails != null && displayComplaint.suspectDetails!.isNotEmpty);
  }

  bool _hasTechnicalFields() {
    return (displayComplaint.systemDetails != null && displayComplaint.systemDetails!.isNotEmpty) ||
           (displayComplaint.technicalInfo != null && displayComplaint.technicalInfo!.isNotEmpty) ||
           (displayComplaint.vulnerabilityDetails != null && displayComplaint.vulnerabilityDetails!.isNotEmpty) ||
           (displayComplaint.attackVector != null && displayComplaint.attackVector!.isNotEmpty) ||
           (displayComplaint.securityLevel != null && displayComplaint.securityLevel!.isNotEmpty);
  }

  bool _hasLocationPlatformFields() {
    return (displayComplaint.incidentLocation != null && displayComplaint.incidentLocation!.isNotEmpty) ||
           (displayComplaint.platformWebsite != null && displayComplaint.platformWebsite!.isNotEmpty) ||
           (displayComplaint.targetInfo != null && displayComplaint.targetInfo!.isNotEmpty) ||
           (displayComplaint.contentDescription != null && displayComplaint.contentDescription!.isNotEmpty) ||
           (displayComplaint.impactAssessment != null && displayComplaint.impactAssessment!.isNotEmpty);
  }

  Widget _buildFinancialCard(bool isDark) {
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.attach_money,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Financial Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (displayComplaint.estimatedFinancialLoss != null && displayComplaint.estimatedFinancialLoss! > 0) ...[
            _buildInfoRow(
              icon: Icons.money_off,
              label: 'Financial Loss',
              value: '₱${displayComplaint.estimatedFinancialLoss?.toStringAsFixed(2) ?? '0.00'}',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.accountReference != null && displayComplaint.accountReference!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.account_balance,
              label: 'Account/Reference',
              value: displayComplaint.accountReference ?? 'N/A',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuspectCard(bool isDark) {
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
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person_search,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Suspect Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (displayComplaint.suspectName != null && displayComplaint.suspectName!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.person,
              label: 'Suspect Name',
              value: displayComplaint.suspectName ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.suspectRelationship != null && displayComplaint.suspectRelationship!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.family_restroom,
              label: 'Relationship',
              value: displayComplaint.suspectRelationship ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.suspectContact != null && displayComplaint.suspectContact!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.contact_phone,
              label: 'Contact Info',
              value: displayComplaint.suspectContact ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.suspectDetails != null && displayComplaint.suspectDetails!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.info,
              label: 'Additional Details',
              value: displayComplaint.suspectDetails ?? 'N/A',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTechnicalCard(bool isDark) {
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
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.computer,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Technical Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (displayComplaint.systemDetails != null && displayComplaint.systemDetails!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.devices,
              label: 'System Details',
              value: displayComplaint.systemDetails ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.technicalInfo != null && displayComplaint.technicalInfo!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.code,
              label: 'Technical Info',
              value: displayComplaint.technicalInfo ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.vulnerabilityDetails != null && displayComplaint.vulnerabilityDetails!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.security,
              label: 'Vulnerability',
              value: displayComplaint.vulnerabilityDetails ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.attackVector != null && displayComplaint.attackVector!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.gps_fixed,
              label: 'Attack Vector',
              value: displayComplaint.attackVector ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.securityLevel != null && displayComplaint.securityLevel!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.verified_user,
              label: 'Security Level',
              value: displayComplaint.securityLevel ?? 'N/A',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationPlatformCard(bool isDark) {
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
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Location & Platform Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (displayComplaint.incidentLocation != null && displayComplaint.incidentLocation!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.place,
              label: 'Incident Location',
              value: displayComplaint.incidentLocation ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.platformWebsite != null && displayComplaint.platformWebsite!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.web,
              label: 'Platform/Website',
              value: displayComplaint.platformWebsite ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.targetInfo != null && displayComplaint.targetInfo!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.my_location,
              label: 'Target Information',
              value: displayComplaint.targetInfo ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.contentDescription != null && displayComplaint.contentDescription!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.content_copy,
              label: 'Content Description',
              value: displayComplaint.contentDescription ?? 'N/A',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (displayComplaint.impactAssessment != null && displayComplaint.impactAssessment!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.assessment,
              label: 'Impact Assessment',
              value: displayComplaint.impactAssessment ?? 'N/A',
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help;
    }
  }

  // Enhanced Risk Card with AI indication
  Widget _buildEnhancedRiskCard() {
    // Use AI risk score if available, fallback to regular risk score
    final effectiveRiskScore = displayComplaint.aiRiskScore ?? displayComplaint.riskScore;
    final isAiAssessed = displayComplaint.aiRiskScore != null;
    final riskColor = _getRiskColor(effectiveRiskScore);
    final hasHighConfidence = displayComplaint.aiConfidenceScore != null && displayComplaint.aiConfidenceScore! >= 80;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAiAssessed ? Icons.psychology : Icons.analytics,
            size: 14,
            color: riskColor,
          ),
          const SizedBox(width: 4),
          Text(
            'Risk: $effectiveRiskScore%',
            style: TextStyle(
              fontSize: 12,
              color: riskColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isAiAssessed && hasHighConfidence) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Check if complaint has AI assessment data
  bool _hasAiAssessment() {
    return displayComplaint.aiPriority != null ||
           displayComplaint.aiRiskScore != null ||
           displayComplaint.aiConfidenceScore != null ||
           displayComplaint.riskFactors != null ||
           displayComplaint.urgencyIndicators != null ||
           displayComplaint.aiReasoning != null;
  }

  // AI Assessment Card
  Widget _buildAiAssessmentCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.purple.withOpacity(0.3),
          width: 1,
        ),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Risk Assessment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Powered by Gemini 2.0 Flash',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (displayComplaint.lastAiAssessment != null)
                Text(
                  'Updated ${_formatTimeAgo(displayComplaint.lastAiAssessment!)}',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // AI Metrics Row
          Row(
            children: [
              // AI Priority
              if (displayComplaint.aiPriority != null) ...[
                Expanded(
                  child: _buildAiMetricCard(
                    title: 'AI Priority',
                    value: (displayComplaint.aiPriority ?? 'N/A').toUpperCase(),
                    color: _getPriorityColor(displayComplaint.aiPriority ?? 'low'),
                    icon: Icons.priority_high,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // AI Risk Score
              if (displayComplaint.aiRiskScore != null) ...[
                Expanded(
                  child: _buildAiMetricCard(
                    title: 'Risk Score',
                    value: '${displayComplaint.aiRiskScore}%',
                    color: _getRiskColor(displayComplaint.aiRiskScore!),
                    icon: Icons.trending_up,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // AI Confidence
              if (displayComplaint.aiConfidenceScore != null) ...[
                Expanded(
                  child: _buildAiMetricCard(
                    title: 'Confidence',
                    value: '${displayComplaint.aiConfidenceScore}%',
                    color: _getConfidenceColor(displayComplaint.aiConfidenceScore!),
                    icon: Icons.verified,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
          
          // Risk Factors
          if (displayComplaint.riskFactors != null && displayComplaint.riskFactors!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRiskFactorsSection(isDark),
          ],
          
          // Urgency Indicators
          if (displayComplaint.urgencyIndicators != null && displayComplaint.urgencyIndicators!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildUrgencyIndicatorsSection(isDark),
          ],
          
          // AI Reasoning
          if (displayComplaint.aiReasoning != null && displayComplaint.aiReasoning!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildAiReasoningSection(isDark),
          ],
        ],
      ),
    );
  }

  // AI Metric Card
  Widget _buildAiMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Risk Factors Section
  Widget _buildRiskFactorsSection(bool isDark) {
    List<String> factors = displayComplaint.riskFactors;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: 16,
              color: Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              'Risk Factors',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: factors.map((factor) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              factor,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // Urgency Indicators Section
  Widget _buildUrgencyIndicatorsSection(bool isDark) {
    List<String> indicators = displayComplaint.urgencyIndicators;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              'Urgency Indicators',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: indicators.map((indicator) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              indicator,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  // AI Reasoning Section
  Widget _buildAiReasoningSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Colors.blue,
            ),
            const SizedBox(width: 6),
            Text(
              'AI Analysis',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            displayComplaint.aiReasoning!,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[200] : Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to get confidence color
  Color _getConfidenceColor(int confidence) {
    if (confidence >= 90) return Colors.green;
    if (confidence >= 70) return Colors.blue;
    if (confidence >= 50) return Colors.orange;
    return Colors.red;
  }

  // Helper method to get risk color (enhanced version)
  Color _getRiskColor(int riskScore) {
    if (riskScore >= 80) return Colors.red;
    if (riskScore >= 60) return Colors.orange;  
    if (riskScore >= 40) return Colors.amber;
    return Colors.green;
  }

  // Helper method to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    // Use PhilippineTime utility for proper timezone handling
    final now = PhilippineTime.now();
    final philippineDateTime = PhilippineTime.fromUtc(dateTime);
    final difference = now.difference(philippineDateTime);
    
    // Temporary debug logging
    print('🕐 AI Assessment Debug:');
    print('   Database timestamp (UTC): $dateTime');
    print('   Philippines timestamp: $philippineDateTime');
    print('   Current Philippines time: $now');
    print('   Difference: ${difference.inMinutes} minutes');
    
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }

  // Check if complaint has update history
  bool _hasUpdateHistory() {
    return _updateHistory.isNotEmpty;
  }

  // Build update history card
  Widget _buildUpdateHistoryCard(bool isDark) {
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.history,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_updateHistory.length} Update${_updateHistory.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Update entries
          ..._updateHistory.map((update) {
            final createdAt = DateTime.parse(update['created_at']);
            final fieldsUpdated = List<String>.from(update['fields_updated'] ?? []);
            final updaterName = update['updater_name'] ?? 'Unknown';
            final updateType = update['update_type'] ?? 'citizen_update';
            final updateNotes = update['update_notes'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        updateType == 'citizen_update' 
                            ? Icons.person 
                            : Icons.security,
                        size: 16,
                        color: updateType == 'citizen_update'
                            ? Colors.blue
                            : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          updaterName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimeAgo(createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Fields updated
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fieldsUpdated.map((field) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatFieldName(field),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (updateNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      updateNotes,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  
                  // AI reassessment indicator
                  if (update['requires_ai_reassessment'] == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          update['ai_reassessment_completed'] == true
                              ? Icons.check_circle
                              : Icons.pending,
                          size: 14,
                          color: update['ai_reassessment_completed'] == true
                              ? Colors.green
                              : Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          update['ai_reassessment_completed'] == true
                              ? 'AI re-assessment completed'
                              : 'AI re-assessment pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: update['ai_reassessment_completed'] == true
                                ? Colors.green
                                : Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Format field names for display
  String _formatFieldName(String field) {
    // Convert snake_case to Title Case
    return field
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

// Video Player Widget
class _VideoPlayerWidget extends StatefulWidget {
  final EvidenceFile file;
  final bool isDark;

  const _VideoPlayerWidget({
    required this.file,
    required this.isDark,
  });

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // Try to load from URL first
      if (widget.file.downloadUrl != null && widget.file.downloadUrl!.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.file.downloadUrl!),
        );
      } 
      // Try local file
      else if (File(widget.file.filePath).existsSync()) {
        _controller = VideoPlayerController.file(
          File(widget.file.filePath),
        );
      } else {
        setState(() {
          _errorMessage = 'Video file not found';
        });
        return;
      }

      await _controller!.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading video: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading video...',
              style: TextStyle(
                color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(
        maxHeight: 400,
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _VideoControls(
            controller: _controller!,
            isDark: widget.isDark,
          ),
        ],
      ),
    );
  }
}

// Video Controls Widget
class _VideoControls extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isDark;

  const _VideoControls({
    required this.controller,
    required this.isDark,
  });

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    final duration = widget.controller.value.duration;
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF374151) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Progress bar
          VideoProgressIndicator(
            widget.controller,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: const Color(0xFF2563EB),
              bufferedColor: Colors.grey.withOpacity(0.3),
              backgroundColor: Colors.grey.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  if (_isPlaying) {
                    widget.controller.pause();
                  } else {
                    widget.controller.play();
                  }
                },
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 32,
                ),
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 16),
              Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 12,
                  color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}