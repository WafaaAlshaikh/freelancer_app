// lib/models/message_model.dart
class ReplyPreview {
  final int messageId;
  final String senderName;
  final String content;
  final String? mediaType;

  ReplyPreview({
    required this.messageId,
    required this.senderName,
    required this.content,
    this.mediaType,
  });

  factory ReplyPreview.fromJson(Map<String, dynamic> json) {
    print('📥 ReplyPreview.fromJson: $json');

    return ReplyPreview(
      messageId: json['id'] != null
          ? int.tryParse(json['id'].toString()) ?? 0
          : (json['messageId'] != null
                ? int.tryParse(json['messageId'].toString()) ?? 0
                : 0),
      senderName:
          json['senderName']?.toString() ??
          json['sender_name']?.toString() ??
          'Unknown',
      content: json['content']?.toString() ?? '',
      mediaType: json['type']?.toString() ?? json['mediaType']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': messageId,
      'senderName': senderName,
      'content': content,
      'type': mediaType,
    };
  }
}
