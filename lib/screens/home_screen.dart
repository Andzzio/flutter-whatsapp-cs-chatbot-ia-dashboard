import 'package:boty_flutter/providers/chat_provider.dart';
import 'package:boty_flutter/screens/analytics_screen.dart';
import 'package:boty_flutter/screens/chat_screen.dart';
import 'package:boty_flutter/screens/orders_screen.dart';
import 'package:boty_flutter/screens/products_screen.dart';
import 'package:boty_flutter/screens/settings_screen.dart';
import 'package:boty_flutter/screens/snippets_screen.dart';
import 'package:boty_flutter/widgets/contact_card.dart';
import 'package:boty_flutter/widgets/side_menu.dart'; // Import SideMenu
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _statsScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _sortBy = 'newest'; // 'newest' or 'oldest'
  String _selectedMenuItem = 'Inicio'; // For SideMenu selection
  late ChatProvider _chatProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider = Provider.of<ChatProvider>(context, listen: false);
      _chatProvider.addListener(_onContactsChanged);
      _chatProvider.fetchDashboardStats();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _onContactsChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chatProvider.removeListener(_onContactsChanged);
    _statsScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await Future.wait([
      chatProvider.fetchDashboardStats(forceRefresh: true),
      chatProvider.refreshContacts(),
    ]);
  }

  void _onMenuSelect(String item) {
    if (item == "Log out") {
      Provider.of<ChatProvider>(context, listen: false).logout();
      // Assuming there is a listener in Main or AuthWrapper that handles null token to redirect
      return;
    }

    // Navigate to new screens
    if (item == "Pedidos") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OrdersScreen()),
      );
      return;
    }

    if (item == "Productos") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductsScreen()),
      );
      return;
    }

    if (item == "Estadísticas") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
      );
      return;
    }

    // Handle specific navigations if needed for Profile/Edit

    setState(() {
      _selectedMenuItem = item;
    });

    // Close drawer if open (Mobile)
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout Decision
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final isTablet = width > 600 && width <= 900;
    final isMobile = width <= 600;

    return Scaffold(
      key: _scaffoldKey, // Key for controlling drawer
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isMobile
          ? SideMenu(
              isMobile: true,
              selectedItem: _selectedMenuItem,
              onSelect: _onMenuSelect,
            )
          : null,
      body: Row(
        children: [
          // Sidebar for Desktop/Tablet
          if (isDesktop)
            SideMenu(selectedItem: _selectedMenuItem, onSelect: _onMenuSelect),
          if (isTablet)
            SideMenu(
              compact: true,
              selectedItem: _selectedMenuItem,
              onSelect: _onMenuSelect,
            ),

          Expanded(
            child: SafeArea(
              child: RefreshIndicator(
                color: Theme.of(context).primaryColor,
                onRefresh: _refreshData,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels >=
                        scrollInfo.metrics.maxScrollExtent - 200) {
                      Provider.of<ChatProvider>(
                        context,
                        listen: false,
                      ).loadMoreContacts();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    controller:
                        _statsScrollController, // Usamos el controlador existente o null si no se requiere scroll to top explícito
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        sliver: SliverToBoxAdapter(
                          child: _buildHeader(context, isMobile),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        sliver: SliverToBoxAdapter(
                          child: _buildStatsSection(context),
                        ),
                      ),
                      SliverToBoxAdapter(child: _buildFilterHeader(context)),
                      _buildContactList(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SnippetsScreen()),
          );
        },
        tooltip: "Snippets",
        child: const Icon(Icons.flash_on, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Column(
      children: [
        Row(
          children: [
            // Mobile Menu Button
            if (isMobile) ...[
              Container(
                height: 48,
                width: 48,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 24),
                  color: Colors.grey[800],
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
            ],

            Expanded(
              child: Container(
                height: 48, // Standard iOS height
                decoration: BoxDecoration(
                  color: Colors.white, // Pure white for clean look
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: "Search contacts...",
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).primaryColor.withOpacity(0.7),
                      size: 22,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, size: 22),
                color: Colors.grey[700],
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Title Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // Update Title based on selection
                  _selectedMenuItem == "Inicio"
                      ? "Dashboard"
                      : _selectedMenuItem,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Overview",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "10 online",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // Stats section
  Widget _buildStatsSection(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        final stats = provider.dashboardStats;
        if (stats == null) {
          return const SizedBox(
            height: 120,
            child: Center(child: CupertinoActivityIndicator()),
          );
        }
        return _buildStatsList(stats);
      },
    );
  }

  Widget _buildStatsList(Map<String, dynamic> data) {
    final metrics = [
      _Metric(
        "Sales",
        "S/ ${data['sales_today'] ?? '0.00'}",
        Icons.attach_money_rounded,
        const Color(0xFF4CAF50),
      ),
      _Metric(
        "Pending",
        "${data['pending_orders'] ?? '0'}",
        Icons.pending_rounded,
        const Color(0xFFFF9800),
      ),
      _Metric(
        "Unread",
        "${data['unread_chats'] ?? '0'}",
        Icons.mark_chat_unread_rounded,
        const Color(0xFF9C27B0),
      ),
      _Metric(
        "Conversion",
        "${data['conversion_rate'] ?? '0'}%",
        Icons.pie_chart_rounded,
        const Color(0xFF2196F3),
      ),
      _Metric(
        "Avg. Ticket",
        "S/ ${data['avg_ticket'] ?? '0.00'}",
        Icons.receipt_long_rounded,
        const Color(0xFF009688),
      ),
    ];

    return SizedBox(
      height: 110,
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            final offset = event.scrollDelta.dy;
            if (_statsScrollController.hasClients) {
              final newOffset = _statsScrollController.offset + offset;
              _statsScrollController.jumpTo(
                newOffset.clamp(
                  0.0,
                  _statsScrollController.position.maxScrollExtent,
                ),
              );
            }
          }
        },
        child: ListView.separated(
          controller: _statsScrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: metrics.length,
          separatorBuilder: (ctx, i) => const SizedBox(width: 16),
          itemBuilder: (context, index) {
            final m = metrics[index];
            return Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: m.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(m.icon, color: m.color, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    m.value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: Color(0xFF2D3142),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    m.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          const Text(
            "Sort by",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins', // Corrected fontFamily
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),

          // Smart Sort Dropdown (Apple Style)
          PopupMenuButton<String>(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            offset: const Offset(0, 40),
            child: Row(
              children: [
                Text(
                  _sortBy == 'newest' ? "Newest First" : "Oldest First",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            onSelected: (val) {
              setState(() {
                _sortBy = val;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 16),
                    SizedBox(width: 8),
                    Text("Newest First"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 16),
                    SizedBox(width: 8),
                    Text("Oldest First"),
                  ],
                ),
              ),
            ],
          ),

          const Spacer(),

          // Filter Button
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) => PopupMenuButton<ChatFilter>(
                icon: Icon(
                  Icons.filter_list_rounded,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                offset: const Offset(0, 45),
                initialValue: provider.filter,
                onSelected: (ChatFilter value) {
                  provider.setFilter(value);
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<ChatFilter>>[
                      const PopupMenuItem(
                        value: ChatFilter.all,
                        child: Text("All Chats"),
                      ),
                      const PopupMenuItem(
                        value: ChatFilter.unread,
                        child: Text("Unread Only"),
                      ),
                      const PopupMenuItem(
                        value: ChatFilter.needsAttention,
                        child: Text("Needs Attention"),
                      ),
                      const PopupMenuItem(
                        value: ChatFilter.botActive,
                        child: Text("Bot Active"),
                      ),
                      const PopupMenuItem(
                        value: ChatFilter.botInactive,
                        child: Text("Bot Inactive"),
                      ),
                    ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactList(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, provider, child) {
        // 1. Filter by Search Query
        var contacts = provider.contacts.where((c) {
          final q = _searchQuery.trim();
          if (q.isEmpty) return true;
          return c.name.toLowerCase().contains(q) || c.phone.contains(q);
        }).toList();

        // 2. Filter by SIDEBAR Tag (New Logic)
        if (_selectedMenuItem != "Inicio" &&
            _selectedMenuItem != "Log out" &&
            _selectedMenuItem != "Profile" &&
            _selectedMenuItem != "Edit") {
          // We treat sidebar labels as required tags.
          // e.g. If selected "Work", contact must have "Work" (case insensitive possible)
          contacts = contacts.where((c) {
            return c.tags.any(
              (t) => t.toLowerCase() == _selectedMenuItem.toLowerCase(),
            );
          }).toList();
        }

        // 3. Sort Logic
        contacts.sort((a, b) {
          final dateA = a.lastActivity ?? DateTime(2000);
          final dateB = b.lastActivity ?? DateTime(2000);
          if (_sortBy == 'newest') {
            return dateB.compareTo(dateA); // Descending
          } else {
            return dateA.compareTo(dateB); // Ascending
          }
        });

        if (contacts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No contacts found",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.only(bottom: 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return ContactCard(
                contact: contacts[index],
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(contact: contacts[index]),
                    ),
                  ).then((_) {
                    Provider.of<ChatProvider>(
                      context,
                      listen: false,
                    ).fetchDashboardStats(forceRefresh: true);
                  });
                },
              );
            }, childCount: contacts.length),
          ),
        );
      },
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _Metric(this.title, this.value, this.icon, this.color);
}
