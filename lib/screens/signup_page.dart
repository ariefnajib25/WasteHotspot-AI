import 'package:flutter/material.dart';

import '../data/user_store.dart';

class SignupPage extends StatefulWidget {
  final Widget nextPage;

  const SignupPage({super.key, required this.nextPage});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String selectedZone = 'Zone A';
  String selectedHomeArea = 'Residential Area';

  bool agreeLocation = false;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  // ==========================================================
  // CREATE ACCOUNT
  // ==========================================================

  void createAccount() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all account fields.')),
      );

      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));

      return;
    }

    if (!agreeLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm the location usage information.'),
        ),
      );

      return;
    }

    UserStore.login(email: email, name: name);

    // Prototype account creation
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => widget.nextPage),
      (route) => false,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),

      appBar: AppBar(backgroundColor: const Color(0xFFF5F8F6), elevation: 0),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 5, 22, 35),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF16875B),
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Create your WasteHotspot AI profile.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // ACCOUNT INFORMATION
                    // ==================================================

                    const Text(
                      'Account Information',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

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

                    const SizedBox(height: 15),

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

                    const SizedBox(height: 15),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: hideConfirmPassword,

                      decoration: InputDecoration(
                        labelText: 'Confirm Password',

                        prefixIcon: const Icon(Icons.lock_outline),

                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              hideConfirmPassword = !hideConfirmPassword;
                            });
                          },

                          icon: Icon(
                            hideConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ==================================================
                    // HOME INFORMATION
                    // ==================================================
                    const Row(
                      children: [
                        Icon(Icons.home_outlined, color: Color(0xFF16875B)),

                        SizedBox(width: 8),

                        Text(
                          'Home Reference',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'This helps WasteHotspot AI compare your home area with future waste report locations.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),

                    const SizedBox(height: 18),

                    // HOME ZONE
                    DropdownButtonFormField<String>(
                      initialValue: selectedZone,

                      decoration: InputDecoration(
                        labelText: 'Home Zone',
                        prefixIcon: const Icon(Icons.location_on_outlined),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 'Zone A',
                          child: Text('Zone A'),
                        ),

                        DropdownMenuItem(
                          value: 'Zone B',
                          child: Text('Zone B'),
                        ),

                        DropdownMenuItem(
                          value: 'Zone C',
                          child: Text('Zone C'),
                        ),

                        DropdownMenuItem(
                          value: 'Zone D',
                          child: Text('Zone D'),
                        ),
                      ],

                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedZone = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    // HOME AREA TYPE
                    DropdownButtonFormField<String>(
                      initialValue: selectedHomeArea,

                      decoration: InputDecoration(
                        labelText: 'Home Area Type',

                        prefixIcon: const Icon(Icons.apartment_outlined),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),

                      items: const [
                        DropdownMenuItem(
                          value: 'Residential Area',
                          child: Text('Residential Area'),
                        ),

                        DropdownMenuItem(
                          value: 'Apartment / Condominium',
                          child: Text('Apartment / Condominium'),
                        ),

                        DropdownMenuItem(
                          value: 'Student Residence',
                          child: Text('Student Residence'),
                        ),

                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],

                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedHomeArea = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // LOCATION INFORMATION
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F1),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: agreeLocation,
                      activeColor: const Color(0xFF16875B),

                      onChanged: (value) {
                        setState(() {
                          agreeLocation = value ?? false;
                        });
                      },
                    ),

                    const SizedBox(width: 5),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Verification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16875B),
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            'I understand that WasteHotspot AI will request my current location when I create a waste report.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // CREATE ACCOUNT
              // ==================================================
              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: createAccount,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16875B),
                    foregroundColor: Colors.white,

                    padding: const EdgeInsets.symmetric(vertical: 16),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Center(
                child: Text(
                  'Your current GPS is requested only when reporting waste.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
