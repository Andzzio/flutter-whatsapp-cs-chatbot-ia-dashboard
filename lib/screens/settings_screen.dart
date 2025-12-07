import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _tokenController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ChatProvider>(context, listen: false);
    _tokenController.text = provider.apiToken;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Configuración")),
      body: Padding(
        padding: EdgeInsetsGeometry.all(16),
        child: Column(
          children: [
            Text(
              "Ingresa tu Token de Autenticación",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _tokenController,
              decoration: InputDecoration(
                labelText: "Token",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final token = _tokenController.text.trim();
                if (token.isNotEmpty) {
                  Provider.of<ChatProvider>(
                    context,
                    listen: false,
                  ).setToken(token);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Token guardado y sincronizando..."),
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              icon: Icon(Icons.save),
              label: Text("Guardar y Sicronizar"),
            ),
          ],
        ),
      ),
    );
  }
}
