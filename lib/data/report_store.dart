import 'user_store.dart';

class ReportStore {
  // ==========================================================
  // ZONE D HOTSPOT
  // ==========================================================
  static int zoneDReportCount = 0;
  static int zoneDUnresolvedDays = 0;
  static bool zoneDResolved = false;
  static DateTime? zoneDResolvedAt;
  static final Set<String> zoneDReporters = {};

  static final Map<String, int> _ecoPointsByUser = {};
  static final Map<String, int> _validReportsByUser = {};
  static final Map<String, int> _completedReportsByUser = {};

  // Avoid awarding one Firestore incident repeatedly when its snapshot changes.
  static final Set<String> _cloudCreditedIncidents = {};
  static final Set<String> _cloudCompletedIncidents = {};

  static String get _currentUser =>
      UserStore.currentUserEmail.trim().toLowerCase();

  static int get completedReports =>
      _completedReportsByUser[_currentUser] ?? 0;
  static int get ecoPoints => _ecoPointsByUser[_currentUser] ?? 0;
  static int get validReports => _validReportsByUser[_currentUser] ?? 0;

  static bool get currentUserAlreadyReportedZoneD =>
      zoneDReporters.contains(_currentUser);

  // ==========================================================
  // FIRESTORE LISTENER BRIDGE
  // Existing pages may continue reading the original static variables.
  // The Camera page updates these values when a Firestore snapshot arrives.
  // ==========================================================
  static void applyCloudZoneD({
    required int confirmations,
    required int unresolvedDays,
    required bool resolved,
    required DateTime? resolvedAt,
    required bool currentUserParticipated,
    required int currentUserPoints,
    required String incidentId,
    int? cloudTotalPoints,
    int? cloudValidReports,
    int? cloudCompletedReports,
  }) {
    zoneDReportCount = confirmations;
    zoneDUnresolvedDays = unresolvedDays;
    zoneDResolved = resolved;
    zoneDResolvedAt = resolvedAt;

    final user = _currentUser;
    if (user.isEmpty) return;

    // A full total recalculated from Firestore current + archived incidents
    // is stable across page reloads and new report cycles.
    if (cloudTotalPoints != null &&
        cloudValidReports != null &&
        cloudCompletedReports != null) {
      _ecoPointsByUser[user] = cloudTotalPoints;
      _validReportsByUser[user] = cloudValidReports;
      _completedReportsByUser[user] = cloudCompletedReports;
      if (currentUserParticipated) {
        zoneDReporters.add(user);
      } else {
        zoneDReporters.remove(user);
      }
      return;
    }

    if (currentUserParticipated) {
      zoneDReporters.add(user);
      if (incidentId.isNotEmpty) {
        final key = '$incidentId:$user';
        if (_cloudCreditedIncidents.add(key)) {
          _ecoPointsByUser[user] = ecoPoints + currentUserPoints;
          _validReportsByUser[user] = validReports + 1;
        }
        if (resolved && _cloudCompletedIncidents.add(key)) {
          _completedReportsByUser[user] = completedReports + 1;
        }
      }
    } else {
      zoneDReporters.remove(user);
    }
  }

  // ==========================================================
  // ORIGINAL LOCAL PROTOTYPE METHOD (kept for compatibility)
  // Do not call this from the Firebase Camera submission.
  // ==========================================================
  static int submitZoneDReport() {
    if (currentUserAlreadyReportedZoneD) return 0;
    final hotspotAlreadyExists = zoneDReportCount > 0;
    zoneDReporters.add(_currentUser);
    zoneDReportCount++;
    final earnedPoints = hotspotAlreadyExists ? 3 : 10;
    _ecoPointsByUser[_currentUser] = ecoPoints + earnedPoints;
    _validReportsByUser[_currentUser] = validReports + 1;
    return earnedPoints;
  }

  static String get userLevel {
    if (ecoPoints >= 300) return 'Township Hero';
    if (ecoPoints >= 150) return 'Eco Champion';
    if (ecoPoints >= 50) return 'Green Helper';
    return 'Green Starter';
  }

  static int get nextLevelTarget {
    if (ecoPoints < 50) return 50;
    if (ecoPoints < 150) return 150;
    if (ecoPoints < 300) return 300;
    return 300;
  }

  static double get levelProgress {
    if (ecoPoints >= 300) return 1.0;
    if (ecoPoints < 50) return ecoPoints / 50;
    if (ecoPoints < 150) return (ecoPoints - 50) / 100;
    return (ecoPoints - 150) / 150;
  }

  static bool get zoneDManagementAlert =>
      zoneDReportCount > 0 && !zoneDResolved && zoneDUnresolvedDays >= 2;

  static bool get zoneDIsUrgent =>
      zoneDReportCount >= 3 || zoneDUnresolvedDays >= 3;

  static String get zoneDStatus {
    if (zoneDResolved) return 'Resolved';
    if (zoneDUnresolvedDays >= 3) return 'Overdue Hotspot';
    if (zoneDReportCount >= 3) return 'Repeated Hotspot';
    if (zoneDReportCount >= 2) return 'Existing Hotspot';
    if (zoneDReportCount == 1) return 'New Hotspot';
    return 'No Hotspot';
  }

  // Original prototype simulation methods. These update local memory only.
  // When we connect the Admin and Progress pages, we will make these
  // operations use Firestore so they synchronise across different devices.
  static void simulateNextDay() {
    if (zoneDReportCount > 0 && !zoneDResolved) zoneDUnresolvedDays++;
  }

  static void resolveZoneD() {
    if (zoneDResolved || zoneDReportCount == 0) return;
    zoneDResolved = true;
    zoneDResolvedAt = DateTime.now();
    for (final email in zoneDReporters) {
      _completedReportsByUser[email] =
          (_completedReportsByUser[email] ?? 0) + 1;
    }
  }

  static bool get zoneDVisibleToResidents {
    if (zoneDReportCount == 0) return false;
    if (!zoneDResolved || zoneDResolvedAt == null) return true;
    return DateTime.now().difference(zoneDResolvedAt!) <
        const Duration(hours: 2);
  }

  // Local demo reset only. Do not use to reset a Firestore incident.
  static void simulateTwoHoursLater() {
    if (zoneDResolved && zoneDResolvedAt != null) {
      zoneDResolvedAt = DateTime.now().subtract(
        const Duration(hours: 2, seconds: 1),
      );
      zoneDReportCount = 0;
      zoneDReporters.clear();
      zoneDUnresolvedDays = 0;
      zoneDResolved = false;
      zoneDResolvedAt = null;
    }
  }
}
