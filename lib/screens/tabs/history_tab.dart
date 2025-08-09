import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/database_service.dart';
import '../../utils/philippine_time.dart';
import '../../models/complaint_model.dart';
import '../../widgets/expandable_status_timeline.dart';
import '../report_detail_screen.dart';
import 'dart:async';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  final DatabaseService _databaseService = DatabaseService();
  List<Complaint> _completedReports = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCompletedReports();
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
        _loadCompletedReports(showLoading: false);
      }
    });
  }

  Future<void> _loadCompletedReports({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Load completed complaints from database
      final complaintData = await _databaseService.getUserCompletedComplaints();
      
      // Convert database data to Complaint objects
      _completedReports = complaintData.map((data) => _complaintFromDatabaseMap(data)).toList();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      print('Error loading completed reports: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Fallback to sample data for development
          _completedReports = _createSampleCompletedReports();
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
          orElse: () => ComplaintStatus.resolved,
        ),
        createdAt: DateTime.parse(data['created_at']),
        updatedAt: DateTime.parse(data['updated_at']),
        complaintNumber: data['complaint_number'],
        assignedOfficer: assignedOfficer,
        remarks: data['remarks'],
        statusHistory: [], // Status history would be loaded separately if needed
        // Citizen update fields for complaint editing
        lastCitizenUpdate: data['last_citizen_update'] != null 
            ? DateTime.parse(data['last_citizen_update']) 
            : null,
        updateRequestMessage: data['update_request_message'],
        totalUpdates: data['total_updates'] ?? 0,
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
        status: ComplaintStatus.resolved,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Fallback sample data for development/testing
  List<Complaint> _createSampleCompletedReports() {
    final now = DateTime.now();
    return [
      Complaint(
        id: 'hist1',
        userId: 'user1',
        crimeType: CrimeType.onlineHarassment,
        description: 'Received threatening messages on social media platforms with fake accounts spreading false information about me.',
        fullName: 'Maria Santos',
        email: 'maria.santos@email.com',
        phoneNumber: '+63 917 123 4567',
        incidentDateTime: now.subtract(const Duration(days: 31)),
        status: ComplaintStatus.resolved,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 25)),
        complaintNumber: 'CYB-2023-078',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 30)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.resolved,
            timestamp: now.subtract(const Duration(days: 25)),
            updatedBy: 'Officer Martinez - Cyber Crime Against Women and Children',
            remarks: 'Case resolved - suspect identified and warned, accounts suspended',
          ),
        ],
      ),
      Complaint(
        id: 'hist2',
        userId: 'user1',
        crimeType: CrimeType.onlineShoppingScams,
        description: 'Scammed by fake online seller - never received purchased items worth ₱15,000 despite payment confirmation.',
        fullName: 'Juan dela Cruz',
        email: 'juan.delacruz@email.com',
        phoneNumber: '+63 928 987 6543',
        incidentDateTime: now.subtract(const Duration(days: 46)),
        status: ComplaintStatus.resolved,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 40)),
        complaintNumber: 'CYB-2023-052',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 45)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.resolved,
            timestamp: now.subtract(const Duration(days: 40)),
            updatedBy: 'Officer Santos - Economic Offenses Wing',
            remarks: 'Full refund processed through platform mediation and escrow release',
          ),
        ],
      ),
      Complaint(
        id: 'hist3',
        userId: 'user1',
        crimeType: CrimeType.phishing,
        description: 'Received fake bank emails requesting account information and OTP codes claiming account suspension.',
        fullName: 'Ana Rodriguez',
        email: 'ana.rodriguez@email.com',
        phoneNumber: '+63 935 555 1234',
        incidentDateTime: now.subtract(const Duration(days: 61)),
        status: ComplaintStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 55)),
        complaintNumber: 'CYB-2023-033',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 60)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.dismissed,
            timestamp: now.subtract(const Duration(days: 55)),
            updatedBy: 'Officer Cruz - Cyber Crime Investigation Cell',
            remarks: 'General phishing attempt - no specific target identified, no financial loss incurred',
          ),
        ],
      ),
      Complaint(
        id: 'hist4',
        userId: 'user1',
        crimeType: CrimeType.identityTheft,
        description: 'Someone used my identity to open unauthorized bank accounts and credit cards, causing financial damage.',
        fullName: 'Roberto Garcia',
        email: 'roberto.garcia@email.com',
        phoneNumber: '+63 922 777 8888',
        incidentDateTime: now.subtract(const Duration(days: 91)),
        status: ComplaintStatus.resolved,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 75)),
        complaintNumber: 'CYB-2023-001',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 90)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.underInvestigation,
            timestamp: now.subtract(const Duration(days: 85)),
            updatedBy: 'Officer Reyes - Cyber Security Division',
            remarks: 'Investigation started - banks contacted for account verification and fraud alerts',
          ),
          StatusUpdate(
            status: ComplaintStatus.resolved,
            timestamp: now.subtract(const Duration(days: 75)),
            updatedBy: 'Officer Reyes - Cyber Security Division',
            remarks: 'Identity theft case resolved - fraudulent accounts closed, credit restored, suspect arrested',
          ),
        ],
      ),
      Complaint(
        id: 'hist5',
        userId: 'user1',
        crimeType: CrimeType.cyberbullying,
        description: 'Persistent online harassment and bullying through multiple social media platforms affecting mental health.',
        fullName: 'Lisa Fernandez',
        email: 'lisa.fernandez@email.com',
        phoneNumber: '+63 918 444 2222',
        incidentDateTime: now.subtract(const Duration(days: 121)),
        status: ComplaintStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now.subtract(const Duration(days: 110)),
        complaintNumber: 'CYB-2022-089',
        statusHistory: [
          StatusUpdate(
            status: ComplaintStatus.pending,
            timestamp: now.subtract(const Duration(days: 120)),
            updatedBy: 'System',
            remarks: 'Complaint submitted successfully',
          ),
          StatusUpdate(
            status: ComplaintStatus.dismissed,
            timestamp: now.subtract(const Duration(days: 110)),
            updatedBy: 'Officer Luna - Cyber Crime Against Women and Children',
            remarks: 'Insufficient evidence to pursue criminal charges - referred to civil remedies',
          ),
        ],
      ),
    ];
  }

  List<Complaint> get filteredReports {
    if (_selectedFilter == 'All') {
      return _completedReports;
    } else if (_selectedFilter == 'Resolved') {
      return _completedReports.where((report) => report.status == ComplaintStatus.resolved).toList();
    } else if (_selectedFilter == 'Dismissed') {
      return _completedReports.where((report) => report.status == ComplaintStatus.dismissed).toList();
    }
    return _completedReports;
  }

  List<String> get filterOptions {
    return ['All', 'Resolved', 'Dismissed'];
  }

  void _showReportDetail(Complaint report) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportDetailScreen(complaint: report),
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
                Icons.history_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Report History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? Colors.white : const Color(0xFF2563EB),
            ),
            onPressed: () => _loadCompletedReports(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCompletedReports,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Cards
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildOverviewCard(
                            context,
                            icon: Icons.history_outlined,
                            title: '${_completedReports.length}',
                            subtitle: 'Total Completed',
                            color: Colors.blue,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewCard(
                            context,
                            icon: Icons.check_circle_outline,
                            title: '${_completedReports.where((r) => r.status == ComplaintStatus.resolved).length}',
                            subtitle: 'Resolved',
                            color: Colors.green,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOverviewCard(
                            context,
                            icon: Icons.cancel_outlined,
                            title: '${_completedReports.where((r) => r.status == ComplaintStatus.dismissed).length}',
                            subtitle: 'Dismissed',
                            color: Colors.orange,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),


                  // Filter Chips
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

                  // Completed Reports List
                  Expanded(
                    child: filteredReports.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredReports.length,
                            itemBuilder: (context, index) {
                              final report = filteredReports[index];
                              return _buildComplaintCard(context, report, isDark);
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewCard(
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
          onTap: () => _showReportDetail(complaint),
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
                
                const SizedBox(height: 12),
                
                // Expandable Status Timeline
                ExpandableStatusTimeline(
                  complaint: complaint,
                  isDarkMode: isDark,
                ),
                
                const SizedBox(height: 12),
                
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
              Icons.history_outlined,
              size: 48,
              color: isDark ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _completedReports.isEmpty
                ? 'No completed reports yet'
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
            _completedReports.isEmpty
                ? 'Completed cybercrime reports will appear here once resolved or dismissed'
                : 'Try selecting a different status filter',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
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