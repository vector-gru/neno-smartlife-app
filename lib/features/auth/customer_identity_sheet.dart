import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/auth/auth_models.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomerIdentitySheet
//
// A modal bottom sheet that asks for the customer's full name and phone number
// before they can perform an action that requires identification (e.g. save a
// favourite, submit a request).
//
// Usage:
//   final saved = await CustomerIdentitySheet.show(context);
//   if (saved == true) { /* proceed with the protected action */ }
// ─────────────────────────────────────────────────────────────────────────────

class CustomerIdentitySheet extends StatefulWidget {
  const CustomerIdentitySheet({super.key});

  /// Shows the sheet and returns true if the identity was successfully saved.
  ///
  /// If the current user is an admin the sheet is skipped entirely and `true`
  /// is returned — the admin's identity is not managed through this flow, and
  /// showing the sheet would risk triggering `signInAnonymously()` which
  /// would overwrite the admin's Firebase Auth session.
  static Future<bool> show(BuildContext context) async {
    // Short-circuit for admin — never show the customer identity sheet.
    if (context.appState.isAdmin) return true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CustomerIdentitySheet(),
    );
    return result == true;
  }

  @override
  State<CustomerIdentitySheet> createState() => _CustomerIdentitySheetState();
}

class _CustomerIdentitySheetState extends State<CustomerIdentitySheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // ── Phone-lookup state ─────────────────────────────────────────────────────
  bool _isLookingUp = false;
  CustomerIdentity? _matchedIdentity; // non-null = returning customer found
  bool _lookupDone = false; // true once lookup returned (match or no match)
  Timer? _debounce;

  // Name is editable ONLY when lookup is done AND no match was found.
  bool get _nameEditable => _lookupDone && _matchedIdentity == null;
  // Name is locked (auto-filled) when a match was found.
  bool get _nameLocked => _matchedIdentity != null;

  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    final identity = context.appState.customerIdentity;
    if (identity != null) {
      // Pre-fill existing session — treat as a known match immediately.
      _matchedIdentity = identity;
      _lookupDone = true;
      _nameController.text = identity.fullName;
      final phone = identity.phone;
      _phoneController.text =
          phone.startsWith('+237') ? phone.substring(4).trimLeft() : phone;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _phoneController.removeListener(_onPhoneChanged);
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Phone change handler ───────────────────────────────────────────────────

  void _onPhoneChanged() {
    // Reset all lookup state whenever the phone number changes.
    if (_matchedIdentity != null || _lookupDone) {
      setState(() {
        _matchedIdentity = null;
        _lookupDone = false;
        _nameController.clear();
      });
    }

    _debounce?.cancel();
    final digits = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');

    // Only look up once we have a plausible number length.
    if (digits.length < 8) return;

    _debounce = Timer(const Duration(milliseconds: 600), () => _lookupPhone());
  }

  Future<void> _lookupPhone() async {
    final rawPhone = _phoneController.text.trim();
    final fullPhone = rawPhone.startsWith('+237') ? rawPhone : '+237 $rawPhone';

    setState(() => _isLookingUp = true);
    try {
      final found = await AuthService.instance.findCustomerByPhone(fullPhone);
      if (!mounted) return;
      setState(() {
        _lookupDone = true;
        if (found != null) {
          _matchedIdentity = found;
          _nameController.text = found.fullName;
        }
        // If no match, _nameEditable becomes true — user can type their name.
      });
    } catch (_) {
      // On error, allow the user to type their name so they're not stuck.
      if (mounted) setState(() => _lookupDone = true);
    } finally {
      if (mounted) setState(() => _isLookingUp = false);
    }
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawPhone = _phoneController.text.trim();
      final fullPhone =
          rawPhone.startsWith('+237') ? rawPhone : '+237 $rawPhone';
      await context.appState.saveCustomerIdentity(
        fullName: _nameController.text.trim(),
        phone: fullPhone,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primaryDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Just one step',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'We need your name and phone to save this.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Form ──────────────────────────────────────────────────────
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Phone number (first) ────────────────────────────────
                const _FieldLabel('Phone number'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofocus: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s]')),
                  ],
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: _inputDecoration(
                    hint: '6XX XXX XXX',
                    icon: Icons.phone_outlined,
                    prefix: '+237 ',
                    suffix: _isLookingUp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : _matchedIdentity != null
                            ? const Icon(Icons.check_circle_rounded,
                                color: AppColors.success, size: 18)
                            : null,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    final digits = v.replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 8) {
                      return 'Enter a valid Cameroonian number';
                    }
                    return null;
                  },
                ),

                // ── Returning customer banner ───────────────────────────
                if (_matchedIdentity != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.waving_hand_rounded,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Welcome back! Your name has been filled in.',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // ── Full name (second) ──────────────────────────────────
                const _FieldLabel('Full name'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  // Editable only after lookup confirms no existing account.
                  readOnly: !_nameEditable,
                  onFieldSubmitted: _nameEditable ? (_) => _submit() : null,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _nameLocked
                        ? AppColors.textSecondary
                        : !_nameEditable
                            ? AppColors.textMuted
                            : AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration(
                    hint: _isLookingUp
                        ? 'Checking…'
                        : !_lookupDone
                            ? 'Enter phone number first'
                            : 'e.g. Marie Kamgaing',
                    icon: Icons.person_outline_rounded,
                    locked: !_nameEditable,
                    lockIcon: _isLookingUp
                        ? Icons.hourglass_top_rounded
                        : !_lookupDone
                            ? Icons.lock_outline_rounded
                            : Icons.lock_outline_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    if (v.trim().length < 2) return 'Name is too short';
                    return null;
                  },
                ),

                // ── Error ──────────────────────────────────────────────
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.error),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Confirm button ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(
                                  AppColors.textOnPrimary),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Privacy note ───────────────────────────────────────
                Center(
                  child: Text(
                    'Your info is only shared with the store.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefix,
    Widget? suffix,
    bool locked = false,
    IconData lockIcon = Icons.lock_outline_rounded,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
      prefixText: prefix,
      prefixStyle: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      suffixIcon: locked
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(lockIcon, size: 16, color: AppColors.textMuted),
            )
          : suffix != null
              ? Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: suffix,
                )
              : null,
      filled: true,
      fillColor: locked ? const Color(0xFFEEEEEE) : const Color(0xFFF4F4F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: AppColors.error.withValues(alpha: 0.5), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: locked
            ? BorderSide.none
            : const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}

// ── Small label widget ────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
