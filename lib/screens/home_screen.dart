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
    // Colores base para tarjetas de dashboard
    final cardColors = [
      const Color(0xFF6C63FF), // Purple
      const Color(0xFFFF6584), // Salmon
      const Color(0xFF4ECDC4), // Teal
    ];

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            if (isDesktop) {
              return _buildDesktopLayout(context, cardColors);
            }

            return Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                // --- CAROUSEL DE ESTADÍSTICAS (MOCK) ---
                SizedBox(
                  height: 200,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    children: [
                      _buildDashboardCard(
                        context,
                        title: "Mensajes Totales",
                        subtitle: "1,245",
                        icon: Icons.message_rounded,
                        color: cardColors[0],
                      ),
                      const SizedBox(width: 16),
                      _buildDashboardCard(
                        context,
                        title: "Usuarios Activos",
                        subtitle: "34",
                        icon: Icons.people_alt_rounded,
                        color: cardColors[1],
                      ),
                      const SizedBox(width: 16),
                      _buildDashboardCard(
                        context,
                        title: "Bot Status",
                        subtitle: "Online",
                        icon: Icons.smart_toy_rounded,
                        color: cardColors[2],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildFilterHeader(context),
                const SizedBox(height: 10),
                Expanded(child: _buildContactList(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, List<Color> cardColors) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          _buildHeader(context, isDesktop: true),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildDashboardCard(
                  context,
                  title: "Mensajes Totales",
                  subtitle: "1,245",
                  icon: Icons.message_rounded,
                  color: cardColors[0],
                  isDesktop: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  title: "Usuarios Activos",
                  subtitle: "34",
                  icon: Icons.people_alt_rounded,
                  color: cardColors[1],
                  isDesktop: true,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildDashboardCard(
                  context,
                  title: "Bot Status",
                  subtitle: "Online",
                  icon: Icons.smart_toy_rounded,
                  color: cardColors[2],
                  isDesktop: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildFilterHeader(context),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final contacts = provider.contacts;
                if (contacts.isEmpty) return _buildEmptyState();

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    return ContactCard(
                      contact: contacts[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(contact: contacts[index]),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {bool isDesktop = false}) {
    return Padding(
      padding: isDesktop
          ? EdgeInsets.zero
          : const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hola Admin,",
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Dashboard",
                style: TextStyle(
                  fontSize: isDesktop ? 36 : 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.settings_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ), // Keep padding for mobile consistent with old Code
      child: Row(
        children: [
          Text(
            "Chats Recientes",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return PopupMenuButton<ChatFilter>(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: provider.filter == ChatFilter.all
                      ? Colors.grey[400]
                      : Theme.of(context).primaryColor,
                ),
                onSelected: (ChatFilter result) {
                  provider.setFilter(result);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<ChatFilter>>[
                      const PopupMenuItem<ChatFilter>(
                        value: ChatFilter.all,
                        child: Text('Todos'),
                      ),
                      const PopupMenuItem<ChatFilter>(
                        value: ChatFilter.unread,
                        child: Text('No leídos'),
                      ),
                      const PopupMenuItem<ChatFilter>(
                        value: ChatFilter.botActive,
                        child: Text('Bot Activo'),
                      ),
                      const PopupMenuItem<ChatFilter>(
                        value: ChatFilter.botInactive,
                        child: Text('Bot Inactivo'),
                      ),
                    ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final contacts = provider.contacts;
        if (contacts.isEmpty) return _buildEmptyState();
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: contacts.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ContactCard(
                contact: contacts[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(contact: contacts[index]),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 10),
          Text(
            "Sin contactos activos",
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isDesktop = false,
  }) {
    return Container(
      width: isDesktop ? double.infinity : 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 22 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
