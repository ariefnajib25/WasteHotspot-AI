import 'package:flutter/material.dart';

import 'screens/home_page.dart';
import 'screens/camera_page.dart';
import 'screens/community_page.dart';
import 'screens/progress_page.dart';
import 'screens/profile_page.dart';
import 'screens/splash_screen.dart';
import 'screens/login_page.dart';
import 'data/user_store.dart';

void main() {
  runApp(const WasteHotspotApp());
}

// ==========================================================
// MAIN APP
// ==========================================================

class WasteHotspotApp extends StatelessWidget {
  const WasteHotspotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WasteHotspot AI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF16875B)),
      ),
      home: const SplashScreen(nextPage: MainScreen()),
    );
  }
}

// ==========================================================
// MAIN SCREEN
// ==========================================================

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  // Did the user submit our dummy report?
  bool newReportSubmitted = false;

  void logout() {
    UserStore.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(nextPage: MainScreen()),
      ),
      (route) => false,
    );
  }

  // ==========================================================
  // PAGES
  // ==========================================================

  List<Widget> get pages => [
    HomePage(hasNewReport: newReportSubmitted),
    CommunityPage(hasNewReport: newReportSubmitted),
    ProgressPage(hasNewReport: newReportSubmitted),
    
    
    ProfilePage(onLogout: logout),
  ];

  // ==========================================================
  // LOCATION PERMISSION
  // ==========================================================

  void requestLocationPermission() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),

          icon: Container(
            width: 65,
            height: 65,
            decoration: const BoxDecoration(
              color: Color(0xFFE4F4EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xFF16875B),
              size: 34,
            ),
          ),

          title: const Text(
            'Allow Location Access?',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WasteHotspot AI needs your location to identify where the waste was reported.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text(
                'Your location will also help verify whether the waste is in a public or personal area.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),

          actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),

          actions: [
            Row(
              children: [
                // DON'T ALLOW
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      setState(() {
                        currentIndex = 0;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Don't Allow"),
                  ),
                ),

                const SizedBox(width: 10),

                // ALLOW
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);

                      openCameraPage();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16875B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // OPEN CAMERA
  // ==========================================================

  Future<void> openCameraPage() async {
    final bool? reportSubmitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CameraPage()),
    );

    // CameraPage sends TRUE when report is submitted
    if (reportSubmitted == true && mounted) {
      setState(() {
        newReportSubmitted = true;
        currentIndex = 0;
      });
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: pages[currentIndex],

      // ======================================================
      // CAMERA BUTTON
      // ======================================================
      floatingActionButton: FloatingActionButton(
        onPressed: requestLocationPermission,
        backgroundColor: const Color(0xFF16875B),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 30),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ======================================================
      // BOTTOM NAVIGATION
      // ======================================================
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 15,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,

        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              navItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                pageIndex: 0,
              ),

              navItem(
                icon: Icons.groups_outlined,
                selectedIcon: Icons.groups,
                label: 'Community',
                pageIndex: 1,
              ),

              const SizedBox(width: 65),

              navItem(
                icon: Icons.timeline_outlined,
                selectedIcon: Icons.timeline,
                label: 'Progress',
                pageIndex: 2,
              ),

              navItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profile',
                pageIndex: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // NAVIGATION ITEM
  // ==========================================================

  Widget navItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int pageIndex,
  }) {
    final bool isSelected = currentIndex == pageIndex;

    return InkWell(
      onTap: () {
        setState(() {
          currentIndex = pageIndex;
        });
      },
      borderRadius: BorderRadius.circular(15),
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 25,
              color: isSelected ? const Color(0xFF16875B) : Colors.grey,
            ),

            const SizedBox(height: 3),

            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF16875B) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================================
// PLACEHOLDER
// ==========================================================

class PagePlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const PagePlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 70, color: const Color(0xFF16875B)),

            const SizedBox(height: 20),

            Text(
              title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
