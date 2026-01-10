/// Notification Model for Firebase Realtime Database
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'order', 'announcement'
  final String userId; // Empty for announcements (broadcast to all)
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data; // Additional data like order ID

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.userId,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  // Convert to Realtime Database Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'type': type,
      'userId': userId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'data': data ?? {},
    };
  }

  // Create from Realtime Database Map
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      userId: map['userId'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      isRead: map['isRead'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  // Create from Supabase Map
  factory NotificationModel.fromSupabaseMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      userId: map['user_id'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at_timestamp'] ?? 0),
      isRead: map['is_read'] ?? false,
      data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
    );
  }

  // Copy with new fields
  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    String? userId,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

/// Announcement Model for Firebase Realtime Database
class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String createdBy; // Admin user ID
  final bool isActive;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
  });

  // Convert to Realtime Database Map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  // Create from Realtime Database Map
  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      createdBy: map['createdBy'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }
}