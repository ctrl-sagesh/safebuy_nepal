import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Notification categories used for the icon/colour and the filter tabs.
enum NotifType { report, response, scoreChange, digest, system }

NotifType _typeFromString(String? raw) {
  switch (raw) {
    case 'fraud_alert':
    case 'report':
      return NotifType.report;
    case 'response':
    case 'seller_response':
      return NotifType.response;
    case 'score_change':
    case 'scoreChange':
      return NotifType.scoreChange;
    case 'digest':
    case 'weekly_digest':
      return NotifType.digest;
    default:
      return NotifType.system;
  }
}

class NotificationItem {
  final String id;
  final NotifType type;
  final String title;
  final String body;
  final DateTime time;
  final bool read;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.time,
    this.read = false,
  });

  factory NotificationItem.fromDoc(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    final ts = d['createdAt'];
    return NotificationItem(
      id: doc.id,
      type: _typeFromString(d['type'] as String?),
      title: d['title'] as String? ?? 'Notification',
      body: d['body'] as String? ?? '',
      time: ts is Timestamp ? ts.toDate() : DateTime.now(),
      read: (d['read'] as bool?) ?? (d['isRead'] as bool?) ?? false,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _activeFilter = 0;
  final _filters = ['All', 'Reports', 'Alerts', 'System'];

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('notifications');

  List<NotificationItem> _applyFilter(List<NotificationItem> all) {
    switch (_activeFilter) {
      case 1:
        return all
            .where((n) =>
                n.type == NotifType.report || n.type == NotifType.response)
            .toList();
      case 2:
        return all
            .where((n) =>
                n.type == NotifType.scoreChange || n.type == NotifType.digest)
            .toList();
      case 3:
        return all.where((n) => n.type == NotifType.system).toList();
      default:
        return all;
    }
  }

  Future<void> _markRead(String id) async {
    try {
      await _col.doc(id).update({'read': true, 'isRead': true});
    } catch (_) {}
  }

  Future<void> _markAllRead(List<NotificationItem> items) async {
    HapticFeedback.lightImpact();
    final batch = FirebaseFirestore.instance.batch();
    for (final n in items.where((n) => !n.read)) {
      batch.update(_col.doc(n.id), {'read': true, 'isRead': true});
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  Future<void> _dismiss(String id) async {
    try {
      await _col.doc(id).delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;

    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text('Notifications', style: AppTextStyles.headlineSmall()),
      ),
      body: uid == null
          ? _signedOutState()
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _col
                  .where('userId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary));
                }
                final all = (snap.data?.docs ?? [])
                    .map(NotificationItem.fromDoc)
                    .toList()
                  ..sort((a, b) => b.time.compareTo(a.time));
                final unread = all.where((n) => !n.read).length;
                final filtered = _applyFilter(all);

                return Column(
                  children: [
                    _filterBar(unread, all),
                    Expanded(
                      child: filtered.isEmpty
                          ? _emptyState()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) => Dismissible(
                                key: ValueKey(filtered[i].id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _dismiss(filtered[i].id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.highRiskBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded,
                                      color: AppColors.highRisk),
                                ),
                                child: _NotifCard(
                                  item: filtered[i],
                                  index: i,
                                  onTap: () => _markRead(filtered[i].id),
                                ),
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _filterBar(int unread, List<NotificationItem> all) {
    return Container(
      color: AppColors.bgPrimary,
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        color: active
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                      side: BorderSide(
                        color:
                            active ? AppColors.primary : AppColors.borderLight,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          if (unread > 0)
            TextButton(
              onPressed: () => _markAllRead(all),
              child: Text('Mark all read',
                  style: AppTextStyles.labelMedium()
                      .copyWith(color: AppColors.primary)),
            ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 64, color: AppColors.borderMedium),
          const SizedBox(height: 16),
          Text('No notifications yet',
              style: AppTextStyles.headlineSmall()
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'You will be notified about seller updates and responses to '
              'your reports.',
              style: AppTextStyles.bodyMedium(),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _signedOutState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 64, color: AppColors.borderMedium),
          const SizedBox(height: 16),
          Text('Sign in to see notifications',
              style: AppTextStyles.headlineSmall()
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({required this.item, required this.index, this.onTap});
  final NotificationItem item;
  final int index;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: item.read
            ? AppColors.bgCard
            : AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.read
              ? AppColors.borderLight
              : AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.title,
                              style: AppTextStyles.titleSmall().copyWith(
                                fontWeight: item.read
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              )),
                        ),
                        if (!item.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(item.body,
                        style: AppTextStyles.bodySmall(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Text(_timeAgo(item.time),
                        style: AppTextStyles.labelSmall()),
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
