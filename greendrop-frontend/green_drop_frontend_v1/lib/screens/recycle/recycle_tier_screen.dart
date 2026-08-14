import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/qr_collection_modal.dart';
import '../chat/chat_screen.dart';
import 'create_recycle_item_screen.dart';

// ─────────────────────────────────────────────────────────────────────────
//  RecycleTierScreen  –  Donor-Recycler interaction hub
//  • Donors post scrap batches (FAB visible ONLY for DONOR role)
//  • Recyclers send a pickup request  → Donor accepts/rejects
//  • After acceptance: location revealed, chat unlocked, QR handshake
//  • Donor confirms handover to complete the recycle cycle
// ─────────────────────────────────────────────────────────────────────────
class RecycleTierScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const RecycleTierScreen({super.key, required this.user});

  @override
  State<RecycleTierScreen> createState() => _RecycleTierScreenState();
}

class _RecycleTierScreenState extends State<RecycleTierScreen> {
  List<dynamic> _recycleItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  String get _role => widget.user['role'] ?? 'DONOR';
  bool get _isDonor => _role == 'DONOR';
  bool get _isRecycler => _role == 'RECYCLER';

  @override
  void initState() {
    super.initState();
    _fetchRecycleItems();
  }

  Future<void> _fetchRecycleItems() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/donations/nearby');
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body)['data'] as List<dynamic>;
        final fetched = all.where((item) {
          final isRecycle = item['isRecycleItem'] == true;
          final category = (item['category'] ?? '').toString().toLowerCase();
          return isRecycle ||
              category.contains('recycle') ||
              category.contains('scrap') ||
              category.contains('e-waste');
        }).toList();

        if (mounted) {
          setState(() {
            _recycleItems = fetched;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Recycler sends pickup request to donor ──────────────────────────────
  Future<void> _sendPickupRequest(Map<String, dynamic> item) async {
    try {
      await ApiService.patch('/donations/${item['_id']}/request', {
        'ngoId': widget.user['_id'],
        'ngoName': widget.user['name'],
      });
      NotificationService().showNotification(
        id: 202,
        title: '♻️ Pickup Requested!',
        body: '${widget.user['name']} has requested your scrap batch "${item['title']}".',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.teal,
          content: Text('✅ Pickup request sent to Donor! Awaiting acceptance...'),
        ),
      );
      _fetchRecycleItems();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ── Donor accepts recycler's request ───────────────────────────────────
  Future<void> _acceptRequest(Map<String, dynamic> item) async {
    await ApiService.patch('/donations/${item['_id']}/accept', {});
    _fetchRecycleItems();
  }

  // ── Donor confirms handover  ────────────────────────────────────────────
  Future<void> _confirmHandover(Map<String, dynamic> item) async {
    await ApiService.post('/donations/${item['_id']}/confirm-handover', {});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.teal,
        content: Text('🎉 Handover confirmed! Batch moved to your Recycle Impact History.'),
      ),
    );
    _fetchRecycleItems();
  }

  List<dynamic> get _filteredItems {
    if (_selectedCategory == 'All') return _recycleItems;
    return _recycleItems.where((i) {
      final cat = (i['category'] ?? '').toString();
      return cat.contains(_selectedCategory);
    }).toList();
  }

  // ── Full-screen image gallery modal ────────────────────────────────────
  void _showImageGallery(List<dynamic> photos) {
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
          height: MediaQuery.of(context).size.height * 0.82,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📷 Scrap Photos (${photos.length})',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(c),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                                errorBuilder: (_, _, v) => const Icon(Icons.broken_image, color: Colors.white, size: 60),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text('Swipe left/right to view all photos', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // ── FAB: only DONORS can post recycling material ─────────────────
      floatingActionButton: _isDonor
          ? FloatingActionButton.extended(
              backgroundColor: Colors.teal.shade900,
              icon: const Icon(Icons.add_circle, color: Colors.white),
              label: const Text(
                'Post Recycling Material',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onPressed: () async {
                final posted = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (c) => CreateRecycleItemScreen(user: widget.user)),
                );
                if (posted == true) _fetchRecycleItems();
              },
            )
          : null,
      body: RefreshIndicator(
        color: Colors.teal.shade900,
        onRefresh: _fetchRecycleItems,
        child: Column(
          children: [
            // ── HEADER BANNER ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade900, Colors.teal.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
              ),
              child: Row(
                children: [
                  const _SpinningRecycleLogo(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '♻️ Zero-Landfill Recycle & Upcycle Hub',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isRecycler
                              ? 'Browse donor-posted scrap batches. Send a pickup request and coordinate collection.'
                              : 'Post your scrap material for certified recyclers to pick up.',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── CATEGORY FILTER CHIPS ─────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _filterChip('All', '✓ All ♻️'),
                  _filterChip('Paper', 'Paper 📄'),
                  _filterChip('Textiles', 'Textiles 👕'),
                  _filterChip('E-Waste', 'E-Waste 💻'),
                  _filterChip('Plastics', 'Plastics 📦'),
                  _filterChip('Metal', 'Metal 🔩'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── ITEMS LIST ────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : _filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.recycling_outlined, size: 54, color: Colors.teal.shade200),
                              const SizedBox(height: 12),
                              Text(
                                _isDonor
                                    ? 'No recycling posts yet.\nTap the button below to post your first scrap batch!'
                                    : 'No recycling batches available yet.\nCheck back soon!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey, fontSize: 13.5, height: 1.4),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                          itemCount: _filteredItems.length,
                          itemBuilder: (c, i) => _buildRecycleCard(_filteredItems[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecycleCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'AVAILABLE';
    final isOwner = item['donorId'] == widget.user['_id'];
    final photos = (item['photoUrls'] as List<dynamic>?) ?? [];
    final firstPhoto = photos.isNotEmpty ? photos[0].toString() : '';
    final title = item['title'] ?? 'Recyclable Material';
    final category = (item['category'] ?? 'Recycle').replaceAll('Recycle - ', '');
    final quantity = item['quantity'] ?? '—';
    final weightKg = item['weightKg'] ?? '—';
    final donorName = item['donorName'] ?? 'Donor';
    final requestedByName = item['requestedByNgoName'] ?? item['requestedByName'] ?? '';
    final requestedById = item['requestedByNgoId'] ?? item['requestedById'] ?? '';
    final verCode = item['verificationCode'] ?? '000000';

    // Location: only shown after acceptance
    final addressStr = (status == 'ACCEPTED' || status == 'CODE_VERIFIED' || status == 'COMPLETED')
        ? (item['address'] is Map
            ? (item['address']['formattedAddress'] ?? item['address'].toString())
            : (item['address']?.toString() ?? 'Pune, India'))
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.teal.shade100, width: 1),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TITLE ROW + PHOTO THUMBNAIL ──────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clickable photo thumbnail
                GestureDetector(
                  onTap: () => _showImageGallery(photos),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 78,
                          height: 78,
                          child: firstPhoto.isNotEmpty
                              ? (firstPhoto.startsWith('data:image')
                                  ? Image.memory(base64Decode(firstPhoto.split(',').last), fit: BoxFit.cover)
                                  : Image.network(
                                      firstPhoto,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, v) => Container(
                                        color: Colors.teal.shade50,
                                        child: Icon(Icons.recycling, size: 34, color: Colors.teal.shade700),
                                      ),
                                    ))
                              : Container(
                                  color: Colors.teal.shade50,
                                  child: Icon(Icons.recycling, size: 34, color: Colors.teal.shade700),
                                ),
                        ),
                      ),
                      if (photos.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '📷 ${photos.length}',
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
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(
                        isOwner ? '📤 Posted by: You' : '👤 Posted by: $donorName',
                        style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _chip(category, Colors.teal.shade50, Colors.teal.shade900),
                          _statusChip(status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── PHOTO PREVIEW STRIP (if multiple) ───────────────────
            if (photos.length > 1) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 62,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  itemBuilder: (ctx, idx) {
                    final pUrl = photos[idx].toString();
                    return GestureDetector(
                      onTap: () => _showImageGallery(photos),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: pUrl.startsWith('data:image')
                              ? Image.memory(base64Decode(pUrl.split(',').last), fit: BoxFit.cover)
                              : Image.network(pUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, _, v) => const Icon(Icons.image, color: Colors.teal)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),

            // ── DETAILS BOX ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.scale_outlined, size: 14, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text('$weightKg kg  •  Qty: $quantity',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 4),
                        // Location – revealed ONLY after acceptance
                        if (addressStr != null)
                          Row(children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.teal),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text('Pickup: $addressStr',
                                  style: const TextStyle(fontSize: 11.5, color: Colors.black87)),
                            ),
                          ])
                        else
                          Row(children: [
                            const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              _isRecycler
                                  ? 'Location revealed after donor accepts request'
                                  : 'Location shared after accepting pickup request',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ══════════════════════════════════════════════════════════
            //  INTERACTION BUTTONS — mirrors Donor-NGO flow exactly
            // ══════════════════════════════════════════════════════════

            // (A) RECYCLER: send pickup request when item is AVAILABLE
            if (_isRecycler && status == 'AVAILABLE')
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade900,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                label: const Text('Send Pickup Request ♻️',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _sendPickupRequest(item),
              ),

            // (A2) RECYCLER: already requested — show waiting status
            if (_isRecycler && status == 'REQUESTED' && requestedById == widget.user['_id'])
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: const Row(children: [
                  Icon(Icons.hourglass_top_rounded, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('⏳ Request sent – awaiting donor acceptance...',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.orange)),
                  ),
                ]),
              ),

            // (B) DONOR: accept / reject recycler's pickup request
            if (isOwner && status == 'REQUESTED' && requestedByName.isNotEmpty) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: Text('Accept request from $requestedByName',
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                      onPressed: () => _acceptRequest(item),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    label: const Text('Reject', style: TextStyle(color: Colors.red, fontSize: 12)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                    onPressed: () async {
                      await ApiService.patch('/donations/${item['_id']}/reject', {});
                      _fetchRecycleItems();
                    },
                  ),
                ],
              ),
            ],

            // (C) CODE_VERIFIED — Donor confirms handover
            if (status == 'CODE_VERIFIED') ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade600, width: 1.5),
                ),
                child: Column(
                  children: [
                    const Row(children: [
                      Icon(Icons.check_circle, color: Colors.teal, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('✅ Recycler Passcode Verified! Tap to Confirm Handover.',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (isOwner)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          minimumSize: const Size(double.infinity, 42),
                        ),
                        icon: const Icon(Icons.handshake, color: Colors.white),
                        label: const Text('Confirm & Complete Recycle Handover',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        onPressed: () => _confirmHandover(item),
                      ),
                  ],
                ),
              ),
            ],

            // (D) ACCEPTED or beyond — connection info + QR + Chat
            if (status == 'ACCEPTED' || status == 'CODE_VERIFIED' || status == 'COMPLETED') ...[
              // Connected-with banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.recycling, color: Colors.teal, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOwner
                            ? '♻️ Connected with Recycler: $requestedByName'
                            : '♻️ Pickup accepted by: $donorName',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Colors.teal.shade900),
                      ),
                    ),
                  ],
                ),
              ),

              // QR Handshake + Chat buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.teal.shade700),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      ),
                      icon: Icon(Icons.qr_code, color: Colors.teal.shade800, size: 16),
                      label: Text(
                        _isRecycler ? 'Verify QR Code' : 'QR Pass 🔑',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
                      ),
                      onPressed: () {
                        QrCollectionModal.show(
                          context,
                          donationId: item['_id'],
                          verificationCode: verCode,
                          itemTitle: title,
                          isNgo: _isRecycler, // recycler scans, donor shows
                          onCollectionVerified: _fetchRecycleItems,
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
                      ),
                      icon: const Icon(Icons.chat, color: Colors.white, size: 16),
                      label: const Text('1-on-1 Chat 💬',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ChatScreen(
                              donationId: item['_id'],
                              currentUserId: widget.user['_id'],
                              recipientId: isOwner ? requestedById : item['donorId'],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],

            // (E) COMPLETED badge
            if (status == 'COMPLETED')
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('🎉 Zero-Landfill Handover Complete! Batch recycled successfully.',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.green)),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.3)),
        ),
        child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
      );

  Widget _statusChip(String status) {
    Color bg;
    Color fg;
    String label;
    if (status == 'AVAILABLE') {
      bg = Colors.teal.shade50; fg = Colors.teal.shade800; label = '🟢 AVAILABLE';
    } else if (status == 'REQUESTED') {
      bg = Colors.orange.shade50; fg = Colors.orange.shade900; label = '⏳ REQUESTED';
    } else if (status == 'ACCEPTED') {
      bg = Colors.blue.shade50; fg = Colors.blue.shade900; label = '✅ ACCEPTED';
    } else if (status == 'CODE_VERIFIED') {
      bg = Colors.purple.shade50; fg = Colors.purple.shade900; label = '🔐 CODE VERIFIED';
    } else if (status == 'COMPLETED') {
      bg = Colors.green.shade50; fg = Colors.green.shade900; label = '♻️ RECYCLED';
    } else {
      bg = Colors.grey.shade100; fg = Colors.grey.shade700; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  Widget _filterChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        backgroundColor: Colors.white,
        selectedColor: Colors.teal.shade800,
        side: BorderSide(color: isSelected ? Colors.teal.shade800 : Colors.grey.shade300),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
        onSelected: (_) => setState(() => _selectedCategory = key),
      ),
    );
  }
}

// ─── Spinning animation for header icon ──────────────────────────────────────
class _SpinningRecycleLogo extends StatefulWidget {
  const _SpinningRecycleLogo();

  @override
  State<_SpinningRecycleLogo> createState() => _SpinningRecycleLogoState();
}

class _SpinningRecycleLogoState extends State<_SpinningRecycleLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: const Icon(Icons.recycling, size: 44, color: Colors.tealAccent),
    );
  }
}
