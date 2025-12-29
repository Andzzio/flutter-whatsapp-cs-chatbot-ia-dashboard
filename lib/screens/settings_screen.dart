import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:boty_flutter/providers/theme_provider.dart';
import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/screens/snippets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Cargar el token actual al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _tokenController.text = chatProvider.apiToken;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _saveToken() async {
    setState(() => _isLoading = true);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.setToken(_tokenController.text.trim());
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Token guardado exitosamente'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configuración"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECCIÓN APARIENCIA ---
            const Text(
              "Apariencia",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color:
                  Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.nightlight_round
                        : Icons.wb_sunny_rounded,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: const Text(
                  "Modo Oscuro",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  themeProvider.isDarkMode ? "Activado" : "Desactivado",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: Switch.adaptive(
                  value: themeProvider.isDarkMode,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- SECCIÓN PRODUCTIVIDAD ---
            const Text(
              "Productividad",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color:
                  Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flash_on_rounded,
                    color: Colors.green,
                  ),
                ),
                title: const Text(
                  "Respuestas Rápidas",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                subtitle: Text(
                  "Gestiona tus atajos de texto",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SnippetsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // --- SECCIÓN CONEXIÓN ---
            const Text(
              "Conexión",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              color:
                  Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "API Token",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Introduce el token de tu servidor Boty para sincronizar chats.",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tokenController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Ej: abc123def456...",
                        filled: true,
                        fillColor: Theme.of(context).scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.check_circle_rounded),
                                color: Theme.of(context).primaryColor,
                                onPressed: _saveToken,
                                tooltip: "Guardar Token",
                              ),
                      ),
                      onSubmitted: (_) => _saveToken(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
