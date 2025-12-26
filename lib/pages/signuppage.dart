import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _branchController = TextEditingController();
  final _semesterController = TextEditingController();
  final _hostelController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _branchController.dispose();
    _semesterController.dispose();
    _hostelController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      userData: {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'studentId': _studentIdController.text.trim(),
        'branch': _branchController.text.trim(),
        'semester': _semesterController.text.trim(),
        'hostel': _hostelController.text.trim(),
        'profilePicUrl': '',
      },
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to login
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.storefront,
                    size: 60,
                    color: Colors.limeAccent.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fill in your details to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Unbounded',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Step Indicator
                  _buildStepIndicator(),
                  
                  const SizedBox(height: 32),
                  
                  // Form Fields based on current step
                  if (_currentStep == 0) ..._buildPersonalInfoFields(),
                  if (_currentStep == 1) ..._buildAcademicInfoFields(),
                  if (_currentStep == 2) ..._buildAccountInfoFields(),
                  
                  const SizedBox(height: 32),
                  
                  // Navigation Buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() => _currentStep--);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.limeAccent.shade700),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                fontFamily: 'Unbounded',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: _currentStep == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            if (_currentStep < 2) {
                              if (_validateCurrentStep()) {
                                setState(() => _currentStep++);
                              }
                            } else {
                              _handleSignUp();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.limeAccent.shade700,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'Sign Up' : 'Next',
                                  style: const TextStyle(
                                    fontFamily: 'Unbounded',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontFamily: 'Unbounded',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontFamily: 'Unbounded',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.limeAccent.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        bool isActive = index <= _currentStep;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Colors.limeAccent.shade700 : Colors.grey.shade300,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            if (index < 2)
              Container(
                width: 40,
                height: 2,
                color: index < _currentStep ? Colors.limeAccent.shade700 : Colors.grey.shade300,
              ),
          ],
        );
      }),
    );
  }

  List<Widget> _buildPersonalInfoFields() {
    return [
      const Text(
        'Personal Information',
        style: TextStyle(
          fontFamily: 'Unbounded',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _nameController,
        label: 'Full Name',
        icon: Icons.person,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _emailController,
        label: 'Email',
        icon: Icons.email,
        keyboardType: TextInputType.emailAddress,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (!value!.contains('@')) return 'Invalid email';
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _phoneController,
        label: 'Phone Number',
        icon: Icons.phone,
        keyboardType: TextInputType.phone,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (value!.length < 10) return 'Invalid phone number';
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildAcademicInfoFields() {
    return [
      const Text(
        'Academic Details',
        style: TextStyle(
          fontFamily: 'Unbounded',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _studentIdController,
        label: 'Student ID / Roll Number',
        icon: Icons.badge,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _branchController,
        label: 'Branch / Department',
        icon: Icons.school,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _semesterController,
        label: 'Semester',
        icon: Icons.calendar_today,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _hostelController,
        label: 'Hostel & Room Number',
        icon: Icons.home,
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
    ];
  }

  List<Widget> _buildAccountInfoFields() {
    return [
      const Text(
        'Account Security',
        style: TextStyle(
          fontFamily: 'Unbounded',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.limeAccent.shade700, width: 2),
          ),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (value!.length < 6) return 'Password must be at least 6 characters';
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.limeAccent.shade700, width: 2),
          ),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (value != _passwordController.text) return 'Passwords do not match';
          return null;
        },
      ),
    ];
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.limeAccent.shade700, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  bool _validateCurrentStep() {
    final form = _formKey.currentState!;
    if (!form.validate()) return false;
    return true;
  }
}
