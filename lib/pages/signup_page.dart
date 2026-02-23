import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/auth/supabase_auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseAuthService _authService = SupabaseAuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _admissionYearController = TextEditingController();
  final _admissionRollNumberController = TextEditingController();
  final _hostelController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Dropdown selections
  String _selectedBranch = '';
  String _selectedSemester = '';

  // Toggle
  bool _isHosteler = true;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;

  // Branch and semester options
  final List<String> branches = [
    'Computer Science & Engineering',
    'Computer Science & Engineering (Data Science)',
    'Computer Science & Engineering (Business Studies)',
    'Civil Engineering',
    'Electrical & Electronics Engineering',
    'Electronics & Communication Engineering',
    'Mechanical Engineering',
  ];

  final List<String> semesters = [
    'S1',
    'S2',
    'S3',
    'S4',
    'S5',
    'S6',
    'S7',
    'S8',
  ];

  final Map<String, String> branchCodes = {
    'Computer Science & Engineering': 'CSE',
    'Computer Science & Engineering (Data Science)': 'CD',
    'Computer Science & Engineering (Business Studies)': 'CB',
    'Civil Engineering': 'CE',
    'Electrical & Electronics Engineering': 'EEE',
    'Electronics & Communication Engineering': 'ECE',
    'Mechanical Engineering': 'ME',
  };

  @override
  void initState() {
    super.initState();
    // Add listeners to update Student ID preview in real-time
    _admissionYearController.addListener(() {
      setState(() {});
    });
    _admissionRollNumberController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _admissionYearController.dispose();
    _admissionRollNumberController.dispose();
    _hostelController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _generateStudentIdPreview() {
    String branchCode = branchCodes[_selectedBranch] ?? '___';
    String yearInput = _admissionYearController.text.trim();
    String year = yearInput.isEmpty
        ? '__'
        : (yearInput.length == 4 ? yearInput.substring(2) : yearInput);
    String roll = _admissionRollNumberController.text.trim();
    String formattedRoll = roll.isEmpty ? '___' : roll.padLeft(3, '0');
    return 'CCE$year$branchCode$formattedRoll';
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Generate Student ID
      String branchCode = branchCodes[_selectedBranch] ?? '';
      String yearInput = _admissionYearController.text.trim();
      // Normalize year to 2 digits
      String year = yearInput.length == 4 ? yearInput.substring(2) : yearInput;
      String roll = _admissionRollNumberController.text.trim().padLeft(3, '0');
      String studentId = 'CCE$year$branchCode$roll';

      final result = await _authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userData: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'studentId': studentId,
          'admissionYear': year,
          'admissionRollNumber': roll,
          'branch': _selectedBranch,
          'semester': _selectedSemester,
          'hostel': _isHosteler ? _hostelController.text.trim() : 'HOMESCHOLAR',
          'profilePicUrl': '',
        },
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account created successfully!'),
              backgroundColor: AppColors.green,
            ),
          );
          Navigator.pop(context); // Go back to login
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('An unexpected error occurred'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      // Logo and Title
                      Image.asset(
                          'assets/logo/Catino.png',
                          width: 70,
                          height: 70,
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

                        const SizedBox(height: 20),

                        // Step Indicator
                        _buildStepIndicator(),

                        const SizedBox(height: 20),

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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: AppColors.primaryCta,
                                    ),
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
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        if (_currentStep < 2) {
                                          if (_validateCurrentStep()) {
                                            setState(() => _currentStep++);
                                          }
                                        } else {
                                          _handleSignUp();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryCta,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.black,
                                              ),
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
                                  color: AppColors.primaryCta,
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
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
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
                color: isActive
                    ? AppColors.primaryCta
                    : Colors.grey.shade300,
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
                color: index < _currentStep
                    ? AppColors.primaryCta
                    : Colors.grey.shade300,
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
        controller: _admissionYearController,
        label: 'Admission Year (e.g., 24 or 2024)',
        icon: Icons.calendar_today,
        keyboardType: TextInputType.number,
        onChanged: (value) => setState(() {}),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (int.tryParse(value!) == null) return 'Invalid year';
          if (value.length != 2 && value.length != 4) {
            return 'Enter 2 or 4 digit year';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildTextField(
        controller: _admissionRollNumberController,
        label: 'Admission Roll Number',
        icon: Icons.confirmation_number,
        keyboardType: TextInputType.number,
        onChanged: (value) => setState(() {}),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (int.tryParse(value!) == null) return 'Invalid roll number';
          return null;
        },
      ),
      const SizedBox(height: 16),
      _buildDropdownField(
        label: 'Branch',
        icon: Icons.school,
        value: _selectedBranch,
        items: branches,
        onChanged: (value) => setState(() => _selectedBranch = value!),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      _buildDropdownField(
        label: 'Semester',
        icon: Icons.calendar_view_month,
        value: _selectedSemester,
        items: semesters,
        onChanged: (value) => setState(() => _selectedSemester = value!),
        validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Icon(Icons.home, color: Colors.grey),
          const SizedBox(width: 16),
          const Text(
            'Hosteler',
            style: TextStyle(
              fontFamily: 'Unbounded',
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isHosteler,
            onChanged: (value) => setState(() => _isHosteler = value),
            activeThumbColor: AppColors.primaryCta,
          ),
        ],
      ),
      if (_isHosteler) ...[
        const SizedBox(height: 16),
        _buildTextField(
          controller: _hostelController,
          label: 'Hostel & Room Number',
          icon: Icons.home,
          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
        ),
      ],
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black26, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.badge, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Your Student ID',
                  style: TextStyle(
                    fontFamily: 'Unbounded',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _generateStudentIdPreview(),
              style: TextStyle(
                fontFamily: 'Unbounded',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
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
        style: const TextStyle(
          fontFamily: 'Unbounded',
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
          prefixIcon: const Icon(Icons.lock),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryCta, width: 2),
          ),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (value!.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _confirmPasswordController,
        obscureText: _obscureConfirmPassword,
        style: const TextStyle(
          fontFamily: 'Unbounded',
          fontWeight: FontWeight.w300,
        ),
        decoration: InputDecoration(
          labelText: 'Confirm Password',
          labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            ),
            onPressed: () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryCta, width: 2),
          ),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }
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
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Unbounded',
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryCta, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdownField({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value.isEmpty ? null : value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: const TextStyle(
                  fontFamily: 'Unbounded',
                  fontWeight: FontWeight.w300,
                  fontSize: 15,
                ),
                maxLines: 2,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (BuildContext context) {
        return items.map((item) {
          return Text(
            item,
            style: const TextStyle(
              fontFamily: 'Unbounded',
              fontWeight: FontWeight.w300,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          );
        }).toList();
      },
      onChanged: onChanged,
      validator: validator,
      itemHeight: 50,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Unbounded', fontSize: 13),
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryCta, width: 2),
        ),
      ),
    );
  }

  bool _validateCurrentStep() {
    final form = _formKey.currentState!;
    if (!form.validate()) return false;
    return true;
  }
}

