import 'package:boty_flutter/models/contact.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrmEditDialog extends StatefulWidget {
  final Contact contact;
  const CrmEditDialog({super.key, required this.contact});

  @override
  State<CrmEditDialog> createState() => _CrmEditDialogState();
}

class _CrmEditDialogState extends State<CrmEditDialog> {
  late TextEditingController _notesController;
  late TextEditingController _tagController;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.contact.notes);
    _tagController = TextEditingController();
    _tags = List.from(widget.contact.tags);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _save() {
    Provider.of<ChatProvider>(context, listen: false).updateContactCrm(
      widget.contact.phone,
      notes: _notesController.text.trim(),
      tags: _tags,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Información de Contacto"),
      content: SizedBox(
        width: 400, // Fixed width for desktop consistency
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Notas ---
              const Text(
                "Notas Privadas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Escribe notas sobre este cliente...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
              ),
              const SizedBox(height: 16),

              // --- Etiquetas ---
              const Text(
                "Etiquetas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: "Nueva etiqueta",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    icon: const Icon(Icons.add_circle, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                    backgroundColor: Colors.blue.withValues(alpha: 0.1),
                    labelStyle: const TextStyle(color: Colors.blue),
                    deleteIconColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: Colors.blue.withValues(alpha: 0.2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(onPressed: _save, child: const Text("Guardar")),
      ],
    );
  }
}
