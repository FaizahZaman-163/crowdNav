import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/announcement_model.dart';
import '../services/supabase_service.dart';
import '../auth/login_page.dart';
import '../pages/profile_page.dart';

class AdminHomePage extends StatefulWidget {
  final UserModel user;
  const AdminHomePage({super.key, required this.user});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardTab(user: widget.user),
      const _AnnouncementsTab(),
      const _UsersTab(),
      ProfilePage(user: widget.user),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('CrowdNav – Admin', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF1E8449),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await SupabaseService.signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2ECC71),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Announcements'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  final UserModel user;
  const _DashboardTab({required this.user});

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await SupabaseService.getAdminStats();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadStats,
      color: const Color(0xFF2ECC71),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, color: Color(0xFF2ECC71)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${widget.user.name.isNotEmpty ? widget.user.name : 'Admin'}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                    const Text('CrowdNav Administration', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text('System Overview', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15, color: const Color(0xFF2C3E50))),
          const SizedBox(height: 12),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(label: 'Total Students', value: '${_stats['students'] ?? 0}', icon: Icons.school, color: const Color(0xFF2ECC71)),
                _StatCard(label: 'Total Drivers', value: '${_stats['drivers'] ?? 0}', icon: Icons.directions_bus, color: Colors.blue),
                _StatCard(label: 'Announcements', value: '${_stats['announcements'] ?? 0}', icon: Icons.campaign, color: Colors.orange),
                _StatCard(label: 'Active Buses', value: '${_stats['active_buses'] ?? 0}', icon: Icons.location_on, color: Colors.redAccent),
              ],
            ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _loadStats,
              icon: const Icon(Icons.refresh, color: Color(0xFF2ECC71), size: 16),
              label: const Text('Refresh', style: TextStyle(color: Color(0xFF2ECC71))),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsTab extends StatefulWidget {
  const _AnnouncementsTab();

  @override
  State<_AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<_AnnouncementsTab> {
  List<Announcement> _announcements = [];
  bool _loading = true;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedDept = 'all';
  String _selectedProgram = 'all';
  String _selectedPriority = 'normal';

  final List<String> _depts = ['all', 'CSE', 'EEE', 'BBA', 'English', 'Law'];
  final List<String> _programs = ['all', 'BSc', 'MSc', 'BBA', 'MBA'];
  final List<String> _priorities = ['normal', 'high', 'emergency'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await SupabaseService.getAllAnnouncements();
    if (mounted) setState(() { _announcements = data; _loading = false; });
  }

  Future<void> _post() async {
    if (_titleController.text.trim().isEmpty || _bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and body are required.'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    try {
      await SupabaseService.postAnnouncement(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        targetDepartment: _selectedDept,
        targetProgram: _selectedProgram,
        priority: _selectedPriority,
      );
      _titleController.clear();
      _bodyController.clear();
      setState(() { _selectedDept = 'all'; _selectedProgram = 'all'; _selectedPriority = 'normal'; });
      if (mounted) { Navigator.pop(context); }
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement posted!'), backgroundColor: Color(0xFF2ECC71), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('Are you sure you want to delete this announcement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.deleteAnnouncement(id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _showPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New Announcement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF2ECC71))),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: const Color(0xFFF9F9F9),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Body',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true, fillColor: const Color(0xFFF9F9F9),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildSheetDropdown('Department', _selectedDept, _depts, (v) => setState(() => _selectedDept = v!))),
                const SizedBox(width: 8),
                Expanded(child: _buildSheetDropdown('Program', _selectedProgram, _programs, (v) => setState(() => _selectedProgram = v!))),
              ],
            ),
            const SizedBox(height: 10),
            _buildSheetDropdown('Priority', _selectedPriority, _priorities, (v) => setState(() => _selectedPriority = v!)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _post,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Post Announcement', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true, fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'emergency': return Colors.redAccent;
      case 'high': return Colors.orange;
      default: return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPostSheet,
        backgroundColor: const Color(0xFF2ECC71),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
          : _announcements.isEmpty
              ? const Center(child: Text('No announcements yet.', style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2ECC71),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _announcements.length,
                    itemBuilder: (_, i) {
                      final a = _announcements[i];
                      final color = _priorityColor(a.priority);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: color, width: 1.5)),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: color, child: Icon(_priorityIcon(a.priority), color: Colors.white, size: 18)),
                          title: Text(a.title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.body, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _chip(a.targetDepartment == 'all' ? 'All Depts' : a.targetDepartment, color),
                                  const SizedBox(width: 4),
                                  _chip(a.priority.toUpperCase(), color),
                                  const Spacer(),
                                  Text(DateFormat('dd MMM, HH:mm').format(a.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _delete(a.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
    );
  }

  IconData _priorityIcon(String p) {
    switch (p) {
      case 'emergency': return Icons.warning_amber_rounded;
      case 'high': return Icons.priority_high;
      default: return Icons.notifications_outlined;
    }
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  List<UserModel> _users = [];
  List<UserModel> _filtered = [];
  bool _loading = true;
  String _roleFilter = 'all';

  final List<String> _roles = ['all', 'student', 'driver', 'admin'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAllUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _filtered = data;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter(String role) {
    setState(() {
      _roleFilter = role;
      _filtered = role == 'all' ? _users : _users.where((u) => u.role == role).toList();
    });
  }

  Future<void> _updateRole(UserModel user, String newRole) async {
    try {
      await SupabaseService.updateUserRole(userId: user.id, role: newRole);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} role updated to $newRole'), backgroundColor: const Color(0xFF2ECC71), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _assignRoute(UserModel user, String? route) async {
    try {
      await SupabaseService.assignRoute(userId: user.id, route: route);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(route == null ? '${user.name} route cleared' : '${user.name} assigned to $route'),
            backgroundColor: const Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.purple;
      case 'driver': return Colors.blue;
      default: return const Color(0xFF2ECC71);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: _roles.map((r) {
              final selected = _roleFilter == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _applyFilter(r),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2ECC71) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      r[0].toUpperCase() + r.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
              : _filtered.isEmpty
                  ? const Center(child: Text('No users found.', style: TextStyle(color: Colors.grey)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF2ECC71),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final u = _filtered[i];
                          final roleColor = _roleColor(u.role);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: roleColor.withValues(alpha: 0.15),
                                        child: Text(
                                          u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                                          style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(u.name.isNotEmpty ? u.name : 'No name', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                            Text(u.email, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            if (u.role != 'driver')
                                              Text('${u.department} • ${u.studentId}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: u.role,
                                        underline: const SizedBox(),
                                        style: TextStyle(fontSize: 12, color: roleColor, fontWeight: FontWeight.bold),
                                        items: ['student', 'driver', 'admin']
                                            .map((r) => DropdownMenuItem(value: r, child: Text(r, style: TextStyle(color: _roleColor(r), fontWeight: FontWeight.w600))))
                                            .toList(),
                                        onChanged: (newRole) {
                                          if (newRole != null && newRole != u.role) {
                                            _updateRole(u, newRole);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  if (u.role == 'driver') ...[
                                    const SizedBox(height: 8),
                                    const Divider(height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_bus, size: 14, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        const Text('Assigned Route:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: DropdownButton<String?>(
                                            value: u.assignedRoute,
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            hint: const Text('No route assigned', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                            style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w600),
                                            items: [
                                              const DropdownMenuItem<String?>(value: null, child: Text('No route', style: TextStyle(color: Colors.grey, fontSize: 12))),
                                              ...const ['Route 1 – Tilagor', 'Route 2 – Surma Tower', 'Route 3 – Lakkatura', 'Route 4 – Tilagor (Bypass)']
                                                  .map((r) => DropdownMenuItem<String?>(value: r, child: Text(r, style: const TextStyle(color: Colors.blue, fontSize: 12)))),
                                            ],
                                            onChanged: (newRoute) => _assignRoute(u, newRoute),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
}