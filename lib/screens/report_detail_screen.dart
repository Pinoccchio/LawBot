import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/complaint_model.dart';
import '../providers/theme_provider.dart';
import '../utils/philippine_time.dart';

class ReportDetailScreen extends StatefulWidget {
  final Complaint complaint;

  const ReportDetailScreen({super.key, required this.complaint});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (widget.complaint.hasEvidence) ...[
              const SizedBox(height: 16),
              _buildEvidenceCard(isDark),
            ],
            
            // Contact Information Card
            if (widget.complaint.hasContactInfo) ...[
              const SizedBox(height: 16),
              _buildContactCard(isDark),
            ],
            
            // Status Timeline Card
            const SizedBox(height: 16),
            _buildStatusTimelineCard(isDark),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeaderCard(bool isDark) {
    final statusColor = _getStatusColor(widget.complaint.status);
    // Use AI priority if available, fallback to regular priority
    final effectivePriority = widget.complaint.aiPriority ?? widget.complaint.priority;
    final priorityColor = _getPriorityColor(effectivePriority);
    final isAiAssessed = widget.complaint.aiPriority != null;
    
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
                      widget.complaint.crimeType.categoryIcon,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.complaint.crimeTypeDisplay,
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
                      widget.complaint.statusDisplay,
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
          if (widget.complaint.complaintNumber != null) ...[
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
              widget.complaint.complaintNumber!,
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
                        PhilippineTime.fromUtc(widget.complaint.createdAt)
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
                        PhilippineTime.fromUtc(widget.complaint.updatedAt)
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

  Widget _buildHeaderCard(bool isDark) {
    final statusColor = _getStatusColor(widget.complaint.status);
    
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
                  widget.complaint.crimeTypeDisplay,
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
                      widget.complaint.statusDisplay,
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
          if (widget.complaint.complaintNumber != null) ...[
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
              widget.complaint.complaintNumber!,
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
                        PhilippineTime.fromUtc(widget.complaint.createdAt)
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
                        PhilippineTime.fromUtc(widget.complaint.updatedAt)
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
            widget.complaint.description,
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
                '${widget.complaint.evidenceFiles.length} file${widget.complaint.evidenceFiles.length != 1 ? 's' : ''}',
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
            itemCount: widget.complaint.evidenceFiles.length,
            itemBuilder: (context, index) {
              final file = widget.complaint.evidenceFiles[index];
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
            onPressed: () {
              _showFilePreview(file);
            },
            icon: Icon(
              Icons.visibility,
              size: 20,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
          if (widget.complaint.fullName != null) ...[
            _buildContactItem(
              label: 'Full Name',
              value: widget.complaint.fullName!,
              icon: Icons.person,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.complaint.email != null) ...[
            _buildContactItem(
              label: 'Email Address',
              value: widget.complaint.email!,
              icon: Icons.email,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          if (widget.complaint.phoneNumber != null) ...[
            _buildContactItem(
              label: 'Phone Number',
              value: widget.complaint.phoneNumber!,
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
            itemCount: widget.complaint.statusHistory.length,
            itemBuilder: (context, index) {
              final statusUpdate = widget.complaint.statusHistory[index];
              final isLast = index == widget.complaint.statusHistory.length - 1;
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
    if (file.downloadUrl != null) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            file.downloadUrl!,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildFileError('Could not load image', isDark);
            },
          ),
        ),
      );
    } else if (File(file.filePath).existsSync()) {
      return Center(
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
              Icons.play_circle_outline,
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
            'Video preview not available',
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Open" to play the video in your default video player',
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
            'Uploaded: ${PhilippineTime.formatChatHistoryTime(file.uploadedAt.toIso8601String())}',
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
      // For now, show a message about download functionality
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download functionality for ${file.fileName} will be implemented with backend integration'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFileExternally(EvidenceFile file) async {
    try {
      if (file.downloadUrl != null) {
        final uri = Uri.parse(file.downloadUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
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
            content: Text('File URL not available'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
    return widget.complaint.assignedUnit != null ||
           widget.complaint.assignedOfficer != null ||
           widget.complaint.assignedOfficerId != null;
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
          if (widget.complaint.assignedUnit != null) ...[
            _buildInfoRow(
              icon: Icons.security,
              label: 'PNP Unit',
              value: widget.complaint.assignedUnit!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          // Assigned Officer
          if (widget.complaint.assignedOfficer != null) ...[
            _buildInfoRow(
              icon: Icons.person_2,
              label: 'Assigned Officer',
              value: widget.complaint.assignedOfficer!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          // Officer ID
          if (widget.complaint.assignedOfficerId != null) ...[
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Officer ID',
              value: widget.complaint.assignedOfficerId!,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildDynamicFieldsCards(bool isDark) {
    final List<Widget> cards = [];
    
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
    return widget.complaint.estimatedFinancialLoss != null ||
           widget.complaint.accountReference != null;
  }

  bool _hasSuspectFields() {
    return widget.complaint.suspectName != null ||
           widget.complaint.suspectRelationship != null ||
           widget.complaint.suspectContact != null ||
           widget.complaint.suspectDetails != null;
  }

  bool _hasTechnicalFields() {
    return widget.complaint.systemDetails != null ||
           widget.complaint.technicalInfo != null ||
           widget.complaint.vulnerabilityDetails != null ||
           widget.complaint.attackVector != null ||
           widget.complaint.securityLevel != null;
  }

  bool _hasLocationPlatformFields() {
    return widget.complaint.incidentLocation != null ||
           widget.complaint.platformWebsite != null ||
           widget.complaint.targetInfo != null ||
           widget.complaint.contentDescription != null ||
           widget.complaint.impactAssessment != null;
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
          
          if (widget.complaint.estimatedFinancialLoss != null) ...[
            _buildInfoRow(
              icon: Icons.money_off,
              label: 'Financial Loss',
              value: '₱${widget.complaint.estimatedFinancialLoss!.toStringAsFixed(2)}',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.accountReference != null) ...[
            _buildInfoRow(
              icon: Icons.account_balance,
              label: 'Account/Reference',
              value: widget.complaint.accountReference!,
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
          
          if (widget.complaint.suspectName != null) ...[
            _buildInfoRow(
              icon: Icons.person,
              label: 'Suspect Name',
              value: widget.complaint.suspectName!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.suspectRelationship != null) ...[
            _buildInfoRow(
              icon: Icons.family_restroom,
              label: 'Relationship',
              value: widget.complaint.suspectRelationship!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.suspectContact != null) ...[
            _buildInfoRow(
              icon: Icons.contact_phone,
              label: 'Contact Info',
              value: widget.complaint.suspectContact!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.suspectDetails != null) ...[
            _buildInfoRow(
              icon: Icons.info,
              label: 'Additional Details',
              value: widget.complaint.suspectDetails!,
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
          
          if (widget.complaint.systemDetails != null) ...[
            _buildInfoRow(
              icon: Icons.devices,
              label: 'System Details',
              value: widget.complaint.systemDetails!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.technicalInfo != null) ...[
            _buildInfoRow(
              icon: Icons.code,
              label: 'Technical Info',
              value: widget.complaint.technicalInfo!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.vulnerabilityDetails != null) ...[
            _buildInfoRow(
              icon: Icons.security,
              label: 'Vulnerability',
              value: widget.complaint.vulnerabilityDetails!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.attackVector != null) ...[
            _buildInfoRow(
              icon: Icons.gps_fixed,
              label: 'Attack Vector',
              value: widget.complaint.attackVector!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.securityLevel != null) ...[
            _buildInfoRow(
              icon: Icons.verified_user,
              label: 'Security Level',
              value: widget.complaint.securityLevel!,
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
          
          if (widget.complaint.incidentLocation != null) ...[
            _buildInfoRow(
              icon: Icons.place,
              label: 'Incident Location',
              value: widget.complaint.incidentLocation!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.platformWebsite != null) ...[
            _buildInfoRow(
              icon: Icons.web,
              label: 'Platform/Website',
              value: widget.complaint.platformWebsite!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.targetInfo != null) ...[
            _buildInfoRow(
              icon: Icons.my_location,
              label: 'Target Information',
              value: widget.complaint.targetInfo!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.contentDescription != null) ...[
            _buildInfoRow(
              icon: Icons.content_copy,
              label: 'Content Description',
              value: widget.complaint.contentDescription!,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.complaint.impactAssessment != null) ...[
            _buildInfoRow(
              icon: Icons.assessment,
              label: 'Impact Assessment',
              value: widget.complaint.impactAssessment!,
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
    final effectiveRiskScore = widget.complaint.aiRiskScore ?? widget.complaint.riskScore;
    final isAiAssessed = widget.complaint.aiRiskScore != null;
    final riskColor = _getRiskColor(effectiveRiskScore);
    final hasHighConfidence = widget.complaint.aiConfidenceScore != null && widget.complaint.aiConfidenceScore! >= 80;
    
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
    return widget.complaint.aiPriority != null ||
           widget.complaint.aiRiskScore != null ||
           widget.complaint.aiConfidenceScore != null ||
           widget.complaint.riskFactors != null ||
           widget.complaint.urgencyIndicators != null ||
           widget.complaint.aiReasoning != null;
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
              if (widget.complaint.lastAiAssessment != null)
                Text(
                  'Updated ${_formatTimeAgo(widget.complaint.lastAiAssessment!)}',
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
              if (widget.complaint.aiPriority != null) ...[
                Expanded(
                  child: _buildAiMetricCard(
                    title: 'AI Priority',
                    value: widget.complaint.aiPriority!.toUpperCase(),
                    color: _getPriorityColor(widget.complaint.aiPriority!),
                    icon: Icons.priority_high,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // AI Risk Score
              if (widget.complaint.aiRiskScore != null) ...[
                Expanded(
                  child: _buildAiMetricCard(
                    title: 'Risk Score',
                    value: '${widget.complaint.aiRiskScore}%',
                    color: _getRiskColor(widget.complaint.aiRiskScore!),
                    icon: Icons.trending_up,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              
              // AI Confidence
              if (widget.complaint.aiConfidenceScore != null) ...[
                Expanded(
                  child: _buildAiMetricCard(
                    title: 'Confidence',
                    value: '${widget.complaint.aiConfidenceScore}%',
                    color: _getConfidenceColor(widget.complaint.aiConfidenceScore!),
                    icon: Icons.verified,
                    isDark: isDark,
                  ),
                ),
              ],
            ],
          ),
          
          // Risk Factors
          if (widget.complaint.riskFactors != null && widget.complaint.riskFactors!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildRiskFactorsSection(isDark),
          ],
          
          // Urgency Indicators
          if (widget.complaint.urgencyIndicators != null && widget.complaint.urgencyIndicators!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildUrgencyIndicatorsSection(isDark),
          ],
          
          // AI Reasoning
          if (widget.complaint.aiReasoning != null && widget.complaint.aiReasoning!.isNotEmpty) ...[
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
    List<String> factors = widget.complaint.riskFactors;
    
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
    List<String> indicators = widget.complaint.urgencyIndicators;
    
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
            widget.complaint.aiReasoning!,
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
}