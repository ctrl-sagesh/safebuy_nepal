import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Notification types used throughout the app.
enum NotifType { report, response, scoreChange, digest, system }

class NotificationItem {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;
  final String? routeTo;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
    this.routeTo,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _activeFilter = 0;
  final _filters = ['All', 'Reports', 'Reviews', 'System'];

  // Demo data — in production this comes from Firestore
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: NotifType.report,
      title: 'New report filed',
      body: 'A buyer reported seller @quickbuy_np for non-delivery.',
      time: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationItem(
      id: '2',
      type: NotifType.response,
      title: 'Seller responded',
      body: 'The seller has provided a response to report #RPT-2026-048.',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      read: true,
    ),
    NotificationItem(
      id: '3',
      type: NotifType.scoreChange,
      title: 'Trust score updated',
      body: 'Seller @nepal_fashion\'s score changed from 72 to 68 after a new report.',
      time: DateTime.now().subtract(const Duration(hours: 8)),
      read: true,
    ),
    NotificationItem(
      id: '4',
      type: NotifType.digest,
      title: 'Weekly trust digest',
      body: 'Your weekly trust summary is ready. 3 new reports, 12 sellers verified this week.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      read: true,
    ),
    NotificationItem(
      id: '5',
      type: NotifType.system,
      title: 'Welcome to SafeBuy Nepal!',
      body: 'Thank you for joining the community. Start by verifying a seller before your next purchase.',
      time: DateTime.now().subtract(const Duration(days: 3)),
      read: true,
    ),
  ];

  List<NotificationItem> get _filtered {
    if (_activeFilter == 0) return _notifications;
    switch (_activeFilter) {
      case 1:
        return _notifications
            .where((n) => n.type == NotifType.report || n.type == NotifType.response)
            .toList();
      case 2:
        return _notifications
            .where((n) => n.type == NotifType.scoreChange)
            .toList();
      case 3:
        return _notifications
            .where((n) => n.type == NotifType.digest || n.type == NotifType.system)
            .toList();
      default:
        return _notifications;
    }
  }

  void _markAllRead() {
    HapticFeedback.lightImpact();
    setState(() {
      for (var i = 0; i < _notifications.length; i++) {
        _notifications[i] = NotificationItem(
          id: _notifications[i].id,
          type: _notifications[i].type,
          title: _notifications[i].title,
          body: _notifications[i].body,
          time: _notifications[i].time,
          read: true,
          routeTo: _notifications[i].routeTo,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.read).length;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          'Notifications',
          style: AppTextStyles.headlineSmall(),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Mark all read',
                style: AppTextStyles.labelMedium()
                    .copyWith(color: AppColors.primary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: AppColors.bgPrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: List.generate(_filters.length, (i) {
                final active = i == _activeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_filters[i]),
                    selected: active,
                    onSelected: (_) => setState(() => _activeFilter = i),
                    selectedColor: AppColors.primary.withValues(alpha: 0.1),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: active ? AppColors.primary : AppColors.textSecondary,
                    ),
                    side: BorderSide(
                      color: active ? AppColors.primary : AppColors.borderLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Notification list
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _NotifCard(
                      item: _filtered[i],
                      index: i,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.borderMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: AppTextStyles.headlineSmall()
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'You\'ll be notified about seller updates and responses to your reports.',
              style: AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.item, required this.index});
  final NotificationItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: item.read ? AppColors.bgCard : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.read ? AppColors.borderLight : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          // In production: navigate to relevant screen
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconData, size: 20, color: _iconColor),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTextStyles.titleSmall().copyWith(
                              fontWeight: item.read ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.read)
                          Container(
                            width: 8, height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: AppTextStyles.bodySmall(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(item.time),
                      style: AppTextStyles.labelSmall(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 60), duration: 250.ms)
        .slideX(begin: 0.05, end: 0);
  }

  IconData get _iconData => switch (item.type) {
        NotifType.report => Icons.warning_rounded,
        NotifType.response => Icons.chat_rounded,
        NotifType.scoreChange => Icons.star_rounded,
        NotifType.digest => Icons.bar_chart_rounded,
        NotifType.system => Icons.info_outline_rounded,
      };

  Color get _iconColor => switch (item.type) {
        NotifType.report => AppColors.highRisk,
        NotifType.response => AppColors.primary,
        NotifType.scoreChange => AppColors.unverified,
        NotifType.digest => AppColors.trusted,
        NotifType.system => AppColors.accentCyan,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
