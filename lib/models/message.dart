class Message {
  final String user;
  final String text;
  final String time;
  final bool isBot;
  final String type;
  final String? mediaId;
  final String? caption;

  Message({
    required this.user,
    required this.text,
    required this.time,
    required this.isBot,
    this.type = 'text',
    this.mediaId,
    this.caption,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      user: json["user"] ?? "",
      text: json["text"] ?? "",
      time: json["time"] ?? "",
      isBot: json["is_bot"] ?? false,
      type: json["type"] ?? "text",
      mediaId: json["media_id"],
      caption: json["caption"],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "user": user,
      "text": text,
      "time": time,
      "is_bot": isBot,
      "type": type,
      "media_id": mediaId,
      "caption": caption,
    };
  }
}
