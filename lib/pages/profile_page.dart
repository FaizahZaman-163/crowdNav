import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/login_page.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  final UserModel? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserModel? _profile;
  bool _loading = true;
  String? _error;
  bool _editMode = false;
  bool _saving = false;
  bool _uploadingPhoto = false;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedDepartment = 'CSE';
  String _selectedProgram = 'BSc';
  String _selectedBloodGroup = 'A+';

  final List<String> _departments = ['CSE', 'EEE', 'BBA', 'English', 'Law'];
  final List<String> _programs = ['BSc', 'MSc', 'BBA', 'MBA'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _profile = widget.user;
      _loading = false;
      _populateControllers();
    } else {
      _loadProfile();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _populateControllers() {
    if (_profile == null) return;
    _nameController.text = _profile!.name;
    _phoneController.text = _profile!.phone;
    _selectedDepartment = _departments.contains(_profile!.department)
        ? _profile!.department
        : _departments.first;
    _selectedProgram = _programs.contains(_profile!.program)
        ? _profile!.program
        : _programs.first;
    _selectedBloodGroup = _bloodGroups.contains(_profile!.bloodGroup)
        ? _profile!.bloodGroup
        : _bloodGroups.first;
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() { _error = 'Not logged in.'; _loading = false; });
        return;
      }
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (data == null) {
        setState(() { _error = 'Profile not found.'; _loading = false; });
      } else {
        setState(() { _profile = UserModel.fromMap(data); _loading = false; });
        _populateControllers();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = 'Failed to load profile: ${e.toString()}'; _loading = false; });
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Choose Photo', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt, color: Color(0xFF2ECC71)),
              ),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.photo_library, color: Color(0xFF2ECC71)),
              ),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_profile?.avatarUrl != null)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFEBEE),
                  child: Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
                title: const Text('Remove photo', style: TextStyle(color: Colors.redAccent)),
                onTap: () => Navigator.pop(context, null),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (!mounted) return;

    if (source == null && _profile?.avatarUrl != null) {
      await _removePhoto();
      return;
    }
    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final path = 'avatars/$userId.$ext';

      await Supabase.instance.client.storage
          .from('profiles')
          .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

      final publicUrl = Supabase.instance.client.storage
          .from('profiles')
          .getPublicUrl(path);

      final cacheBustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      await SupabaseService.updateProfile({'avatar_url': cacheBustedUrl});

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;
      if (data != null) {
        setState(() => _profile = UserModel.fromMap(data));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated!'),
            backgroundColor: Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _uploadingPhoto = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await SupabaseService.updateProfile({'avatar_url': null});

      for (final ext in ['jpg', 'jpeg', 'png', 'webp']) {
        try {
          await Supabase.instance.client.storage
              .from('profiles')
              .remove(['avatars/$userId.$ext']);
        } catch (_) {}
      }

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;
      if (data != null) setState(() => _profile = UserModel.fromMap(data));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo removed.'),
            backgroundColor: Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove photo: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await SupabaseService.updateProfile({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _selectedDepartment,
        'program': _selectedProgram,
        'blood_group': _selectedBloodGroup,
      });

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;
      if (data != null) {
        setState(() {
          _profile = UserModel.fromMap(data);
          _editMode = false;
          _saving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF2ECC71),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _cancelEdit() {
    _populateControllers();
    setState(() => _editMode = false);
  }

  Future<void> _logout() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    final p = _profile!;

    return Container(
      color: const Color(0xFFECF0F1),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Header with avatar ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2ECC71),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _buildAvatar(p.avatarUrl),
                        if (_uploadingPhoto)
                          const Positioned.fill(
                            child: CircleAvatar(
                              backgroundColor: Colors.black38,
                              child: SizedBox(
                                width: 24, height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF2ECC71)),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    p.name.isNotEmpty ? p.name : 'No Name',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),

                  const SizedBox(height: 4),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      p.role.toUpperCase(),
                      style: const TextStyle(color: Color(0xFF2ECC71), fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    _uploadingPhoto ? 'Updating photo...' : 'Tap photo to change',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Edit / Save / Cancel ─────────────────────────────
            if (!_editMode)
              OutlinedButton.icon(
                onPressed: () => setState(() => _editMode = true),
                icon: const Icon(Icons.edit, color: Color(0xFF2ECC71)),
                label: const Text('Edit Profile', style: TextStyle(color: Color(0xFF2ECC71))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2ECC71)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveProfile,
                      icon: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: Text(_saving ? 'Saving...' : 'Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _cancelEdit,
                      icon: const Icon(Icons.close, color: Colors.grey),
                      label: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // ── Personal Info ────────────────────────────────────
            _buildCard('Personal Info', [
              _editMode
                  ? _editField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Name is required';
                        if (v.trim().length < 3) return 'At least 3 characters';
                        if (!RegExp(r"^[a-zA-Z\s'.]+$").hasMatch(v.trim())) return 'Letters and spaces only';
                        return null;
                      },
                    )
                  : _viewItem(Icons.person_outline, 'Name', p.name),
              _lockedItem(Icons.email_outlined, 'Email', p.email, 'Email cannot be changed'),
              _editMode
                  ? _editField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Phone is required';
                        if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(v.trim())) return 'Enter valid BD number (01XXXXXXXXX)';
                        return null;
                      },
                    )
                  : _viewItem(Icons.phone_outlined, 'Phone', p.phone),
              _lockedItem(Icons.badge_outlined, 'Student ID', p.studentId, 'Student ID cannot be changed'),
            ]),

            // ── Academic Info ────────────────────────────────────
            _buildCard('Academic Info', [
              _editMode
                  ? _dropdownField(label: 'Department', icon: Icons.school_outlined, value: _selectedDepartment, items: _departments, onChanged: (v) => setState(() => _selectedDepartment = v!))
                  : _viewItem(Icons.school_outlined, 'Department', p.department),
              _editMode
                  ? _dropdownField(label: 'Program', icon: Icons.menu_book_outlined, value: _selectedProgram, items: _programs, onChanged: (v) => setState(() => _selectedProgram = v!))
                  : _viewItem(Icons.menu_book_outlined, 'Program', p.program),
            ]),

            // ── Emergency Info ───────────────────────────────────
            _buildCard('Emergency Info', [
              _editMode
                  ? _dropdownField(label: 'Blood Group', icon: Icons.bloodtype_outlined, value: _selectedBloodGroup, items: _bloodGroups, onChanged: (v) => setState(() => _selectedBloodGroup = v!))
                  : _viewItem(Icons.bloodtype_outlined, 'Blood Group', p.bloodGroup),
            ]),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Logout'),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.white,
        backgroundImage: NetworkImage(avatarUrl),
        onBackgroundImageError: (_, __) {},
      );
    }
    return const CircleAvatar(
      radius: 40,
      backgroundColor: Colors.white,
      child: Icon(Icons.person, size: 44, color: Color(0xFF2ECC71)),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF2ECC71))),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _viewItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2ECC71)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
          Expanded(child: Text(value.isNotEmpty ? value : '—', style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _lockedItem(IconData icon, String label, String value, String tooltip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          Expanded(child: Text(value.isNotEmpty ? value : '—', style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
          Tooltip(message: tooltip, child: const Icon(Icons.lock_outline, size: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2ECC71), size: 18),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.redAccent)),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF2ECC71), size: 18),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2ECC71), width: 2)),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}