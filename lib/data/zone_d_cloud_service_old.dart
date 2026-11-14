import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One shared Zone D hotspot for the WasteHotspot AI prototype.
/// This service uses Firebase Authentication UIDs to prevent duplicate reports.
class ZoneDCloudReport {
  final int confirmations;
  final List<String> reporterUids;
  final String firstReporterUid;
  final String incidentId;
  final String status;
  final bool resolved;
  final DateTime? resolvedAt;
  final int unresolvedDays;

  const ZoneDCloudReport({
    required this.confirmations,
    required this.reporterUids,
    required this.firstReporterUid,
    required this.incidentId,
    required this.status,
    required this.resolved,
    required this.resolvedAt,
    required this.unresolvedDays,
  });

  bool reportedBy(String? uid) => uid != null && reporterUids.contains(uid);

  int pointsFor(String? uid) {
    if (!reportedBy(uid)) return 0;
    return uid == firstReporterUid ? 10 : 3;
  }

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
    return ZoneDCloudReport(
      confirmations: ids.length,
      reporterUids: ids,
      firstReporterUid: data['firstReporterUid'] as String? ?? '',
      incidentId: data['incidentId'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending Review',
      resolved: data['resolved'] == true,
      resolvedAt: timestamp is Timestamp ? timestamp.toDate() : null,
      unresolvedDays: (data['unresolvedDays'] as num?)?.toInt() ?? 0,
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

  /// Uses a transaction so simultaneous submissions are safely merged.
  /// NOTE: Firestore transactions need an internet connection.
  static Future<ZoneDSubmitResult> submitZoneD() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Please sign in as a resident first.');
    }

    // Created once outside the transaction because Firestore may retry it.
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
            'unresolvedDays': 0,
            'confirmations': 1,
            'reporterUids': <String>[user.uid],
            'firstReporterUid': user.uid,
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
          throw StateError(
            'Zone D is already resolved. A new incident will need a new cycle.',
          );
        }

        final reporters =
            List<String>.from(data['reporterUids'] ?? <String>[]);
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
