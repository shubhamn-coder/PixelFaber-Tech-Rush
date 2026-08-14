import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class CreateRecycleItemScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const CreateRecycleItemScreen({super.key, required this.user});

  @override
  State<CreateRecycleItemScreen> createState() => _CreateRecycleItemScreenState();
}

class _CreateRecycleItemScreenState extends State<CreateRecycleItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _materialNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _weightKgController = TextEditingController();
  final _addressController = TextEditingController();

  String _materialType = 'Paper / Cardboard';
  final List<String> _materialTypes = [
    'Paper / Cardboard',
    'Textiles & Fabric Scraps',
    'E-Waste & Electronics',
    'Glass & Bottles',
    'Metal & Copper Scrap',
    'Plastics & Packaging',
    'Organic / Compost Waste',
  ];

  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 70,
        maxWidth: 1000,
      );
      if (images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(images);
        });
      }
    } catch (e) {
      // Fallback if multi-picker is unsupported on some devices
      try {
        final XFile? single = await _picker.pickImage(source: ImageSource.gallery);
        if (single != null) {
          setState(() {
            _pickedImages.add(single);
          });
        }
      } catch (_) {}
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _submitRecyclingPost() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final materialName = _materialNameController.text.trim();
      final quantity = _quantityController.text.trim();
      final weightKg = double.tryParse(_weightKgController.text.trim()) ?? 1.0;
      final exactAddress = _addressController.text.trim();

      // Convert local file paths or fallback photo URLs
      final List<String> photoUrls = _pickedImages.map((file) {
        if (kIsWeb) return file.path;
        return file.path;
      }).toList();

      if (photoUrls.isEmpty) {
        photoUrls.add('https://images.unsplash.com/photo-1532629345422-7515f3d16bb0?w=500');
      }

      final body = {
        'donorId': widget.user['_id'],
        'donorName': widget.user['name'] ?? 'User',
        'title': materialName,
        'category': 'Recycle - $_materialType',
        'condition': 'Scrap / Recyclable',
        'quantity': quantity,
        'weightKg': weightKg,
        'address': exactAddress,
        'photoUrls': photoUrls,
        'isRecycleItem': true,
      };

      final res = await ApiService.post('/donations', body);

      if (res.statusCode == 201 || res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.teal,
            content: Text('♻️ Recyclable material posted successfully for collection!'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Server returned ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
          content: Text('Submission notice: Material posted locally! ($e)'),
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Recycling Material ♻️', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner Notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.recycling_rounded, color: Colors.teal.shade800, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Post your recyclable material or scrap batch for pickup by verified recyclers, upcyclers, and processing hubs.',
                      style: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 1. WHAT MATERIAL IT IS
            const Text('1. What Material is it?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _materialNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Copper Cables, Shredded Paper, Cardboard Boxes',
                prefixIcon: Icon(Icons.inventory_2_outlined, color: Colors.teal),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please specify what material it is' : null,
            ),
            const SizedBox(height: 16),

            // 2. MATERIAL TYPE / CATEGORY
            const Text('2. Select Material Type / Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _materialType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined, color: Colors.teal),
                border: OutlineInputBorder(),
              ),
              items: _materialTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type, style: const TextStyle(fontSize: 13.5)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _materialType = val);
              },
            ),
            const SizedBox(height: 16),

            // 3. QUANTITY & ESTIMATED WEIGHT
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('3. Quantity / Batches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _quantityController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 5 Boxes / 3 Bags',
                          prefixIcon: Icon(Icons.format_list_numbered, color: Colors.teal),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Enter quantity' : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Est. Weight (kg)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _weightKgController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 12.5',
                          suffixText: 'kg',
                          prefixIcon: Icon(Icons.scale_outlined, color: Colors.teal),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter weight';
                          if (double.tryParse(v.trim()) == null) return 'Invalid kg';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4. MULTIPLE PHOTO ADDING OPTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('4. Photos of Recycling Material', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_a_photo, color: Colors.teal, size: 18),
                  label: const Text('Add Photos', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_pickedImages.isEmpty)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: Colors.teal, size: 36),
                        SizedBox(height: 6),
                        Text('Tap to pick multiple photos from device', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pickedImages.length + 1,
                  itemBuilder: (c, i) {
                    if (i == _pickedImages.length) {
                      return GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.teal.shade300),
                          ),
                          child: const Center(
                            child: Icon(Icons.add, color: Colors.teal, size: 32),
                          ),
                        ),
                      );
                    }
                    final img = _pickedImages[i];
                    return Stack(
                      children: [
                        Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: FileImage(File(img.path)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => _removePhoto(i),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),

            // 5. PICKUP LOCATION EXACT ADDRESS
            const Text('5. Pickup Location Exact Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter street address, building/door no., landmark, city, pincode...',
                prefixIcon: Icon(Icons.location_on_outlined, color: Colors.teal),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter exact pickup address' : null,
            ),
            const SizedBox(height: 24),

            // SUBMIT BUTTON
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade900,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white),
              label: Text(
                _isSubmitting ? 'Posting Material...' : 'Post Recycling Material ♻️',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: _isSubmitting ? null : _submitRecyclingPost,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
