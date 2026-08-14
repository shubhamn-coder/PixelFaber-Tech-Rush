import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class DisasterModeManagerScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const DisasterModeManagerScreen({super.key, required this.user});

  @override
  State<DisasterModeManagerScreen> createState() =>
      _DisasterModeManagerScreenState();
}

class _DisasterModeManagerScreenState
    extends State<DisasterModeManagerScreen> {
  bool _isDisasterMode = false;
  String _disasterType = 'Flood Relief Emergency';
  final _reasonCtrl = TextEditingController();
  final _materialsCtrl = TextEditingController(text: 'Clean Water, Medicines, Blankets, Dry Ration');
  final _dropoffCtrl = TextEditingController(text: 'Disaster Relief Hub, Pune Collectorate');
  bool _isSubmitting = false;

  final List<String> _disasterTypes = [
    'Flood Relief Emergency',
    'Earthquake Disaster',
    'Fire Emergency',
    'Cyclone / Hurricane',
    'Landslide Crisis',
    'Drought Relief',
    'Other Disaster Emergency'
  ];

  @override
  void initState() {
    super.initState();
    final ngo = widget.user['ngoDetails'];
    if (ngo != null) {
      _isDisasterMode = ngo['isDisasterMode'] ?? false;
      if (ngo['disasterType'] != null && _disasterTypes.contains(ngo['disasterType'])) {
        _disasterType = ngo['disasterType'];
      } else {
        _disasterType = _disasterTypes[0];
      }
      if (ngo['disasterReason'] != null && ngo['disasterReason'].toString().isNotEmpty) {
        _reasonCtrl.text = ngo['disasterReason'];
      }
      if (ngo['requiredMaterials'] != null && ngo['requiredMaterials'].toString().isNotEmpty) {
        _materialsCtrl.text = ngo['requiredMaterials'];
      }
      if (ngo['dropoffAddress'] != null && ngo['dropoffAddress'].toString().isNotEmpty) {
        _dropoffCtrl.text = ngo['dropoffAddress'];
      }
    }
  }

  Future<void> _toggleMode(bool targetState) async {
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.patch('/ngo/disaster-mode', {
        'ngoId': widget.user['_id'],
        'isDisasterMode': targetState,
        'disasterType': _disasterType,
        'reason': _reasonCtrl.text.trim(),
        'requiredMaterials': _materialsCtrl.text.trim(),
        'dropoffAddress': _dropoffCtrl.text.trim(),
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          _isDisasterMode = targetState;
          if (widget.user['ngoDetails'] != null) {
            widget.user['ngoDetails']['isDisasterMode'] = targetState;
            widget.user['ngoDetails']['disasterType'] = _disasterType;
            widget.user['ngoDetails']['disasterReason'] = _reasonCtrl.text.trim();
            widget.user['ngoDetails']['requiredMaterials'] = _materialsCtrl.text.trim();
            widget.user['ngoDetails']['dropoffAddress'] = _dropoffCtrl.text.trim();
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: targetState ? Colors.red.shade800 : Colors.green,
            content: Text(
              targetState
                  ? '🚨 Emergency Disaster Relief Broadcast ACTIVATED!'
                  : '✅ Disaster Relief Broadcast Deactivated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade900,
          content: Text('Disaster status updated locally! ($e)'),
        ),
      );
      setState(() => _isDisasterMode = targetState);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Disaster Relief Manager', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: _isDisasterMode ? Colors.red.shade800 : Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: _isDisasterMode ? Colors.red.shade50 : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isDisasterMode ? Colors.red : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeThumbColor: Colors.red,
                      title: Text(
                        _isDisasterMode
                            ? '🚨 EMERGENCY DISASTER MODE IS ACTIVE'
                            : '🚨 Activate Emergency Disaster Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _isDisasterMode ? Colors.red.shade900 : Colors.black,
                        ),
                      ),
                      subtitle: const Text(
                        'Broadcasts urgent disaster demands to all donors across the platform.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _isDisasterMode,
                      onChanged: _isSubmitting ? null : (val) => _toggleMode(val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '📋 Disaster Relief Declaration Form',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _disasterTypes.contains(_disasterType) ? _disasterType : _disasterTypes[0],
              decoration: const InputDecoration(
                labelText: 'Kind of Disaster Occurred *',
                border: OutlineInputBorder(),
              ),
              items: _disasterTypes
                  .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 13.5))))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _disasterType = v);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Disaster Context & Situation Description *',
                hintText: 'Explain ground situation, affected area, and urgency...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _materialsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Required Emergency Materials List *',
                hintText: 'e.g. Blankets, First Aid Kits, Bottled Water, Tarpaulins',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dropoffCtrl,
              decoration: const InputDecoration(
                labelText: 'Emergency Relief Drop-off Location Address *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: _isDisasterMode ? Colors.red.shade800 : Colors.green.shade800,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.broadcast_on_personal, color: Colors.white),
              label: Text(
                _isDisasterMode ? 'Update Disaster Broadcast' : 'Activate & Broadcast Disaster Mode',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: _isSubmitting ? null : () => _toggleMode(!_isDisasterMode),
            )
          ],
        ),
      ),
    );
  }
}
