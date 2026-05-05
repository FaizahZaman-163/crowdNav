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
  final List<String> _roles = ['student', 'driver', 'admin'];

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
        await Supabase.instance.client.from('profiles').insert({
          'id': user.id,
          'name': _nameController.text.trim(),
          'student_id': _idController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'department': _selectedDepartment,
          'program': _selectedProgram,
          'blood_group': _selectedBloodGroup,
          'role': _selectedRole,
        });
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
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
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
      value: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
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
                        children: [
                          Text(
                            'Register',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InputField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: _idController,
                            keyboardType: TextInputType.text,
                            label: 'Student ID',
                            hint: 'e.g. 01823xxxxxxxxxxx',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            label: 'Email',
                            hint: 'Enter email',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            label: 'Phone',
                            hint: '01XXXXXXXXX',
                            icon: Icons.phone_outlined,
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            label: 'Department',
                            value: _selectedDepartment,
                            items: _departments,
                            onChanged: (v) =>
                                setState(() => _selectedDepartment = v!),
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            label: 'Program',
                            value: _selectedProgram,
                            items: _programs,
                            onChanged: (v) =>
                                setState(() => _selectedProgram = v!),
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            label: 'Blood Group',
                            value: _selectedBloodGroup,
                            items: _bloodGroups,
                            onChanged: (v) =>
                                setState(() => _selectedBloodGroup = v!),
                          ),
                          const SizedBox(height: 10),
                          _buildDropdown(
                            label: 'Role',
                            value: _selectedRole,
                            items: _roles,
                            onChanged: (v) =>
                                setState(() => _selectedRole = v!),
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: _passwordController,
                            keyboardType: TextInputType.visiblePassword,
                            label: 'Password',
                            hint: 'Min 8 characters',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 10),
                          InputField(
                            controller: _confirmController,
                            keyboardType: TextInputType.visiblePassword,
                            label: 'Confirm Password',
                            hint: 'Re-enter password',
                            icon: Icons.lock_outline,
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF2ECC71),
                                    ),
                                  )
                                : ElevatedButton(
                                    onPressed: _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2ECC71),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      'Register',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                            ),
                            child: const Text(
                              "Already have an account? Login",
                              style: TextStyle(
                                color: Color(0xFF1E8449),
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
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