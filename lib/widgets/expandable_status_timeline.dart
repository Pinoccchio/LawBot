import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import '../utils/philippine_time.dart';

/// Expandable widget that shows status timeline for a complaint
/// Lazy loads status history when expanded to maintain performance
class ExpandableStatusTimeline extends StatefulWidget {
  final Complaint complaint;
  final bool isDarkMode;

  const ExpandableStatusTimeline({
    super.key,
    required this.complaint,
    required this.isDarkMode,
  });

  @override
  State<ExpandableStatusTimeline> createState() => _ExpandableStatusTimelineState();
}

class _ExpandableStatusTimelineState extends State<ExpandableStatusTimeline> {
  final ComplaintService _complaintService = ComplaintService();
  bool _isExpanded = false;
  bool _isLoading = false;
  List<StatusUpdate> _statusHistory = [];
  String? _loadError;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      color: widget.isDarkMode ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            Icons.timeline,
            color: widget.isDarkMode ? Colors.white70 : const Color(0xFF64748B),
            size: 20,
          ),
          title: Text(
            'Status Timeline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: widget.isDarkMode ? Colors.white : const Color(0xFF374151),
            ),
          ),
          subtitle: Text(
            _isExpanded ? 
              (_statusHistory.isEmpty ? 'No status updates' : '${_statusHistory.length} updates') :
              'Tap to view status history',
            style: TextStyle(
              fontSize: 12,
              color: widget.isDarkMode ? Colors.white60 : const Color(0xFF6B7280),
            ),
          ),
          onExpansionChanged: _onExpansionChanged,
          children: [
            _buildTimelineContent(),
          ],
        ),
      ),
    );
  }

  void _onExpansionChanged(bool expanded) {
    setState(() {
      _isExpanded = expanded;
    });

    if (expanded && _statusHistory.isEmpty && !_isLoading) {
      _loadStatusHistory();
    }
  }

  Future<void> _loadStatusHistory() async {
    final complaintId = widget.complaint.id;
    final complaintNumber = widget.complaint.complaintNumber;
    
    print('🔄 [ExpandableTimeline] Starting to load status history');
    print('📊 [ExpandableTimeline] Complaint ID: $complaintId');
    print('📊 [ExpandableTimeline] Complaint Number: $complaintNumber');
    
    if (complaintId == null) {
      print('❌ [ExpandableTimeline] Complaint ID is null');
      setState(() {
        _loadError = 'Complaint ID not available';
      });
      return;
    }
    
    if (complaintId.isEmpty) {
      print('❌ [ExpandableTimeline] Complaint ID is empty');
      setState(() {
        _loadError = 'Complaint ID is empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      print('🔄 [ExpandableTimeline] Calling loadComplaintStatusHistory with ID: $complaintId');
      final statusHistory = await _complaintService.loadComplaintStatusHistory(complaintId);
      
      print('📊 [ExpandableTimeline] Received ${statusHistory.length} status updates');
      
      setState(() {
        _statusHistory = statusHistory;
        _isLoading = false;
      });
      
      if (statusHistory.isNotEmpty) {
        print('✅ [ExpandableTimeline] Successfully loaded status history');
      } else {
        print('⚠️ [ExpandableTimeline] Status history is empty');
      }
    } catch (e) {
      print('❌ [ExpandableTimeline] Error loading status history: $e');
      print('❌ [ExpandableTimeline] Error type: ${e.runtimeType}');
      setState(() {
        _loadError = 'Failed to load status history: $e';
        _isLoading = false;
      });
    }
  }

  Widget _buildTimelineContent() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: _buildTimelineItems(),
    );
  }

  Widget _buildTimelineItems() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadStatusHistory,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_statusHistory.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.timeline,
                color: widget.isDarkMode ? Colors.white60 : const Color(0xFF9CA3AF),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'No status history available',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white60 : const Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _statusHistory.asMap().entries.map((entry) {
        final index = entry.key;
        final statusUpdate = entry.value;
        final isLast = index == _statusHistory.length - 1;
        
        return _buildTimelineItem(statusUpdate, isLast);
      }).toList(),
    );
  }

  Widget _buildTimelineItem(StatusUpdate statusUpdate, bool isLast) {
    final statusColor = _getStatusColor(statusUpdate.status);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.isDarkMode ? const Color(0xFF374151) : Colors.white,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: widget.isDarkMode ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
              ),
          ],
        ),
        
        const SizedBox(width: 16),
        
        // Status content
        Expanded(
          child: Container(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and timestamp
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusUpdate.status.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      PhilippineTime.getSpecificTimeString(statusUpdate.timestamp),
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white60 : const Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Updated by
                Text(
                  'Updated by: ${statusUpdate.updatedBy}',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : const Color(0xFF374151),
                    fontSize: 12,
                  ),
                ),
                
                // Remarks (if any)
                if (statusUpdate.remarks != null && statusUpdate.remarks!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    statusUpdate.remarks!,
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white60 : const Color(0xFF6B7280),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ComplaintStatus status) {
    switch (status) {
      case ComplaintStatus.pending:
        return const Color(0xFFF59E0B); // Amber
      case ComplaintStatus.underInvestigation:
        return const Color(0xFF3B82F6); // Blue
      case ComplaintStatus.requiresMoreInfo:
        return const Color(0xFF8B5CF6); // Purple
      case ComplaintStatus.resolved:
        return const Color(0xFF10B981); // Emerald
      case ComplaintStatus.dismissed:
        return const Color(0xFF6B7280); // Gray
    }
  }
}