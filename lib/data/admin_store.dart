import 'report_store.dart';

/// Prototype-only admin state. This is NOT a database or authentication system.
/// The admin and resident demo share data only inside one running Flutter app.
class AdminStore {
  static String zoneDActionStatus = 'Pending Review';
  static String zoneDAssignedTeam = 'Not assigned';
  static String zoneDAdminNote = '';
  static bool _observedResolved = false;

  static void syncWithReport() {
    // Observe resolution, so a later brand-new incident starts fresh.
    if (ReportStore.zoneDResolved) {
      _observedResolved = true;
      zoneDActionStatus = 'Resolved';
    } else if (ReportStore.zoneDReportCount == 0 || _observedResolved) {
      reset();
    }
  }

  static void reset() {
    zoneDActionStatus = 'Pending Review';
    zoneDAssignedTeam = 'Not assigned';
    zoneDAdminNote = '';
    _observedResolved = false;
  }

  static void update({
    required String status,
    required String team,
    required String note,
  }) {
    if (ReportStore.zoneDReportCount == 0 || ReportStore.zoneDResolved) {
      return;
    }
    zoneDActionStatus = status;
    zoneDAssignedTeam = team;
    zoneDAdminNote = note.trim();
  }

  static void resolve() {
    if (ReportStore.zoneDReportCount == 0 || ReportStore.zoneDResolved) {
      return;
    }
    ReportStore.resolveZoneD();
    zoneDActionStatus = 'Resolved';
    _observedResolved = true;
  }

  static String get effectiveStatus {
    syncWithReport();
    if (ReportStore.zoneDResolved) return 'Resolved';
    return zoneDActionStatus;
  }
}
