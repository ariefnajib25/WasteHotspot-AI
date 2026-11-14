import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';
import 'admin_dashboard_page.dart';
import '../data/user_store.dart';

/// WasteHotspot AI - Firebase Authentication for Resident and Admin.
///
/// The layout remains mobile-first. This checks the user role from Firestore.
/// Live report synchronisation will be added in the following step.
class LoginPage extends StatefulWidget {
  final Widget nextPage;

  const LoginPage({
    super.key,
    required this.nextPage,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const Color green = Color(0xFF16875B);
  static const Color darkGreen = Color(0xFF123C2D);
  static const Color background = Color(0xFFF5F8F6);

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool hidePassword = true;
  bool isAdminMode = false;
  bool isLoading = false;

  // Firebase verifies the email/password. Firestore supplies the app role.
  Future<void> signInWithFirebase() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;
    final selectedRole = isAdminMode ? 'admin' : 'resident';

    if (email.isEmpty || password.isEmpty) {
      _message('Please enter your Firebase email and password.');
      return;
    }

    setState(() => isLoading = true);

    try {
      final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;

      // Your Firestore rules allow each signed-in user to read only
      // users/{their own UID}. Do NOT let users edit this role in the app.
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final actualRole = userDoc.data()?['role'];

      if (actualRole != selectedRole) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        _message(
          'This account is not registered as $selectedRole. '
          'Choose the correct role and try again.',
        );
        return;
      }

      if (!mounted) return;

      if (selectedRole == 'resident') {
        // Keep the existing resident-specific screens and EcoPoints logic.
        UserStore.login(email: (credential.user!.email ?? email));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => widget.nextPage),
        );
      } else {
        // Admin Dashboard remains the existing mobile-sized Flutter page.
        // Firebase login controls who is allowed to open it.
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AdminDashboardPage(),
          ),
        );
        // Going back from the Admin Dashboard signs the admin out.
        await FirebaseAuth.instance.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final friendlyMessage = switch (e.code) {
        'invalid-email' => 'Please enter a valid email address.',
        'invalid-credential' || 'wrong-password' || 'user-not-found' =>
          'Incorrect email or password. Try your Firebase test account.',
        'too-many-requests' =>
          'Too many login attempts. Please try again later.',
        'network-request-failed' =>
          'No network connection. Check your internet and try again.',
        _ => 'Login failed: ${e.message ?? e.code}',
      };
      _message(friendlyMessage);
    } catch (e) {
      if (!mounted) return;
      _message('Unable to check your account role. Check Firebase access.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 22,
            vertical: 26,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F4EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: green,
                      size: 49,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'WasteHotspot AI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: darkGreen,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'One app. Two connected roles.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF69766E),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // RESIDENT / ADMIN MODE SELECTOR
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5EFE8),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _modeButton(
                            icon: Icons.person_outline_rounded,
                            label: 'Resident',
                            selected: !isAdminMode,
                            onTap: () {
                              if (isLoading) return;
                              setState(() => isAdminMode = false);
                            },
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: _modeButton(
                            icon: Icons.admin_panel_settings_outlined,
                            label: 'Admin',
                            selected: isAdminMode,
                            onTap: () {
                              if (isLoading) return;
                              setState(() => isAdminMode = true);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isAdminMode
                        ? _adminCard()
                        : _residentCard(),
                  ),

                  if (!isAdminMode) ...[
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Color(0xFF67756C),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _message('This is the old prototype sign-up page. '
                                'Firebase signup is not connected yet; use the two accounts '
                                'created in Firebase Console for this test.');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignupPage(
                                  nextPage: widget.nextPage,
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: green,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'WasteHotspot AI • Firebase Login Test',
                    style: TextStyle(
                      color: Color(0xFF8A978F),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD1E9DA)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? green : const Color(0xFF708177),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? darkGreen : const Color(0xFF64766B),
                  fontWeight:
                      selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _residentCard() {
    return Container(
      key: const ValueKey('resident'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_rounded, color: green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Resident Login',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Report rubbish and track waste incidents in your township.',
            style: TextStyle(
              color: Color(0xFF69766E),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 23),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: hidePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { signInWithFirebase(); },
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => hidePassword = !hidePassword);
                },
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : signInWithFirebase,
              icon: const Icon(Icons.login_rounded),
              label: Text(isLoading ? 'Signing in...' : 'Log In as Resident'),
              style: FilledButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminCard() {
    return Container(
      key: const ValueKey('admin'),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Township Admin',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Manage waste reports submitted by residents.',
            style: TextStyle(
              color: Color(0xFF69766E),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Admin Email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: passwordController,
            obscureText: hidePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { signInWithFirebase(); },
            decoration: InputDecoration(
              labelText: 'Admin Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => hidePassword = !hidePassword),
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _adminFeature(
            Icons.notifications_active_outlined,
            'Receive simulated waste alerts',
          ),
          const SizedBox(height: 11),
          _adminFeature(
            Icons.assignment_outlined,
            'Review and manage Zone D reports',
          ),
          const SizedBox(height: 11),
          _adminFeature(
            Icons.verified_outlined,
            'Update status and resolve cases',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : signInWithFirebase,
              icon: const Icon(Icons.login_rounded),
              label: Text(isLoading ? 'Signing in...' : 'Log In as Admin'),
              style: FilledButton.styleFrom(
                backgroundColor: darkGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          const Text(
            'Admin access is checked through Firebase Authentication and your '
            'Firestore role. Real-time report sharing is the next step.',
            style: TextStyle(
              color: Color(0xFF7B8980),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _adminFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 19, color: green),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF3E5C4A),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE2ECE5)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 15,
          offset: Offset(0, 7),
        ),
      ],
    );
  }
}
