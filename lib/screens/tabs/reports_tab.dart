import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';
import '../../models/complaint_model.dart';
import '../dynamic_complaint_form_screen.dart';
import '../report_detail_screen.dart';

class ReportsTab extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const ReportsTab({super.key, this.onNavigateToTab});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  final DatabaseService _databaseService = DatabaseService();
  
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadComplaints(showLoading: false);
      }
    });
  }

  Future<void> _loadComplaints({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Check current user
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _complaints = [];
        });
        return;
      }

      // Load active complaints from database
      final complaintData = await _databaseService.getUserActiveComplaints();
      
      // Convert database data to Complaint objects
      _complaints = complaintData.map((data) => _complaintFromDatabaseMap(data)).toList();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      print('Error loading complaints: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Fallback to sample data for development
          _complaints = _createSampleComplaints();
        });
      }
    }
  }

  // Convert database map to Complaint object
  Complaint _complaintFromDatabaseMap(Map<String, dynamic> data) {
    try {
      // Parse evidence files
      final evidenceFiles = <EvidenceFile>[];
      if (data['evidence_files'] != null) {
        for (final evidenceData in data['evidence_files'] as List) {
          evidenceFiles.add(EvidenceFile(
            id: evidenceData['id'],
            fileName: evidenceData['file_name'],
            filePath: evidenceData['file_path'] ?? '',
            fileType: evidenceData['file_type'],
            fileSize: evidenceData['file_size'],
            uploadedAt: DateTime.parse(evidenceData['created_at']),
            downloadUrl: evidenceData['download_url'],
          ));
        }
      }

      // Parse assigned officer info
      String? assignedOfficer;
      if (data['case_assignments'] != null && 
          (data['case_assignments'] as List).isNotEmpty) {
        final assignment = (data['case_assignments'] as List).first;
        if (assignment['pnp_officer_profiles'] != null) {
          final officer = assignment['pnp_officer_profiles'];
          assignedOfficer = '${officer['rank']} ${officer['full_name']} (${officer['badge_number']})';
        }
      }

      // Parse status history
      final statusHistory = <StatusUpdate>[];
      // Note: Status history would need to be loaded separately if needed

      return Complaint(
        id: data['id'],
        userId: data['user_id'],
        crimeType: CrimeType.values.firstWhere(
          (e) => e.name == data['crime_type'],
          orElse: () => CrimeType.phishing,
        ),
        description: data['description'],
        evidenceFiles: evidenceFiles,
        fullName: data['full_name'],
        email: data['email'],
        phoneNumber: data['phone_number'],
        incidentDateTime: DateTime.parse(data['incident_date_time']),
        incidentLocation: data['incident_location'],
        estimatedFinancialLoss: data['estimated_loss']?.toDouble(),
        status: ComplaintStatus.values.firstWhere(
          (e) => e.displayName == data['status'],
          orElse: () => ComplaintStatus.pending,
        ),
        createdAt: DateTime.parse(data['created_at']),
        updatedAt: DateTime.parse(data['updated_at']),
        complaintNumber: data['complaint_number'],
        assignedOfficer: assignedOfficer,
        remarks: data['remarks'],
        statusHistory: statusHistory,
      );
    } catch (e) {
      print('Error converting database data to Complaint: $e');
      // Return a basic complaint object as fallback
      return Complaint(
        id: data['id'] ?? 'unknown',
        userId: data['user_id'] ?? '',
        crimeType: CrimeType.phishing,
        description: data['description'] ?? 'Unable to load description',
        fullName: data['full_name'] ?? 'Unknown',
        email: data['email'] ?? '',
        phoneNumber: data['phone_number'] ?? '',
        incidentDateTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Fallback sample data for development/testing
  List<Complaint> _createSampleComplaints() {
    final now = DateTime.now();
    return [
      Complaint(
        id: '1',
        userId: 'user1',
        crimeType: CrimeType.onlineHarassment,
        description: 'I am being harassed on social media platforms with threatening messages and fake accounts being created to spread false information about me.',
        fullName: 'Carlos Mendoza',
        email: 'carlos.mendoza@email.com',
        phoneNumber: '+63 917 555 1234',
        incidentDateTime: now.subtract(const Duration(days: 3)),
        status: ComplaintStatus.underInvestigation,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        complaintNumber: 'CYB-2024-001',
        evidenceFiles: [
          EvidenceFile(
            id: '1',
            fileName: 'harassment_screenshot.png',
            filePath: '/screenshots/harassment.png',
            fileType: 'png',
            fileSize: 245760,
            uploadedAt: now.subtract(const Duration(days: 2)),
          )
        ],
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 2)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.underInvestigation,
            timestamp: now.subtract(const Duration(hours: 4)),
            updatedBy: 'Officer Santos',
            remarks: 'Assigned to investigation team',
          ),
        ],
      ),
      Complaint(
        id: '2',
        userId: 'user1',
        crimeType: CrimeType.onlineShoppingScams,
        description: 'I paid for a product online but never received it. The seller has stopped responding to messages.',
        fullName: 'Rosa Valencia',
        email: 'rosa.valencia@email.com',
        phoneNumber: '+63 928 777 9999',
        incidentDateTime: now.subtract(const Duration(days: 1)),
        status: ComplaintStatus.pending,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        complaintNumber: 'CYB-2024-002',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(hours: 6)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
        ],
      ),
      Complaint(
        id: '3',
        userId: 'user1',
        crimeType: CrimeType.onlineImpersonation,
        description: 'Someone has created fake accounts using my personal information and photos to impersonate me on various social media platforms.',
        fullName: 'Miguel Torres',
        email: 'miguel.torres@email.com',
        phoneNumber: '+63 935 888 7777',
        incidentDateTime: now.subtract(const Duration(days: 12)),
        status: ComplaintStatus.underInvestigation,
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 1)),
        complaintNumber: 'CYB-2024-003',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 10)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.underInvestigation,
            timestamp: now.subtract(const Duration(days: 1)),
            updatedBy: 'Officer Cruz',
            remarks: 'Investigation started - gathering evidence of fake accounts',
          ),
        ],
      ),
      Complaint(
        id: '4',
        userId: 'user1',
        crimeType: CrimeType.phishing,
        description: 'I received suspicious emails claiming to be from my bank asking for my account details and passwords.',
        fullName: 'Elena Ramirez',
        email: 'elena.ramirez@email.com',
        phoneNumber: '+63 922 333 4444',
        incidentDateTime: now.subtract(const Duration(hours: 18)),
        status: ComplaintStatus.pending,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now.subtract(const Duration(hours: 12)),
        complaintNumber: 'CYB-2024-004',
        evidenceFiles: [
          EvidenceFile(
            id: '4',
            fileName: 'phishing_email.pdf',
            filePath: '/evidence/phishing_email.pdf',
            fileType: 'pdf',
            fileSize: 156780,
            uploadedAt: now.subtract(const Duration(hours: 12)),
          )
        ],
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(hours: 12)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
        ],
      ),
      Complaint(
        id: '5',
        userId: 'user1',
        crimeType: CrimeType.socialEngineering,
        description: 'I was deceived by someone I met on a dating app who asked for money after building a romantic relationship.',
        fullName: 'Diana Lopez',
        email: 'diana.lopez@email.com',
        phoneNumber: '+63 918 666 5555',
        incidentDateTime: now.subtract(const Duration(days: 7)),
        status: ComplaintStatus.requiresMoreInfo,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 3)),
        complaintNumber: 'CYB-2024-005',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 5)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.requiresMoreInfo,
            timestamp: now.subtract(const Duration(days: 3)),
            updatedBy: 'Officer Reyes',
            remarks: 'Additional communication records needed for investigation',
          ),
        ],
      ),
    ];
  }

  List<Complaint> get filteredComplaints {
    if (_selectedFilter == 'All') {
      return _complaints;
    } else if (_selectedFilter == 'Pending') {
      return _complaints.where((c) => c.status == ComplaintStatus.pending).toList();
    } else if (_selectedFilter == 'Under Investigation') {
      return _complaints.where((c) => c.status == ComplaintStatus.underInvestigation).toList();
    } else if (_selectedFilter == 'Requires More Info') {
      return _complaints.where((c) => c.status == ComplaintStatus.requiresMoreInfo).toList();
    }
    return _complaints;
  }

  List<String> get filterOptions => ['All', 'Pending', 'Under Investigation', 'Requires More Info'];

  void _navigateToNewComplaint() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DynamicComplaintFormScreen(),
      ),
    );
    
    if (result == true) {
      _loadComplaints();
    }
  }

  void _navigateToComplaintDetail(Complaint complaint) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(complaint: complaint),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                      : [const Color(0xFF2563EB), const Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB)).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.report_problem_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2563EB),
                    ),
                  ),
                  Text(
                    'Current PNP Cybercrime Cases',
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
        actions: [
          TextButton.icon(
            onPressed: () {
              // Navigate to History tab (completed reports)
              if (widget.onNavigateToTab != null) {
                widget.onNavigateToTab!(2); // History tab index
              }
            },
            icon: Icon(
              Icons.history,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            label: Text(
              'History',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF2563EB),
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            onPressed: () => _loadComplaints(),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading reports...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadComplaints,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: '${_complaints.length}',
                            subtitle: 'Total Reports',
                            icon: Icons.report_outlined,
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: '${_complaints.where((c) => c.status == ComplaintStatus.pending).length}',
                            subtitle: 'Pending',
                            icon: Icons.hourglass_empty,
                            color: Colors.orange,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            context,
                            title: '${_complaints.where((c) => c.status == ComplaintStatus.underInvestigation).length}',
                            subtitle: 'Investigating',
                            icon: Icons.search,
                            color: Colors.purple,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Section
                  if (filterOptions.length > 1) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Filter by Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filterOptions.length,
                        itemBuilder: (context, index) {
                          final option = filterOptions[index];
                          final isSelected = option == _selectedFilter;
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(option),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = option;
                                });
                              },
                              backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey[100],
                              selectedColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isDark ? Colors.grey[300] : Colors.grey[700],
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Reports List
                  Expanded(
                    child: filteredComplaints.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredComplaints.length,
                            itemBuilder: (context, index) {
                              final complaint = filteredComplaints[index];
                              return _buildComplaintCard(context, complaint, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToNewComplaint,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Complaint'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint, bool isDark) {
    final statusColor = _getStatusColor(complaint.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToComplaintDetail(complaint),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        complaint.crimeTypeDisplay,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            complaint.statusDisplay,
                            style: TextStyle(
                              fontSize: 10,
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
                if (complaint.complaintNumber != null) ...[
                  Text(
                    'Complaint #${complaint.complaintNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Description
                Text(
                  complaint.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 16),
                
                // Footer Row
                Row(
                  children: [
                    if (complaint.hasEvidence) ...[
                      Icon(
                        Icons.attach_file,
                        size: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.evidenceFiles.length} file${complaint.evidenceFiles.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      PhilippineTime.formatChatHistoryTime(complaint.createdAt.toIso8601String()),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF374151), const Color(0xFF1F2937)]
                    : [const Color(0xFFF3F4F6), const Color(0xFFE5E7EB)],
              ),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.report_problem_outlined,
              size: 48,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _complaints.isEmpty
                ? 'No reports yet'
                : 'No reports match your filter',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _complaints.isEmpty
                ? 'Submit your first cybercrime report to get started'
                : 'Try selecting a different status filter',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (_complaints.isEmpty) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToNewComplaint,
              icon: const Icon(Icons.add),
              label: const Text('Submit Report'),
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
          ],
        ],
      ),
    );
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
}