import 'package:flutter/material.dart';
import '../data/report_store.dart';

class ProgressPage extends StatefulWidget {
  final bool hasNewReport;

  const ProgressPage({
    super.key,
    required this.hasNewReport,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  // ==========================================================
  // ZONE D DATA
  // ==========================================================

  bool get zoneDExists {
    return ReportStore.zoneDVisibleToResidents;
  }

  bool get isResolved {
    return ReportStore.zoneDResolved;
  }

  bool get isUrgent {
    return ReportStore.zoneDIsUrgent;
  }

  int get unresolvedDays {
    return ReportStore.zoneDUnresolvedDays;
  }

  int get residentConfirmations {
    return ReportStore.zoneDReportCount;
  }

  bool get managementAlertSent {
    return ReportStore.zoneDManagementAlert;
  }

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  bool get currentUserHasZoneDReport {
    return ReportStore.currentUserAlreadyReportedZoneD;
  }

  // ==========================================================
  // ACTIVE / COMPLETED REPORT COUNTS
  // ==========================================================

  int get myActiveReports {
    // Current prototype starts with 2 active reports.
    const int existingActiveReports = 1;

    int active =
        existingActiveReports +
        ReportStore.validReports;

    // Once Zone D is resolved,
    // remove it from Active Reports.
    if (ReportStore.zoneDResolved &&
        currentUserHasZoneDReport) {
      active--;
    }

    if (active < 0) {
      return 0;
    }

    return active;
  }

  int get myCompletedReports {
    // Current prototype already contains 1 completed report.
    const int existingCompletedReports = 1;

    if (ReportStore.zoneDResolved &&
        currentUserHasZoneDReport) {
      return existingCompletedReports + 1;
    }

    return existingCompletedReports;
  }

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
  // ACTION STATUS
  // ==========================================================

  String get actionStatus {
    if (isResolved) {
      return 'Resolved';
    }

    if (unresolvedDays >= 3) {
      return 'Overdue - Action Required';
    }

    if (unresolvedDays >= 2) {
      return 'Management Alert Sent';
    }

    if (unresolvedDays >= 1) {
      return 'Pending Action';
    }

    return 'Searching for Action';
  }

  // ==========================================================
  // REPORT AGE
  // ==========================================================

  String get reportAge {
    if (unresolvedDays == 0) {
      return 'Today • Day 0';
    }

    if (unresolvedDays == 1) {
      return '1 Day';
    }

    return '$unresolvedDays Days';
  }

  // ==========================================================
  // SIMULATE NEXT DAY
  // ==========================================================

  void simulateNextDay() {
    if (!zoneDExists || isResolved) {
      return;
    }

    ReportStore.simulateNextDay();

    setState(() {});

    // ========================================================
    // DAY 2
    // ========================================================

    if (ReportStore.zoneDUnresolvedDays == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Day 2 reached. Township management has been automatically alerted.',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ========================================================
    // DAY 3+
    // ========================================================

    else if (ReportStore.zoneDUnresolvedDays >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF8B0000),
          content: Row(
            children: [
              Icon(
                Icons.warning_amber,
                color: Colors.white,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hotspot is overdue. Priority has been escalated to URGENT.',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ==========================================================
  // RESOLVE HOTSPOT
  // ==========================================================

  void resolveHotspot() {
    if (!zoneDExists || isResolved) {
      return;
    }

    ReportStore.resolveZoneD();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16875B),
        content: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Zone D hotspot has been resolved.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // SIMULATE 2 HOURS LATER
  // ==========================================================

  void simulateTwoHoursLater() {
    if (!ReportStore.zoneDResolved) {
      return;
    }

    ReportStore.simulateTwoHoursLater();

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF16875B),
        content: Row(
          children: [
            Icon(
              Icons.schedule,
              color: Colors.white,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '2 hours have passed. The resolved hotspot has been removed from the resident active view.',
              ),
            ),
          ],
        ),
      ),
    );
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
          padding: const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            110,
          ),

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
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 24),

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
                      ? 'Recently Resolved'
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
              // OTHER REPORTS
              // ==================================================

              const Text(
                'Other Reports',
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
                extraInfo:
                    'Resolved on 15 Oct 2026 • 12 volunteers',
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
            ? Border.all(
                color: const Color(0xFF8B0000)
                    .withOpacity(0.30),
              )
            : isResolved
                ? Border.all(
                    color: const Color(0xFF16875B)
                        .withOpacity(0.25),
                  )
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
                  isResolved
                      ? Icons.check_circle
                      : Icons.delete_outline,
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
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      '#WH-003',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
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
            title: 'Report Age',
            value: reportAge,
            valueColor:
                unresolvedDays >= 2 && !isResolved
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
            value: ReportStore.zoneDStatus,
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
                      ? const Color(0xFF8B0000)
                          .withOpacity(0.20)
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                  Icon(
                    Icons.check_circle,
                    color: Color(0xFF16875B),
                    size: 28,
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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
                          'This waste issue has been resolved. The green marker will remain visible to residents for 2 hours before disappearing from the active map.',
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          const TimelineStep(
            title: 'Report Submitted',
            subtitle:
                'Waste hotspot detected and recorded.',
            completed: true,
          ),

          TimelineStep(
            title: 'Management Alert',
            subtitle: managementAlertSent
                ? 'Township management has been notified.'
                : 'Automatically triggered if unresolved for 2 days.',
            completed:
                managementAlertSent || isResolved,
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
              Icon(
                Icons.science_outlined,
                color: Color(0xFF16875B),
              ),

              SizedBox(width: 8),

              Text(
                'Hackathon Demo Control',
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
                ? 'The hotspot is resolved. Use the button below to simulate the 2-hour period before it disappears from the resident active view.'
                : 'Use these controls to simulate time and resolution. In the real system, time would be calculated automatically.',
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
                    onPressed: simulateNextDay,

                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF16875B),
                      foregroundColor: Colors.white,

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 13,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                    ),

                    icon: const Icon(
                      Icons.skip_next,
                      size: 19,
                    ),

                    label: const Text(
                      'Simulate Next Day',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: resolveHotspot,

                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF16875B),

                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 13,
                      ),

                      side: const BorderSide(
                        color: Color(0xFF16875B),
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                    ),

                    icon: const Icon(
                      Icons.check_circle_outline,
                      size: 19,
                    ),

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
                onPressed: simulateTwoHoursLater,

                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF16875B),
                  foregroundColor: Colors.white,

                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                ),

                icon: const Icon(
                  Icons.schedule,
                ),

                label: const Text(
                  'Simulate 2 Hours Later',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 10),

          Center(
            child: Text(
              isResolved
                  ? 'Status: Resolved ✅'
                  : 'Current simulation: Day $unresolvedDays',
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

            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
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
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
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
        Icon(
          icon,
          color: const Color(0xFF16875B),
          size: 20,
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
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

                border: Border.all(
                  color: color,
                  width: 2,
                ),
              ),

              child: Icon(
                completed
                    ? Icons.check
                    : Icons.circle,
                color: color,
                size: completed ? 15 : 7,
              ),
            ),

            if (!isLast)
              Container(
                width: 2,
                height: 42,
                color: completed
                    ? const Color(0xFF16875B)
                        .withOpacity(0.30)
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
                    color: completed
                        ? const Color(0xFF143D2C)
                        : Colors.grey,

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

                child: Icon(
                  icon,
                  color: statusColor,
                  size: 25,
                ),
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
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      reportId,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),

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
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}