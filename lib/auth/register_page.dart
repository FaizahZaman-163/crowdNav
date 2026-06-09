import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import '../pages/home_page.dart';
import '../widgets/input_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String _selectedDepartment = 'CSE';
  String _selectedProgram = 'BSc';
  String _selectedBloodGroup = 'A+';
  String _selectedRole = 'student';

  bool _isLoading = false;

  final List<String> _departments = ['CSE', 'EEE', 'BBA', 'English', 'Law'];
  final List<String> _programs = ['BSc', 'MSc', 'BBA', 'MBA'];
  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _roles = ['student', 'driver'];

  bool get _isDriver => _selectedRole == 'driver';

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _friendlyAuthError(AuthException e) {
    switch (e.code) {
      case 'over_email_send_rate_limit':
        return 'Too many emails sent. Please wait a few minutes and try again.';
      case 'email_address_invalid':
        return 'This email address is not valid.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists. Try logging in.';
      case 'weak_password':
        return 'Password is too weak. Use at least 8 characters.';
      default:
        return e.message;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = authResponse.user;

      if (user != null) {
        final profileData = {
          'id': user.id,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'role': _selectedRole,
          if (!_isDriver) ...{
            'student_id': _idController.text.trim(),
            'department': _selectedDepartment,
            'program': _selectedProgram,
            'blood_group': _selectedBloodGroup,
          },
        };

        await Supabase.instance.client.from('profiles').insert(profileData);
      }

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyAuthError(e)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF0F1),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'CrowdNav',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E8449),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 5,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Register',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Role selector (pick first) ───────────
                          _buildDropdown(
                            label: 'I am a...',
                            value: _selectedRole,
                            items: _roles,
                            onChanged: (v) {
                              setState(() {
                                _selectedRole = v!;
                                _idController.clear();
                              });
                            },
                          ),
                          if (_isDriver) ...[
                            const SizedBox(height: 6),
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 13, color: Colors.grey),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Driver accounts are for university bus drivers only.',
                                    style: TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),

                          // ── Divider with role label ──────────────
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  _isDriver ? 'Driver Details' : 'Student Details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Full Name (both roles) ───────────────
                          InputField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Full name is required';
                              if (v.trim().length < 3) return 'Name must be at least 3 characters';
                              if (!RegExp(r"^[a-zA-Z\s'.]+$").hasMatch(v.trim())) {
                                return 'Name can only contain letters and spaces';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // ── Student ID (students only) ───────────
                          if (!_isDriver) ...[
                            InputField(
                              controller: _idController,
                              keyboardType: TextInputType.text,
                              label: 'Student ID',
                              hint: 'e.g. 0182320012101164',
                              icon: Icons.badge_outlined,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Student ID is required';
                                if (!RegExp(r'^\d{16}$').hasMatch(v.trim())) {
                                  return 'Student ID must be exactly 16 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                          ],

                          // ── Email (both roles) ───────────────────
                          InputField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            label: 'Email',
                            hint: 'Enter your email',
                            icon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // ── Phone (both roles) ───────────────────
                          InputField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            label: 'Phone',
                            hint: '01XXXXXXXXX',
                            icon: Icons.phone_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Phone number is required';
                              if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(v.trim())) {
                                return 'Enter a valid BD number (e.g. 01XXXXXXXXX)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // ── Student-only fields ──────────────────
                          if (!_isDriver) ...[
                            _buildDropdown(
                              label: 'Department',
                              value: _selectedDepartment,
                              items: _departments,
                              onChanged: (v) => setState(() => _selectedDepartment = v!),
                            ),
                            const SizedBox(height: 10),

                            _buildDropdown(
                              label: 'Program',
                              value: _selectedProgram,
                              items: _programs,
                              onChanged: (v) => setState(() => _selectedProgram = v!),
                            ),
                            const SizedBox(height: 10),

                            _buildDropdown(
                              label: 'Blood Group',
                              value: _selectedBloodGroup,
                              items: _bloodGroups,
                              onChanged: (v) => setState(() => _selectedBloodGroup = v!),
                            ),
                            const SizedBox(height: 10),
                          ],

                          // ── Password (both roles) ────────────────
                          InputField(
                            controller: _passwordController,
                            keyboardType: TextInputType.visiblePassword,
                            label: 'Password',
                            hint: 'Min 8 characters',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 8) return 'Password must be at least 8 characters';
                              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
                              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // ── Confirm Password (both roles) ────────
                          InputField(
                            controller: _confirmController,
                            keyboardType: TextInputType.visiblePassword,
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm your password';
                              if (v != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _isLoading
                                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2ECC71)))
                                : ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2ECC71),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      'Register',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginPage()),
                              ),
                              child: const Text(
                                'Already have an account? Login',
                                style: TextStyle(
                                  color: Color(0xFF1E8449),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}