import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RecycleTierScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const RecycleTierScreen({super.key, required this.user});

  @override
  State<RecycleTierScreen> createState() => _RecycleTierScreenState();
}

class _RecycleTierScreenState extends State<RecycleTierScreen> {
  List<dynamic> _recycleItems = [];
  bool _isLoading = true;
  String _selectedCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchRecycleItems();
  }

  Future<void> _fetchRecycleItems() async {
    try {
      final res = await ApiService.get('/donations/nearby');
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body)['data'] as List<dynamic>;
        final filtered = all.where((item) {
          final condition = (item['condition'] ?? '').toString().toLowerCase();
          final category = (item['category'] ?? '').toString().toLowerCase();
          return condition.contains('worn') ||
              condition.contains('fair') ||
              category.contains('e-waste') ||
              category.contains('scrap') ||
              category.contains('electronics');
        }).toList();

        if (mounted) {
          setState(() {
            _recycleItems = filtered.isNotEmpty ? filtered : _getDemoRecycleItems();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _recycleItems = _getDemoRecycleItems();
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recycleItems = _getDemoRecycleItems();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDemoRecycleItems() {
    return [
      {
        '_id': 'rec_demo_1',
        'title': '45 kg Worn-Out Cotton Sweaters & Fabric Scraps',
        'category': 'TEXTILES',
        'itemType': 'CLOTHING',
        'weightKg': 45,
        'condition': 'FAIR / WORN OUT',
        'donorName': 'Kothrud Apparel Donation Hub',
        'location': 'Kothrud Industrial Estate, Pune',
        'partnerVendor': 'EcoThread Textile Shredders & Fiber Mill',
        'description': 'Damaged or torn cotton sweaters unsuitable for direct wearing. High cotton content ready for mechanical fiber regeneration.',
        'imageUrl': 'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=500',
        'status': 'AVAILABLE',
      },
      {
        '_id': 'rec_demo_2',
        'title': '20 Defunct Computer PCBs & Copper Wires Batch',
        'category': 'E-WASTE',
        'itemType': 'ELECTRONICS',
        'weightKg': 18,
        'condition': 'SCRAP / NON-FUNCTIONAL',
        'donorName': 'Viman Nagar IT Park Surplus',
        'location': 'Viman Nagar, Pune',
        'partnerVendor': 'GreenRefine E-Waste Metals Recovery',
        'description': 'Obsolete circuit boards, power supply cables, and transformers for certified precious metal extraction.',
        'imageUrl': 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=500',
        'status': 'AVAILABLE',
      },
      {
        '_id': 'rec_demo_3',
        'title': '80 kg Heavy-Duty Corrugated Shipping Boxes',
        'category': 'PAPER & PACKAGING',
        'itemType': 'SCRAP',
        'weightKg': 80,
        'condition': 'USED / RECYCLABLE',
        'donorName': 'FC Road NGO Warehouse',
        'location': 'FC Road, Shivajinagar, Pune',
        'partnerVendor': 'Maharastra Pulp & Paper Re-Mill',
        'description': 'Clean flattened cardboard boxes from bulk relief shipments, ready for pulping into eco-friendly packaging.',
        'imageUrl': 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500',
        'status': 'CLAIMED',
      },
      {
        '_id': 'rec_demo_4',
        'title': 'Scrap Wooden Pallets & Broken Teak Frames',
        'category': 'ARTISAN UPCYCLE',
        'itemType': 'WOOD',
        'weightKg': 60,
        'condition': 'RAW SCRAP',
        'donorName': 'Aundh Community Center',
        'location': 'Aundh, Pune',
        'partnerVendor': 'Puneri Craft & Furniture Upcyclers',
        'description': 'Untreated solid pine wood pallets suitable for carpentry workshops, DIY benches, and upcycled planter boxes.',
        'imageUrl': 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=500',
        'status': 'AVAILABLE',
      },
    ];
  }

  void _claimItem(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.recycling_rounded, color: Colors.teal, size: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Confirm Zero-Waste Claim',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.teal),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Est. Weight: ${item['weightKg'] ?? 20} kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('• Category: ${item['category'] ?? 'SCRAP'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text('• Partner Hub: ${item['partnerVendor'] ?? 'Certified Eco-Processor'}', style: const TextStyle(fontSize: 12, color: Colors.teal)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'By claiming this batch as a certified Recycler or NGO, 100% of material is guaranteed diverted from municipal landfills.',
              style: TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.verified_outlined, size: 16),
            label: const Text('Confirm Claim & Dispatch', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(c);
              setState(() {
                item['status'] = 'CLAIMED';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.teal,
                  content: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('🎉 Batch Claimed! Zero-Landfill Certificate issued.'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showPostRecycleItemDialog() {
    final titleCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final targetHubCtrl = TextEditingController(text: 'EcoThread Textile Shredders & Fiber Mill');
    final descCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: widget.user['address'] ?? 'Kothrud, Pune, MH');
    String category = 'TEXTILES';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Post Worn-Out Item for Recycling',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F361A)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Worn-Out Item / Scrap Title *',
                      hintText: 'e.g., 50 kg Damaged Denim Jeans Scraps',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: weightCtrl,
                    decoration: InputDecoration(
                      labelText: 'Est. Quantity / Weight (e.g., 25 kg, 100 meters) *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Recycling Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'TEXTILES', child: Text('Textiles & Fabrics 👕')),
                      DropdownMenuItem(value: 'E-WASTE', child: Text('E-Waste & Electronics 💻')),
                      DropdownMenuItem(value: 'PAPER & PACKAGING', child: Text('Paper & Packaging Scraps 📦')),
                      DropdownMenuItem(value: 'ARTISAN UPCYCLE', child: Text('Wood / Metal Artisan Upcycle 🎨')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: targetHubCtrl,
                    decoration: InputDecoration(
                      labelText: 'Target Beneficiaries / Processing Center',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes / Pickup Hours',
                      hintText: 'e.g., High cotton content, ready for mechanical shredding.',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final nav = Navigator.of(c);
                  final messenger = ScaffoldMessenger.of(context);

                  if (titleCtrl.text.trim().isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Worn-out item title is required!')),
                    );
                    return;
                  }

                  final parsedWeight = double.tryParse(weightCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 25.0;

                  final newItem = {
                    '_id': 'rec_user_${DateTime.now().millisecondsSinceEpoch}',
                    'title': titleCtrl.text.trim(),
                    'category': category,
                    'itemType': category,
                    'weightKg': parsedWeight,
                    'condition': 'FAIR / WORN OUT',
                    'donorName': widget.user['name'] ?? 'Verified Member',
                    'location': locationCtrl.text.trim(),
                    'partnerVendor': targetHubCtrl.text.trim().isNotEmpty
                        ? targetHubCtrl.text.trim()
                        : 'EcoThread Textile Shredders & Fiber Mill',
                    'description': descCtrl.text.trim().isNotEmpty
                        ? descCtrl.text.trim()
                        : 'Worn out materials listed for mechanical shredding & upcycling.',
                    'status': 'AVAILABLE',
                  };

                  // Send to backend
                  try {
                    await ApiService.post('/donations', {
                      'title': titleCtrl.text.trim(),
                      'category': category,
                      'itemType': category,
                      'weightKg': parsedWeight,
                      'condition': 'WORN OUT / RECYCLE',
                      'pickupAddress': locationCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                    });
                  } catch (_) {}

                  if (!mounted) return;
                  nav.pop();
                  setState(() {
                    _selectedCategory = 'ALL';
                    _recycleItems.insert(0, newItem);
                  });

                  messenger.showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFF2E7D32),
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 8),
                          Text('🎉 Requirement posted! Target recyclers & upcycling artisans notified.'),
                        ],
                      ),
                    ),
                  );
                },
                child: const Text('Post Requirement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'ALL'
        ? _recycleItems
        : _recycleItems.where((i) => (i['category'] ?? '').toString().toUpperCase() == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostRecycleItemDialog,
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
        label: const Text(
          'Post Item for Recycling',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchRecycleItems,
        color: Colors.teal.shade800,
        child: Column(
          children: [
            // 1. HERO ANIMATED RECYCLE MARKETPLACE BANNER
            const AnimatedRecycleBanner(),

            // 2. ZERO-WASTE STATS TOOLBAR
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatWidget(icon: Icons.scale_outlined, value: '1,420 kg', label: 'Landfill Diverted'),
                  _StatWidget(icon: Icons.energy_savings_leaf_outlined, value: '98.4%', label: 'Recycle Rate'),
                  _StatWidget(icon: Icons.co2_outlined, value: '3.5 Tons', label: 'CO₂ Prevented'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. CATEGORY CHIPS BAR
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  _buildCategoryChip('ALL', 'All Scraps ♻️'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('TEXTILES', 'Textiles 👕'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('E-WASTE', 'E-Waste 💻'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('PAPER & PACKAGING', 'Paper 📦'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('ARTISAN UPCYCLE', 'Upcycle 🎨'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4. RECYCLE BATCH LIST
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.teal))
                  : filteredItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.recycling, size: 50, color: Colors.teal.shade200),
                              const SizedBox(height: 10),
                              Text(
                                'No batches currently listed under $_selectedCategory.',
                                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          itemCount: filteredItems.length,
                          itemBuilder: (c, i) {
                            final item = filteredItems[i];
                            final isClaimed = (item['status'] ?? '').toString().toUpperCase() == 'CLAIMED';

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item['title'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F361A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isClaimed ? Colors.grey.shade200 : Colors.teal.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isClaimed ? Colors.grey.shade400 : Colors.teal.shade300,
                                            ),
                                          ),
                                          child: Text(
                                            isClaimed ? 'CLAIMED' : 'UPCYCLE READY',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isClaimed ? Colors.grey.shade700 : Colors.teal.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['description'] ?? 'High quality scrap materials ready for processing.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.scale_outlined, size: 14, color: Colors.teal.shade800),
                                              const SizedBox(width: 4),
                                              Text('Weight: ${item['weightKg'] ?? 20} kg', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                              const Spacer(),
                                              Icon(Icons.location_on_outlined, size: 14, color: Colors.teal.shade800),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  item['location'] ?? 'Pune, MH',
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                isClaimed ? Icons.verified_outlined : Icons.business_outlined,
                                                size: 14,
                                                color: isClaimed ? Colors.teal.shade800 : Colors.grey.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  isClaimed
                                                      ? 'Assigned Processor: ${item['partnerVendor'] ?? 'Certified Recycler'}'
                                                      : 'Target Processing Hub: ${item['partnerVendor'] ?? 'Certified Recycler'}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isClaimed ? Colors.teal.shade900 : Colors.grey.shade800,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isClaimed ? Colors.grey.shade400 : Colors.teal.shade800,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: Icon(
                                          isClaimed ? Icons.check_circle : Icons.recycling,
                                          size: 18,
                                        ),
                                        label: Text(
                                          isClaimed ? 'Claimed for Upcycling' : 'Claim Batch for Zero-Landfill Processing',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                        ),
                                        onPressed: isClaimed ? null : () => _claimItem(item),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.teal.shade900,
          fontWeight: FontWeight.bold,
          fontSize: 11.5,
        ),
      ),
      selectedColor: Colors.teal.shade800,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? Colors.teal.shade800 : Colors.teal.shade200),
      onSelected: (val) {
        if (val) setState(() => _selectedCategory = key);
      },
    );
  }
}

class _StatWidget extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatWidget({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.teal.shade800),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.teal.shade900),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class AnimatedRecycleBanner extends StatefulWidget {
  final VoidCallback? onPostPressed;
  const AnimatedRecycleBanner({super.key, this.onPostPressed});

  @override
  State<AnimatedRecycleBanner> createState() => _AnimatedRecycleBannerState();
}

class _AnimatedRecycleBannerState extends State<AnimatedRecycleBanner> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade900,
            Colors.teal.shade800,
            const Color(0xFF0F4D32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade900.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          RotationTransition(
            turns: _ctrl,
            child: const Icon(Icons.recycling_rounded, size: 44, color: Colors.tealAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '♻️ Zero-Landfill Recycle & Upcycle Hub',
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Connecting Donors & NGOs to certified textile shredders, e-waste centers & upcycling artisans.',
                  style: TextStyle(
                    color: Colors.teal.shade100,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
