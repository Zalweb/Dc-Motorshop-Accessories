import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' as iconoir;

import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/brand_mark.dart';
import 'auth_controller.dart';

enum AuthTab { login, register }

class LoginScreen extends ConsumerStatefulWidget {
  final AuthTab initialTab;

  const LoginScreen({super.key, this.initialTab = AuthTab.login});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Shared controllers
  final _email = TextEditingController();
  final _password = TextEditingController();
  
  // Register-only controllers
  final _username = TextEditingController();
  final _confirm = TextEditingController();

  bool _rememberMe = false;
  late AuthTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('remember_me_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _email.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _username.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!v.contains('@') || !v.contains('.')) return 'Invalid email';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);

    // Handle Remember Me
    final prefs = await SharedPreferences.getInstance();
    if (_activeTab == AuthTab.login) {
      if (_rememberMe) {
        await prefs.setString('remember_me_email', _email.text);
      } else {
        await prefs.remove('remember_me_email');
      }
      await controller.login(_email.text, _password.text);
    } else {
      await controller.register(
        email: _email.text,
        password: _password.text,
        username: _username.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final size = MediaQuery.of(context).size;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text('${next.error}'),
            backgroundColor: Colors.redAccent,
          ));
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Theme-aware colors
    final bgColor = theme.scaffoldBackgroundColor;
    final curveColor = theme.colorScheme.surfaceContainer;
    final textColor = theme.colorScheme.onSurface;
    final pillBgColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final tabActiveBg = isDark ? const Color(0xFFE0E0E0) : Colors.white;
    final tabActiveText = isDark ? const Color(0xFF222224) : Colors.black;
    final tabInactiveText = isDark ? const Color(0xFF999999) : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── BACKGROUND SHAPES ──────────────────────────────────────────────
          
          // Top White Curve
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.35,
            child: ClipPath(
              clipper: _TopCurveClipper(),
              child: Container(
                color: curveColor,
                child: SafeArea(
                  child: Align(
                    alignment: const Alignment(0, -0.4),
                    child: Hero(
                      tag: 'app_logo',
                      child: BrandMark(size: 80),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Bottom White Curve (Only visible on Login as per reference)
          if (_activeTab == AuthTab.login)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.15,
              child: ClipPath(
                clipper: _BottomCurveClipper(),
                child: Container(
                  color: curveColor,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.only(right: 24, bottom: 24),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Remember me',
                        style: AppTextStyles.body.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v),
                        activeThumbColor: theme.colorScheme.primary,
                        activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
                        inactiveThumbColor: isDark ? Colors.white : Colors.grey.shade400,
                        inactiveTrackColor: isDark ? const Color(0xFF555555) : const Color(0xFFDCDCDC),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── MAIN CONTENT ───────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Spacer to push content down below the white area
                SizedBox(height: size.height * 0.28),
                
                // Toggle Pill
                Center(
                  child: Container(
                    height: 48,
                    width: size.width * 0.7,
                    decoration: BoxDecoration(
                      color: pillBgColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildTabButton('Login', AuthTab.login, tabActiveBg, tabActiveText, tabInactiveText)),
                        Expanded(child: _buildTabButton('Sign up', AuthTab.register, tabActiveBg, tabActiveText, tabInactiveText)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Form(
                      key: _formKey,
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        alignment: Alignment.topCenter,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_activeTab == AuthTab.register) ...[
                              _buildField(
                                label: 'Username',
                                controller: _username,
                                icon: const iconoir.User(width: 20, height: 20),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 20),
                            ],
                            
                            _buildField(
                              label: 'Email',
                              controller: _email,
                              icon: const iconoir.Mail(width: 20, height: 20),
                              keyboardType: TextInputType.emailAddress,
                              validator: _emailValidator,
                            ),
                            const SizedBox(height: 20),

                            _buildField(
                              label: 'Password',
                              controller: _password,
                              icon: const iconoir.Lock(width: 20, height: 20),
                              obscureText: true,
                              validator: (v) => (v == null || v.length < 8) ? 'At least 8 chars' : null,
                            ),

                            if (_activeTab == AuthTab.register) ...[
                              const SizedBox(height: 20),
                              _buildField(
                                label: 'Confirm password',
                                controller: _confirm,
                                icon: const iconoir.CheckCircle(width: 20, height: 20),
                                obscureText: true,
                                validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                              ),
                            ],

                            const SizedBox(height: 40),

                            // Action Button
                            SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.primary,
                                  foregroundColor: isDark ? const Color(0xFF222224) : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 4,
                                  shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(isDark ? const Color(0xFF222224) : Colors.white),
                                        ),
                                      )
                                    : Text(
                                        _activeTab == AuthTab.login ? 'Login' : 'Sign up',
                                        style: AppTextStyles.button.copyWith(
                                          color: isDark ? const Color(0xFF222224) : Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                            
                            if (_activeTab == AuthTab.login) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () => context.push('/forgot-password'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: theme.colorScheme.primary,
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            ],
                            
                            // Spacing at bottom
                            SizedBox(height: _activeTab == AuthTab.login ? 80 : 40),
                          ],
                        ),
                      ),
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

  Widget _buildTabButton(String text, AuthTab tab, Color activeBg, Color activeText, Color inactiveText) {
    final isActive = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: AppTextStyles.body.copyWith(
            color: isActive ? activeText : inactiveText,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    Widget? icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    
    // Luxury Input Design
    final fillColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: textColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: icon != null ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconTheme(
                data: IconThemeData(color: textColor.withOpacity(0.5)),
                child: icon,
              ),
            ) : null,
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}

// ── CUSTOM CLIPPERS ──────────────────────────────────────────────────────────

class _TopCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.85);

    // Creates an S-curve that swoops up towards the right
    path.cubicTo(
      size.width * 0.3, size.height,          // control point 1
      size.width * 0.7, size.height * 0.5,    // control point 2
      size.width, size.height * 0.65,         // end point
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at bottom left
    path.moveTo(0, size.height);
    // Draw the top curve (starts higher on right, dips to left)
    path.lineTo(0, size.height * 0.9);
    
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.2,    // control point
      size.width, 0,                          // end point
    );

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
