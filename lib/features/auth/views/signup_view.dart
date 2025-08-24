import 'package:agritech/features/auth/widgets/auth_background.dart';
import 'package:agritech/features/auth/widgets/language_switcher.dart';
import 'package:agritech/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});
  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'farmer';
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  // 1. Add a state variable for password visibility
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        mobileNumber: _phoneController.text.trim(),
        role: _selectedRole,
      );
      if (userCredential != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please log in.'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up failed. Email or phone might already be in use.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: AuthBackground(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LanguageSwitcher(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: l10n.nameLabel, filled: true, fillColor: Colors.white.withAlpha(204), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                validator: (value) => (value == null || value.isEmpty) ? l10n.nameValidationError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l10n.phoneLabel, filled: true, fillColor: Colors.white.withAlpha(204), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.length < 10) ? l10n.phoneValidationError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: l10n.emailLabel, filled: true, fillColor: Colors.white.withAlpha(204), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@')) ? l10n.emailValidationError : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                // 2. Use the state variable here
                obscureText: !_isPasswordVisible, 
                decoration: InputDecoration(
                  labelText: l10n.passwordLabel,
                  filled: true,
                  fillColor: Colors.white.withAlpha(204),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  // 3. Add the icon button to toggle visibility
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
                validator: (value) => (value == null || value.length < 6) ? l10n.passwordValidationError : null,
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedRole,
                decoration: InputDecoration(filled: true, fillColor: Colors.white.withAlpha(204), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: [
                  DropdownMenuItem(value: 'farmer', child: Text(l10n.farmer)),
                  DropdownMenuItem(value: 'retailer', child: Text(l10n.retailer)),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: Colors.amber, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.signUpButton, style: const TextStyle(fontSize: 18, color: Colors.black87)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}