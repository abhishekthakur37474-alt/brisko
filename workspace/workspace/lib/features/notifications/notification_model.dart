class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? orderId;
  final bool isRead;
  final int createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: id,
      title: (map['title'] ?? '') as String,
      body: (map['body'] ?? '') as String,
      type: (map['type'] ?? 'general') as String,
      orderId: map['orderId'] as String?,
      isRead: map['isRead'] == true,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    );
  }
}
