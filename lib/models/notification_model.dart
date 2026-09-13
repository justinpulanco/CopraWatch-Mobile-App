import 'package:uuid/uuid.dart';

enum NotificationType {
  warning,
  success,
  critical,
  information,
}

class AppNotification {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final String? batchId;

  AppNotification({
    String? id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.batchId,
  }) : id = id ?? const Uuid().v4();

  String get typeString {
    switch (type) {
      case NotificationType.warning:
        return 'Warning';
      case NotificationType.success:
        return 'Success';
      case NotificationType.critical:
        return 'Critical';
      case NotificationType.information:
        return 'Information';
    }
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? description,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionUrl,
    String? batchId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      batchId: batchId ?? this.batchId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
      'actionUrl': actionUrl,
      'batchId': batchId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? const Uuid().v4(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: _parseNotificationType(map['type']),
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: (map['isRead'] ?? 0) == 1,
      actionUrl: map['actionUrl'],
      batchId: map['batchId'],
    );
  }

  static NotificationType _parseNotificationType(String? typeString) {
    if (typeString == null) return NotificationType.information;
    if (typeString.contains('warning')) return NotificationType.warning;
    if (typeString.contains('success')) return NotificationType.success;
    if (typeString.contains('critical')) return NotificationType.critical;
    return NotificationType.information;
  }
}
