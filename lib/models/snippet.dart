class Snippet {
  String shortcut; // e.g., "/hola"
  String content; // e.g., "Hola, ¿en qué puedo ayudarte hoy?"

  Snippet({required this.shortcut, required this.content});

  Map<String, dynamic> toJson() => {'shortcut': shortcut, 'content': content};

  factory Snippet.fromJson(Map<String, dynamic> json) {
    return Snippet(shortcut: json['shortcut'], content: json['content']);
  }
}
