import 'user_store.dart';

class ReportStore {
  // ==========================================================
  // ZONE D HOTSPOT
  // ==========================================================

  static int zoneDReportCount = 0;
  static int zoneDUnresolvedDays = 0;
  static bool zoneDResolved = false;
  static DateTime? zoneDResolvedAt;

  // Stores the emails of users who already reported Zone D
  static final Set<String> zoneDReporters = {};

  // ==========================================================
  // ECOPOINTS PER USER
  // ==========================================================

  static final Map<String, int> _ecoPointsByUser = {};
  static final Map<String, int> _validReportsByUser = {};

  static String get _currentUser {
    return UserStore.currentUserEmail.toLowerCase();
  }

  static int get ecoPoints {
    return _ecoPointsByUser[_currentUser] ?? 0;
  }

  static int get validReports {
    return _validReportsByUser[_currentUser] ?? 0;
  }

  // ==========================================================
  // CHECK IF CURRENT USER ALREADY REPORTED ZONE D
  // ==========================================================

  static bool get currentUserAlreadyReportedZoneD {
    return zoneDReporters.contains(_currentUser);
  }

  // ==========================================================
  // SUBMIT ZONE D REPORT
  // ==========================================================

  static int submitZoneDReport() {
    // Same user already reported this hotspot
    if (currentUserAlreadyReportedZoneD) {
      return 0;
    }

    final bool hotspotAlreadyExists = zoneDReportCount > 0;

    // Add user to reporter list
    zoneDReporters.add(_currentUser);

    // Increase UNIQUE report count
    zoneDReportCount++;

    // Reward
    final int earnedPoints = hotspotAlreadyExists ? 3 : 10;

    _ecoPointsByUser[_currentUser] = ecoPoints + earnedPoints;

    _validReportsByUser[_currentUser] = validReports + 1;

    return earnedPoints;
  }

  // ==========================================================
  // LEVEL
  // ==========================================================

  static String get userLevel {
    if (ecoPoints >= 300) {
      return 'Township Hero';
    }

    if (ecoPoints >= 150) {
      return 'Eco Champion';
    }

    if (ecoPoints >= 50) {
      return 'Green Helper';
    }

    return 'Green Starter';
  }

  static int get nextLevelTarget {
    if (ecoPoints < 50) {
      return 50;
    }

    if (ecoPoints < 150) {
      return 150;
    }

    if (ecoPoints < 300) {
      return 300;
    }

    return 300;
  }

  static double get levelProgress {
    if (ecoPoints >= 300) {
      return 1.0;
    }

    if (ecoPoints < 50) {
      return ecoPoints / 50;
    }

    if (ecoPoints < 150) {
      return (ecoPoints - 50) / 100;
    }

    return (ecoPoints - 150) / 150;
  }

  static bool get zoneDManagementAlert {
    return zoneDReportCount > 0 && !zoneDResolved && zoneDUnresolvedDays >= 2;
  }

  static bool get zoneDIsUrgent {
    // Urgent if:
    // 1. 3+ different residents confirmed it
    // OR
    // 2. It has remained unresolved for 3+ days
    return zoneDReportCount >= 3 || zoneDUnresolvedDays >= 3;
  }

  static String get zoneDStatus {
    if (zoneDResolved) {
      return 'Resolved';
    }

    if (zoneDUnresolvedDays >= 3) {
      return 'Overdue Hotspot';
    }

    if (zoneDReportCount >= 3) {
      return 'Repeated Hotspot';
    }

    if (zoneDReportCount >= 2) {
      return 'Existing Hotspot';
    }

    if (zoneDReportCount == 1) {
      return 'New Hotspot';
    }

    return 'No Hotspot';
  }

  static void simulateNextDay() {
    if (zoneDReportCount > 0 && !zoneDResolved) {
      zoneDUnresolvedDays++;
    }
  }

  static void resolveZoneD() {
    zoneDResolved = true;
    zoneDResolvedAt = DateTime.now();
  }

  // ==========================================================
  // RESIDENT VISIBILITY AFTER RESOLUTION
  // ==========================================================

  static bool get zoneDVisibleToResidents {
    // No hotspot has ever been created
    if (zoneDReportCount == 0) {
      return false;
    }

    // Active hotspot should always be visible
    if (!zoneDResolved) {
      return true;
    }

    // Safety fallback
    if (zoneDResolvedAt == null) {
      return true;
    }

    // Resolved hotspot stays visible for 2 hours
    final Duration timeSinceResolved = DateTime.now().difference(
      zoneDResolvedAt!,
    );

    return timeSinceResolved < const Duration(hours: 2);
  }

  // Used only for hackathon demonstration
  static void simulateTwoHoursLater() {
    if (zoneDResolved && zoneDResolvedAt != null) {
      // Simulate that the 2-hour resolved display period has passed
      zoneDResolvedAt = DateTime.now().subtract(
        const Duration(hours: 2, seconds: 1),
      );

      // ========================================================
      // CLOSE THE OLD RESIDENT HOTSPOT CYCLE
      // ========================================================

      zoneDReportCount = 0;

      // Allow residents to report a NEW waste incident
      // at Zone D in the future.
      zoneDReporters.clear();

      zoneDUnresolvedDays = 0;
      zoneDResolved = false;
      zoneDResolvedAt = null;
    }
  }
}
