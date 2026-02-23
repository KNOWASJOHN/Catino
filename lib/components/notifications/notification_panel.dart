import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/cache/notification_cache_service.dart';
import 'dart:async';

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

  /// Load notifications from cache first for instant UI
  Future<void> _loadCachedNotifications() async {
    try {
      final cached = await _cacheService.getCachedNotifications();
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() {
          _cachedNotifications = cached;
          _cacheLoaded = true;
        });
      }
    } catch (e) {
      print('Error loading cached notifications: $e');
    }
  }

  /// Setup explicit realtime subscription for instant updates
  void _setupRealtimeSubscription() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _notificationStreamController =
        StreamController<List<Map<String, dynamic>>>.broadcast();

    // Subscribe to realtime changes
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
            print('🔔 Realtime event received: ${payload.eventType}');
            // Trigger a refresh by fetching latest data
            _fetchAndBroadcastNotifications();
          },
        )
        .subscribe();

    // Initial fetch
    _fetchAndBroadcastNotifications();
  }

  /// Fetch notifications and broadcast to stream
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
        _notificationStreamController!.add(
          response,
        );
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.7,
      height: MediaQuery.of(context).size.height * 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Clear All button
                        if (_isClearing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _showClearAllDialog,
                            child: Text(
                              'Clear All',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Unbounded',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: widget.onClose,
                          child: const Icon(Icons.close, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Notifications List with Realtime Updates
              Expanded(
                child: Builder(
                  builder: (context) {
                    final userId =
                        Supabase.instance.client.auth.currentUser?.id;

                    // If no user is logged in, show login message
                    if (userId == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_circle_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Please log in to view notifications',
                              style: TextStyle(
                                decoration: TextDecoration.none,
                                fontFamily: 'Unbounded',
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _notificationStreamController?.stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Error loading notifications',
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontFamily: 'Unbounded',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    decoration: TextDecoration.none,
                                    fontFamily: 'Unbounded',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w300,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Check if we have data from stream or cache
                        List<NotificationModel>? notifications;

                        if (snapshot.hasData) {
                          // Use stream data when available
                          final notificationMaps =
                              snapshot.data ?? <Map<String, dynamic>>[];
                          notifications = notificationMaps
                              .map(
                                (map) => NotificationModel.fromSupabaseMap(map),
                              )
                              .toList()
                              .cast<NotificationModel>();

                          // Update cache in background
                          if (notifications.isNotEmpty) {
                            _cacheService.cacheNotifications(notifications);
                          }
                        } else if (_cacheLoaded &&
                            _cachedNotifications != null) {
                          // Use cached data while stream loads (instant UI!)
                          notifications = _cachedNotifications;
                        }

                        if (notifications != null) {
                          if (notifications.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No notifications yet',
                                    style: TextStyle(
                                      decoration: TextDecoration.none,
                                      fontFamily: 'Unbounded',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              ListView.builder(
                                padding: const EdgeInsets.all(5),
                                shrinkWrap: true,
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
                                        horizontal: 20,
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.delete_outline,
                                          color: Colors.red.shade700,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await _deleteNotification(
                                        notification.id,
                                      );
                                    },
                                    child: AnimatedOpacity(
                                      opacity: isDeleting ? 0.5 : 1.0,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: _buildNotificationItem(
                                        notification.title,
                                        notification.message,
                                        _getTimeAgo(notification.createdAt),
                                        _getNotificationIcon(notification.type),
                                        _getNotificationColor(
                                          notification.type,
                                        ),
                                        notification.isRead,
                                        () => _markAsRead(notification.id),
                                        isDeleting,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Show subtle loading indicator while stream is connecting (but cache is shown)
                            ],
                          );
                        }

                        // Fallback loading state
                        return const Center(
                          child: CircularProgressIndicator(),
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

  Future<void> _markAsRead(String notificationId) async {
    try {
      // Update the database - the realtime subscription will trigger a refresh
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      print('✅ Marked notification as read: $notificationId');

      // Trigger immediate refresh to update UI
      await _fetchAndBroadcastNotifications();
    } catch (e) {
      print('❌ Error marking as read: $e');
    }
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

      // Remove from cache as well
      await _cacheService.removeNotificationFromCache(notificationId);

      // Trigger immediate refresh
      await _fetchAndBroadcastNotifications();

      return true; // Allow dismissal
    } catch (e) {
      print('Error deleting notification: $e');
      return false; // Prevent dismissal on error
    } finally {
      if (mounted) {
        setState(() {
          _deletingNotifications.remove(notificationId);
        });
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    setState(() {
      _isClearing = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('notifications')
            .delete()
            .eq('user_id', userId);

        // Clear cache as well
        await _cacheService.clearCache();

        // Trigger immediate refresh
        await _fetchAndBroadcastNotifications();
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
      }
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Clear All Notifications',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete all notifications? This action cannot be undone.',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAllNotifications();
              },
              child: Text(
                'Clear All',
                style: TextStyle(
                  fontFamily: 'Unbounded',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
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
        return Icons.shopping_bag;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order':
        return Colors.green;
      case 'announcement':
        return AppColors.statusPending;
      default:
        return AppColors.notificationDot;
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.transparent
              : AppColors.notificationDot.withValues(alpha: 0.05),
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 16),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            decoration: TextDecoration.none,
                            fontFamily: 'Unbounded',
                            fontSize: 13,
                            fontWeight: isRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      if (isDeleting)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.red,
                            ),
                          ),
                        )
                      else if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.notificationDot,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    time,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: TextDecoration.none,
                      fontFamily: 'Unbounded',
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: Colors.grey.shade500,
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
