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
    final priorityColor = _getPriorityColor(widget.complaint.priority);
    
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
                    Icon(
                      _getPriorityIcon(widget.complaint.priority),
                      size: 12,
                      color: priorityColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.complaint.priority.toUpperCase(),
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
              // Risk Score
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.analytics,
                      size: 14,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Risk: ${widget.complaint.riskScore}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
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
}