import 'package:flutter/material.dart';

import '../data/report_store.dart';

class FullMapPage extends StatelessWidget {
  final bool hasNewReport;

  const FullMapPage({super.key, required this.hasNewReport});

  // ==========================================================
  // ZONE D DATA
  // ==========================================================

  int get zoneDReportCount {
    return ReportStore.zoneDReportCount;
  }

  bool get zoneDResolved {
    return ReportStore.zoneDResolved;
  }

  bool get zoneDVisible {
    return ReportStore.zoneDVisibleToResidents;
  }

  bool get zoneDIsUrgent {
    return ReportStore.zoneDIsUrgent;
  }

  // ==========================================================
  // ZONE D PRIORITY
  // ==========================================================

  String get zoneDPriority {
    if (zoneDResolved) {
      return 'RESOLVED';
    }

    if (zoneDIsUrgent) {
      return 'URGENT';
    }

    return 'HIGH';
  }

  // ==========================================================
  // ZONE D STATUS
  // ==========================================================

  String get zoneDStatus {
    if (zoneDResolved) {
      return 'Resolved';
    }

    return ReportStore.zoneDStatus;
  }

  // ==========================================================
  // ZONE D MARKER LABEL
  // ==========================================================

  String get zoneDMarkerLabel {
    if (zoneDResolved) {
      return 'RESOLVED';
    }

    if (zoneDReportCount <= 1) {
      return 'NEW';
    }

    return '$zoneDReportCount CONFIRMED';
  }

  // ==========================================================
  // ZONE D MARKER COLOR
  // ==========================================================

  Color get zoneDMarkerColor {
    if (zoneDResolved) {
      return const Color(0xFF16875B);
    }

    return Colors.red;
  }

  // ==========================================================
  // ZONE D LABEL COLOR
  // ==========================================================

  Color get zoneDLabelColor {
    if (zoneDResolved) {
      return const Color(0xFF16875B);
    }

    if (zoneDReportCount <= 1) {
      return const Color(0xFF16875B);
    }

    if (zoneDIsUrgent) {
      return const Color(0xFF8B0000);
    }

    return Colors.red;
  }

  // ==========================================================
  // ZONE D PRIORITY COLOR
  // ==========================================================

  Color get zoneDPriorityColor {
    if (zoneDResolved) {
      return const Color(0xFF16875B);
    }

    if (zoneDIsUrgent) {
      return const Color(0xFF8B0000);
    }

    return Colors.red;
  }

  // ==========================================================
  // MAIN BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F8F6),
        elevation: 0,
        centerTitle: true,
        title: const Column(
          children: [
            Text(
              'Waste Hotspot Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143D2C),
              ),
            ),
            Text(
              'Township Waste Intelligence',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final double mapWidth = constraints.maxWidth;
          final double mapHeight = constraints.maxHeight;

          return InteractiveViewer(
            minScale: 1.0,
            maxScale: 4.0,
            boundaryMargin: const EdgeInsets.all(120),

            child: SizedBox(
              width: mapWidth,
              height: mapHeight,

              child: Stack(
                children: [
                  // ==================================================
                  // MAP BACKGROUND
                  // ==================================================

                  Positioned.fill(
                    child: Container(color: const Color(0xFFE9F0EB)),
                  ),

                  // ==================================================
                  // GREEN / PARK AREAS
                  // ==================================================
                  Positioned(
                    top: mapHeight * 0.08,
                    left: mapWidth * 0.05,
                    child: Container(
                      width: mapWidth * 0.30,
                      height: mapHeight * 0.18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5E8D9),
                        borderRadius: BorderRadius.circular(45),
                      ),
                    ),
                  ),

                  Positioned(
                    top: mapHeight * 0.53,
                    right: mapWidth * 0.03,
                    child: Container(
                      width: mapWidth * 0.30,
                      height: mapHeight * 0.18,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5E8D9),
                        borderRadius: BorderRadius.circular(45),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: mapHeight * 0.05,
                    left: mapWidth * 0.08,
                    child: Container(
                      width: mapWidth * 0.28,
                      height: mapHeight * 0.15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8E7D5),
                        borderRadius: BorderRadius.circular(40),
                      ),
                    ),
                  ),

                  // ==================================================
                  // FAKE ROADS
                  // ==================================================
                  Positioned(
                    top: mapHeight * 0.17,
                    left: -40,
                    right: -40,
                    child: Transform.rotate(
                      angle: -0.10,
                      child: Container(height: 30, color: Colors.white),
                    ),
                  ),

                  Positioned(
                    top: mapHeight * 0.43,
                    left: -40,
                    right: -40,
                    child: Transform.rotate(
                      angle: 0.08,
                      child: Container(height: 34, color: Colors.white),
                    ),
                  ),

                  Positioned(
                    top: mapHeight * 0.68,
                    left: -40,
                    right: -40,
                    child: Transform.rotate(
                      angle: -0.05,
                      child: Container(height: 28, color: Colors.white),
                    ),
                  ),

                  Positioned(
                    top: -60,
                    bottom: -60,
                    left: mapWidth * 0.40,
                    child: Transform.rotate(
                      angle: 0.08,
                      child: Container(width: 28, color: Colors.white),
                    ),
                  ),

                  Positioned(
                    top: -60,
                    bottom: -60,
                    right: mapWidth * 0.20,
                    child: Transform.rotate(
                      angle: -0.07,
                      child: Container(width: 24, color: Colors.white),
                    ),
                  ),

                  // ==================================================
                  // ZONE LABELS
                  // ==================================================
                  Positioned(
                    top: mapHeight * 0.05,
                    left: mapWidth * 0.08,
                    child: const MapZoneLabel(text: 'ZONE A'),
                  ),

                  Positioned(
                    top: mapHeight * 0.30,
                    right: mapWidth * 0.08,
                    child: const MapZoneLabel(text: 'ZONE B'),
                  ),

                  Positioned(
                    bottom: mapHeight * 0.18,
                    left: mapWidth * 0.08,
                    child: const MapZoneLabel(text: 'ZONE C'),
                  ),

                  Positioned(
                    bottom: mapHeight * 0.08,
                    right: mapWidth * 0.08,
                    child: const MapZoneLabel(text: 'ZONE D'),
                  ),

                  // ==================================================
                  // ZONE A - WALKING TRACK
                  // ==================================================
                  Positioned(
                    top: mapHeight * 0.14,
                    left: mapWidth * 0.20,
                    child: PulseMapMarker(
                      color: const Color(0xFFE1A72E),
                      label: '2 REPORTS',
                      labelColor: const Color(0xFFE1A72E),
                      onTap: () {
                        showHotspotDetails(
                          context: context,
                          location: 'Walking Track, Zone A',
                          severity: 'LOW',
                          severityColor: const Color(0xFFE1A72E),
                          wasteType: 'Plastic Bottles',
                          confirmations: '2 residents',
                          priority: 'LOW',
                          priorityColor: const Color(0xFFE1A72E),
                          status: 'Resolved',
                          statusColor: const Color(0xFF16875B),
                          additionalInfo:
                              'This hotspot has already been cleaned.',
                        );
                      },
                    ),
                  ),

                  // ==================================================
                  // ZONE B - PLAYGROUND
                  // ==================================================
                  Positioned(
                    top: mapHeight * 0.36,
                    right: mapWidth * 0.16,
                    child: PulseMapMarker(
                      color: Colors.orange,
                      label: '4 REPORTS',
                      labelColor: Colors.orange,
                      onTap: () {
                        showHotspotDetails(
                          context: context,
                          location: 'Community Playground, Zone B',
                          severity: 'MEDIUM',
                          severityColor: Colors.orange,
                          wasteType: 'Mixed Public Waste',
                          confirmations: '4 residents',
                          priority: 'HIGH',
                          priorityColor: Colors.red,
                          status: 'Cleanup In Progress',
                          statusColor: Colors.orange,
                          additionalInfo: 'Community cleanup activity is currently in progress.',
                        );
                      },
                    ),
                  ),

                  // ==================================================
                  // ZONE C - RECREATIONAL AREA
                  // ==================================================
                  Positioned(
                    bottom: mapHeight * 0.27,
                    left: mapWidth * 0.20,
                    child: PulseMapMarker(
                      color: Colors.red,
                      label: '17 REPORTS',
                      labelColor: const Color(0xFF8B0000),
                      strongPulse: true,
                      onTap: () {
                        showHotspotDetails(
                          context: context,
                          location: 'Recreational Area, Zone C',
                          severity: 'HIGH',
                          severityColor: Colors.red,
                          wasteType: 'Mixed Public Waste',
                          confirmations: '17 residents',
                          priority: 'URGENT',
                          priorityColor: const Color(0xFF8B0000),
                          status: 'Repeated Hotspot',
                          statusColor: const Color(0xFF8B0000),
                          additionalInfo: 'Multiple resident confirmations indicate a repeated waste hotspot requiring urgent attention.',
                        );
                      },
                    ),
                  ),

                  // ==================================================
                  // ZONE D - DYNAMIC HOTSPOT
                  //
                  // ACTIVE:
                  // Red marker
                  //
                  // RESOLVED:
                  // Green marker for 2 hours
                  //
                  // AFTER 2 HOURS:
                  // Hidden from resident map
                  // ==================================================
                  if (zoneDVisible)
                    Positioned(
                      bottom: mapHeight * 0.15,
                      right: mapWidth * 0.16,
                      child: PulseMapMarker(
                        color: zoneDMarkerColor,
                        label: zoneDMarkerLabel,
                        labelColor: zoneDLabelColor,

                        // Stop strong pulse when resolved
                        strongPulse: !zoneDResolved,

                        onTap: () {
                          showZoneDDetails(context);
                        },
                      ),
                    ),

                  // ==================================================
                  // LEGEND
                  // ==================================================
                  Positioned(
                    top: 18,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Map Legend',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8),

                          LegendItem(color: Color(0xFFE1A72E), text: 'Low'),

                          SizedBox(height: 5),

                          LegendItem(color: Colors.orange, text: 'Medium'),

                          SizedBox(height: 5),

                          LegendItem(color: Colors.red, text: 'High'),

                          SizedBox(height: 5),

                          LegendItem(color: Color(0xFF8B0000), text: 'Urgent'),

                          SizedBox(height: 5),

                          LegendItem(
                            color: Color(0xFF16875B),
                            text: 'Resolved',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================
  // ZONE D DETAILS
  // ==========================================================

  void showZoneDDetails(BuildContext context) {
    showHotspotDetails(
      context: context,
      location: 'Township Park, Zone D',

      severity: 'HIGH',
      severityColor: Colors.red,

      wasteType: 'Plastic & Food Packaging',

      confirmations:
          '$zoneDReportCount ${zoneDReportCount == 1 ? 'resident' : 'residents'}',

      priority: zoneDPriority,
      priorityColor: zoneDPriorityColor,

      status: zoneDStatus,

      statusColor: zoneDResolved
          ? const Color(0xFF16875B)
          : zoneDIsUrgent
          ? const Color(0xFF8B0000)
          : Colors.red,

      additionalInfo: zoneDResolved
          ? 'This hotspot has been resolved. It will remain visible to residents for 2 hours before being removed from the active map.'
          : zoneDReportCount == 1
          ? 'This is a newly detected public waste hotspot.'
          : '$zoneDReportCount unique residents have confirmed this same waste hotspot. Their reports have been merged into one case.',
    );
  }

  // ==========================================================
  // HOTSPOT DETAILS BOTTOM SHEET
  // ==========================================================

  void showHotspotDetails({
    required BuildContext context,
    required String location,
    required String severity,
    required Color severityColor,
    required String wasteType,
    required String confirmations,
    required String priority,
    required Color priorityColor,
    required String status,
    required Color statusColor,
    required String additionalInfo,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,

      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),

          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==============================================
                // HANDLE
                // ==============================================

                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ==============================================
                // HEADER
                // ==============================================
                Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        status == 'Resolved'
                            ? Icons.check_circle
                            : Icons.location_on,
                        color: statusColor,
                        size: 29,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF143D2C),
                            ),
                          ),

                          const SizedBox(height: 5),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const Divider(),

                const SizedBox(height: 8),

                // ==============================================
                // SEVERITY
                // ==============================================
                MapDetailRow(
                  icon: Icons.warning_amber,
                  title: 'Severity',
                  value: severity,
                  valueColor: severityColor,
                ),

                const Divider(height: 27),

                // ==============================================
                // WASTE TYPE
                // ==============================================
                MapDetailRow(
                  icon: Icons.delete_outline,
                  title: 'Waste Type',
                  value: wasteType,
                ),

                const Divider(height: 27),

                // ==============================================
                // RESIDENT CONFIRMATIONS
                // ==============================================
                MapDetailRow(
                  icon: Icons.groups_outlined,
                  title: 'Resident Confirmations',
                  value: confirmations,
                  valueColor: const Color(0xFF16875B),
                ),

                const Divider(height: 27),

                // ==============================================
                // PRIORITY
                // ==============================================
                MapDetailRow(
                  icon: Icons.priority_high,
                  title: 'Hotspot Priority',
                  value: priority,
                  valueColor: priorityColor,
                ),

                const Divider(height: 27),

                // ==============================================
                // STATUS
                // ==============================================
                MapDetailRow(
                  icon: Icons.track_changes,
                  title: 'Hotspot Status',
                  value: status,
                  valueColor: statusColor,
                ),

                const SizedBox(height: 20),

                // ==============================================
                // INFORMATION BOX
                // ==============================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: status == 'Resolved'
                        ? const Color(0xFFEAF7F1)
                        : const Color(0xFFF5F8F6),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        status == 'Resolved'
                            ? Icons.check_circle_outline
                            : Icons.info_outline,
                        color: status == 'Resolved'
                            ? const Color(0xFF16875B)
                            : Colors.grey.shade600,
                        size: 21,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          additionalInfo,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==============================================
                // CLOSE
                // ==============================================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16875B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================================
// PULSING MAP MARKER
// ==========================================================

class PulseMapMarker extends StatefulWidget {
  final Color color;
  final String? label;
  final Color? labelColor;
  final bool strongPulse;
  final VoidCallback? onTap;

  const PulseMapMarker({
    super.key,
    required this.color,
    this.label,
    this.labelColor,
    this.strongPulse = false,
    this.onTap,
  });

  @override
  State<PulseMapMarker> createState() => _PulseMapMarkerState();
}

class _PulseMapMarkerState extends State<PulseMapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> pulseAnimation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.strongPulse ? 850 : 1500),
    );

    createPulseAnimation();

    // All markers animate.
    // Active/urgent = stronger pulse.
    // Resolved = gentle pulse.
    controller.repeat(reverse: true);
  }

  void createPulseAnimation() {
    pulseAnimation = Tween<double>(
      begin: widget.strongPulse ? 0.88 : 0.95,
      end: widget.strongPulse ? 1.28 : 1.08,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant PulseMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.strongPulse != widget.strongPulse) {
      controller.duration = Duration(
        milliseconds: widget.strongPulse ? 850 : 1500,
      );

      createPulseAnimation();

      controller
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget marker = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null)
          Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 5),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.17),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 23,
                height: 23,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (widget.onTap == null) {
      return marker;
    }

    return GestureDetector(onTap: widget.onTap, child: marker);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ==========================================================
// MAP DETAIL ROW
// ==========================================================

class MapDetailRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const MapDetailRow({
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
        const SizedBox(width: 2),

        Icon(icon, color: const Color(0xFF16875B), size: 21),

        const SizedBox(width: 11),

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
// LEGEND
// ==========================================================

class LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const LegendItem({super.key, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),

        const SizedBox(width: 6),

        Text(text, style: const TextStyle(fontSize: 8, color: Colors.black54)),
      ],
    );
  }
}
