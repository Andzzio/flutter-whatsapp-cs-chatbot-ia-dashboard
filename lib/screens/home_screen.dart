import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/screens/chat_screen.dart';
import 'package:boty_flutter/screens/settings_screen.dart';
import 'package:boty_flutter/widgets/contact_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Boty Contacts"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final contacts = provider.contacts;
          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.perm_contact_calendar,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 10),
                  Text("No hay contactos o falta Token"),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (BuildContext context, int index) {
              final contact = contacts[index];
              return ContactCard(
                contact: contact,

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(contact: contact),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
