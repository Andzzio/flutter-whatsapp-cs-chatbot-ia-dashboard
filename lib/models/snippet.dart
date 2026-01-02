class Snippet {
  final int id;
  final String shortcut;
  final String content;

  Snippet({required this.id, required this.shortcut, required this.content});

  Map<String, dynamic> toJson() => {
    'id': id,
    'shortcut': shortcut,
    'content': content,
  };

  factory Snippet.fromJson(Map<String, dynamic> json) {
    return Snippet(
      id: json['id'] ?? 0,
      shortcut: json['shortcut'] ?? '',
      content: json['content'] ?? '',
    );
  }
}
