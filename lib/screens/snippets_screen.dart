import 'package:boty_flutter/models/snippet.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SnippetsScreen extends StatelessWidget {
  const SnippetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Respuestas Rápidas")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chatProvider.snippets.length,
        itemBuilder: (context, index) {
          final snippet = chatProvider.snippets[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                snippet.shortcut,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              subtitle: Text(
                snippet.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  chatProvider.removeSnippet(snippet.shortcut);
                },
              ),
              onTap: () =>
                  _showSnippetDialog(context, chatProvider, snippet: snippet),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSnippetDialog(context, chatProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSnippetDialog(
    BuildContext context,
    ChatProvider provider, {
    Snippet? snippet,
  }) {
    final shortcutCtrl = TextEditingController(text: snippet?.shortcut ?? "/");
    final contentCtrl = TextEditingController(text: snippet?.content ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(snippet == null ? "Crear Snippet" : "Editar Snippet"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: shortcutCtrl,
              decoration: const InputDecoration(
                labelText: "Atajo (ej. /hola)",
                hintText: "Debe empezar con /",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(
                labelText: "Mensaje completo",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final shortcut = shortcutCtrl.text.trim();
              final content = contentCtrl.text.trim();

              if (shortcut.isNotEmpty &&
                  content.isNotEmpty &&
                  shortcut.startsWith("/")) {
                final newSnippet = Snippet(
                  shortcut: shortcut,
                  content: content,
                );
                if (snippet == null) {
                  provider.addSnippet(newSnippet);
                } else {
                  provider.updateSnippet(snippet.shortcut, newSnippet);
                }
                Navigator.pop(context);
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }
}
