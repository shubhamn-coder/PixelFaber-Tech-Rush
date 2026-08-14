import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

class NotificationCenterModal extends StatefulWidget {
  final Map<String, dynamic> user;

  const NotificationCenterModal({super.key, required this.user});

  static void show(BuildContext context, Map<String, dynamic> user) {
    NotificationService().markAllRead();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (c) => NotificationCenterModal(user: user),
    );
  }

  @override
  State<NotificationCenterModal> createState() => _NotificationCenterModalState();
}

class _NotificationCenterModalState extends State<NotificationCenterModal> {
  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'] ?? 'DONOR';
    final isDonor = role == 'DONOR';
    final warning = widget.user['warningMessage'] ?? widget.user['warning'];
    final hasWarning = warning != null && warning.toString().trim().isNotEmpty;

    // Real notifications list generated dynamically
    final List<Map<String, dynamic>> notifications = [];

    if (hasWarning) {
      notifications.add({
        'type': 'ADMIN_WARNING',
        'title': '🚨 ADMINISTRATIVE WARNING ISSUED',
        'subtitle': warning.toString(),
        'time': 'Just now',
        'badge': 'Admin Alert',
        'isWarning': true,
      });
    }

    for (var chatNotif in NotificationService.liveNotifications) {
      notifications.add({
        'type': chatNotif.type,
        'title': chatNotif.title,
        'subtitle': chatNotif.body,
        'time': 'Recent',
        'badge': '1-on-1 Chat',
        'isWarning': false,
      });
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade800,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isDonor ? '🔔 Donor Notifications' : '🔔 NGO Notifications',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: notifications.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_off_outlined,
                            size: 48,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No New Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111111),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isDonor
                              ? "You're all caught up! Real-time notifications for NGO messages, pickup requests, recycler requests, and admin alerts will appear here."
                              : "You're all caught up! Real-time notifications for donor messages, claim acceptances, and admin alerts will appear here.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, color: Colors.green.shade800, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Account Status: Active & Clean ✓',
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      if (item['isWarning'] == true) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    item['title'],
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['subtitle'],
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.chat_bubble_outline, color: Colors.blue, size: 20),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item['title'] ?? '1-on-1 Message',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['badge'] ?? 'Chat',
                                  style: TextStyle(color: Colors.blue.shade900, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              item['subtitle'] ?? '',
                              style: const TextStyle(fontSize: 12.5, color: Colors.black87),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
