import 'package:flutter/material.dart';
import '../services/complaint_service.dart';
import '../models/complaint_model.dart';
import 'report_detail_screen.dart';

/// Wrapper screen that loads a complaint by ID and shows ReportDetailScreen
class ReportDetailByIdScreen extends StatefulWidget {
  final String complaintId;

  const ReportDetailByIdScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<ReportDetailByIdScreen> createState() => _ReportDetailByIdScreenState();
}

class _ReportDetailByIdScreenState extends State<ReportDetailByIdScreen> {
  final ComplaintService _complaintService = ComplaintService();
  Complaint? _complaint;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadComplaint();
  }

  Future<void> _loadComplaint() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔍 Loading complaint with ID: ${widget.complaintId}');
      
      final complaint = await _complaintService.getComplaintWithDetails(widget.complaintId);
      
      if (complaint != null) {
        setState(() {
          _complaint = complaint;
          _isLoading = false;
        });
        print('✅ Successfully loaded complaint: ${complaint.complaintNumber}');
      } else {
        setState(() {
          _errorMessage = 'Complaint not found or you don\'t have permission to view it';
          _isLoading = false;
        });
        print('❌ Complaint not found: ${widget.complaintId}');
      }
    } catch (e) {
      print('❌ Error loading complaint: $e');
      setState(() {
        _errorMessage = 'Error loading complaint: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Complaint...'),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              ),
              SizedBox(height: 16),
              Text(
                'Loading complaint details...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to Load Complaint',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadComplaint,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // If we have the complaint data, show the actual detail screen
    if (_complaint != null) {
      return ReportDetailScreen(complaint: _complaint!);
    }

    // Fallback (shouldn't happen)
    return const Scaffold(
      body: Center(
        child: Text('Something went wrong'),
      ),
    );
  }
}