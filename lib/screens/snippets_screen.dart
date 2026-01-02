import 'package:boty_flutter/models/snippet.dart';
import 'package:boty_flutter/services/api_service.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _shortcutController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  List<Snippet> _snippets = [];

  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }

  Future<void> _loadSnippets() async {
    setState(() => _isLoading = true);
    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;
    try {
      final snippets = await _apiService.getSnippets(token);
      setState(() => _snippets = snippets);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createSnippet() async {
    if (!_formKey.currentState!.validate()) return;
    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;
    try {
      await _apiService.createSnippet(
        token,
        _shortcutController.text.trim(),
        _contentController.text.trim(),
      );
      _shortcutController.clear();
      _contentController.clear();
      Navigator.pop(context); // Close dialog
      _loadSnippets(); // Refresh
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteSnippet(int id) async {
    final token = Provider.of<ChatProvider>(context, listen: false).apiToken;
    try {
      await _apiService.deleteSnippet(token, id);
      _loadSnippets();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Snippet"),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _shortcutController,
                decoration: const InputDecoration(
                  labelText: "Atajo (ej: /hola)",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: "Mensaje",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "Requerido" : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          FilledButton(onPressed: _createSnippet, child: const Text("Guardar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestión de Snippets")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _snippets.isEmpty
          ? const Center(child: Text("No hay snippets creados."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _snippets.length,
              itemBuilder: (context, index) {
                final s = _snippets[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(s.shortcut.substring(0, 1)),
                    ),
                    title: Text(
                      s.shortcut,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      s.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSnippet(s.id),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
