import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_store_app/auth/auth_service.dart';
import 'package:multi_store_app/widgets/auth_widgets.dart';

/// Lets a signed-in user change their password.
///
///  1. Enter current (old) password — re-authenticates with Firebase.
///  2. Enter new password — validated for strength.
///  3. Confirm new password.
///
/// Push from the profile screen or settings.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  String _oldPassword = '';
  String _newPassword = '';
  // ignore: unused_field 
  String _confirmPassword = '';

  bool _oldVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _loading = false;

  int _strengthScore = 0;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService.instance.changePassword(
        oldPassword: _oldPassword,
        newPassword: _newPassword,
      );
      if (!mounted) return;
      _showSnack('Password changed successfully!', success: true);
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showSnack(AuthService.friendlyError(e));
    } catch (e) {
      _showSnack('Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green : null,
      ),
    );
  }

  // ─── strength indicator ───────────────────────────────────────────────────

  Color get _strengthColor {
    switch (_strengthScore) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      default:
        return Colors.green;
    }
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Icon(Icons.password, size: 60, color: Colors.purple),
              const SizedBox(height: 24),

              // ── Current password ─────────────────────────────────────────
              _buildField(
                label: 'Current Password',
                hint: 'Enter your current password',
                obscure: !_oldVisible,
                toggleVisible: () => setState(() => _oldVisible = !_oldVisible),
                visible: _oldVisible,
                onChanged: (v) => _oldPassword = v,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter your current password.';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── New password ──────────────────────────────────────────────
              _buildField(
                label: 'New Password',
                hint: 'Enter your new password',
                obscure: !_newVisible,
                toggleVisible: () => setState(() => _newVisible = !_newVisible),
                visible: _newVisible,
                onChanged: (v) {
                  _newPassword = v;
                  setState(() {
                    _strengthScore = AuthService.passwordStrengthScore(v);
                  });
                },
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password.';
                  final err = AuthService.validatePasswordStrength(v);
                  if (err != null) return err;
                  if (v == _oldPassword) {
                    return 'New password must differ from current password.';
                  }
                  return null;
                },
              ),

              // Strength bar
              if (_newPassword.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _strengthScore / 4,
                        color: _strengthColor,
                        backgroundColor: Colors.grey.shade200,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _strengthLabel,
                      style: TextStyle(
                        color: _strengthColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Min 8 chars · uppercase · lowercase · digit · special char',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],

              const SizedBox(height: 20),

              // ── Confirm new password ──────────────────────────────────────
              _buildField(
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                obscure: !_confirmVisible,
                toggleVisible: () => setState(() => _confirmVisible = !_confirmVisible),
                visible: _confirmVisible,
                onChanged: (v) => _confirmPassword = v,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm your password.';
                  if (v != _newPassword) return 'Passwords do not match.';
                  return null;
                },
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Update Password', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback toggleVisible,
    required bool visible,
    required ValueChanged<String> onChanged,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      obscureText: obscure,
      onChanged: onChanged,
      validator: validator,
      decoration: textFormDecoration.copyWith(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.purple),
        suffixIcon: IconButton(
          onPressed: toggleVisible,
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility, color: Colors.purple),
        ),
      ),
    );
  }
}
