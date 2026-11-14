import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/report_store.dart';
import '../data/zone_d_demo_preview.dart';
import '../data/zone_d_cloud_service.dart';
import 'full_map_page.dart';

/// Resident Home shows live Zone D data from Firebase.
/// Other township pins and overview figures remain demo examples.
class HomePage extends StatefulWidget {
  final bool hasNewReport;

  const HomePage({super.key, required this.hasNewReport});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  StreamSubscription<ZoneDCloudReport>? _zoneDSubscription;
  Timer? _resolvedMarkerExpiry;
  ZoneDCloudReport? _zoneD;
  bool _loadingZoneD = true;
  String? _firestoreError;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  // The service reads the current Zone D incident and its archived history.
  // A resident does not need to have reported it to see a public hotspot.
  bool get zoneDExists =>
      (_zoneD?.visibleOnResidentMap ?? false) &&
      !ZoneDDemoPreview.isMarkerHidden(_zoneD);
  int get zoneDReportCount => _zoneD?.confirmations ?? 0;
  bool get zoneDResolved => _zoneD?.resolved ?? false;
  bool get zoneDIsUrgent => !zoneDResolved &&
      (zoneDReportCount >= 3 || (_zoneD?.unresolvedDays ?? 0) >= 3);

  String get zoneDMarkerLabel => zoneDReportCount <= 1
      ? 'NEW'
      : '$zoneDReportCount REPORTS';

  // Calculate the current user's points directly from Firebase data.
  // This preserves points from older incidents after a new cycle begins.
  int get ecoPoints => _zoneD?.totalPointsFor(_currentUid) ?? 0;

  String get userLevel {
    if (ecoPoints >= 300) return 'Township Hero';
    if (ecoPoints >= 150) return 'Eco Champion';
    if (ecoPoints >= 50) return 'Green Helper';
    return 'Green Starter';
  }

  int get nextLevelTarget {
    if (ecoPoints < 50) return 50;
    if (ecoPoints < 150) return 150;
    return 300;
  }

  double get levelProgress {
    if (ecoPoints >= 300) return 1.0;
    if (ecoPoints < 50) return ecoPoints / 50;
    if (ecoPoints < 150) return (ecoPoints - 50) / 100;
    return (ecoPoints - 150) / 150;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ZoneDDemoPreview.hiddenResolvedIncidentId.addListener(_onDemoPreviewChanged);

    if (_currentUid == null) {
      _loadingZoneD = false;
      _firestoreError = 'Sign in to view live Zone D reports.';
      return;
    }

    _zoneDSubscription = ZoneDCloudService.watchZoneD().listen(
      (report) {
        if (!mounted) return;

        // A compatibility bridge for existing Full Map/Profile widgets
        // that still access ReportStore's local getters.
        final uid = _currentUid;
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

        setState(() {
          _zoneD = report;
          _loadingZoneD = false;
          _firestoreError = null;
        });
        _scheduleMarkerExpiry(report);
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loadingZoneD = false;
          _firestoreError = error.toString();
        });
      },
    );
  }

  // Firestore does not emit a change merely because 2 hours elapsed.
  // Schedule a local repaint when a resolved marker should disappear.
  void _scheduleMarkerExpiry(ZoneDCloudReport report) {
    _resolvedMarkerExpiry?.cancel();
    _resolvedMarkerExpiry = null;
    if (!report.resolved || report.resolvedAt == null) return;

    final expiresAt = report.resolvedAt!.add(const Duration(hours: 2));
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) return;

    _resolvedMarkerExpiry = Timer(
      remaining + const Duration(milliseconds: 50),
      () {
        if (mounted) setState(() {});
      },
    );
  }

  // Re-evaluate the deadline if the app was suspended in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _zoneD != null) {
      setState(() {});
    }
  }

  void _onDemoPreviewChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ZoneDDemoPreview.hiddenResolvedIncidentId.removeListener(_onDemoPreviewChanged);
    WidgetsBinding.instance.removeObserver(this);
    _resolvedMarkerExpiry?.cancel();
    _zoneDSubscription?.cancel();
    super.dispose();
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

              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WasteHotspot AI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF143D2C),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Township Waste Intelligence',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF16875B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // WELCOME BANNER
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFF16875B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cleaner Township,\nSmarter Future.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              height: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            'Report waste and help turn everyday observations into useful township intelligence.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 15),

                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // ECOPOINTS CARD
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
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
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF7F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.eco,
                            color: Color(0xFF16875B),
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 13),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My EcoPoints',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                '$ecoPoints pts',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF143D2C),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7F1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userLevel,
                            style: const TextStyle(
                              color: Color(0xFF16875B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: levelProgress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE9EEEB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF16875B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Level: ${userLevel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        Text(
                          ecoPoints >= 300
                              ? 'Maximum level reached'
                              : '$ecoPoints / $nextLevelTarget pts',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ==================================================
              // MAP TITLE
              // ==================================================
              const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waste Hotspot Map',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF143D2C),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Live township waste overview',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  Icon(Icons.map_outlined, color: Color(0xFF16875B)),
                ],
              ),

              const SizedBox(height: 12),

              if (_loadingZoneD)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Loading live Zone D status...',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),

              if (_firestoreError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.deepOrange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Live Zone D unavailable: $_firestoreError',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),

              // ==================================================
              // MAP
              // ==================================================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullMapPage(hasNewReport: widget.hasNewReport),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 340,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0EC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFDDE7E1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // ==========================================
                        // MAP BACKGROUND
                        // ==========================================

                        Container(color: const Color(0xFFE9F0EB)),

                        // ==========================================
                        // FAKE ROADS
                        // ==========================================
                        Positioned(
                          top: 60,
                          left: -20,
                          right: -20,
                          child: Transform.rotate(
                            angle: -0.10,
                            child: Container(height: 25, color: Colors.white),
                          ),
                        ),

                        Positioned(
                          top: 185,
                          left: -20,
                          right: -20,
                          child: Transform.rotate(
                            angle: 0.08,
                            child: Container(height: 28, color: Colors.white),
                          ),
                        ),

                        Positioned(
                          top: -30,
                          bottom: -30,
                          left: 150,
                          child: Transform.rotate(
                            angle: 0.08,
                            child: Container(width: 24, color: Colors.white),
                          ),
                        ),

                        Positioned(
                          top: -30,
                          bottom: -30,
                          right: 65,
                          child: Transform.rotate(
                            angle: -0.08,
                            child: Container(width: 19, color: Colors.white),
                          ),
                        ),

                        // ==========================================
                        // PARK AREAS
                        // ==========================================
                        Positioned(
                          top: 92,
                          left: 25,
                          child: Container(
                            width: 85,
                            height: 62,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7E8DB),
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 32,
                          right: 28,
                          child: Container(
                            width: 95,
                            height: 70,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7E8DB),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),

                        // ==========================================
                        // ZONE LABELS
                        // ==========================================
                        const Positioned(
                          top: 18,
                          left: 25,
                          child: MapZoneLabel(text: 'ZONE A'),
                        ),

                        const Positioned(
                          top: 110,
                          right: 22,
                          child: MapZoneLabel(text: 'ZONE B'),
                        ),

                        const Positioned(
                          bottom: 30,
                          left: 28,
                          child: MapZoneLabel(text: 'ZONE C'),
                        ),

                        const Positioned(
                          bottom: 25,
                          right: 38,
                          child: MapZoneLabel(text: 'ZONE D'),
                        ),

                        // ==========================================
                        // EXISTING HOTSPOTS
                        // ==========================================
                        const Positioned(
                          top: 73,
                          left: 88,
                          child: HotspotMarker(
                            color: Color(0xFFE1A72E),
                            size: 26,
                          ),
                        ),

                        const Positioned(
                          top: 145,
                          right: 74,
                          child: HotspotMarker(color: Colors.orange, size: 30),
                        ),

                        const Positioned(
                          bottom: 72,
                          left: 90,
                          child: HotspotMarker(
                            color: Colors.red,
                            size: 35,
                            label: '17 REPORTS',
                          ),
                        ),

                        // ==========================================
                        // ZONE D
                        //
                        // Firestore listener drives the marker for all
                        // signed-in residents, not the local report flag.
                        // ==========================================
                        if (zoneDExists)
                          Positioned(
                            bottom: 78,
                            right: 78,
                            child: HotspotMarker(
                              key: ValueKey('zone_d_${_zoneD?.incidentId}_${zoneDResolved ? 'resolved' : 'active'}'),
                              color: zoneDResolved
                                  ? const Color(0xFF16875B)
                                  : Colors.red,

                              size: zoneDResolved
                                  ? 35
                                  : zoneDIsUrgent
                                  ? 39
                                  : 35,

                              label: zoneDResolved
                                  ? 'RESOLVED'
                                  : zoneDMarkerLabel,

                              labelColor: zoneDResolved
                                  ? const Color(0xFF16875B)
                                  : zoneDReportCount == 1
                                  ? const Color(0xFF16875B)
                                  : Colors.red,

                              strongPulse: !zoneDResolved,
                            ),
                          ),
                        // ==========================================
                        // TAP TO EXPAND
                        // ==========================================
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.open_in_full,
                                  size: 13,
                                  color: Color(0xFF16875B),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Tap to expand',
                                  style: TextStyle(
                                    color: Color(0xFF16875B),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ==================================================
              // NEW REPORT MESSAGE
              //
              // Personal success banner is session-based.
              // Live Zone D map data comes from Firestore.
              // ==================================================
              if (widget.hasNewReport &&
                  zoneDExists &&
                  !zoneDResolved &&
                  (_zoneD?.reportedBy(_currentUid) ?? false)) ...[
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Color(0xFF16875B),
                        child: Icon(Icons.check, color: Colors.white, size: 19),
                      ),

                      SizedBox(width: 11),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'New report added',
                              style: TextStyle(
                                color: Color(0xFF16875B),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),

                            SizedBox(height: 2),

                            Text(
                              'Township Park, Zone D • High Severity',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 27),

              // ==================================================
              // TOWNSHIP OVERVIEW
              // ==================================================
              const Text(
                'Township Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143D2C),
                ),
              ),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: OverviewCard(
                      icon: Icons.location_on,
                      title: 'Hotspots',
                      value: zoneDExists ? '8' : '7',
                      subtitle: 'Detected areas',
                      iconColor: Colors.red,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OverviewCard(
                      icon: Icons.warning_amber,
                      title: 'High Severity',
                      value: zoneDExists && !zoneDResolved ? '4' : '3',
                      subtitle: 'Need attention',
                      iconColor: Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OverviewCard(
                      icon: Icons.description_outlined,
                      title: 'Reports',
                      value: '${32 + (zoneDExists ? 1 : 0)}',
                      subtitle: 'Unique reports',
                      iconColor: const Color(0xFF16875B),
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: OverviewCard(
                      icon: Icons.eco_outlined,
                      title: 'Cleanliness',
                      value: '82%',
                      subtitle: 'Township score',
                      iconColor: Color(0xFF16875B),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 27),

              // ==================================================
              // CURRENT HOTSPOT
              // ==================================================
              const Text(
                'Current Hotspot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143D2C),
                ),
              ),

              const SizedBox(height: 13),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFEBEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 14),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zone C Recreational Area',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Row(
                            children: [
                              Icon(
                                Icons.local_fire_department,
                                color: Colors.red,
                                size: 15,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Very Hotspot',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 7),

                          Text(
                            '17 reports • Repeated waste hotspot',
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),

              // ==================================================
              // OPTIONAL ZONE D STATUS CARD
              // ==================================================
              if (zoneDExists) ...[
                const SizedBox(height: 13),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: zoneDIsUrgent
                              ? const Color(0xFFFFEBEE)
                              : const Color(0xFFEAF7F1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          zoneDResolved
                              ? Icons.check_circle_outline
                              : Icons.delete_outline,
                          color: zoneDIsUrgent
                              ? Colors.red
                              : const Color(0xFF16875B),
                          size: 28,
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Township Park, Zone D',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              zoneDResolved
                                  ? 'RESOLVED • Cleanup completed'
                                  : zoneDIsUrgent
                                  ? 'URGENT • Repeated Hotspot'
                                  : zoneDReportCount >= 2
                                  ? 'HIGH • Existing Hotspot'
                                  : 'HIGH • New Hotspot',
                              style: TextStyle(
                                color: zoneDResolved
                                    ? const Color(0xFF16875B)
                                    : zoneDIsUrgent
                                    ? Colors.red
                                    : Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 7),

                            Text(
                              '$zoneDReportCount ${zoneDReportCount == 1 ? 'resident confirmation' : 'resident confirmations'} • Plastic & Food Packaging',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// HOTSPOT MARKER
// ==========================================================

class HotspotMarker extends StatefulWidget {
  final Color color;
  final double size;
  final String? label;
  final bool strongPulse;
  final Color? labelColor;

  const HotspotMarker({
    super.key,
    required this.color,
    this.size = 30,
    this.label,
    this.strongPulse = false,
    this.labelColor,
  });

  @override
  State<HotspotMarker> createState() => _HotspotMarkerState();
}

class _HotspotMarkerState extends State<HotspotMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.strongPulse ? 900 : 1400),
    )..repeat(reverse: true);

    pulseAnimation = Tween<double>(
      begin: 0.85,
      end: widget.strongPulse ? 1.25 : 1.12,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4),
              ],
            ),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: widget.labelColor ?? widget.color,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        ScaleTransition(
          scale: pulseAnimation,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: widget.size * 0.55,
                height: widget.size * 0.55,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==========================================================
// MAP ZONE LABEL
// ==========================================================

class MapZoneLabel extends StatelessWidget {
  final String text;

  const MapZoneLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    );
  }
}

// ==========================================================
// OVERVIEW CARD
// ==========================================================

class OverviewCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color iconColor;

  const OverviewCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),

              const Spacer(),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF143D2C),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 3),

          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 9),
          ),
        ],
      ),
    );
  }
}
