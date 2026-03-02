import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cache/notification_cache_service.dart';
import 'dart:async';

// ignore_for_file: deprecated_member_use

class NotificationPanel extends StatefulWidget {
  final VoidCallback onClose;

  const NotificationPanel({super.key, required this.onClose});

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  bool _isClearing = false;
  final Set<String> _deletingNotifications = <String>{};
  final NotificationCacheService _cacheService = NotificationCacheService();
  List<NotificationModel>? _cachedNotifications;
  bool _cacheLoaded = false;
  RealtimeChannel? _realtimeChannel;
  StreamController<List<Map<String, dynamic>>>? _notificationStreamController;

  @override
  void initState() {
    super.initState();
    _loadCachedNotifications();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _notificationStreamController?.close();
    super.dispose();
  }

  Future<void> _loadCachedNotifications() async {
    try {
      final cached = await _cacheService.getCachedNotifications();
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() {
          _cachedNotifications = cached;
          _cacheLoaded = true;
        });
      }
    } catch (_) {}
  }

  void _setupRealtimeSubscription() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificationStreamController =
        StreamController<List<Map<String, dynamic>>>.broadcast();

    _realtimeChannel = Supabase.instance.client
        .channel('notifications-panel-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            _fetchAndBroadcastNotifications();
          },
        )
        .subscribe();

    _fetchAndBroadcastNotifications();
  }

  Future<void> _fetchAndBroadcastNotifications() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at_timestamp', ascending: false)
          .limit(50);

      if (_notificationStreamController != null &&
          !_notificationStreamController!.isClosed) {
        _notificationStreamController!.add(response);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.75,
      height: MediaQuery.of(context).size.height * 0.45,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          decoration: TextDecoration.none,
                          fontFamily: 'Unbounded',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        if (_isClearing)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.statusError,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _showClearAllDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.statusError.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color: AppColors.statusError.withOpacity(0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Clear All',
                                style: TextStyle(
                                  decoration: TextDecoration.none,
                                  fontFamily: 'Unbounded',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.statusError,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Notifications List
              Expanded(
                child: Builder(
                  builder: (context) {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;

                    if (userId == null) {
                      return _buildEmptyState(
                        icon: Icons.account_circle_outlined,
                        label: 'Log in to view notifications',
                        color: AppColors.primary,
                      );
                    }

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _notificationStreamController?.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildEmptyState(
                            icon: Icons.error_outline_rounded,
                            label: 'Error loading notifications',
                            color: AppColors.statusError,
                          );
                        }

                        List<NotificationModel>? notifications;

                        if (snapshot.hasData) {
                          final notificationMaps =
                              snapshot.data ?? <Map<String, dynamic>>[];
                          notifications = notificationMaps
                              .map((map) => NotificationModel.fromSupabaseMap(map))
                              .toList()
                              .cast<NotificationModel>();

                          if (notifications.isNotEmpty) {
                            _cacheService.cacheNotifications(notifications);
                          }
                        } else if (_cacheLoaded && _cachedNotifications != null) {
                          notifications = _cachedNotifications;
                        }

                        if (notifications != null) {
                          if (notifications.isEmpty) {
                            return _buildEmptyState(
                              icon: Icons.notifications_none_rounded,
                              label: 'No notifications yet',
                              color: AppColors.primary,
                            );
                          }

                          return ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.black, Colors.transparent],
                                stops: [0.78, 1.0],
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.dstIn,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              physics: const BouncingScrollPhysics(),
                              itemCount: notifications.length,
                              itemBuilder: (context, index) {
                                final notification = notifications![index];
                                final isDeleting = _deletingNotifications
                                    .contains(notification.id);

                                return Dismissible(
                                  key: Key(notification.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 2,
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusError.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Icon(
                                      Icons.delete_sweep_outlined,
                                      color: AppColors.statusError,
                                      size: 22,
                                    ),
                                  ),
                                  confirmDismiss: (direction) async {
                                    return await _deleteNotification(notification.id);
                                  },
                                  child: AnimatedOpacity(
                                    opacity: isDeleting ? 0.4 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: _buildNotificationItem(
                                      notification.title,
                                      notification.message,
                                      _getTimeAgo(notification.createdAt),
                                      _getNotificationIcon(notification.type),
                                      _getNotificationColor(notification.type),
                                      notification.isRead,
                                      () => _markAsRead(notification.id),
                                      isDeleting,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }

                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: color.withOpacity(0.2), width: 1),
            ),
            child: Icon(icon, size: 22, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              decoration: TextDecoration.none,
              fontFamily: 'Unbounded',
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      await _fetchAndBroadcastNotifications();
    } catch (_) {}
  }

  Future<bool> _deleteNotification(String notificationId) async {
    setState(() {
      _deletingNotifications.add(notificationId);
    });

    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      await _cacheService.removeNotificationFromCache(notificationId);
      await _fetchAndBroadcastNotifications();
      return true;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _deletingNotifications.remove(notificationId);
        });
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() => _isClearing = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('user_id', userId);
        await _cacheService.clearCache();
        await _fetchAndBroadcastNotifications();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          title: const Text(
            'Clear All',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          content: Text(
            'Delete all notifications? This cannot be undone.',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: Colors.grey.shade500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllNotifications();
              },
              child: const Text(
                'Clear All',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.statusError,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.shopping_bag_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return AppColors.statusSuccess;
      case 'announcement':
        return AppColors.statusWarning;
      default:
        return AppColors.primary;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildNotificationItem(
    String title,
    String message,
    String time,
    IconData icon,
    Color iconColor,
    bool isRead,
    VoidCallback onTap,
    bool isDeleting,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, color: iconColor, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontFamily: 'Unbounded',
                            fontSize: 10,
                            fontWeight:
                                isRead ? FontWeight.w400 : FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      if (isDeleting)
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.statusError,
                            ),
                          ),
                        )
                      else if (!isRead)
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontFamily: 'Unbounded',
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontFamily: 'Unbounded',
                      fontSize: 8,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
