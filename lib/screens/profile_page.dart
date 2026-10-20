import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.onLogout});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userName = 'Arief Najib';
  String userEmail = 'ariefnajib@example.com';

  bool darkMode = false;
  bool notifications = true;

  // ==========================================================
  // EDIT PROFILE
  // ==========================================================

  void editProfile() {
    final nameController =
        TextEditingController(text: userName);

    final emailController =
        TextEditingController(text: userEmail);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(
                    Icons.person_outline,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  userName =
                      nameController.text.trim();
                  userEmail =
                      emailController.text.trim();
                });

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF16875B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // SIMPLE INFO POPUP
  // ==========================================================

  void showSimpleMessage(
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF16875B),
                foregroundColor:
                    Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // LOGOUT POPUP
  // ==========================================================

  void showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.logout,
            color: Colors.red,
            size: 45,
          ),
          title: const Text(
            'Log Out?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Are you sure you want to log out of WasteHotspot AI?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                widget.onLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Log Out',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          20,
          20,
          110,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==================================================
            // TITLE
            // ==================================================

            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16875B),
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'Manage your account and app preferences.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 25),

            // ==================================================
            // PROFILE CARD
            // ==================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // PROFILE AVATAR
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE4F4EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: Color(0xFF16875B),
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 18),

                  OutlinedButton.icon(
                    onPressed: editProfile,
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 11,
                      ),
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                    ),
                    label: const Text(
                      'Edit Profile',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // PREFERENCES
            // ==================================================

            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  // DARK MODE
                  SettingsSwitchTile(
                    icon: darkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: darkMode
                        ? 'Dark appearance enabled'
                        : 'Light appearance enabled',
                    value: darkMode,
                    onChanged: (value) {
                      setState(() {
                        darkMode = value;
                      });
                    },
                  ),

                  const Divider(
                    height: 1,
                    indent: 60,
                  ),

                  // NOTIFICATIONS
                  SettingsSwitchTile(
                    icon:
                        Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle:
                        'Receive report and community updates',
                    value: notifications,
                    onChanged: (value) {
                      setState(() {
                        notifications = value;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // SETTINGS
            // ==================================================

            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  SettingsTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location Permission',
                    subtitle:
                        'Manage location access',
                    onTap: () {
                      showSimpleMessage(
                        'Location Permission',
                        'WasteHotspot AI uses location to identify waste hotspots and verify public areas.',
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                    indent: 60,
                  ),

                  SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Privacy & Security',
                    subtitle:
                        'Manage privacy settings',
                    onTap: () {
                      showSimpleMessage(
                        'Privacy & Security',
                        'Privacy settings will be available in the full version.',
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                    indent: 60,
                  ),

                  SettingsTile(
                    icon:
                        Icons.help_outline,
                    title: 'Help & Support',
                    subtitle:
                        'Get help using the app',
                    onTap: () {
                      showSimpleMessage(
                        'Help & Support',
                        'Help and support information will appear here.',
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                    indent: 60,
                  ),

                  SettingsTile(
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle:
                        'About WasteHotspot AI',
                    onTap: () {
                      showSimpleMessage(
                        'WasteHotspot AI',
                        'AI-Powered Township Waste Intelligence System.',
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ==================================================
            // LOGOUT
            // ==================================================

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: showLogoutDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(
                    color: Colors.redAccent,
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(
                  Icons.logout,
                ),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'WasteHotspot AI • Prototype',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// NORMAL SETTINGS TILE
// ==========================================================

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,

      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF7F1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF16875B),
          size: 21,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),

      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
    );
  }
}

// ==========================================================
// SETTINGS SWITCH
// ==========================================================

class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFEAF7F1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color(0xFF16875B),
          size: 21,
        ),
      ),

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
        ),
      ),

      trailing: Switch(
        value: value,
        activeThumbColor:
            const Color(0xFF16875B),
        onChanged: onChanged,
      ),
    );
  }
}