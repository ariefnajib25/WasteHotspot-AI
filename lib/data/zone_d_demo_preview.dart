import 'package:flutter/foundation.dart';

import 'zone_d_cloud_service.dart';

/// A SAFE hackathon-only presentation override.
/// It hides a resolved incident from maps in this running Resident app.
/// It does not change Firestore, the actual resolvedAt timestamp, or
/// the 30-second server-side restriction on starting a new case.
class ZoneDDemoPreview {
  ZoneDDemoPreview._();

  // Tracks a specific case, so starting another incident will not hide it.
  static final ValueNotifier<String?> hiddenResolvedIncidentId =
      ValueNotifier<String?>(null);

  // Legacy API name retained for compatibility. Simulates 30 seconds.
  static void simulateTwoHoursLater(ZoneDCloudReport report) {
    if (!report.resolved || report.incidentId.isEmpty) return;
    hiddenResolvedIncidentId.value = report.incidentId;
  }

  static void restoreMarker() => hiddenResolvedIncidentId.value = null;

  static bool isMarkerHidden(ZoneDCloudReport? report) =>
      report != null &&
      report.resolved &&
      hiddenResolvedIncidentId.value == report.incidentId;
}
