import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A previously resolved Zone D case, kept when a fresh case starts.
/// Demo storage: small history array inside hotspots/zone_d.
class ZoneDArchivedIncident {
  final String incidentId;
  final List<String> reporterUids;
  final String firstReporterUid;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const ZoneDArchivedIncident({
    required this.incidentId,
    required this.reporterUids,
    required this.firstReporterUid,
    required this.createdAt,
    required this.resolvedAt,
  });

  bool reportedBy(String? uid) => uid != null && reporterUids.contains(uid);

  int pointsFor(String? uid) {
    if (!reportedBy(uid)) return 0;
    return firstReporterUid == uid ? 10 : 3;
  }

  factory ZoneDArchivedIncident.fromMap(Map<String, dynamic> data) {
    final created = data['createdAt'];
    final resolved = data['resolvedAt'];
    return ZoneDArchivedIncident(
      incidentId: data['incidentId'] as String? ?? '',
      reporterUids: List<String>.from(data['reporterUids'] ?? <String>[]),
      firstReporterUid: data['firstReporterUid'] as String? ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      resolvedAt: resolved is Timestamp ? resolved.toDate() : null,
    );
  }
}

/// One CURRENT Zone D case, plus the small hackathon history of old cases.
class ZoneDCloudReport {
  final int confirmations;
  final List<String> reporterUids;
  final String firstReporterUid;
  final String incidentId;
  final String status;
  final bool resolved;
  final DateTime? resolvedAt;
  final bool demoUnlocked;
  final int unresolvedDays;
  final List<ZoneDArchivedIncident> history;

  const ZoneDCloudReport({
    required this.confirmations,
    required this.reporterUids,
    required this.firstReporterUid,
    required this.incidentId,
    required this.status,
    required this.resolved,
    required this.resolvedAt,
    this.demoUnlocked = false,
    required this.unresolvedDays,
    this.history = const <ZoneDArchivedIncident>[],
  });

  bool reportedBy(String? uid) => uid != null && reporterUids.contains(uid);

  int pointsFor(String? uid) {
    if (!reportedBy(uid)) return 0;
    return uid == firstReporterUid ? 10 : 3;
  }

  int totalPointsFor(String? uid) =>
      pointsFor(uid) + history.fold<int>(0, (sum, caseItem) => sum + caseItem.pointsFor(uid));

  int validReportsFor(String? uid) =>
      (reportedBy(uid) ? 1 : 0) + history.where((e) => e.reportedBy(uid)).length;

  int completedReportsFor(String? uid) =>
      ((resolved && reportedBy(uid)) ? 1 : 0) +
      history.where((e) => e.reportedBy(uid)).length;

  /// Server security rules, not this client clock, enforce the 30-second limit.
  bool get canStartNewIncident =>
      resolved && (demoUnlocked || (resolvedAt != null &&
      !DateTime.now().isBefore(resolvedAt!.add(const Duration(seconds: 30)))));

  bool get visibleOnResidentMap => confirmations > 0 &&
      (!resolved || (resolvedAt != null && !canStartNewIncident));

  factory ZoneDCloudReport.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return const ZoneDCloudReport(
        confirmations: 0,
        reporterUids: <String>[],
        firstReporterUid: '',
        incidentId: '',
        status: 'No Hotspot',
        resolved: false,
        resolvedAt: null,
        unresolvedDays: 0,
      );
    }
    final timestamp = data['resolvedAt'];
    final ids = List<String>.from(data['reporterUids'] ?? <String>[]);
    final rawHistory = data['history'] as List<dynamic>? ?? <dynamic>[];
    final previous = rawHistory.map((item) =>
        ZoneDArchivedIncident.fromMap(Map<String, dynamic>.from(item as Map))).toList();
    return ZoneDCloudReport(
      confirmations: ids.length,
      reporterUids: ids,
      firstReporterUid: data['firstReporterUid'] as String? ?? '',
      incidentId: data['incidentId'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending Review',
      resolved: data['resolved'] == true,
      resolvedAt: timestamp is Timestamp ? timestamp.toDate() : null,
      demoUnlocked: data['demoUnlocked'] == true,
      unresolvedDays: (data['unresolvedDays'] as num?)?.toInt() ?? 0,
      history: previous,
    );
  }
}

class ZoneDSubmitResult {
  final bool alreadyReported;
  final bool merged;
  final int confirmations;
  final int earnedPoints;

  const ZoneDSubmitResult({
    required this.alreadyReported,
    required this.merged,
    required this.confirmations,
    required this.earnedPoints,
  });
}

class ZoneDCloudService {
  ZoneDCloudService._();

  static final DocumentReference<Map<String, dynamic>> _zoneD =
      FirebaseFirestore.instance.collection('hotspots').doc('zone_d');

  static Stream<ZoneDCloudReport> watchZoneD() =>
      _zoneD.snapshots().map(ZoneDCloudReport.fromSnapshot);

  /// HACKATHON DEMO: A Resident who reported this active incident may
  /// advance the shared demo day counter by exactly one day per tap.
  /// This updates Firebase, so the Admin sees the alert in real time.
  /// The Firestore rules enforce the participant role and the same limit.
  static Future<int> simulateNextDay() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please log in as a participating Resident.');
    }

    return FirebaseFirestore.instance.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_zoneD);
      final data = snapshot.data();
      if (data == null || data['resolved'] == true) {
        throw StateError('A currently active Zone D report is required.');
      }

      final reporters = List<String>.from(data['reporterUids'] ?? <String>[]);
      if (!reporters.contains(user.uid)) {
        throw StateError('Report Zone D first before using this demo button.');
      }

      final currentDay = (data['unresolvedDays'] as num?)?.toInt() ?? 0;
      if (currentDay >= 7) {
        throw StateError('The demo has reached Day 7 (maximum).');
      }

      final nextDay = currentDay + 1;
      transaction.update(_zoneD, {
        'unresolvedDays': nextDay,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return nextDay;
    });
  }

  /// HACKATHON DEMO ONLY.
  /// The FIRST resident who created a resolved incident can simulate that
  /// the 30-second cooldown has elapsed. This updates a controlled flag in
  /// Firestore; it does not alter the real resolvedAt timestamp or history.
  /// Firestore Security Rules enforce the role, ownership and allowed fields.
  // Legacy API name retained for compatibility with older Resident pages.
  // This now simulates a 30-second wait, not two hours.
  static Future<void> simulateTwoHoursLater() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in as the original Resident.');
    }

    await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(_zoneD);
      final data = snapshot.data();
      if (data == null || data['resolved'] != true) {
        throw StateError('Zone D must be resolved before simulating 30 seconds.');
      }
      if (data['firstReporterUid'] != user.uid) {
        throw StateError(
          'Only the Resident who first reported this incident can run this demo.',
        );
      }
      if (data['demoUnlocked'] == true) return;

      transaction.update(_zoneD, {
        'demoUnlocked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// One transaction protects the confirmation count and report history.
  /// Transactions require internet access.
  static Future<ZoneDSubmitResult> submitZoneD() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in as a resident first.');
    }

    // Make the new ID once: transactions can retry their callback.
    final newIncidentId =
        'zone_d_${DateTime.now().toUtc().microsecondsSinceEpoch}';

    return FirebaseFirestore.instance.runTransaction<ZoneDSubmitResult>(
      (transaction) async {
        final snapshot = await transaction.get(_zoneD);
        final data = snapshot.data();

        if (data == null) {
          transaction.set(_zoneD, {
            'incidentId': newIncidentId,
            'location': 'Township Park, Zone D',
            'wasteType': 'Plastic & Food Packaging',
            'severity': 'HIGH',
            'status': 'Pending Review',
            'resolved': false,
            'resolvedAt': null,
            'demoUnlocked': false,
            'unresolvedDays': 0,
            'confirmations': 1,
            'reporterUids': <String>[user.uid],
            'firstReporterUid': user.uid,
            'history': <Map<String, dynamic>>[],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return const ZoneDSubmitResult(
            alreadyReported: false,
            merged: false,
            confirmations: 1,
            earnedPoints: 10,
          );
        }

        if (data['resolved'] == true) {
          final oldResolvedAt = data['resolvedAt'];
          if (oldResolvedAt is! Timestamp) {
            throw StateError('Resolved time is missing. Contact Admin.');
          }
          final allowedAt =
              oldResolvedAt.toDate().add(const Duration(seconds: 30));
          if (DateTime.now().isBefore(allowedAt) && data['demoUnlocked'] != true) {
            throw StateError('Zone D is resolved. Wait 30 real seconds, or use Simulate 30 Seconds Later in Progress.');
          }

          final history = List<dynamic>.from(data['history'] ?? <dynamic>[]);
          if (history.length >= 30) {
            throw StateError('Demo history limit reached. Ask Admin to archive older cases.');
          }
          // Preserve the exact previous case before changing the active case.
          final previousCase = <String, dynamic>{
            'incidentId': data['incidentId'],
            'reporterUids': data['reporterUids'],
            'firstReporterUid': data['firstReporterUid'],
            'createdAt': data['createdAt'],
            'resolvedAt': data['resolvedAt'],
          };

          transaction.update(_zoneD, {
            'history': <dynamic>[...history, previousCase],
            'incidentId': newIncidentId,
            'reporterUids': <String>[user.uid],
            'firstReporterUid': user.uid,
            'confirmations': 1,
            'status': 'Pending Review',
            'resolved': false,
            'resolvedAt': null,
            'demoUnlocked': false,
            'unresolvedDays': 0,
            'assignedTeam': 'Not assigned',
            'adminNote': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return const ZoneDSubmitResult(
            alreadyReported: false,
            merged: false,
            confirmations: 1,
            earnedPoints: 10,
          );
        }

        final reporters = List<String>.from(data['reporterUids'] ?? <String>[]);
        if (reporters.contains(user.uid)) {
          return ZoneDSubmitResult(
            alreadyReported: true,
            merged: true,
            confirmations: reporters.length,
            earnedPoints: 0,
          );
        }

        final updatedReporters = <String>[...reporters, user.uid];
        transaction.update(_zoneD, {
          'reporterUids': updatedReporters,
          'confirmations': updatedReporters.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return ZoneDSubmitResult(
          alreadyReported: false,
          merged: true,
          confirmations: updatedReporters.length,
          earnedPoints: 3,
        );
      },
    );
  }
}
