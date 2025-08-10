import 'package:flutter/material.dart';

/// A reusable notification badge widget that displays unread count
/// Used for showing notification badges on tab bars and other UI elements
class NotificationBadge extends StatelessWidget {
  /// The child widget to display the badge on (usually an Icon)
  final Widget child;
  
  /// The notification count to display (0 = no badge shown)
  final int count;
  
  /// The color of the badge background (default: red)
  final Color? badgeColor;
  
  /// The color of the badge text (default: white)
  final Color? textColor;
  
  /// Custom position offset for the badge
  final Offset? offset;
  
  /// Whether to show animation when count changes
  final bool animated;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.offset,
    this.animated = true,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show badge if count is 0 or negative
    if (count <= 0) {
      return child;
    }

    // Get theme for future use if needed
    final theme = Theme.of(context);
    
    // Default colors based on theme
    final defaultBadgeColor = badgeColor ?? const Color(0xFFFF3B30); // iOS red
    final defaultTextColor = textColor ?? Colors.white;
    
    // Format the display text
    final displayText = count > 99 ? '99+' : count.toString();
    
    // Calculate badge size based on text length
    final isLargeNumber = count > 9;
    final badgeSize = isLargeNumber ? 18.0 : 16.0;
    
    Widget badge = Container(
      constraints: BoxConstraints(
        minWidth: badgeSize,
        minHeight: badgeSize,
      ),
      decoration: BoxDecoration(
        color: defaultBadgeColor,
        borderRadius: BorderRadius.circular(badgeSize / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isLargeNumber ? 6.0 : 4.0,
        vertical: 2.0,
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: defaultTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );

    // Add animation if enabled
    if (animated) {
      badge = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: badge,
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset?.dy ?? -6,
          right: offset?.dx ?? -6,
          child: badge,
        ),
      ],
    );
  }
}

/// A specialized notification badge for bottom navigation bar items
class BottomNavNotificationBadge extends StatelessWidget {
  final Widget child;
  final int count;
  final bool isDark;

  const BottomNavNotificationBadge({
    super.key,
    required this.child,
    required this.count,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      count: count,
      offset: const Offset(-2, -2), // Slightly adjusted for bottom nav
      badgeColor: const Color(0xFFFF3B30),
      child: child,
    );
  }
}

/// Extension to easily add badges to any widget
extension WidgetBadgeExtension on Widget {
  /// Add a notification badge to this widget
  Widget withBadge({
    required int count,
    Color? badgeColor,
    Color? textColor,
    Offset? offset,
    bool animated = true,
  }) {
    return NotificationBadge(
      count: count,
      badgeColor: badgeColor,
      textColor: textColor,
      offset: offset,
      animated: animated,
      child: this,
    );
  }
}