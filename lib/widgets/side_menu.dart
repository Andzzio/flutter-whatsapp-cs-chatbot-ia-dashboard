import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  final bool compact;
  final bool isMobile;
  final String selectedItem;
  final Function(String) onSelect;

  const SideMenu({
    super.key,
    this.compact = false,
    this.isMobile = false,
    this.selectedItem = "Inicio",
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    // The sidebar in the design is always dark/blackish
    const backgroundColor = Color(0xFF1E1E24);

    return Container(
      width: isMobile ? 280 : (compact ? 64 : 80),
      height: isMobile ? double.infinity : null, // Fill height in drawer
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: isMobile
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: isMobile ? 50 : 30,
          ), // Extra padding for mobile notch
          // Logo or App Icon
          if (isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Icon(
                    Icons.change_history,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Boty App",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            const Icon(Icons.change_history, color: Colors.white, size: 32),

          const SizedBox(height: 40),

          // Menu Items
          _SideMenuItem(
            icon: Icons.home_outlined,
            label: "Inicio",
            isActive: selectedItem == "Inicio",
            badgeCount: 43,
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Inicio"),
          ),
          _SideMenuItem(
            icon: Icons.receipt_long_outlined,
            label: "Pedidos",
            isActive: selectedItem == "Pedidos",
            badgeCount: 12, // Pedidos pendientes
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Pedidos"),
          ),
          _SideMenuItem(
            icon: Icons.inventory_2_outlined,
            label: "Productos",
            isActive: selectedItem == "Productos",
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Productos"),
          ),
          _SideMenuItem(
            icon: Icons.bar_chart_outlined,
            label: "Estadísticas",
            isActive: selectedItem == "Estadísticas",
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Estadísticas"),
          ),
          _SideMenuItem(
            icon: Icons.notifications_none,
            label: "Notificaciones",
            isActive: selectedItem == "Notificaciones",
            badgeCount: 0, // TODO: Connect to provider
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Notificaciones"),
          ),

          const Spacer(),
          _SideMenuItem(
            icon: Icons.person_outline,
            label: "Profile",
            isActive: selectedItem == "Profile",
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Profile"),
          ),
          _SideMenuItem(
            icon: Icons.settings_outlined,
            label: "Edit",
            isActive: selectedItem == "Edit",
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Edit"),
          ),
          const SizedBox(height: 20),
          _SideMenuItem(
            icon: Icons.logout,
            label: "Log out",
            showLabel: !compact || isMobile,
            isMobile: isMobile,
            onTap: () => onSelect("Log out"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final bool showLabel;
  final bool isMobile;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.badgeCount = 0,
    this.showLabel = true,
    this.isMobile = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mobile Layout: Row (ListTile style)
    if (isMobile) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF32323A) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white54,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontSize: 16,
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7A55),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // Desktop/Tablet Layout: Column (Compact icon-focused)
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF32323A)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : Colors.white54,
                    size: 26,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7A55), // Orange badge
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (showLabel) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.white54,
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
