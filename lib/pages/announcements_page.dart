import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/announcement_model.dart';
import '../services/supabase_service.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  List<Announcement> _announcements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getAnnouncements();
    if (mounted) {
      setState(() {
        _announcements = data;
        _loading = false;
      });
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'emergency':
        return Colors.redAccent;
      case 'high':
        return Colors.orange;
      default:
        return const Color(0xFF2E7D32);
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'emergency':
        return Icons.warning_amber_rounded;
      case 'high':
        return Icons.priority_high;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _announcements.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_off_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No announcements yet',
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _announcements.length,
                    itemBuilder: (context, i) {
                      final a = _announcements[i];
                      final color = _priorityColor(a.priority);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: color, width: 1.5),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: color,
                            child: Icon(
                              _priorityIcon(a.priority),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            a.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(a.body),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(30),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      a.targetDepartment == 'all'
                                          ? 'All Departments'
                                          : a.targetDepartment,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    DateFormat('dd MMM, hh:mm a')
                                        .format(a.createdAt),
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}