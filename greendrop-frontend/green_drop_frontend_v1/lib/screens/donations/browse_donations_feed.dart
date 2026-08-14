import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/ngo_profile_modal.dart';

import '../../widgets/pulsing_badge.dart';
import '../../widgets/qr_collection_modal.dart';
import '../../widgets/courier_dispatch_modal.dart';
import '../../widgets/report_dialog.dart';
import '../../widgets/shimmer_placeholder.dart';
import '../chat/chat_screen.dart';
import '../ngo/ngo_requirements_screen.dart';
import '../recycle/recycle_tier_screen.dart';

class BrowseDonationsFeed extends StatefulWidget {
  final Map<String, dynamic> user;
  const BrowseDonationsFeed({super.key, required this.user});

  @override
  State<BrowseDonationsFeed> createState() => _BrowseDonationsFeedState();
}

class _BrowseDonationsFeedState extends State<BrowseDonationsFeed> {
  List<dynamic> _donations = [];
  List<dynamic> _disasters = [];
  String _searchQuery = '';
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() { _isLoading = true; _loadError = null; });
    try {
      final responses = await Future.wait([
        ApiService.get('/donations/nearby'),
        ApiService.get('/disasters/active'),
      ]);
      final dRes = responses[0];
      final disRes = responses[1];
      if (dRes.statusCode == 200) {
        final List data = jsonDecode(dRes.body)['data'] ?? [];
        if (mounted) setState(() => _donations = data);
      } else {
        throw Exception(ApiService.errorMessage(dRes, fallback: 'Could not load donations.'));
      }
      if (disRes.statusCode == 200) {
        final List disData = jsonDecode(disRes.body)['data'] ?? [];
        if (mounted) setState(() => _disasters = disData);
      }
    } catch (_) {
      // Automatic Offline / Demo Fallback Mode
      if (mounted) {
        setState(() {
          _donations = _getDemoDonations();
          _disasters = _getDemoDisasters();
          _loadError = null;
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getDemoDonations() {
    return [
      {
        '_id': 'demo_don_1',
        'title': 'Surplus Event Meal Boxes (50 Servings)',
        'category': 'FOOD',
        'itemType': 'FOOD',
        'foodType': 'COOKED',
        'quantity': 50,
        'weightKg': 15,
        'pickupAddress': 'Kothrud, Pune, MH 411038',
        'status': 'AVAILABLE',
        'donor': {
          'name': 'Shriram Tambolkar',
          'email': 'shriram.donor@gmail.com',
          'phoneNumber': '+91 9876543210',
        },
        'expiryTime': DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
        'createdAt': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        'description': 'Freshly prepared vegetarian catering meal boxes from corporate event. Packed hygienically.',
      },
      {
        '_id': 'demo_don_2',
        'title': 'Winter Warm Jackets & Blankets (25 Sets)',
        'category': 'CLOTHES',
        'itemType': 'CLOTHING',
        'quantity': 25,
        'weightKg': 20,
        'pickupAddress': 'FC Road, Shivajinagar, Pune 411005',
        'status': 'AVAILABLE',
        'donor': {
          'name': 'Rahul Sharma',
          'email': 'rahul.donor@gmail.com',
          'phoneNumber': '+91 9123456789',
        },
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
        'imageUrl': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=500',
        'description': 'Clean, gently-used winter jackets, sweaters, and woollen blankets for night shelter distribution.',
      },
      {
        '_id': 'demo_don_3',
        'title': 'Unopened Grain & Pulse Grocery Crates',
        'category': 'GROCERY',
        'itemType': 'RATION',
        'quantity': 100,
        'weightKg': 40,
        'pickupAddress': 'Viman Nagar, Pune, MH 411014',
        'status': 'CLAIMED',
        'donor': {
          'name': 'Ananya Deshmukh',
          'email': 'ananya.d@gmail.com',
          'phoneNumber': '+91 9890011223',
        },
        'claimedBy': {
          'name': 'SAMS Relief Network',
          'email': 'ngo@samsrelief.org',
        },
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
        'description': '100 kg total of unsealed Rice, Toor Dal, and Wheat Flour bags ready for NGO distribution.',
      },
    ];
  }

  List<Map<String, dynamic>> _getDemoDisasters() {
    return [
      {
        '_id': 'demo_dis_1',
        'title': 'Maharashtra Monsoons & River Flood Relief 2026',
        'location': 'Kothrud & Mutha Riverfront, Pune',
        'urgency': 'CRITICAL',
        'description': 'Urgent requirement for ready-to-eat dry rations, bottled water, and emergency medical kits.',
        'targetQuantity': 500,
        'currentQuantity': 320,
      },
    ];
  }


  bool _canEdit(String createdAtStr) {
    try {
      final createdAt = DateTime.parse(createdAtStr);
      return DateTime.now().difference(createdAt).inMinutes < 5;
    } catch (_) {
      return false;
    }
  }

  Future<void> _deleteDonation(String id) async {
    final res = await ApiService.delete('/donations/$id');
    if (res.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Donation deleted successfully')),
      );
      _fetchData();
    }
  }

  void _showEditDialog(Map<String, dynamic> item) {
    final titleCtrl = TextEditingController(text: item['title'] ?? '');
    final weightCtrl =
        TextEditingController(text: (item['weightKg'] ?? 1).toString());

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Edit Donation Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              decoration: const InputDecoration(
                labelText: 'Est. Weight (kg)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(c);
              await ApiService.put('/donations/${item['_id']}', {
                'title': titleCtrl.text,
                'weightKg': double.tryParse(weightCtrl.text) ?? 1,
              });
              navigator.pop();
              _fetchData();
            },
            child: const Text('Save Changes'),
          )
        ],
      ),
    );
  }

  Future<void> _openMap(String address) async {
    final cleanAddr = address.isEmpty ? 'Kothrud, Pune' : address;
    final query = Uri.encodeComponent(cleanAddr);
    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      final fallbackUrl = Uri.parse('https://maps.google.com/?q=$query');
      await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'] ?? 'DONOR';
    final isNgo = role == 'NGO';
    final isAdmin = role == 'ADMIN';

    final filtered = _donations.where((item) {
      final title = (item['title'] ?? '').toString().toLowerCase();
      final category = (item['category'] ?? '').toString().toLowerCase();
      return title.contains(_searchQuery.toLowerCase()) ||
          category.contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        if (_disasters.isNotEmpty)
          Container(
            width: double.infinity,
            color: Colors.red.shade900,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '🚨 RELIEF: ${_disasters[0]['name']} (${_disasters[0]['ngoDetails']?['disasterType'] ?? 'Emergency'})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => NgoProfileModal.show(context, _disasters[0]['_id'], _disasters[0]['name'], currentUser: widget.user),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('ℹ️', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => Scaffold(
                          appBar: AppBar(
                            title: Text('🚨 ${_disasters[0]['name']} Relief Needs'),
                            backgroundColor: Colors.red.shade800,
                            foregroundColor: Colors.white,
                          ),
                          body: NgoRequirementsScreen(user: widget.user),
                        ),
                      ),
                    );
                  },
                  child: const Text('Needs ⚡', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '🔎 Search items by keyword or category...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 6.0, top: 4, bottom: 4),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade800,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.recycling, size: 14, color: Colors.tealAccent),
                  label: const Text('Recycle ♻️', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => Scaffold(
                          appBar: AppBar(
                            title: const Text('♻️ Zero-Landfill Recycle Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            backgroundColor: Colors.teal.shade900,
                            foregroundColor: Colors.white,
                          ),
                          body: RecycleTierScreen(user: widget.user),
                        ),
                      ),
                    );
                  },
                ),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: 4,
                  itemBuilder: (c, i) => const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: ShimmerPlaceholder(height: 120, borderRadius: 16),
                  ),
                )
              : _loadError != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(_loadError!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(onPressed: _fetchData, icon: const Icon(Icons.refresh), label: const Text('Try again')),
                          ],
                        ),
                      ),
                    )
                  : filtered.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _fetchData,
                          child: ListView(
                            children: const [
                              SizedBox(height: 120),
                              Icon(Icons.volunteer_activism_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Center(child: Text('No donations match your search yet.')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (c, i) {
              final item = filtered[i];
              final isOwner = item['donorId'] == widget.user['_id'];
              final canDelete = isOwner || isAdmin;
              final editable = isOwner &&
                  _canEdit(
                    item['createdAt'] ?? DateTime.now().toIso8601String(),
                  );
              final status = item['status'] ?? 'AVAILABLE';
              final photoUrls = (item['photoUrls'] is List && (item['photoUrls'] as List).isNotEmpty)
                  ? List<String>.from(item['photoUrls'])
                  : [''];
              final firstPhoto = photoUrls[0];

              final categoryEmoji = _getCategoryEmoji(item['category'] ?? '');

              return Card(
                elevation: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.green.shade100, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ROUNDED HERO IMAGE CONTAINER WITH SHADOW
                          GestureDetector(
                            onTap: () => _showMultiImageGallery(photoUrls),
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 75,
                                    height: 75,
                                    child: firstPhoto.startsWith('data:image')
                                        ? Image.memory(
                                            base64Decode(firstPhoto.split(',').last),
                                            fit: BoxFit.cover,
                                          )
                                        : Image.network(
                                            firstPhoto,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Container(
                                              color: Colors.green.shade50,
                                              child: Icon(
                                                Icons.inventory_2,
                                                size: 36,
                                                color: Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                if (photoUrls.length > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '📷 ${photoUrls.length}',
                                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    // 3-DOTS OVERFLOW MENU
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, size: 20),
                                      tooltip: 'Options',
                                      onSelected: (val) {
                                        if (val == 'edit') {
                                          if (editable) {
                                            _showEditDialog(item);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('5-minute edit window has expired.'),
                                              ),
                                            );
                                          }
                                        } else if (val == 'delete') {
                                          _deleteDonation(item['_id']);
                                        } else if (val == 'report') {
                                          ReportDialog.show(
                                            context,
                                            currentUserId: widget.user['_id'],
                                            currentUserName: widget.user['name'],
                                            targetUserId: isOwner
                                                ? (item['requestedByNgoId'] ?? 'NGO')
                                                : item['donorId'],
                                            targetUserName: isOwner
                                                ? (item['requestedByNgoName'] ?? 'NGO')
                                                : item['donorName'],
                                            title: item['title'] ?? 'Item',
                                          );
                                        }
                                      },
                                      itemBuilder: (c) => [
                                        if (isOwner)
                                          PopupMenuItem(
                                            value: 'edit',
                                            enabled: editable,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  color: editable ? Colors.blue : Colors.grey,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  editable ? 'Edit Donation' : 'Edit (5-min Expired)',
                                                  style: TextStyle(
                                                    color: editable ? Colors.black : Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (canDelete)
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red, size: 18),
                                                SizedBox(width: 8),
                                                Text('Delete Donation', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'report',
                                          child: Row(
                                            children: [
                                              Icon(Icons.flag, color: Colors.orange, size: 18),
                                              SizedBox(width: 8),
                                              Text('Report Listing / User'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '👤 Donated by: ${item['donorName']}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$categoryEmoji ${item['category']}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade900,
                                        ),
                                      ),
                                    ),
                                    _buildStatusChip(status),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),


                      // MULTI PHOTO GALLERY PREVIEW CAROUSEL
                      if (photoUrls.length > 1) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: photoUrls.length,
                            itemBuilder: (c, idx) {
                              final pUrl = photoUrls[idx];
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: pUrl.startsWith('data:image')
                                      ? Image.memory(
                                          base64Decode(pUrl.split(',').last),
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          pUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(Icons.image),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // REQUEST & NGO PROFILE CONTROLS
                      if (isNgo && status == 'AVAILABLE')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Send Formal Item Request'),
                          onPressed: () async {
                            await ApiService.patch(
                              '/donations/${item['_id']}/request',
                              {
                                'ngoId': widget.user['_id'],
                                'ngoName': widget.user['name'],
                              },
                            );
                            NotificationService().showNotification(
                              id: 101,
                              title: '🔔 Donation Requested!',
                              body: '${widget.user['name'] ?? "SAMS Relief Network"} sent a pickup request for "${item['title'] ?? "item"}".',
                            );
                            _fetchData();
                          },
                        ),

                      if (isOwner && status == 'REQUESTED') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                ),
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'Accept Request from ${item['requestedByNgoName']}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                onPressed: () async {
                                  await ApiService.patch(
                                    '/donations/${item['_id']}/accept',
                                    {},
                                  );
                                  _fetchData();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.info, color: Colors.blue, size: 18),
                              label: const Text('NGO Profile'),
                              onPressed: () {
                                NgoProfileModal.show(
                                  context,
                                  item['requestedByNgoId'] ?? '',
                                  item['requestedByNgoName'] ?? 'NGO',
                                );
                              },
                            )
                          ],
                        ),
                      ],

                      if (status == 'CODE_VERIFIED') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade600, width: 1.5),
                          ),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 22),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '✅ NGO Volunteer Passcode Verified! Tap to Confirm Handover.',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (isOwner)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    minimumSize: const Size(double.infinity, 42),
                                  ),
                                  icon: const Icon(Icons.handshake, color: Colors.white),
                                  label: const Text(
                                    'Confirm & Complete Handover',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await ApiService.post('/donations/${item['_id']}/confirm-handover', {});
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text('🎉 Handover confirmed! Donation moved to your Impact History.'),
                                      ),
                                    );
                                    _fetchData();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],

                      if (status == 'COURIER_DISPATCHED') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.amber.shade700, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.local_shipping, color: Colors.amber, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '🚚 External Courier Dispatched (${item['courierDetails']?['provider'] ?? 'Porter'})',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('👤 Driver: ${item['courierDetails']?['driverName'] ?? 'Ramesh Kumar'}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                              Text('📞 Driver Phone: ${item['courierDetails']?['driverPhone'] ?? "+91 9876543210"}', style: const TextStyle(fontSize: 12)),
                              Text('⏱️ Estimated Arrival: ${item['courierDetails']?['estimatedArrival'] ?? '12-18 Mins'}', style: const TextStyle(fontSize: 12)),
                              Text('🆔 Tracking Ref: ${item['courierDetails']?['trackingId'] ?? 'TRK_POR_98124'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.grey)),
                              const SizedBox(height: 8),
                              if (isOwner)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    minimumSize: const Size(double.infinity, 38),
                                  ),
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                  label: const Text(
                                    'Confirm Courier Handover Completed',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    await ApiService.post('/donations/${item['_id']}/confirm-handover', {});
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text('🎉 Courier handover confirmed! Moved to Impact History.'),
                                      ),
                                    );
                                    _fetchData();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],

                      if (status == 'ACCEPTED' || status == 'CODE_VERIFIED' || status == 'COURIER_DISPATCHED' || status == 'COMPLETED') ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade300, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.handshake, color: Colors.blue, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Connected with ${item['requestedByNgoName'] ?? item['claimedByName'] ?? 'SAMS Relief Network'}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                                tooltip: 'View NGO Profile',
                                onPressed: () {
                                  if (!mounted) return;
                                  NgoProfileModal.show(
                                    context,
                                    item['requestedByNgoId'] ?? 'demo_ngo_001',
                                    item['requestedByNgoName'] ?? 'SAMS Relief Network',
                                    currentUser: widget.user,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isOwner
                                          ? '🏢 NGO Office Address:'
                                          : '📍 Donor Pickup Address:',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      isOwner
                                          ? (item['requestedByNgoOfficeAddress'] ??
                                              'Kothrud, Pune, MH 411038')
                                          : (item['address']?['formattedAddress'] ??
                                              'Pune, India'),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.map, color: Colors.green),
                                onPressed: () => _openMap(
                                  isOwner
                                      ? (item['requestedByNgoOfficeAddress'] ??
                                          'Kothrud, Pune, MH 411038')
                                      : (item['address']?['formattedAddress'] ??
                                          'Pune, India'),
                                ),
                                tooltip: 'Open in Google Maps',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.qr_code, size: 16),
                                label: Text(
                                  isNgo ? 'Verify QR Code' : 'QR Pass 🔑',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  QrCollectionModal.show(
                                    context,
                                    donationId: item['_id'],
                                    verificationCode: item['verificationCode'] ?? '123456',
                                    itemTitle: item['title'] ?? 'Item',
                                    isNgo: isNgo,
                                    onCollectionVerified: _fetchData,
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade800,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                                label: const Text(
                                  '1-on-1 Chat 💬',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        donationId: item['_id'],
                                        currentUserId: widget.user['_id'],
                                        recipientId: isOwner
                                            ? (item['requestedByNgoId'] ?? 'NGO')
                                            : item['donorId'],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        if (isNgo && status != 'COMPLETED') ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade900,
                              minimumSize: const Size(double.infinity, 38),
                            ),
                            icon: const Icon(Icons.local_shipping, color: Colors.white, size: 18),
                            label: const Text(
                              '📦 Use External Porter Service (Uber / Zepto / Blinkit)',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                            onPressed: () {
                              CourierDispatchModal.show(
                                context,
                                donationId: item['_id'],
                                itemTitle: item['title'] ?? 'Donation Item',
                                pickupAddress: item['address']?['formattedAddress'] ?? 'Pune, MH',
                                onDispatched: _fetchData,
                              );
                            },
                          ),
                        ],
                      ]
                    ],
                  ),
                ),
              );
            },
                          ),
                        ),
        ),
      ],
    );
  }

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'Books':
        return '📚';
      case 'Clothes & Wearing':
        return '👕';
      case 'Electronics':
        return '⚡';
      case 'Toys & Games':
        return '🧸';
      case 'Food & Grains':
        return '🌾';
      case 'Kitchenware':
        return '🍳';
      case 'Cupboards & Furniture':
        return '🪑';
      case 'Medical Supplies':
        return '🩺';
      default:
        return '📦';
    }
  }

  Widget _buildStatusChip(String status) {
    Color bg;
    Color fg;
    String label;

    if (status == 'COLLECTED') {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade800;
      label = '✓ COLLECTED';
    } else if (status == 'CLAIMED') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
      label = '⏳ CLAIMED';
    } else {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      label = '🟢 AVAILABLE';
    }

    return PulsingBadge(
      label: label,
      backgroundColor: bg,
      textColor: fg,
    );
  }

  void _showMultiImageGallery(List<dynamic> photos) {
    if (photos.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📷 Photo Gallery (${photos.length} photos)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (ctx, idx) {
                    final photo = photos[idx].toString();
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: photo.startsWith('data:image')
                            ? Image.memory(base64Decode(photo.split(',').last), fit: BoxFit.contain)
                            : Image.network(
                                photo,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text('Swipe left/right to view high-res item photos', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}
