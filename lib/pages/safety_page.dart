import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const _emergencyContacts = [
  {
    'name': 'National Emergency',
    'number': '999',
    'icon': Icons.local_police,
    'color': Colors.red,
  },
  {
    'name': 'Fire Service',
    'number': '199',
    'icon': Icons.local_fire_department,
    'color': Colors.orange,
  },
  {
    'name': 'Ambulance',
    'number': '199',
    'icon': Icons.local_hospital,
    'color': Colors.green,
  },
  {
    'name': 'LU Campus Security',
    'number': '01700000000',
    'icon': Icons.security,
    'color': Colors.blue,
  },
  {
    'name': 'LU Transport Office',
    'number': '01700000001',
    'icon': Icons.directions_bus,
    'color': Colors.purple,
  },
];

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

  Future<void> _call(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency & Safety', style: GoogleFonts.poppins()),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFEBEE), Colors.white],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap any contact below to call immediately in an emergency.',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Emergency Contacts',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 12),
            ..._emergencyContacts.map((c) {
              final color = c['color'] as Color;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: color, width: 1.5),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(c['icon'] as IconData, color: Colors.white),
                  ),
                  title: Text(
                    c['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(c['number'] as String),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _call(c['number'] as String),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Your blood group stored in your profile is visible to first responders and campus security in case of emergency. Keep your profile updated.',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}