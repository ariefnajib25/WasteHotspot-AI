import 'package:flutter/material.dart';

import 'signup_page.dart';
import '../data/user_store.dart';

class LoginPage extends StatefulWidget {
  final Widget nextPage;

  const LoginPage({super.key, required this.nextPage});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;

  // ==========================================================
  // LOGIN
  // ==========================================================

  void login() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );

      return;
    }

    UserStore.login(email: email);

    // Prototype authentication only
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => widget.nextPage),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),

          child: Column(
            children: [
              const SizedBox(height: 30),

              // ==================================================
              // LOGO
              // ==================================================
              Container(
                width: 95,
                height: 95,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4F4EC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco,
                  size: 50,
                  color: Color(0xFF16875B),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'WasteHotspot AI',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16875B),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Township Waste Intelligence',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 40),

              // ==================================================
              // LOGIN CARD
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Log in to continue helping your township.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),

                    const SizedBox(height: 25),

                    // EMAIL
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // PASSWORD
                    TextField(
                      controller: passwordController,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',

                        prefixIcon: const Icon(Icons.lock_outline),

                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
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

                    const SizedBox(height: 25),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16875B),
                          foregroundColor: Colors.white,

                          padding: const EdgeInsets.symmetric(vertical: 16),

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // SIGN UP
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SignupPage(nextPage: widget.nextPage),
                        ),
                      );
                    },

                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF16875B),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                'WasteHotspot AI • Prototype',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
