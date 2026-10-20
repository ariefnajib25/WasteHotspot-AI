import 'package:flutter/material.dart';

import '../data/report_store.dart';
import 'full_map_page.dart';

class HomePage extends StatelessWidget {
  final bool hasNewReport;

  const HomePage({super.key, required this.hasNewReport});

  // ==========================================================
  // SHARED TOWNSHIP DATA
  // ==========================================================

  bool get zoneDExists {
    return ReportStore.zoneDVisibleToResidents;
  }

  int get zoneDReportCount {
    return ReportStore.zoneDReportCount;
  }

  String get zoneDMarkerLabel {
    if (zoneDReportCount <= 1) {
      return 'NEW';
    }

    return '$zoneDReportCount REPORTS';
  }

  bool get zoneDIsUrgent {
    return zoneDReportCount >= 3;
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
                                '${ReportStore.ecoPoints} pts',
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
                            ReportStore.userLevel,
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
                        value: ReportStore.levelProgress,
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
                          'Level: ${ReportStore.userLevel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),

                        Text(
                          ReportStore.ecoPoints >= 300
                              ? 'Maximum level reached'
                              : '${ReportStore.ecoPoints} / ${ReportStore.nextLevelTarget} pts',
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

              // ==================================================
              // MAP
              // ==================================================
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullMapPage(hasNewReport: hasNewReport),
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
                        // IMPORTANT:
                        // This uses ReportStore, NOT hasNewReport.
                        // Therefore User B can still see User A's
                        // hotspot.
                        // ==========================================
                        if (zoneDExists)
                          Positioned(
                            bottom: 78,
                            right: 78,
                            child: HotspotMarker(
                              color: ReportStore.zoneDResolved
                                  ? const Color(0xFF16875B)
                                  : Colors.red,

                              size: ReportStore.zoneDResolved
                                  ? 35
                                  : zoneDIsUrgent
                                  ? 39
                                  : 35,

                              label: ReportStore.zoneDResolved
                                  ? 'RESOLVED'
                                  : zoneDMarkerLabel,

                              labelColor: ReportStore.zoneDResolved
                                  ? const Color(0xFF16875B)
                                  : zoneDReportCount == 1
                                  ? const Color(0xFF16875B)
                                  : Colors.red,

                              strongPulse: !ReportStore.zoneDResolved,
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
              // This remains session-based.
              // User B will not see "New report added" just because
              // User A submitted it.
              // ==================================================
              if (hasNewReport) ...[
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
                      value: zoneDExists ? '4' : '3',
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
                          Icons.delete_outline,
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
                              zoneDIsUrgent
                                  ? 'URGENT • Repeated Hotspot'
                                  : zoneDReportCount >= 2
                                  ? 'HIGH • Existing Hotspot'
                                  : 'HIGH • New Hotspot',
                              style: TextStyle(
                                color: zoneDIsUrgent
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
