class ReplyInfo {
  final int id;
  final String text;
  final String type;
  final String? mediaId;
  final String senderName;

  ReplyInfo({
    required this.id,
    required this.text,
    required this.type,
    this.mediaId,
    required this.senderName,
  });

  factory ReplyInfo.fromJson(Map<String, dynamic> json) {
    return ReplyInfo(
      id: json['id'],
      text: json['text'] ?? '',
      type: json['type'] ?? 'text',
      mediaId: json['media_id'],
      senderName: json['sender_name'] ?? 'Usuario',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'media_id': mediaId,
      'sender_name': senderName,
    };
  }
}

class Message {
  final int? id; // Added ID field for scrolling
  final String user;
  final String text;
  final String time;
  final bool isBot;
  final String type;
  final String? mediaId;
  final String? caption;
  final bool isPending;
  final ReplyInfo? replyTo;

  Message({
    this.id,
    required this.user,
    required this.text,
    required this.time,
    required this.isBot,
    this.type = 'text',
    this.mediaId,
    this.caption,
    this.isPending = false,
    this.replyTo,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json["id"],
      user: json["user"] ?? "",
      text: json["text"] ?? "",
      time: json["time"] ?? "",
      isBot: json["is_bot"] ?? false,
      type: json["type"] ?? "text",
      mediaId: json["media_id"],
      caption: json["caption"],
      isPending: false,
      replyTo: json["reply_to"] != null
          ? ReplyInfo.fromJson(json["reply_to"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "user": user,
      "text": text,
      "time": time,
      "is_bot": isBot,
      "type": type,
      "media_id": mediaId,
      "caption": caption,
      "reply_to": replyTo?.toJson(),
    };
  }
}
