import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/report_store.dart';
import '../data/zone_d_demo_preview.dart';
import '../data/zone_d_cloud_service.dart';

class ProgressPage extends StatefulWidget {
  final bool hasNewReport;

  const ProgressPage({super.key, required this.hasNewReport});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // Firestore is the source of truth for Zone D. Unlike local ReportStore
  // variables, this works across separate resident and admin devices.
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _zoneDSubscription;

  ZoneDCloudReport? _zoneD;
  String _assignedTeam = 'Not assigned';
  String _adminNote = '';
  String? _firestoreError;
  bool _loading = true;
  bool _simulatingTwoHours = false;
  Timer? _cooldownExpiryTimer;
  bool _simulatingNextDay = false;
  bool get _previewTwoHoursLater =>
      (_zoneD?.canStartNewIncident ?? false) || ZoneDDemoPreview.isMarkerHidden(_zoneD);

  @override
  void initState() {
    super.initState();
    _zoneDSubscription = FirebaseFirestore.instance
        .collection('hotspots')
        .doc('zone_d')
        .snapshots()
        .listen(
      (snapshot) {
        final report = ZoneDCloudReport.fromSnapshot(snapshot);
        final data = snapshot.data();
        final uid = FirebaseAuth.instance.currentUser?.uid;

        // Keep other existing resident pages' local state in sync during
        // this session. This bridge is not the permanent cloud history store.
        ReportStore.applyCloudZoneD(
          confirmations: report.confirmations,
          unresolvedDays: report.unresolvedDays,
          resolved: report.resolved,
          resolvedAt: report.resolvedAt,
          currentUserParticipated: report.reportedBy(uid),
          currentUserPoints: report.pointsFor(uid),
          incidentId: report.incidentId,
          cloudTotalPoints: report.totalPointsFor(uid),
          cloudValidReports: report.validReportsFor(uid),
          cloudCompletedReports: report.completedReportsFor(uid),
        );

        if (!mounted) return;
        setState(() {
          _zoneD = report;
          _assignedTeam = data?['assignedTeam'] as String? ?? 'Not assigned';
          _adminNote = data?['adminNote'] as String? ?? '';
          _firestoreError = null;
          _loading = false;
        });
        _scheduleCooldownExpiry(report);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _firestoreError = error.toString();
        });
      },
    );
  }

  // Update the progress UI when the real 30-second cooldown expires.
  // Firestore does not broadcast a new snapshot just because time passed.
  void _scheduleCooldownExpiry(ZoneDCloudReport report) {
    _cooldownExpiryTimer?.cancel();
    _cooldownExpiryTimer = null;
    if (!report.resolved || report.resolvedAt == null ||
        report.canStartNewIncident) return;

    final deadline = report.resolvedAt!.add(const Duration(seconds: 30));
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) return;

    _cooldownExpiryTimer = Timer(
      remaining + const Duration(milliseconds: 120),
      () { if (mounted) setState(() {}); },
    );
  }

  @override
  void dispose() {
    _cooldownExpiryTimer?.cancel();
    _zoneDSubscription.cancel();
    super.dispose();
  }

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // This resident only sees Zone D in their own report history if their
  // Firebase UID is on the report's confirmation list.
  bool get currentUserHasZoneDReport =>
      _zoneD?.reportedBy(_currentUid) ?? false;

  bool get zoneDExists =>
      currentUserHasZoneDReport && (_zoneD?.confirmations ?? 0) > 0;

  bool get isResolved => _zoneD?.resolved ?? false;

  int get unresolvedDays => _zoneD?.unresolvedDays ?? 0;

  int get residentConfirmations => _zoneD?.confirmations ?? 0;

  bool get isUrgent =>
      !isResolved && (residentConfirmations >= 3 || unresolvedDays >= 3);

  bool get managementAlertSent =>
      zoneDExists && !isResolved && unresolvedDays >= 2;

  // Only count the signed-in resident's actual cloud participation.
  // Zone A and Zone B are still static demo examples, not this user's cases.
  int get myActiveReports => zoneDExists && !isResolved ? 1 : 0;

  int get myCompletedReports =>
      _zoneD?.completedReportsFor(_currentUid) ?? 0;

  // ==========================================================
  // PRIORITY
  // ==========================================================

  String get priority {
    if (isResolved) {
      return 'RESOLVED';
    }

    if (isUrgent) {
      return 'URGENT';
    }

    return 'HIGH';
  }

  Color get priorityColor {
    if (isResolved) {
      return const Color(0xFF16875B);
    }

    if (isUrgent) {
      return const Color(0xFF8B0000);
    }

    return Colors.red;
  }

  // ==========================================================
  // LIVE ACTION STATUS
  // ==========================================================

  String get actionStatus {
    if (isResolved) return 'Resolved';

    final cloudStatus = _zoneD?.status ?? 'Pending Review';
    if (cloudStatus == 'Under Review' ||
        cloudStatus == 'In Progress' ||
        cloudStatus == 'Pending Review') {
      return cloudStatus;
    }
    if (unresolvedDays >= 3) return 'Overdue - Action Required';
    if (unresolvedDays >= 2) return 'Management Alert Sent';
    if (unresolvedDays >= 1) return 'Pending Action';
    return cloudStatus;
  }

  String get hotspotStatus {
    if (isResolved) return 'Resolved';
    if (unresolvedDays >= 3) return 'Overdue Hotspot';
    if (residentConfirmations >= 3) return 'Repeated Hotspot';
    if (residentConfirmations >= 2) return 'Existing Hotspot';
    if (residentConfirmations == 1) return 'New Hotspot';
    return 'No Hotspot';
  }

  // ==========================================================
  // REPORT AGE
  // ==========================================================

  String get reportAge {
    if (unresolvedDays == 0) {
      return 'Demo Day 0';
    }

    if (unresolvedDays == 1) {
      return 'Demo Day 1';
    }

    return 'Demo Day $unresolvedDays';
  }

  // ==========================================================
  // FIREBASE DEMO: RESIDENT ADVANCES SHARED UNRESOLVED DAY
  // ==========================================================

  Future<void> simulateNextDay() async {
    if (!zoneDExists || isResolved || _simulatingNextDay || unresolvedDays >= 7) {
      return;
    }
    setState(() => _simulatingNextDay = true);
    try {
      final day = await ZoneDCloudService.simulateNextDay();
      if (!mounted) return;
      final message = day >= 3
          ? 'Demo Day $day: URGENT! Admin has been alerted.'
          : day >= 2
              ? 'Demo Day 2: Management alert sent to Admin.'
              : 'Demo Day 1: Admin received a new day update.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: day >= 3
              ? const Color(0xFF8B0000)
              : const Color(0xFF16875B),
          content: Text(message),
        ),
      );
      // The Firestore .snapshots() listener updates the displayed day.
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to simulate next day: $error')),
      );
    } finally {
      if (mounted) setState(() => _simulatingNextDay = false);
    }
  }

  // ==========================================================
  // FIREBASE DEMO: FAST-FORWARD THE RESOLVED CASE
  // ==========================================================

  Future<void> simulateTwoHoursLater() async {
    if (!zoneDExists || !isResolved || _zoneD == null || _simulatingTwoHours) {
      return;
    }
    if (_previewTwoHoursLater) return;

    setState(() => _simulatingTwoHours = true);
    try {
      // Cloud transaction updates the shared demoUnlocked flag.
      // The real resolvedAt time and archived case are untouched.
      await ZoneDCloudService.simulateTwoHoursLater();
      if (!mounted) return;
      ZoneDDemoPreview.simulateTwoHoursLater(_zoneD!);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF16875B),
          content: Text(
            '30 seconds simulated in Firebase! Zone D is hidden from maps. '
            'You can now create a NEW report using Camera.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not simulate 30 seconds: $error')),
      );
    } finally {
      if (mounted) setState(() => _simulatingTwoHours = false);
    }
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143D2C),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Track waste reports from detection to resolution.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 24),

              if (_loading) ...[
                const LinearProgressIndicator(color: Color(0xFF16875B)),
                const SizedBox(height: 16),
                const Text('Loading your live reports from Firebase...'),
                const SizedBox(height: 18),
              ],
              if (_firestoreError != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Unable to load your Zone D report: $_firestoreError',
                    style: const TextStyle(color: Color(0xFF9F1D1D)),
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // ==================================================
              // SUMMARY
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      icon: Icons.description_outlined,
                      value: '$myActiveReports',
                      title: 'Active Reports',
                      color: const Color(0xFF16875B),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: SummaryCard(
                      icon: Icons.check_circle_outline,
                      value: '$myCompletedReports',
                      title: 'Completed',
                      color: const Color(0xFF16875B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================================
              // ZONE D
              // ==================================================
              if (zoneDExists) ...[
                Text(
                  isResolved
                      ? (_previewTwoHoursLater ? 'Completed Report' : 'Recently Resolved')
                      : 'Active Report',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF143D2C),
                  ),
                ),

                const SizedBox(height: 13),

                buildZoneDReport(),

                const SizedBox(height: 16),

                buildDemoControl(),

                const SizedBox(height: 30),
              ],

              // ==================================================
              // COMPLETED ZONE D HISTORY SAVED IN FIRESTORE
              // ==================================================
              if (_zoneD != null &&
                  _zoneD!.history.any((e) => e.reportedBy(_currentUid))) ...[
                const Text('Completed Zone D History',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF143D2C))),
                const SizedBox(height: 13),
                ..._zoneD!.history.where((e) => e.reportedBy(_currentUid))
                    .map((oldCase) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Township Park, Zone D — Resolved',
                                style: TextStyle(fontWeight: FontWeight.bold,
                                    color: Color(0xFF16875B))),
                            const SizedBox(height: 6),
                            Text('Case: ${oldCase.incidentId}',
                                style: const TextStyle(fontSize: 11,
                                    color: Colors.grey)),
                            const SizedBox(height: 5),
                            Text('EcoPoints earned: +${oldCase.pointsFor(_currentUid)}',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 5),
                            Text('Resolved: ${oldCase.resolvedAt?.toLocal().toString().substring(0, 16) ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 20),
              ],

              // ==================================================
              // OTHER REPORTS
              // ==================================================
              const Text(
                'Other Reports (Demo)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143D2C),
                ),
              ),

              const SizedBox(height: 13),

              // ==================================================
              // ZONE B
              // ==================================================
              const StaticReportCard(
                location: 'Community Playground, Zone B',
                wasteType: 'Mixed Public Waste',
                reportId: '#WH-002',
                status: 'Cleanup In Progress',
                statusColor: Colors.orange,
                severity: 'MEDIUM',
                severityColor: Colors.orange,
                actionBy: 'Green Zone B Community',
                extraInfo: '8 volunteers participating',
                icon: Icons.groups,
              ),

              const SizedBox(height: 14),

              // ==================================================
              // ZONE A
              // ==================================================
              const StaticReportCard(
                location: 'Walking Track, Zone A',
                wasteType: 'Plastic Bottles',
                reportId: '#WH-001',
                status: 'Resolved',
                statusColor: Color(0xFF16875B),
                severity: 'LOW',
                severityColor: Color(0xFFE1A72E),
                actionBy: 'Clean Zone A Community',
                extraInfo: 'Resolved on 15 Oct 2026 • 12 volunteers',
                icon: Icons.check_circle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // ZONE D REPORT CARD
  // ==========================================================

  Widget buildZoneDReport() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        border: isUrgent && !isResolved
            ? Border.all(color: const Color(0xFF8B0000).withOpacity(0.30))
            : isResolved
            ? Border.all(color: const Color(0xFF16875B).withOpacity(0.25))
            : null,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  isResolved ? Icons.check_circle : Icons.delete_outline,
                  color: priorityColor,
                  size: 28,
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Township Park, Zone D',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 4),

                    Text(
                      'Plastic & Food Packaging',
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),

                    SizedBox(height: 3),

                    Text(
                      '#WH-003',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Text(
                  priority,
                  style: TextStyle(
                    color: priorityColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ======================================================
          // REPORT PHOTO
          // ======================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: 190,
              child: Image.asset(
                'assests/images/rubbish_public.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFEAF4EE),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 50,
                            color: Color(0xFF16875B),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Rubbish image not found',
                            style: TextStyle(
                              color: Color(0xFF16875B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Divider(),

          const SizedBox(height: 8),

          // ======================================================
          // SEVERITY
          // ======================================================
          const ProgressDetailRow(
            icon: Icons.warning_amber,
            title: 'Severity',
            value: 'HIGH',
            valueColor: Colors.red,
          ),

          const Divider(height: 25),

          // ======================================================
          // PRIORITY
          // ======================================================
          ProgressDetailRow(
            icon: Icons.priority_high,
            title: 'Priority',
            value: priority,
            valueColor: priorityColor,
          ),

          const Divider(height: 25),

          // ======================================================
          // CONFIRMATIONS
          // ======================================================
          ProgressDetailRow(
            icon: Icons.people_outline,
            title: 'Resident Confirmations',
            value: '$residentConfirmations',
            valueColor: residentConfirmations >= 3
                ? const Color(0xFF8B0000)
                : const Color(0xFF16875B),
          ),

          const Divider(height: 25),

          // ======================================================
          // REPORT AGE
          // ======================================================
          ProgressDetailRow(
            icon: Icons.schedule,
            title: 'Report Age (Demo)',
            value: reportAge,
            valueColor: unresolvedDays >= 2 && !isResolved
                ? Colors.orange
                : Colors.black87,
          ),

          const Divider(height: 25),

          // ======================================================
          // HOTSPOT STATUS
          // ======================================================
          ProgressDetailRow(
            icon: Icons.location_on_outlined,
            title: 'Hotspot Status',
            value: hotspotStatus,
            valueColor: priorityColor,
          ),

          const Divider(height: 25),

          // ======================================================
          // ACTION STATUS
          // ======================================================
          ProgressDetailRow(
            icon: Icons.track_changes,
            title: 'Action Status',
            value: actionStatus,
            valueColor: priorityColor,
          ),

          if (_assignedTeam != 'Not assigned') ...[
            const Divider(height: 25),
            ProgressDetailRow(
              icon: Icons.cleaning_services_outlined,
              title: 'Assigned Team',
              value: _assignedTeam,
              valueColor: const Color(0xFF16875B),
            ),
          ],
          if (_adminNote.isNotEmpty) ...[
            const Divider(height: 25),
            ProgressDetailRow(
              icon: Icons.notes,
              title: 'Management Note',
              value: _adminNote,
            ),
          ],

          // ======================================================
          // MANAGEMENT ALERT
          // ======================================================
          if (managementAlertSent && !isResolved) ...[
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: unresolvedDays >= 3
                    ? const Color(0xFFFFEBEE)
                    : const Color(0xFFFFF7E6),

                borderRadius: BorderRadius.circular(16),

                border: Border.all(
                  color: unresolvedDays >= 3
                      ? const Color(0xFF8B0000).withOpacity(0.20)
                      : Colors.orange.withOpacity(0.25),
                ),
              ),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    unresolvedDays >= 3
                        ? Icons.warning_amber
                        : Icons.notifications_active,
                    color: unresolvedDays >= 3
                        ? const Color(0xFF8B0000)
                        : Colors.orange,
                    size: 28,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          unresolvedDays >= 3
                              ? 'Overdue Hotspot'
                              : 'Management Notified',
                          style: TextStyle(
                            color: unresolvedDays >= 3
                                ? const Color(0xFF8B0000)
                                : Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          unresolvedDays >= 3
                              ? 'This hotspot has remained unresolved for $unresolvedDays days. Its priority is now URGENT and township management has been notified for immediate action.'
                              : 'This hotspot has remained unresolved for 2 days. Township management has been automatically notified.',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ======================================================
          // RESOLVED BOX
          // ======================================================
          if (isResolved) ...[
            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: const Color(0xFFEAF7F1),
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF16875B), size: 28),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hotspot Resolved',
                          style: TextStyle(
                            color: Color(0xFF16875B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 4),

                        Text(
                          'This waste report is complete and remains in your history. The resolved marker disappears after 30 seconds, or immediately when you use the demo button.',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ======================================================
          // TIMELINE
          // ======================================================
          const Text(
            'Resolution Timeline',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          const TimelineStep(
            title: 'Report Submitted',
            subtitle: 'Waste hotspot detected and recorded.',
            completed: true,
          ),

          TimelineStep(
            title: 'Management Alert',
            subtitle: managementAlertSent
                ? 'Township management has been notified.'
                : 'Automatically triggered if unresolved for 2 days.',
            completed: managementAlertSent || isResolved,
          ),

          TimelineStep(
            title: 'Management Review',
            subtitle: actionStatus == 'In Progress'
                ? 'A cleaning team is working on this report.'
                : actionStatus == 'Under Review'
                    ? 'Township management is reviewing this report.'
                    : 'Waiting for management action.',
            completed: isResolved ||
                actionStatus == 'Under Review' ||
                actionStatus == 'In Progress',
          ),

          TimelineStep(
            title: 'Resolved',
            subtitle: isResolved
                ? 'Waste issue has been resolved.'
                : 'Waiting for cleanup and verification.',
            completed: isResolved,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DEMO CONTROL
  // ==========================================================

  Widget buildDemoControl() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, color: Color(0xFF16875B)),

              SizedBox(width: 8),

              Text(
                'Hackathon Demo: Fast-Forward',
                style: TextStyle(
                  color: Color(0xFF143D2C),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 7),

          Text(
            isResolved
                ? 'After resolution, the marker disappears automatically in 30 seconds. For the demo, the first reporting Resident can tap below to skip the wait. A NEW Zone D report can then be submitted, and completed history stays saved.'
                : 'Tap Simulate Next Day to advance the shared Firebase demo day. Admin will receive an in-app alert automatically. Day 2 triggers a MANAGEMENT ALERT and Day 3 becomes URGENT. Only Admin can resolve the report.',
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 15),

          // ======================================================
          // ACTIVE
          // ======================================================
          if (!isResolved)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_simulatingNextDay || unresolvedDays >= 7)
                        ? null
                        : simulateNextDay,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16875B),
                      foregroundColor: Colors.white,

                      padding: const EdgeInsets.symmetric(vertical: 13),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),

                    icon: const Icon(Icons.skip_next, size: 19),

                    label: Text(
                      _simulatingNextDay
                          ? 'Updating Firebase...'
                          : unresolvedDays >= 7
                              ? 'Day 7 Maximum'
                              : 'Simulate Next Day',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: null,

                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16875B),

                      padding: const EdgeInsets.symmetric(vertical: 13),

                      side: const BorderSide(color: Color(0xFF16875B)),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),

                    icon: const Icon(Icons.check_circle_outline, size: 19),

                    label: const Text(
                      'Mark Resolved',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            )
          // ======================================================
          // RESOLVED
          // ======================================================
          else
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: (_previewTwoHoursLater || _simulatingTwoHours)
                    ? null
                    : simulateTwoHoursLater,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16875B),
                  foregroundColor: Colors.white,

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),

                icon: const Icon(Icons.schedule),

                label: Text(
                  _previewTwoHoursLater
                      ? 'New Report Unlocked'
                      : _simulatingTwoHours
                          ? 'Updating Firebase...'
                          : 'Simulate 30 Seconds Later',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              isResolved
                  ? 'Status: Resolved (live Firebase)'
                  : 'Firestore: $unresolvedDays unresolved day(s)',
              style: TextStyle(
                color: isResolved
                    ? const Color(0xFF16875B)
                    : Colors.grey.shade700,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// SUMMARY CARD
// ==========================================================

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;
  final Color color;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.value,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),

            child: Icon(icon, color: color, size: 22),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF143D2C),
                  ),
                ),

                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================
// PROGRESS DETAIL ROW
// ==========================================================

class ProgressDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const ProgressDetailRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF16875B), size: 20),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,

            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// TIMELINE
// ==========================================================

class TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool completed;
  final bool isLast;

  const TimelineStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.completed,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = completed
        ? const Color(0xFF16875B)
        : Colors.grey.shade400;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 25,
              height: 25,

              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFEAF7F1)
                    : Colors.grey.shade100,

                shape: BoxShape.circle,

                border: Border.all(color: color, width: 2),
              ),

              child: Icon(
                completed ? Icons.check : Icons.circle,
                color: color,
                size: completed ? 15 : 7,
              ),
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color: completed
                    ? const Color(0xFF16875B).withOpacity(0.30)
                    : Colors.grey.shade300,
              ),
          ],
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,

                  style: TextStyle(
                    color: completed ? const Color(0xFF143D2C) : Colors.grey,

                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,

                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// STATIC REPORT CARD
// ==========================================================

class StaticReportCard extends StatelessWidget {
  final String location;
  final String wasteType;
  final String reportId;
  final String status;
  final Color statusColor;
  final String severity;
  final Color severityColor;
  final String actionBy;
  final String extraInfo;
  final IconData icon;

  const StaticReportCard({
    super.key,
    required this.location,
    required this.wasteType,
    required this.reportId,
    required this.status,
    required this.statusColor,
    required this.severity,
    required this.severityColor,
    required this.actionBy,
    required this.extraInfo,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),

                child: Icon(icon, color: statusColor, size: 25),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      wasteType,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      reportId,
                      style: const TextStyle(color: Colors.grey, fontSize: 9),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(15),
                ),

                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Divider(),

          const SizedBox(height: 7),

          ProgressDetailRow(
            icon: Icons.warning_amber,
            title: 'Severity',
            value: severity,
            valueColor: severityColor,
          ),

          const Divider(height: 24),

          ProgressDetailRow(
            icon: Icons.groups_outlined,
            title: 'Action By',
            value: actionBy,
            valueColor: const Color(0xFF16875B),
          ),

          const SizedBox(height: 13),

          Text(
            extraInfo,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
