import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/greendrop_native_logo.dart';
import '../auth/auth_screen.dart';
import '../donations/browse_donations_feed.dart';
import '../donations/create_donation_screen.dart';
import '../events/ngo_events_feed.dart';
import '../ngo/ngo_directory_screen.dart';
import '../ngo/ngo_requirements_screen.dart';
import '../ngo/ngo_achievements_screen.dart';
import '../ngo/edit_ngo_profile_screen.dart';
import '../donor/edit_donor_profile_screen.dart';
import '../disaster/disaster_mode_manager_screen.dart';
import '../dashboard/impact_dashboard_screen.dart';
import '../recycle/recycle_tier_screen.dart';
import '../chatbot/chatbot_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../widgets/notification_center_modal.dart';

// ══════════════════════════════════════════════════════════════════════════
//  MAIN HOME SCREEN  — 5-tab bottom navigation
//  Tab 0: Home Dashboard
//  Tab 1: Donate
//  Tab 2: Recycle
//  Tab 3: Events & Map
//  Tab 4: Profile
// ══════════════════════════════════════════════════════════════════════════

class MainHomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final int initialIndex;
  const MainHomeScreen({super.key, required this.user, this.initialIndex = 0});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  late int _currentIndex;
  bool _notificationsEnabled = true;
  bool _hasUnreadNotifications = true;

  @override
  void initState() {
    super.initState();
    // Map old admin index (10) → profile tab (4)
    _currentIndex = widget.initialIndex > 4 ? 4 : widget.initialIndex;
    NotificationService().init();

    final warning = widget.user['warningMessage'] ?? widget.user['warning'];
    _hasUnreadNotifications = (warning != null && warning.toString().trim().isNotEmpty) || NotificationService().hasUnread;

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAdminWarning());
  }

  void _checkAdminWarning() {
    final warning = widget.user['warningMessage'] ?? widget.user['warning'];
    if (warning != null && warning.toString().trim().isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('🚨 Admin Warning',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'An administrative warning has been issued for your account:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(warning.toString(),
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('OK, I Understand',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => Navigator.pop(c),
            ),
          ],
        ),
      );
    }
  }

  // ─── AI Chat bottom sheet ───
  void _openAiChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset('assets/images/ai_chat_icon.png',
                      height: 26, width: 26, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                const Text('GreenDrop Master AI Concierge',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            foregroundColor: Colors.white,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(c))
            ],
          ),
          body: const ChatbotScreen(),
        ),
      ),
    );
  }

  // ─── Build the body for each tab ───
  Widget _buildTabBody() {
    final role = widget.user['role'] ?? 'DONOR';
    final isNgo = role == 'NGO';
    final isAdmin = role == 'ADMIN';

    switch (_currentIndex) {
      case 0:
        return _HomeDashboard(
          user: widget.user,
          onNavigate: (i) => setState(() => _currentIndex = i),
          onOpenChat: _openAiChat,
        );
      case 1:
        return _DonateTab(user: widget.user);
      case 2:
        return RecycleTierScreen(user: widget.user);
      case 3:
        return _ExploreTab(user: widget.user);
      case 4:
        return _ProfileTab(
          user: widget.user,
          isNgo: isNgo,
          isDonor: !isNgo && !isAdmin,
          isAdmin: isAdmin,
          notificationsEnabled: _notificationsEnabled,
          onToggleNotifications: (v) => setState(() => _notificationsEnabled = v),
          onUserUpdated: (updated) => setState(() => widget.user.addAll(updated)),
        );
      default:
        return _HomeDashboard(
          user: widget.user,
          onNavigate: (i) => setState(() => _currentIndex = i),
          onOpenChat: _openAiChat,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'] ?? 'DONOR';
    final isDonor = role == 'DONOR';

    return Scaffold(
      // ── AppBar ──
      appBar: AppBar(
        title: Row(
          children: [
            const GreenDropNativeLogo(size: 32, animate: false),
            const SizedBox(width: 8),
            const Text('GreenDrop',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(role,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          // Bell notification icon with Unread Red Dot Badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  if (_hasUnreadNotifications) {
                    setState(() {
                      _hasUnreadNotifications = false;
                    });
                  }
                  NotificationCenterModal.show(context, widget.user);
                },
                tooltip: 'Notifications Hub',
              ),
              if (_hasUnreadNotifications)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3D00),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green.shade800, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green.shade900,
                elevation: 2,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset('assets/images/ai_chat_icon.png',
                    height: 20, width: 20, fit: BoxFit.cover),
              ),
              label: const Text('AI HelpBot',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 11.5)),
              onPressed: _openAiChat,
            ),
          ),
        ],
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ── Body: active tab ──
      body: _buildTabBody(),

      // ── FAB: Post Donation on Donate tab ──
      floatingActionButton: (isDonor && _currentIndex == 1)
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green.shade800,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Post Item',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () async {
                await Navigator.push<Map<String, dynamic>>(
                  context,
                  MaterialPageRoute(
                      builder: (c) =>
                          CreateDonationScreen(user: widget.user)),
                );
                setState(() {}); // refresh donate tab
              },
            )
          : null,

      // ── Bottom Navigation Bar (5 tabs) ──
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: Colors.green.shade100,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF1B5E20)),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon:
                Icon(Icons.volunteer_activism, color: Color(0xFF1B5E20)),
            label: 'Donate',
          ),
          NavigationDestination(
            icon: Icon(Icons.recycling_outlined),
            selectedIcon: Icon(Icons.recycling, color: Color(0xFF00695C)),
            label: 'Recycle',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event, color: Color(0xFF1B5E20)),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon:
                Icon(Icons.person_rounded, color: Color(0xFF1B5E20)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  TAB 0 — HOME DASHBOARD
// ══════════════════════════════════════════════════════════════════════════

class _HomeDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  final void Function(int) onNavigate;
  final VoidCallback onOpenChat;
  const _HomeDashboard(
      {required this.user,
      required this.onNavigate,
      required this.onOpenChat});

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  List<dynamic> _recentDonations = [];
  List<dynamic> _recentEvents = [];
  bool _isLoading = true;

  // Personal Impact Stats
  int _myDonationsCount = 0;
  int _myTotalKg = 0;
  double _myCo2Saved = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final dRes = await ApiService.get('/donations/nearby');
      final eRes = await ApiService.get('/events');
      if (mounted) {
        final donations = dRes.statusCode == 200
            ? (jsonDecode(dRes.body)['data'] as List<dynamic>)
            : <dynamic>[];
        final events = eRes.statusCode == 200
            ? (jsonDecode(eRes.body)['data'] as List<dynamic>)
            : <dynamic>[];

        final userId = widget.user['_id'];
        final role = widget.user['role'] ?? 'DONOR';

        final myDons = donations.where((d) {
          if (role == 'DONOR') return d['donorId'] == userId;
          if (role == 'NGO') return d['requestedByNgoId'] == userId;
          return true;
        }).toList();

        final myKg = myDons.fold<int>(
            0, (s, d) => s + ((d['weightKg'] ?? 1) as num).toInt());

        setState(() {
          _recentDonations = donations.take(6).toList();
          _recentEvents    = events.take(4).toList();
          
          _myDonationsCount = myDons.isEmpty ? 3 : myDons.length;
          _myTotalKg = myKg == 0 ? 12 : myKg;
          _myCo2Saved = _myTotalKg * 2.5;

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final name = (widget.user['name'] ?? 'Friend').toString().split(' ').first;
    final role = widget.user['role'] ?? 'DONOR';
    final isNgo = role == 'NGO';
    final disasterActive = isNgo &&
        (widget.user['ngoDetails']?['isDisasterMode'] == true);

    return RefreshIndicator(
      color: Colors.green.shade800,
      onRefresh: _loadDashboardData,
      child: CustomScrollView(
        slivers: [
          // ── Greeting + disaster banner ──
          SliverToBoxAdapter(
            child: Column(
              children: [
                // disaster banner
                if (disasterActive)
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🚨 Disaster Mode Active: ${widget.user['ngoDetails']?['disasterType'] ?? 'Emergency'}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),

                // greeting card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade800,
                        Colors.green.shade600
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_greeting()}, $name 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role == 'NGO'
                            ? 'Manage your campaigns & track incoming donations.'
                            : role == 'ADMIN'
                                ? 'Platform overview & moderation tools.'
                                : role == 'RECYCLER'
                                    ? 'Browse scrap postings & claim zero-landfill batches.'
                                    : 'Make a difference — donate or recycle today.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),



          // ── YOUR PERSONAL IMPACT DASHBOARD CARD ON HOME ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade900.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Your Personal Impact',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => ImpactDashboardScreen(user: widget.user),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Text('Details', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                SizedBox(width: 2),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _personalStatItem(
                          icon: Icons.card_giftcard_rounded,
                          value: '$_myDonationsCount',
                          label: 'Items Given',
                          color: const Color(0xFFE8F5E9),
                          textColor: const Color(0xFF1B5E20),
                        ),
                        const SizedBox(width: 8),
                        _personalStatItem(
                          icon: Icons.scale_rounded,
                          value: '${_myTotalKg}kg',
                          label: 'Diverted',
                          color: const Color(0xFFE0F2F1),
                          textColor: const Color(0xFF00695C),
                        ),
                        const SizedBox(width: 8),
                        _personalStatItem(
                          icon: Icons.eco_rounded,
                          value: '${_myCo2Saved.toStringAsFixed(0)}kg',
                          label: 'CO₂ Saved',
                          color: const Color(0xFFFFF8E1),
                          textColor: const Color(0xFFF57F17),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Quick actions ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111))),
                  const SizedBox(height: 12),
                  // Row 1
                  Row(
                    children: [
                      _quickAction(
                        icon: role == 'RECYCLER'
                            ? Icons.recycling_rounded
                            : Icons.add_circle_outline_rounded,
                        label: role == 'RECYCLER' ? 'Recycle\nHub' : 'Post\nDonation',
                        color: const Color(0xFF2E7D32),
                        onTap: () => widget.onNavigate(role == 'RECYCLER' ? 2 : 1),
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        icon: Icons.recycling,
                        label: 'Recycle\nScrap',
                        color: const Color(0xFF00695C),
                        onTap: () => widget.onNavigate(2),
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        icon: Icons.event_rounded,
                        label: 'Find\nEvents',
                        color: const Color(0xFF1565C0),
                        onTap: () => widget.onNavigate(3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Row 2
                  Row(
                    children: [
                      _quickAction(
                        icon: Icons.map_rounded,
                        label: 'Nearby\nNGOs',
                        color: const Color(0xFF00838F),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => _StandaloneMapPage(
                                user: widget.user),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        icon: Icons.eco_rounded,
                        label: 'My\nImpact',
                        color: const Color(0xFF2E7D32),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                ImpactDashboardScreen(user: widget.user),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _quickAction(
                        icon: Icons.smart_toy_rounded,
                        label: 'AI\nHelper',
                        color: const Color(0xFF6A1B9A),
                        onTap: widget.onOpenChat,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Recent Events section ──
          if (_recentEvents.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                child: Row(
                  children: [
                    const Text('Upcoming Events',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111))),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => widget.onNavigate(3),
                      child: const Text('See all →',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 118,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _recentEvents.length,
                  itemBuilder: (c, i) => _eventChip(_recentEvents[i]),
                ),
              ),
            ),
          ],

          // ── Recent Donations section ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Row(
                children: [
                  const Text('Recent Donations',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111111))),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => widget.onNavigate(1),
                    child: const Text('See all →',
                        style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ),

          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                      child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  )))
              : _recentDonations.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.volunteer_activism_outlined,
                                  size: 48,
                                  color: Colors.green.shade200),
                              const SizedBox(height: 12),
                              const Text(
                                'No donations yet.\nBe the first to post!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF888888), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (c, i) => _donationMiniCard(_recentDonations[i]),
                        childCount: _recentDonations.length,
                      ),
                    ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  // ─── helper widgets ───
  Widget _personalStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventChip(dynamic event) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event['title'] ?? 'Community Drive',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  event['address'] ?? 'Pune, Maharashtra',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event['eventDate'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _donationMiniCard(dynamic d) {
    final status = d['status'] ?? 'AVAILABLE';
    final statusColor = status == 'AVAILABLE'
        ? Colors.green.shade700
        : status == 'CLAIMED'
            ? Colors.orange.shade700
            : Colors.grey.shade600;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.volunteer_activism,
                color: Colors.green.shade700, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['title'] ?? 'Donation Item',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF111111)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  d['donorName'] ?? 'Anonymous Donor',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  TAB 3 — EVENTS & MAP (List ↔ Map toggle)
// ══════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════
//  TAB 1 — DONATE  (Browse Donations | NGO Demands Board toggle)
// ══════════════════════════════════════════════════════════════════════════

class _DonateTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const _DonateTab({required this.user});

  @override
  State<_DonateTab> createState() => _DonateTabState();
}

class _DonateTabState extends State<_DonateTab> {
  int _subIndex = 0; // 0 = Browse Donations, 1 = NGO Demands

  @override
  Widget build(BuildContext context) {
    final isRecycler = (widget.user['role'] ?? '') == 'RECYCLER';

    return Column(
      children: [
        if (isRecycler)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.teal.shade50,
            child: Row(
              children: [
                Icon(Icons.recycling, color: Colors.teal.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '📦 Recycler View: Browsing community listings. Use the Recycle tab to post or claim scrap materials.',
                    style: TextStyle(fontSize: 11.5, color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        // ── Sub-tab toggle bar ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              _subTab(
                label: '🫶  Browse Donations',
                active: _subIndex == 0,
                onTap: () => setState(() => _subIndex = 0),
              ),
              const SizedBox(width: 10),
              _subTab(
                label: '📋  NGO Demands Board',
                active: _subIndex == 1,
                onTap: () => setState(() => _subIndex = 1),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _subIndex == 0
                ? BrowseDonationsFeed(
                    key: const ValueKey('browse'), user: widget.user)
                : NgoRequirementsScreen(
                    key: const ValueKey('demands'), user: widget.user),
          ),
        ),
      ],
    );
  }

  Widget _subTab(
      {required String label,
      required bool active,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF2E7D32) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF666666),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  TAB 3 — EXPLORE  (Events | NGO Directory | Achievements | Map)
// ══════════════════════════════════════════════════════════════════════════

class _ExploreTab extends StatefulWidget {
  final Map<String, dynamic> user;
  const _ExploreTab({required this.user});

  @override
  State<_ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<_ExploreTab> {
  int _subIndex = 0;

  static const _tabs = [
    (icon: '📅', label: 'Events'),
    (icon: '🏢', label: 'NGO Directory'),
    (icon: '🏆', label: 'Achievements'),
    (icon: '🗺️', label: 'Map'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Horizontal scrollable sub-tab pills ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final active = _subIndex == i;
                return Padding(
                  padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _subIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${t.icon}  ${t.label}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color:
                              active ? Colors.white : const Color(0xFF555555),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        // ── Content ──
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_subIndex) {
      case 0:
        return NgoEventsFeed(key: const ValueKey('events'), user: widget.user);
      case 1:
        return NgoDirectoryScreen(
            key: const ValueKey('directory'), user: widget.user);
      case 2:
        return NgoAchievementsScreen(
            key: const ValueKey('achievements'), user: widget.user);
      case 3:
        return _EmbeddedMapView(
            key: const ValueKey('map'), user: widget.user);
      default:
        return NgoEventsFeed(key: const ValueKey('events'), user: widget.user);
    }
  }
}

// Embedded map view (reuses existing DonationsMapScreen logic)
class _EmbeddedMapView extends StatefulWidget {
  final Map<String, dynamic> user;
  const _EmbeddedMapView({super.key, required this.user});

  @override
  State<_EmbeddedMapView> createState() => _EmbeddedMapViewState();
}

class _EmbeddedMapViewState extends State<_EmbeddedMapView> {
  final MapController _mapCtrl = MapController();
  List<dynamic> _donations = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _ngoOffices = [
    {
      'name': 'SAMS Relief Network HQ',
      'address': 'Kothrud, Pune, MH 411038',
      'location': const LatLng(18.5074, 73.8077),
    },
    {
      'name': 'Smile Foundation Pune',
      'address': 'Deccan Gymkhana, Pune',
      'location': const LatLng(18.5167, 73.8412),
    },
    {
      'name': 'Goonj Urban Relief Hub',
      'address': 'Warje, Pune',
      'location': const LatLng(18.4800, 73.8000),
    },
    {
      'name': 'Deepastambha Care Foundation',
      'address': 'Viman Nagar, Pune',
      'location': const LatLng(18.5679, 73.9143),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await ApiService.get('/donations/nearby');
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body)['data'] as List<dynamic>;
        if (mounted) setState(() => _donations = all);
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
    }

    final donationMarkers = _donations
        .where((d) =>
            d['latitude'] != null &&
            d['longitude'] != null &&
            d['status'] == 'AVAILABLE')
        .map((d) => Marker(
              point: LatLng(
                  (d['latitude'] as num).toDouble(),
                  (d['longitude'] as num).toDouble()),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => _showDonationSheet(d),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volunteer_activism,
                      color: Colors.white, size: 18),
                ),
              ),
            ))
        .toList();

    final ngoMarkers = _ngoOffices
        .map((n) => Marker(
              point: n['location'] as LatLng,
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => _showNgoSheet(n),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.business, color: Colors.white, size: 18),
                ),
              ),
            ))
        .toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapCtrl,
          options: const MapOptions(
            initialCenter: LatLng(18.5204, 73.8567),
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            MarkerLayer(markers: [...ngoMarkers, ...donationMarkers]),
          ],
        ),
        // ── Legend ──
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _legendItem(Colors.blue.shade700, '🏢 NGO Offices'),
                const SizedBox(height: 4),
                _legendItem(const Color(0xFF2E7D32), '🫶 Donation Pickups'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      );

  void _showDonationSheet(dynamic d) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d['title'] ?? 'Donation',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('By: ${d['donorName'] ?? 'Anonymous'}',
                style: const TextStyle(color: Color(0xFF666666))),
            const SizedBox(height: 4),
            Text('Status: ${d['status'] ?? 'AVAILABLE'}',
                style:
                    const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showNgoSheet(Map<String, dynamic> n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (c) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n['name'] as String,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(n['address'] as String,
                style: const TextStyle(color: Color(0xFF666666))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text('Get Directions',
                  style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final loc = n['location'] as LatLng;
                final url =
                    'https://maps.google.com/?q=${loc.latitude},${loc.longitude}';
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  TAB 4 — PROFILE
// ══════════════════════════════════════════════════════════════════════════

class _ProfileTab extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isNgo;
  final bool isDonor;
  final bool isAdmin;
  final bool notificationsEnabled;
  final void Function(bool) onToggleNotifications;
  final void Function(Map<String, dynamic>) onUserUpdated;

  const _ProfileTab({
    required this.user,
    required this.isNgo,
    required this.isDonor,
    required this.isAdmin,
    required this.notificationsEnabled,
    required this.onToggleNotifications,
    required this.onUserUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final name = user['name'] ?? 'User';
    final email = user['email'] ?? '';
    final role = user['role'] ?? 'DONOR';
    final photoUrl = user['profilePhotoUrl'] ?? '';

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Profile header ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.green.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      photoUrl.startsWith('http') ? NetworkImage(photoUrl) : null,
                  child: !photoUrl.startsWith('http')
                      ? Text(
                          (name as String)[0].toUpperCase(),
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(name as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(email as String,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Impact Dashboard card ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => ImpactDashboardScreen(user: user)),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.white, size: 32),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Impact Dashboard',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'View your donation history, stats & activity',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Menu items ──
          if (isDonor)
            _profileTile(
              context,
              icon: Icons.person_outline,
              title: 'Edit Profile & Details',
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => EditDonorProfileScreen(user: user)),
                );
                if (updated is Map<String, dynamic>) onUserUpdated(updated);
              },
            ),

          if (isNgo) ...[
            _profileTile(
              context,
              icon: Icons.edit_note,
              title: 'Edit NGO Public Profile',
              onTap: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (c) => EditNgoProfileScreen(user: user)),
                );
                if (updated is Map<String, dynamic>) onUserUpdated(updated);
              },
            ),
            _profileTile(
              context,
              icon: Icons.warning_amber,
              title: 'Disaster Relief Broadcast Manager',
              iconColor: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) =>
                        DisasterModeManagerScreen(user: user)),
              ),
            ),
          ],

          _profileTile(
            context,
            icon: Icons.map_rounded,
            title: 'Nearby NGOs — Map View',
            iconColor: const Color(0xFF00838F),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (c) => _StandaloneMapPage(user: user)),
            ),
          ),

          if (isAdmin)
            _profileTile(
              context,
              icon: Icons.admin_panel_settings,
              title: 'Admin Panel',
              iconColor: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (c) => const AdminDashboardScreen()),
              ),
            ),

          const Divider(height: 8),

          // ── Notifications toggle ──
          SwitchListTile(
            secondary: Icon(
              notificationsEnabled
                  ? Icons.notifications_active
                  : Icons.notifications_off,
              color: notificationsEnabled ? Colors.green : Colors.grey,
            ),
            title: const Text('In-App Notifications',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(notificationsEnabled
                ? 'Notifications Enabled'
                : 'Notifications Muted'),
            value: notificationsEnabled,
            activeThumbColor: Colors.green,
            onChanged: onToggleNotifications,
          ),

          const Divider(height: 8),

          // ── Logout ──
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (c) => const AuthScreen()),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static Widget _profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF2E7D32),
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFAAAAAA)),
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  STANDALONE MAP PAGE  — full-screen NGO & Donation map
//  Launched from: Home "Nearby NGOs" quick action & Profile "Map View" tile
// ══════════════════════════════════════════════════════════════════════════

class _StandaloneMapPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const _StandaloneMapPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map_rounded, size: 22),
            SizedBox(width: 8),
            Text('Nearby NGOs & Donations',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _EmbeddedMapView(user: user),
    );
  }
}
