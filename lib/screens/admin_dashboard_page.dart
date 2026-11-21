import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// This is the same document used by lib/data/zone_d_cloud_service.dart.
DocumentReference<Map<String, dynamic>> get _zoneDRef =>
    FirebaseFirestore.instance.collection('hotspots').doc('zone_d');

/// Historical Zone D incidents are stored in the `history` array of
/// hotspots/zone_d whenever a new incident replaces a resolved one.
/// These are read-only. The current incident remains at the top level.
class _AdminArchivedIncident {
  final String incidentId;
  final int confirmations;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const _AdminArchivedIncident({
    required this.incidentId,
    required this.confirmations,
    this.createdAt,
    this.resolvedAt,
  });

  factory _AdminArchivedIncident.fromMap(Map<String, dynamic> data) {
    final reporters = data['reporterUids'];
    final created = data['createdAt'];
    final resolved = data['resolvedAt'];
    return _AdminArchivedIncident(
      incidentId: data['incidentId'] as String? ?? '',
      confirmations: reporters is List ? reporters.length : 0,
      createdAt: created is Timestamp ? created.toDate() : null,
      resolvedAt: resolved is Timestamp ? resolved.toDate() : null,
    );
  }
}

/// Data read from the shared Firestore hotspot document.
class _AdminZoneD {
  final bool exists;
  final String incidentId;
  final int confirmations;
  final int unresolvedDays;
  final bool resolved;
  final DateTime? resolvedAt;
  final bool demoUnlocked;
  final String status;
  final String assignedTeam;
  final String adminNote;
  final List<_AdminArchivedIncident> history;

  const _AdminZoneD({
    this.exists = false,
    this.incidentId = '',
    this.confirmations = 0,
    this.unresolvedDays = 0,
    this.resolved = false,
    this.resolvedAt,
    this.demoUnlocked = false,
    this.status = 'Pending Review',
    this.assignedTeam = 'Not assigned',
    this.adminNote = '',
    this.history = const <_AdminArchivedIncident>[],
  });

  factory _AdminZoneD.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) return const _AdminZoneD();

    final reporters = data['reporterUids'];
    final countFromList = reporters is List ? reporters.length : null;
    final countFromField = (data['confirmations'] as num?)?.toInt() ?? 0;
    final rawHistory = data['history'];
    final archive = <_AdminArchivedIncident>[];
    if (rawHistory is List) {
      for (final entry in rawHistory) {
        if (entry is Map) {
          archive.add(_AdminArchivedIncident.fromMap(
            Map<String, dynamic>.from(entry),
          ));
        }
      }
    }

    return _AdminZoneD(
      exists: snapshot.exists,
      incidentId: data['incidentId'] as String? ?? '',
      confirmations: countFromList ?? countFromField,
      unresolvedDays: (data['unresolvedDays'] as num?)?.toInt() ?? 0,
      resolved: data['resolved'] == true,
      resolvedAt: data['resolvedAt'] is Timestamp
          ? (data['resolvedAt'] as Timestamp).toDate() : null,
      demoUnlocked: data['demoUnlocked'] == true,
      status: data['status'] as String? ?? 'Pending Review',
      assignedTeam: data['assignedTeam'] as String? ?? 'Not assigned',
      adminNote: data['adminNote'] as String? ?? '',
      history: archive,
    );
  }

  bool get urgent => exists && !resolved &&
      (confirmations >= 3 || unresolvedDays >= 3);

  bool get managementAlert =>
      exists && !resolved && unresolvedDays >= 2;
}

// An alert is created from Firestore report changes. The bell keeps recent
// alerts in memory for the current application session (not across devices).
class _AdminNotification {
  final String id;
  final String title;
  final String message;
  final String kind;
  final DateTime receivedAt;
  bool isRead;

  _AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.kind,
    required this.receivedAt,
    this.isRead = false,
  });
}

/// The existing Admin mobile interface, now connected to live Firestore data.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const _green = Color(0xFF16875B);
  static const _dark = Color(0xFF123C2D);
  String _filter = 'All';
  int _selectedTab = 0; // Home, Reports, Profile
  String _selectedZone = 'D'; // Only Zone D currently uses live Firestore
  bool _savingProfile = false;
  bool _signingOutAdmin = false;

  // Keep notifications while navigating between Admin screens in the same
  // running application. Separating by Firebase UID avoids mixing accounts.
  static final Map<String, List<_AdminNotification>> _sessionHistory = {};
  final ValueNotifier<int> _notificationVersion = ValueNotifier<int>(0);
  OverlayEntry? _activeTopAlert;
  Timer? _topAlertTimer;
  Timer? _mapMarkerExpiryTimer;

  String get _adminUid => FirebaseAuth.instance.currentUser?.uid ?? 'guest';
  List<_AdminNotification> get _notifications =>
      _sessionHistory.putIfAbsent(_adminUid, () => <_AdminNotification>[]);

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  _AdminZoneD _report = const _AdminZoneD();
  bool _loading = true;
  String? _loadError;
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _reportSubscription;

  bool get _exists => _report.exists && _report.confirmations > 0;
  bool get _resolved => _report.resolved;
  // Matches the Resident map: resolved marker is visible for 30 seconds,
  // unless the Resident runs the demo "Simulate 30 Seconds Later" shortcut.
  bool get _showZoneDMapMarker {
    if (!_exists) return false;
    if (!_resolved) return true;
    if (_report.demoUnlocked || _report.resolvedAt == null) return false;
    return DateTime.now().isBefore(
      _report.resolvedAt!.add(const Duration(seconds: 30)),
    );
  }

  void _scheduleMapMarkerExpiry(_AdminZoneD report) {
    _mapMarkerExpiryTimer?.cancel();
    _mapMarkerExpiryTimer = null;
    if (!report.resolved || report.demoUnlocked || report.resolvedAt == null) {
      return;
    }
    final deadline = report.resolvedAt!.add(const Duration(seconds: 30));
    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _mapMarkerExpiryTimer = Timer(
      remaining + const Duration(milliseconds: 50),
      () { if (mounted) setState(() {}); },
    );
  }

  bool get _urgent => _report.urgent;
  // Every ACTIVE report has an in-app alert. The message escalates
  // automatically as confirmations or unresolved demo days increase.
  bool get _needsAttention => _exists && !_resolved;

  String get _alertTitle {
    if (_urgent) return 'URGENT WASTE ALERT';
    if (_report.managementAlert) return 'MANAGEMENT ALERT';
    if (_report.unresolvedDays == 1) return 'DAY 1 - MONITORING ALERT';
    if (_report.confirmations >= 2) return 'NEW RESIDENT CONFIRMATION';
    return 'NEW WASTE REPORT';
  }

  String get _alertMessage {
    if (_report.confirmations >= 3 && _report.unresolvedDays >= 3) {
      return 'Zone D has 3+ confirmations and is overdue. Prioritise cleanup immediately.';
    }
    if (_report.confirmations >= 3) {
      return '${_report.confirmations} different residents confirmed Zone D. Priority is now URGENT.';
    }
    if (_report.unresolvedDays >= 3) {
      return 'Zone D is overdue by ${_report.unresolvedDays} demo days. Priority is now URGENT.';
    }
    if (_report.unresolvedDays >= 2) {
      return 'Zone D has remained unresolved for ${_report.unresolvedDays} demo days. Township management needs to take action.';
    }
    if (_report.unresolvedDays == 1) {
      return 'Resident simulated Demo Day 1. Zone D is still awaiting cleanup.';
    }
    if (_report.confirmations >= 2) {
      return '${_report.confirmations} different residents have confirmed the same Zone D hotspot. Their reports are merged.';
    }
    return 'A resident submitted a new public waste report at Township Park, Zone D.';
  }

  // The alert pops down from the TOP of the screen, instead of using
  // ScaffoldMessenger's bottom SnackBar. This is an in-app alert only;
  // the existing Firebase listener and notification bell are unchanged.
  void _dismissTopAlert() {
    _topAlertTimer?.cancel();
    _topAlertTimer = null;
    final entry = _activeTopAlert;
    _activeTopAlert = null;
    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }

  void _showRealtimeNotification(String message, String kind) {
    final color = kind == 'urgent' || kind == 'profile-error'
        ? const Color(0xFFB3261E)
        : kind == 'management'
            ? const Color(0xFFB66D13)
            : const Color(0xFF16875B);
    final icon = _notificationIcon(kind);
    final title = kind == 'profile'
        ? 'PROFILE UPDATED'
        : kind == 'profile-error'
            ? 'PROFILE ERROR'
            : kind == 'urgent'
                ? 'URGENT WASTE ALERT'
        : kind == 'management'
            ? 'MANAGEMENT ALERT'
            : kind == 'confirmation'
                ? 'NEW RESIDENT CONFIRMATION'
                : kind == 'new'
                    ? 'NEW WASTE REPORT'
                    : kind == 'resolved'
                        ? 'REPORT RESOLVED'
                        : 'WASTE REPORT UPDATE';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _dismissTopAlert(); // Replace the previous popup, not the bell history.
      final topInset = MediaQuery.of(context).padding.top;
      final overlay = Overlay.of(context, rootOverlay: true);
      final entry = OverlayEntry(
        builder: (overlayContext) => Positioned(
          top: topInset + 12,
          left: 16,
          right: 16,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: -1.0, end: 0.0),
                duration: const Duration(milliseconds: 330),
                curve: Curves.easeOutCubic,
                builder: (context, slide, child) => Transform.translate(
                  offset: Offset(0, slide * 120),
                  child: child,
                ),
                child: Material(
                  color: color,
                  elevation: 12,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 27),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  )),
                              const SizedBox(height: 3),
                              Text(message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    height: 1.3,
                                  )),
                              if (kind != 'profile' &&
                                  kind != 'profile-error')
                                TextButton(
                                  onPressed: () {
                                    _dismissTopAlert();
                                    if (mounted) _openNotifications();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(40, 30),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('View notifications'),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Dismiss alert',
                          onPressed: _dismissTopAlert,
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      _activeTopAlert = entry;
      overlay.insert(entry);
      _topAlertTimer = Timer(const Duration(seconds: 6), _dismissTopAlert);
    });
  }

  // Only one entry per logical report event, even if Firestore sends the
  // same snapshot again. Newest notifications are shown first.
  void _addNotification({
    required String id,
    required String title,
    required String message,
    required String kind,
    bool isRead = false,
    bool showPopup = true,
  }) {
    if (_notifications.any((n) => n.id == id)) return;
    _notifications.insert(0, _AdminNotification(
      id: id,
      title: title,
      message: message,
      kind: kind,
      receivedAt: DateTime.now(),
      isRead: isRead,
    ));
    if (_notifications.length > 40) {
      _notifications.removeRange(40, _notifications.length);
    }
    _notificationVersion.value++;
    if (showPopup) _showRealtimeNotification(message, kind);
  }

  void _recordChanges(_AdminZoneD previous, _AdminZoneD latest,
      {required bool isFirstSnapshot}) {
    if (!latest.exists || latest.confirmations <= 0) return;
    final incident = latest.incidentId.isEmpty ? 'zone_d' : latest.incidentId;

    if (isFirstSnapshot) {
      // Explain the report already on screen, but do not pretend a new
      // notification arrived when Admin opened the page.
      _addNotification(
        id: '$incident:opened',
        title: 'Current Zone D Report',
        message: latest.resolved
            ? 'The current Zone D report is resolved.'
            : 'Zone D currently has ${latest.confirmations} confirmations '
              'and is on Demo Day ${latest.unresolvedDays}.',
        kind: 'info',
        isRead: true,
        showPopup: false,
      );
      return;
    }

    if (incident != previous.incidentId && !latest.resolved) {
      _addNotification(
        id: '$incident:new',
        title: 'New Waste Report',
        message: 'A new public waste incident was reported at Township Park, Zone D.',
        kind: 'new',
      );
    } else if (latest.confirmations > previous.confirmations) {
      _addNotification(
        id: '$incident:confirmations:${latest.confirmations}',
        title: latest.confirmations >= 3
            ? 'Urgent: Resident Confirmations'
            : 'New Resident Confirmation',
        message: latest.confirmations >= 3
            ? 'Zone D now has ${latest.confirmations} unique confirmations. Priority is URGENT.'
            : 'Zone D now has ${latest.confirmations} unique resident confirmations.',
        kind: latest.confirmations >= 3 ? 'urgent' : 'confirmation',
      );
    }

    if (latest.unresolvedDays > previous.unresolvedDays && !latest.resolved) {
      final day = latest.unresolvedDays;
      _addNotification(
        id: '$incident:day:$day',
        title: day >= 3 ? 'URGENT WASTE ALERT'
            : day == 2 ? 'MANAGEMENT ALERT'
            : 'Day $day Monitoring Update',
        message: day >= 3
            ? 'Zone D has remained unresolved for $day demo days. Immediate attention needed.'
            : day == 2
                ? 'Zone D reached Demo Day 2. Township management should take action.'
                : 'Zone D reached Demo Day $day and is still awaiting cleanup.',
        kind: day >= 3 ? 'urgent' : day == 2 ? 'management' : 'info',
      );
    }

    if (!previous.resolved && latest.resolved) {
      _addNotification(
        id: '$incident:resolved',
        title: 'Report Resolved',
        message: 'Zone D has been marked as resolved by management.',
        kind: 'resolved',
      );
    }
  }

  void _markRead(_AdminNotification item) {
    if (item.isRead) return;
    item.isRead = true;
    _notificationVersion.value++;
    if (mounted) setState(() {});
  }

  void _markAllRead() {
    for (final item in _notifications) {
      item.isRead = true;
    }
    _notificationVersion.value++;
    if (mounted) setState(() {});
  }

  IconData _notificationIcon(String kind) {
    switch (kind) {
      case 'urgent': return Icons.warning_amber_rounded;
      case 'management': return Icons.notifications_active_rounded;
      case 'confirmation': return Icons.groups_rounded;
      case 'new': return Icons.add_location_alt_rounded;
      case 'resolved': return Icons.verified_rounded;
      case 'profile': return Icons.check_circle_outline_rounded;
      case 'profile-error': return Icons.error_outline_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _notificationColor(String kind) {
    switch (kind) {
      case 'urgent': return const Color(0xFFB3261E);
      case 'management': return const Color(0xFFB66D13);
      case 'resolved': return const Color(0xFF16875B);
      default: return const Color(0xFF16875B);
    }
  }

  String _notificationTime(DateTime date) {
    final d = date.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  void _openNotifications() {
    bool unreadOnly = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF5F8F6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: StatefulBuilder(builder: (sheetContext, setSheetState) {
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 8),
                child: Row(children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: _green),
                  const SizedBox(width: 9),
                  const Expanded(child: Text('Notifications',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w800, color: _dark))),
                  TextButton(onPressed: _markAllRead,
                      child: const Text('Mark all read')),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !unreadOnly,
                    onSelected: (_) => setSheetState(() => unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread'),
                    selected: unreadOnly,
                    onSelected: (_) => setSheetState(() => unreadOnly = true),
                  ),
                ]),
              ),
              const SizedBox(height: 9),
              Expanded(child: ValueListenableBuilder<int>(
                valueListenable: _notificationVersion,
                builder: (context, version, child) {
                  final visible = _notifications.where((n) =>
                      !unreadOnly || !n.isRead).toList();
                  if (visible.isEmpty) {
                    return Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(unreadOnly
                          ? 'You have no unread notifications.'
                          : 'No notifications yet. New report and day alerts will appear here.',
                          textAlign: TextAlign.center),
                    ));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = visible[index];
                      final color = _notificationColor(n.kind);
                      return Material(
                        color: n.isRead ? Colors.white
                            : const Color(0xFFE6F4EB),
                        borderRadius: BorderRadius.circular(15),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(15),
                          onTap: () => _markRead(n),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_notificationIcon(n.kind), color: color),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(n.title, style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13)),
                                    const SizedBox(height: 4),
                                    Text(n.message, style: const TextStyle(
                                        fontSize: 12, height: 1.35)),
                                    const SizedBox(height: 6),
                                    Text(_notificationTime(n.receivedAt),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey)),
                                  ],
                                )),
                                if (!n.isRead)
                                  const Icon(Icons.circle,
                                      color: _green, size: 9),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              )),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _notificationBell() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: _openNotifications,
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 2,
            right: 0,
            child: IgnorePointer(child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                  color: Color(0xFFB3261E), shape: BoxShape.circle),
              child: Text(_unreadCount > 9 ? '9+' : '$_unreadCount',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 10, fontWeight: FontWeight.bold)),
            )),
          ),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();
    _reportSubscription = _zoneDRef.snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        final latest = _AdminZoneD.fromSnapshot(snapshot);
        _recordChanges(_report, latest, isFirstSnapshot: _loading);
        _scheduleMapMarkerExpiry(latest);
        setState(() {
          _report = latest;
          _loading = false;
          _loadError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadError = error.toString();
        });
      },
    );
  }

  @override
  void dispose() {
    _dismissTopAlert();
    _mapMarkerExpiryTimer?.cancel();
    _reportSubscription.cancel();
    _notificationVersion.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final snapshot = await _zoneDRef.get(
        const GetOptions(source: Source.server),
      );
      if (!mounted) return;
      final updated = _AdminZoneD.fromSnapshot(snapshot);
      _scheduleMapMarkerExpiry(updated);
      setState(() {
        _report = updated;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to refresh: $error')),
      );
    }
  }

  // The history belongs to resolved past incidents only. The current
  // incident can also be resolved, but it is not added to history until a
  // Resident starts another case. Never count it twice.
  int get _zoneDTotalCases => _report.history.length + (_exists ? 1 : 0);
  int get _zoneDActiveCases => _exists && !_resolved ? 1 : 0;
  int get _zoneDUrgentCases => _urgent ? 1 : 0;
  int get _zoneDResolvedCases => _report.history.length +
      ((_exists && _resolved) ? 1 : 0);

  List<_AdminArchivedIncident> get _filteredArchivedIncidents {
    if (_filter != 'All' && _filter != 'Resolved') {
      return const <_AdminArchivedIncident>[];
    }
    final result = List<_AdminArchivedIncident>.from(_report.history);
    result.sort((a, b) {
      final aa = a.resolvedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bb = b.resolvedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bb.compareTo(aa);
    });
    return result;
  }

  String _formatIncidentDate(DateTime? date) {
    if (date == null) return 'Not recorded';
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  bool get _shouldShowReport {
    if (!_exists) return false;
    switch (_filter) {
      case 'Active':
        return !_resolved;
      case 'Urgent':
        return _urgent;
      case 'Resolved':
        return _resolved;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the same Firestore stream and Admin report management logic on
    // all tabs. Switching tabs never rebuilds the subscription.
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F5),
      appBar: AppBar(
        // Hide the back arrow to Login. The Profile's red Log Out button
        // remains the intentional way to sign out of the Admin session.
        automaticallyImplyLeading: false,
        title: Text(
          _selectedTab == 0 ? 'Admin Home' :
          _selectedTab == 1 ? 'Reports' : 'Admin Profile',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        actions: [
          _notificationBell(),
          IconButton(
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _loadError != null
              ? _connectionErrorPanel()
              : IndexedStack(
                  index: _selectedTab,
                  children: [
                    _homeTab(),
                    _reportsTab(),
                    _profileTab(),
                  ],
                ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        indicatorColor: const Color(0xFFD8F2E4),
        backgroundColor: Colors.white,
        onDestinationSelected: (index) =>
            setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: _green),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: _green),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: _green),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _connectionErrorPanel() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off, color: Colors.orange, size: 44),
        const SizedBox(height: 12),
        Text('Firestore connection error:\n$_loadError',
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton(onPressed: _refresh, child: const Text('Retry')),
      ]),
    ),
  );

  Widget _homeTab() => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      key: const PageStorageKey<String>('admin-home'),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      children: [
        _hero(),
        const SizedBox(height: 18),
        _stats(),
        const SizedBox(height: 8),
        const Text('Live figures currently cover Zone D only.',
            style: TextStyle(fontSize: 11, color: Color(0xFF69786E))),
        const SizedBox(height: 18),
        if (_needsAttention) ...[
          _alertBanner(),
          const SizedBox(height: 18),
        ],
        _homeHotspotMap(),
        const SizedBox(height: 22),
        Row(children: [
          const Expanded(child: Text("Today's Recent Alerts",
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
                  color: _dark))),
          TextButton(onPressed: _openNotifications,
              child: const Text('View all')),
        ]),
        const SizedBox(height: 8),
        _todayAlerts(),
      ],
    ),
  );

  // Step 59B: Same pulsing circular hotspot markers as the Resident map.
  // The location canvas is illustrative; only Zone D is a live Firestore case.
  Widget _homeHotspotMap() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EEE5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.map_outlined, color: _green, size: 25),
          const SizedBox(width: 8),
          const Expanded(child: Text('Waste Hotspot Map',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800,
              color: _dark))),
          IconButton(
            onPressed: _openExpandedAdminMap,
            tooltip: 'Expand hotspot map',
            icon: const Icon(Icons.open_in_full_rounded, color: _green),
          ),
        ]),
        const Text('Demo township map • only Zone D is live • expand to tap a marker',
          style: TextStyle(fontSize: 11, color: Color(0xFF8A9690))),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 320,
            width: double.infinity,
            child: LayoutBuilder(builder: (context, constraints) =>
              _adminResidentStyleMap(
                constraints.maxWidth, constraints.maxHeight,
                // Home preview only. Markers still pulse but cannot be tapped.
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _adminResidentStyleMap(
    double w,
    double h, {
    void Function(String zone)? onZoneTap,
    bool showLegend = false,
  }) {
    final liveColor = _resolved
        ? _green
        : _urgent ? const Color(0xFF8B0000) : const Color(0xFFDC392C);
    final liveLabel = _resolved
        ? 'RESOLVED'
        : _report.confirmations <= 1
            ? 'NEW'
            : '${_report.confirmations} CONFIRMED';

    return Stack(clipBehavior: Clip.hardEdge, children: [
      const Positioned.fill(child: CustomPaint(
          painter: _AdminTownshipMapPainter())),
      Positioned(left: w * .03, top: 11,
        child: const Text('ZONE A', style: _AdminMapZoneLabel.textStyle)),
      Positioned(right: w * .03, top: h * .33,
        child: const Text('ZONE B', style: _AdminMapZoneLabel.textStyle)),
      Positioned(left: w * .03, bottom: h * .10,
        child: const Text('ZONE C', style: _AdminMapZoneLabel.textStyle)),
      Positioned(right: w * .05, bottom: h * .07,
        child: const Text('ZONE D', style: _AdminMapZoneLabel.textStyle)),
      Positioned(left: w * .105, top: h * .22,
        child: _AdminPulseMapMarker(
          color: const Color(0xFFE1A72E), label: '2 DEMO',
          onTap: onZoneTap == null ? null : () => onZoneTap?.call('A'),
        )),
      Positioned(right: w * .06, top: h * .39,
        child: _AdminPulseMapMarker(
          color: Colors.orange, label: '4 DEMO',
          onTap: onZoneTap == null ? null : () => onZoneTap?.call('B'),
        )),
      Positioned(left: w * .13, top: h * .63,
        child: _AdminPulseMapMarker(
          color: Colors.red, label: '17 DEMO', strongPulse: true,
          onTap: onZoneTap == null ? null : () => onZoneTap?.call('C'),
        )),
      if (_showZoneDMapMarker)
        Positioned(right: w * .09, top: h * .60,
          child: _AdminPulseMapMarker(
            key: ValueKey('admin_live_${_report.incidentId}_${_resolved}'),
            color: liveColor, label: liveLabel,
            labelColor: _urgent ? const Color(0xFF8B0000) : liveColor,
            strongPulse: !_resolved,
            onTap: onZoneTap == null ? null : () => onZoneTap?.call('D'),
          )),
      // Show the legend only in the expanded map, not on the Admin Home map.
      if (showLegend)
        Positioned(
          top: 12,
          right: 12,
          child: IgnorePointer(child: _adminMapLegendCard()),
        ),
      // When resolved and 30 seconds have elapsed, Zone D disappears just as it
      // does in the Resident map. Report details remain in the Reports tab.
    ]);
  }

  Widget _adminMapLegendCard() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(.94),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(.05), blurRadius: 8,
      )],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Map Legend', style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.bold,
          color: Color(0xFF253A2F),
        )),
        const SizedBox(height: 7),
        _mapLegend(const Color(0xFFE1A72E), 'Low'),
        const SizedBox(height: 4),
        _mapLegend(Colors.orange, 'Medium'),
        const SizedBox(height: 4),
        _mapLegend(Colors.red, 'High'),
        const SizedBox(height: 4),
        _mapLegend(const Color(0xFF8B0000), 'Urgent'),
        const SizedBox(height: 4),
        _mapLegend(_green, 'Resolved'),
      ],
    ),
  );

  void _openExpandedAdminMap() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (expandedContext) => Scaffold(
        backgroundColor: const Color(0xFFF3F8F5),
        appBar: AppBar(
          title: const Text('Township Hotspot Map'),
          backgroundColor: Colors.white,
          foregroundColor: _dark,
        ),
        body: LayoutBuilder(builder: (context, size) =>
          InteractiveViewer(
            minScale: 1,
            maxScale: 3.5,
            boundaryMargin: const EdgeInsets.all(80),
            child: SizedBox(
              width: size.maxWidth,
              height: size.maxHeight,
              child: _adminResidentStyleMap(
                size.maxWidth, size.maxHeight,
                showLegend: true,
                // Open the report pop-up on top of the expanded map.
                // Do not pop the expanded route when a marker is tapped.
                onZoneTap: (zone) => _openMapZone(
                  zone,
                  expandedMapContext: expandedContext,
                ),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  Widget _mapLegend(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 9, height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10,
          color: Color(0xFF536B5D))),
    ],
  );

  void _openMapZone(String zone, {BuildContext? expandedMapContext}) {
    final bool zoneD = zone == 'D';
    final String description = !zoneD
        ? 'Zone $zone is a demonstration location. Live Firestore reports '
            'are not available for this zone yet.'
        : !_exists
            ? 'No current Zone D report has been submitted.'
            : _resolved
                ? 'The latest Zone D incident has been resolved.'
                : _urgent
                    ? 'Zone D is URGENT and requires immediate attention.'
                    : 'Zone D has an active waste report.';

    showModalBottomSheet<void>(
      context: expandedMapContext ?? context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.place_rounded, color: _green),
                const SizedBox(width: 8),
                Text('Zone $zone Hotspot', style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    color: _dark)),
              ]),
              const SizedBox(height: 12),
              Text(description, style: const TextStyle(
                  fontSize: 13, height: 1.5)),
              if (zoneD && _exists) ...[
                const SizedBox(height: 12),
                Text('Location: Township Park, Zone D',
                    style: const TextStyle(fontSize: 13)),
                Text('Confirmations: ${_report.confirmations}',
                    style: const TextStyle(fontSize: 13)),
                Text('Status: ${_report.status}',
                    style: const TextStyle(fontSize: 13)),
                Text('Demo days unresolved: ${_report.unresolvedDays}',
                    style: const TextStyle(fontSize: 13)),
              ],
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _selectedZone = zone;
                    _selectedTab = 1;
                  });
                  // Only the explicit View Reports button leaves the map.
                  // A normal marker tap keeps the expanded map visible.
                  if (expandedMapContext != null && expandedMapContext.mounted) {
                    Navigator.of(expandedMapContext).pop();
                  }
                },
                icon: const Icon(Icons.assignment_outlined),
                label: Text('View Zone $zone Reports'),
              )),
              if (zoneD && _exists) ...[
                const SizedBox(height: 7),
                SizedBox(width: double.infinity, child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    // Open management above the expanded map so Back returns
                    // to that map, not to Admin Home.
                    await Navigator.push<void>(
                      expandedMapContext ?? context,
                      MaterialPageRoute(
                        builder: (_) => const AdminReportDetailPage(),
                      ),
                    );
                    if (mounted) _refresh();
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: const Text('Manage Zone D Report'),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _todayAlerts() {
    final now = DateTime.now();
    final todays = _notifications.where((n) {
      final day = n.receivedAt.toLocal();
      return day.year == now.year && day.month == now.month &&
          day.day == now.day;
    }).take(4).toList();
    if (todays.isEmpty) {
      return _infoCard(
        Icons.notifications_none_rounded,
        'No alerts received today',
        'New report, confirmation and escalation alerts will appear here '
        'while the Admin app is open.',
      );
    }
    return Column(children: [
      for (final n in todays)
        Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => _markRead(n),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Icon(_notificationIcon(n.kind),
                      color: _notificationColor(n.kind)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.title, style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(n.message, style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(_notificationTime(n.receivedAt),
                          style: const TextStyle(fontSize: 11,
                              color: Colors.grey)),
                    ],
                  )),
                  if (!n.isRead)
                    const Icon(Icons.circle, size: 8, color: _green),
                ]),
              ),
            ),
          ),
        ),
      const Padding(
        padding: EdgeInsets.only(top: 5),
        child: Text('Today’s alerts are stored for this app session only.',
            style: TextStyle(color: Color(0xFF69786E), fontSize: 11)),
      ),
    ]);
  }

  // Step 60: Reports grouped by township zone. Only Zone D currently has
  // real Firestore records. Its older resolved incidents are read from the
  // same document history, with no new database collection or rules needed.
  Widget _reportsTab() => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      key: const PageStorageKey<String>('admin-reports'),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
      children: [
        const Text('Reports by Zone', style: TextStyle(
            fontSize: 23, fontWeight: FontWeight.w800, color: _dark)),
        const SizedBox(height: 5),
        const Text('Select a zone to view its waste incidents and statuses.',
            style: TextStyle(color: Color(0xFF69786E))),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final zone in const ['A', 'B', 'C', 'D'])
            ChoiceChip(
              avatar: Icon(Icons.place_rounded, size: 16,
                color: _selectedZone == zone ? _green :
                    const Color(0xFF70877A)),
              label: Text('Zone $zone'),
              selected: _selectedZone == zone,
              onSelected: (_) => setState(() {
                _selectedZone = zone;
                _filter = 'All';
              }),
              selectedColor: const Color(0xFFD8F2E4),
              backgroundColor: Colors.white,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ]),
        const SizedBox(height: 16),
        if (_selectedZone == 'D') ...[
          Row(children: [
            const Expanded(child: Text('Zone D • Reports', style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w800, color: _dark))),
            _pill('LIVE FIRESTORE', _green),
          ]),
          const SizedBox(height: 6),
          const Text('Shows the current incident plus saved resolved '
              'incidents from Zone D history.', style: TextStyle(
                fontSize: 12, color: Color(0xFF69786E))),
          const SizedBox(height: 15),
          _zoneDReportStatistics(),
          const SizedBox(height: 16),
          if (_needsAttention) ...[
            _alertBanner(),
            const SizedBox(height: 16),
          ],
          const Text('Filter Reports', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: _dark)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in const ['All', 'Active', 'Urgent', 'Resolved'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: const Color(0xFFD8F2E4),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 9),
          Text(
            'Showing ${(_shouldShowReport ? 1 : 0) + _filteredArchivedIncidents.length} '
            'of $_zoneDTotalCases recorded incident(s)',
            style: const TextStyle(fontSize: 11, color: Color(0xFF69786E)),
          ),
          const SizedBox(height: 14),
          if (_shouldShowReport) ...[
            _reportCard(),
            const SizedBox(height: 12),
          ],
          for (final oldIncident in _filteredArchivedIncidents) ...[
            _archivedIncidentCard(oldIncident),
            const SizedBox(height: 12),
          ],
          if (!_shouldShowReport && _filteredArchivedIncidents.isEmpty)
            _emptyReportsForFilter(),
          const SizedBox(height: 17),
          _infoCard(
            Icons.history_rounded,
            'About saved reports',
            'Previous cases are copied into Firestore history when a new '
            'incident starts after the old one is resolved. Archived cases '
            'can be viewed but not edited. The demo keeps a limited history.',
          ),
          const SizedBox(height: 14),
          _demoInfo(),
        ] else ...[
          _infoCard(
            Icons.construction_outlined,
            'Zone $_selectedZone — demo only',
            'Zone $_selectedZone has map markers for demonstration, but '
            'there are no connected Firestore reports for this zone yet. '
            'Its example marker count is not a real report total.',
          ),
          const SizedBox(height: 12),
          _infoCard(
            Icons.assignment_late_outlined,
            'No live report statistics',
            'Active, urgent and resolved counts will become available '
            'after the Resident reporting system supports Zone $_selectedZone.',
          ),
        ],
      ],
    ),
  );

  Widget _zoneDReportStatistics() {
    final values = <({String title, int value, IconData icon, Color color})>[
      (title: 'All Reports', value: _zoneDTotalCases,
        icon: Icons.assignment_outlined, color: _green),
      (title: 'Active', value: _zoneDActiveCases,
        icon: Icons.pending_actions_outlined,
        color: const Color(0xFFE18A16)),
      (title: 'Urgent', value: _zoneDUrgentCases,
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFB71C1C)),
      (title: 'Resolved', value: _zoneDResolvedCases,
        icon: Icons.verified_outlined, color: _green),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 650 ? 4 : 2;
      final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final stat in values)
          SizedBox(width: width, child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE1EEE5)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(stat.icon, color: stat.color, size: 21),
                const SizedBox(height: 7),
                Text('${stat.value}', style: const TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w900, color: _dark)),
                Text(stat.title, style: const TextStyle(fontSize: 11,
                  color: Color(0xFF69786E), fontWeight: FontWeight.w700)),
              ],
            ),
          )),
      ]);
    });
  }

  Widget _archivedIncidentCard(_AdminArchivedIncident incident) =>
      Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1EEE5)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const CircleAvatar(
          radius: 19,
          backgroundColor: Color(0xFFE3F5E9),
          child: Icon(Icons.check_circle_outline, color: _green)),
        const SizedBox(width: 10),
        const Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Township Park — Zone D', style: TextStyle(
                color: _dark, fontWeight: FontWeight.w800, fontSize: 15)),
            Text('Previous waste incident', style: TextStyle(
                fontSize: 11, color: Color(0xFF69786E))),
          ],
        )),
        _pill('RESOLVED', _green),
      ]),
      const SizedBox(height: 12),
      Wrap(spacing: 14, runSpacing: 8, children: [
        _smallInfo(Icons.people_outline,
            '${incident.confirmations} confirmation(s)'),
        _smallInfo(Icons.event_available_outlined,
            _formatIncidentDate(incident.resolvedAt)),
      ]),
      const SizedBox(height: 13),
      SizedBox(width: double.infinity, child: OutlinedButton.icon(
        onPressed: () => _showArchivedIncident(incident),
        icon: const Icon(Icons.visibility_outlined),
        label: const Text('View Previous Report'),
      )),
    ]),
  );

  void _showArchivedIncident(_AdminArchivedIncident incident) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Previous Zone D Report', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: _dark)),
              const SizedBox(height: 7),
              const Text('This incident has already been resolved. '
                  'Archived details are read-only.', style: TextStyle(
                color: Color(0xFF69786E), fontSize: 13)),
              const SizedBox(height: 17),
              _archiveDetailRow('Location', 'Township Park, Zone D'),
              _archiveDetailRow('Incident ID',
                  incident.incidentId.isEmpty ? 'Not recorded' : incident.incidentId),
              _archiveDetailRow('Confirmations',
                  '${incident.confirmations} resident(s)'),
              _archiveDetailRow('Created',
                  _formatIncidentDate(incident.createdAt)),
              _archiveDetailRow('Resolved',
                  _formatIncidentDate(incident.resolvedAt)),
              _archiveDetailRow('Status', 'Resolved'),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _archiveDetailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 100, child: Text(label, style: const TextStyle(
          fontSize: 12, color: Color(0xFF69786E)))),
      Expanded(child: Text(value, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, color: _dark))),
    ]),
  );

  Widget _emptyReportsForFilter() {
    final label = _filter == 'All'
        ? 'No Zone D reports have been recorded.'
        : 'There are no $_filter reports for Zone D.';
    return _infoCard(Icons.inbox_outlined,
        'No reports in this view', label);
  }

  // Step 62: Keep the edit dialog's text field managed by Flutter.
  // The old TextEditingController was disposed immediately after showDialog
  // returned, while the pop animation could still be using it, causing a red
  // error screen on Save. A TextFormField with initialValue owns its controller
  // and cleans it up only when the dialog widget is actually disposed.
  Future<void> _editAdminName() async {
    if (_savingProfile || _signingOutAdmin) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showProfileMessage('Your session has ended. Please log in again.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    String draftName = (user.displayName ?? '').trim();
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Admin Name'),
        content: Form(
          key: formKey,
          child: TextFormField(
            initialValue: draftName,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Display name',
              hintText: 'e.g. Township Administrator',
              prefixIcon: Icon(Icons.badge_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => draftName = value,
            validator: (value) {
              final name = value?.trim() ?? '';
              if (name.isEmpty) return 'Please enter a display name.';
              if (name.length > 40) return 'Use 40 characters or fewer.';
              return null;
            },
            onFieldSubmitted: (value) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(value.trim());
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _green),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(draftName.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || newName == null || newName.isEmpty) return;
    if (newName == (user.displayName ?? '').trim()) return;

    setState(() => _savingProfile = true);
    try {
      await user.updateDisplayName(newName);
      await user.reload();
      if (!mounted) return;
      setState(() {});
      _showProfileMessage('Admin display name updated successfully.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      _showProfileMessage(
        'Unable to update profile: ${error.message ?? error.code}',
      );
    } catch (_) {
      if (!mounted) return;
      _showProfileMessage('Unable to update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  void _showProfileMessage(String text) {
    if (!mounted) return;
    final isError = text.startsWith('Unable') ||
        text.startsWith('Your session');
    // Reuse the same six-second top banner as waste alerts, but don't
    // add profile changes to the waste-report notification bell.
    _showRealtimeNotification(
      text,
      isError ? 'profile-error' : 'profile',
    );
  }

  // The current Firebase login flow pushes AdminDashboardPage above the login
  // page. Popping this page returns Admin to login without changing main.dart.
  Future<void> _signOutAdmin() async {
    if (_signingOutAdmin) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out of Admin?'),
        content: const Text(
          'You will return to the login page. Your reports and Firebase data '
          'will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOutAdmin = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      // The existing LoginPage awaits the Admin route and will show again.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // Fallback for applications that launch this page as their root.
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOutAdmin = false);
      _showProfileMessage('Unable to log out. Please try again.');
    }
  }

  Widget _profileTab() {
    final user = FirebaseAuth.instance.currentUser;
    final rawName = user?.displayName?.trim() ?? '';
    final displayName = rawName.isEmpty ? 'Township Administrator' : rawName;
    final email = user?.email ?? 'Not available';

    return ListView(
      key: const PageStorageKey<String>('admin-profile'),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE1EEE5)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: Color(0xFFD8F2E4),
                child: Icon(Icons.admin_panel_settings_rounded,
                    color: _green, size: 46),
              ),
              const SizedBox(height: 14),
              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F5EA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'TOWNSHIP ADMIN',
                  style: TextStyle(
                    color: _green,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: user != null && !_savingProfile && !_signingOutAdmin
                    ? _editAdminName
                    : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  backgroundColor: const Color(0xFFF5FBF7),
                  side: const BorderSide(color: Color(0xFFD5E8DC)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 17, vertical: 8),
                  minimumSize: const Size(0, 34),
                  shape: const StadiumBorder(),
                ),
                icon: _savingProfile
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _green),
                      )
                    : const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  _savingProfile ? 'Saving...' : 'Edit Profile',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.email_outlined, color: _green),
                title: const Text('Email Address',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: SelectableText(email),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined, color: _green),
                title: const Text('Display Name',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(displayName),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE1EEE5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Account Settings',
                  style: TextStyle(
                      color: _dark,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingProfile || _signingOutAdmin
                      ? null
                      : _signOutAdmin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB3261E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  icon: _signingOutAdmin
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.logout_rounded, size: 20),
                  label: Text(
                    _signingOutAdmin ? 'Signing out...' : 'Log Out',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Profile name is saved to Firebase Authentication. '
          'Your report history, EcoPoints and notification settings '
          'are not changed.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Color(0xFF69786E), fontSize: 11, height: 1.5),
        ),
      ],
    );
  }

  Widget _infoCard(IconData icon, String title, String message) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1EEE5))),
    child: Column(children: [
      Icon(icon, color: _green, size: 36),
      const SizedBox(height: 9),
      Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800,
              color: _dark, fontSize: 15)),
      const SizedBox(height: 6),
      Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF69786E),
              fontSize: 12, height: 1.5)),
    ]),
  );

  Widget _hero() => Container(
        padding: const EdgeInsets.all(23),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF123C2D), Color(0xFF16875B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _green.withOpacity(.22),
              blurRadius: 18, offset: const Offset(0, 9))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.eco_rounded, color: Colors.white, size: 30),
            SizedBox(width: 8),
            Expanded(child: Text('WasteHotspot AI',
                style: TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w900))),
          ]),
          const SizedBox(height: 15),
          const Text('Township Management Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 17,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          const Text('Monitor waste incidents, review alerts and coordinate cleanups.',
              style: TextStyle(color: Color(0xFFD4F0E1), height: 1.5)),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(color: Colors.white.withOpacity(.16),
                borderRadius: BorderRadius.circular(30)),
            child: const Text('LIVE MODE • FIRESTORE SYNC',
                style: TextStyle(color: Colors.white, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: .6)),
          ),
        ]),
      );

  Widget _stats() {
    final stats = <({String title, String value, IconData icon, Color color})>[
      (title: 'Current Incidents', value: _exists ? '1' : '0',
          icon: Icons.place_outlined, color: _green),
      (title: 'Active Cases', value: (_exists && !_resolved) ? '1' : '0',
          icon: Icons.assignment_outlined, color: const Color(0xFFE18A16)),
      (title: 'Urgent Cases', value: _urgent ? '1' : '0',
          icon: Icons.warning_amber_rounded, color: const Color(0xFFB71C1C)),
      (title: 'Resolved Cases', value: (_exists && _resolved) ? '1' : '0',
          icon: Icons.verified_outlined, color: _green),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final count = constraints.maxWidth > 650 ? 4 : 2;
      final width = (constraints.maxWidth - (count - 1) * 12) / count;
      return Wrap(spacing: 12, runSpacing: 12,
        children: stats.map((s) => SizedBox(width: width,
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1EEE5))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(s.icon, color: s.color, size: 24),
              const SizedBox(height: 8),
              Text(s.value, style: const TextStyle(fontSize: 27,
                  fontWeight: FontWeight.w900, color: _dark)),
              const SizedBox(height: 2),
              Text(s.title, style: const TextStyle(fontSize: 11,
                  color: Color(0xFF67776D), fontWeight: FontWeight.w600)),
            ]),
          ),
        )).toList(),
      );
    });
  }

  Widget _alertBanner() {
    final bool important = _urgent || _report.managementAlert;
    final Color foreground = important
        ? const Color(0xFF8A2B1A)
        : const Color(0xFF155B40);
    return Container(
      decoration: BoxDecoration(
        color: important ? const Color(0xFFFFF1ED) : const Color(0xFFEAF7F1),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: important ? const Color(0xFFF5BFB1) : const Color(0xFFB6E4CA),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: foreground, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_alertTitle,
                    style: TextStyle(color: foreground, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(_alertMessage,
                    style: TextStyle(color: foreground, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportCard() {
    final status = _report.status;
    final color = _resolved
        ? _green
        : _urgent ? const Color(0xFF8B0000) : const Color(0xFFDC392C);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EEE5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
          child: Image.asset(
            'assests/images/rubbish_public.jpg',
            height: 164, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(height: 130,
              color: const Color(0xFFEAF2EA),
              alignment: Alignment.center,
              child: const Icon(Icons.delete_outline, size: 48, color: _green)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('Township Park – Zone D',
                  style: const TextStyle(fontWeight: FontWeight.w900,
                      fontSize: 17, color: _dark))),
              const SizedBox(width: 8),
              _pill(_resolved ? 'RESOLVED' : _urgent ? 'URGENT' : 'HIGH', color),
            ]),
            const SizedBox(height: 8),
            const Text('Public recreational area • Mixed waste',
                style: TextStyle(fontSize: 12, color: Color(0xFF687970))),
            const SizedBox(height: 14),
            Wrap(spacing: 14, runSpacing: 8, children: [
              _smallInfo(Icons.people_outline,
                  '${_report.confirmations} confirmations'),
              _smallInfo(Icons.schedule_outlined,
                  '${_report.unresolvedDays} day(s) unresolved'),
              _smallInfo(Icons.fact_check_outlined, status),
            ]),
            const SizedBox(height: 15),
            SizedBox(width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(context,
                      MaterialPageRoute<void>(builder: (_) => const AdminReportDetailPage()));
                  if (mounted) _refresh();
                },
                style: FilledButton.styleFrom(backgroundColor: _green,
                    padding: const EdgeInsets.symmetric(vertical: 13)),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('View Report & Manage'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _emptyState() => Container(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 22),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      const Icon(Icons.inbox_outlined, size: 55, color: Color(0xFF94AEA0)),
      const SizedBox(height: 9),
      const Text('No reports in this view',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 6),
      Text(_exists ? 'Try another filter.' :
            'Submit a waste report from the resident app first.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF69786E), fontSize: 13)),
    ]),
  );

  Widget _demoInfo() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFFEAF3EC),
        borderRadius: BorderRadius.circular(15)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.info_outline, color: _green, size: 20),
      SizedBox(width: 10),
      Expanded(child: Text(
        'Zone D is now synchronised through Cloud Firestore. '
        'Management updates are shared between devices. '
        'This remains a simulated waste detection demo; '
        'the Resident can simulate unresolved days from Progress. '
        'Live alert pop-ups and the notification bell work while the Admin dashboard is open. '
        'The bell keeps recent notifications for this app session only. '
        'Background push notifications and scheduled day escalation are not enabled.',
        style: TextStyle(fontSize: 12, height: 1.45,
            color: Color(0xFF315243)),
      )),
    ]),
  );

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(30)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10,
        fontWeight: FontWeight.w900)),
  );

  Widget _smallInfo(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: const Color(0xFF668072)),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(fontSize: 12,
          color: Color(0xFF465A4E))),
    ],
  );
}

class AdminReportDetailPage extends StatefulWidget {
  const AdminReportDetailPage({super.key});

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  static const green = Color(0xFF16875B);
  static const _statusChoices = [
    'Pending Review', 'Under Review', 'In Progress',
  ];
  static const _teamChoices = [
    'Not assigned', 'Cleaning Team A', 'Cleaning Team B', 'Maintenance Team',
  ];

  _AdminZoneD _report = const _AdminZoneD();
  String _status = 'Pending Review';
  String _team = 'Not assigned';
  late final TextEditingController _notes;
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _reportSubscription;
  bool _loading = true;
  bool _busy = false;
  bool _draftDirty = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
    _notes.addListener(() {
      // Changing the notes means a live snapshot should not erase this draft.
      if (!_loading && !_busy) _draftDirty = true;
    });
    _reportSubscription = _zoneDRef.snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        final latest = _AdminZoneD.fromSnapshot(snapshot);
        setState(() {
          _report = latest;
          _loading = false;
          _loadError = null;
          if (!_draftDirty && !_busy) {
            _syncDraftFromReport();
          }
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _loadError = error.toString();
        });
      },
    );
  }

  void _syncDraftFromReport() {
    _status = _report.resolved ? 'Resolved' :
        (_statusChoices.contains(_report.status)
            ? _report.status : 'Pending Review');
    _team = _teamChoices.contains(_report.assignedTeam)
        ? _report.assignedTeam : 'Not assigned';
    // Controller assignment may invoke its listener, so explicitly clear dirty.
    _notes.text = _report.adminNote;
    _draftDirty = false;
  }

  @override
  void dispose() {
    _reportSubscription.cancel();
    _notes.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Check the *currently authenticated* account. Firebase Auth sessions can
  // change if a different account signs in in another tab of the same browser.
  // This does not bypass Firestore Security Rules; it only gives a clear error.
  Future<void> _requireCurrentAdminRole() async {
    final account = FirebaseAuth.instance.currentUser;
    if (account == null) {
      throw StateError('Admin is signed out. Please log in again as Admin.');
    }
    final roleSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(account.uid)
        .get();
    final role = roleSnapshot.data()?['role'];
    if (role != 'admin') {
      throw StateError(
        'Signed in as ${account.email ?? account.uid} '
        '(role: ${role ?? 'missing'}). '
        'This account cannot save management updates. '
        'Use a separate browser for Admin and sign in with the Admin account.',
      );
    }
  }

  Future<void> _save() async {
    if (!_report.exists || _report.resolved || _busy) return;
    setState(() => _busy = true);
    try {
      await _requireCurrentAdminRole();
      if (_notes.text.trim().length > 500) {
        throw StateError('Management notes must be 500 characters or less.');
      }
      await _zoneDRef.update({
        'status': _status,
        'assignedTeam': _team,
        'adminNote': _notes.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      setState(() {
        _busy = false;
        _draftDirty = false;
      });
      _showMessage('Management update saved to Firebase.');
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      if (error.code == 'permission-denied') {
        final email = FirebaseAuth.instance.currentUser?.email ?? 'unknown user';
        _showMessage(
          'Save denied for $email. Confirm this user has role admin in '
          'Firestore users/{UID}, and check the PUBLISHED Firestore rules.',
        );
      } else {
        _showMessage('Unable to save: ${error.message ?? error.code}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage('Unable to save: $error');
    }
  }

  Future<void> _resolve() async {
    if (!_report.exists || _report.resolved || _busy) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Zone D as resolved?'),
        content: const Text(
          'This will mark the shared Firebase report as resolved. '
          'Resident pages that listen to Firestore will receive the update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await _requireCurrentAdminRole();
      // A transaction avoids acting on a report already resolved elsewhere.
      await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
        final latest = await transaction.get(_zoneDRef);
        if (!latest.exists) {
          throw StateError('Zone D report was not found.');
        }
        if (latest.data()?['resolved'] == true) {
          throw StateError('Zone D is already resolved.');
        }
        transaction.update(_zoneDRef, {
          'status': 'Resolved',
          'resolved': true,
          'resolvedAt': FieldValue.serverTimestamp(),
          'assignedTeam': _team,
          'adminNote': _notes.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      if (!mounted) return;
      setState(() {
        _status = 'Resolved';
        _busy = false;
        _draftDirty = false;
      });
      _showMessage('Zone D marked as resolved in Firebase.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage('Unable to resolve: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: green)),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Zone D • Report Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Firestore connection error:\n$_loadError',
                textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final exists = _report.exists && _report.confirmations > 0;
    final resolved = _report.resolved;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F5),
      appBar: AppBar(title: const Text('Zone D • Report Details'),
          backgroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        _section('Waste Incident', [
          _item('Location', 'Township Park — Zone D'),
          _item('Waste Type', 'Mixed rubbish / plastic / food packaging'),
          _item('Zone', 'Public recreational area (simulated)'),
          _item('Severity', 'High'),
          _item('Confirmations', '${_report.confirmations} unique residents'),
          _item('Days Unresolved', '${_report.unresolvedDays}'),
          _item('Priority', resolved ? 'Resolved' :
              _report.urgent ? 'Urgent' : 'High'),
          _item('Automatic Alert', _report.urgent
              ? 'URGENT - immediate attention'
              : _report.managementAlert
                  ? 'Day 2 alert triggered'
                  : 'Not triggered'),
        ]),
        const SizedBox(height: 16),
        _section('Management Actions', [
          const Text('Case status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            key: ValueKey('status-${resolved ? 'Resolved' : _status}'),
            value: resolved ? 'Resolved' : _status,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: (resolved ? ['Resolved'] : _statusChoices)
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: resolved || !exists || _busy ? null : (s) =>
                setState(() {
                  _status = s ?? _status;
                  _draftDirty = true;
                }),
          ),
          const SizedBox(height: 15),
          const Text('Assigned cleaning team',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            key: ValueKey('team-$_team'),
            value: _team,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _teamChoices
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: resolved || !exists || _busy ? null : (s) =>
                setState(() {
                  _team = s ?? _team;
                  _draftDirty = true;
                }),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _notes,
            enabled: !resolved && exists && !_busy,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Admin notes',
              hintText: 'Example: Team A scheduled for cleanup',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              onPressed: resolved || !exists || _busy ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_busy ? 'Saving...' : 'Save Management Update'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: resolved || !exists || _busy ? null : _resolve,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Mark Case as Resolved'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13)),
            ),
          ),
          if (resolved)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('This incident is resolved in Firebase. '
                  'Resident history syncing will be connected next.',
                  style: TextStyle(color: green)),
            ),
        ]),
      ]),
    );
  }

  Widget _item(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 130, child: Text(label,
          style: const TextStyle(color: Color(0xFF6C796F), fontSize: 12))),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
    ]),
  );

  Widget _section(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE0ECE3))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18,
          fontWeight: FontWeight.w900, color: Color(0xFF123C2D))),
      const SizedBox(height: 12),
      ...children,
    ]),
  );
}


// Original Resident-style township schematic: pale map, green park areas,
// slanted white roads and labelled zones. This is NOT a GPS map.
class _AdminTownshipMapPainter extends CustomPainter {
  const _AdminTownshipMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFE9F0EB));
    final park = Paint()..color = const Color(0xFFD5E8D9);
    final park2 = Paint()..color = const Color(0xFFD8E7D5);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .03, h * .27, w * .15, h * .18),
      const Radius.circular(28)), park);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .85, h * .68, w * .13, h * .22),
      const Radius.circular(36)), park);
    canvas.drawRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(w * .12, h * .70, w * .33, h * .22),
      const Radius.circular(38)), park2);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;
    void line(double x1, double y1, double x2, double y2) =>
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), road);
    line(-40, h * .37, w + 40, h * .05);
    line(-40, h * .48, w + 40, h * .72);
    line(w * .19, -40, w * .16, h + 40);
    line(w * .89, -40, w * .93, h + 40);
  }

  @override
  bool shouldRepaint(covariant _AdminTownshipMapPainter oldDelegate) => false;
}

class _AdminMapZoneLabel {
  static const textStyle = TextStyle(
    color: Color(0xFF6E7773),
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: .9,
  );
}

// Uses the same pulse animation, label badge and circular marker style as
// the Resident FullMapPage, without importing/changing Resident screens.
class _AdminPulseMapMarker extends StatefulWidget {
  final Color color;
  final String label;
  final Color? labelColor;
  final bool strongPulse;
  final VoidCallback? onTap;

  const _AdminPulseMapMarker({
    super.key,
    required this.color,
    required this.label,
    this.labelColor,
    this.strongPulse = false,
    this.onTap,
  });

  @override
  State<_AdminPulseMapMarker> createState() => _AdminPulseMapMarkerState();
}

class _AdminPulseMapMarkerState extends State<_AdminPulseMapMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this,
      duration: Duration(milliseconds: widget.strongPulse ? 850 : 1500));
    _setAnimation();
    controller.repeat(reverse: true);
  }

  void _setAnimation() {
    animation = Tween<double>(
      begin: widget.strongPulse ? .88 : .95,
      end: widget.strongPulse ? 1.28 : 1.08,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _AdminPulseMapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.strongPulse != widget.strongPulse) {
      controller.duration = Duration(
        milliseconds: widget.strongPulse ? 850 : 1500);
      _setAnimation();
      controller..reset()..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: const EdgeInsets.only(bottom: 5),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(.08), blurRadius: 5)],
          ),
          child: Text(widget.label, style: TextStyle(
            color: widget.labelColor ?? widget.color,
            fontSize: 8, fontWeight: FontWeight.w800,
          )),
        ),
        ScaleTransition(
          scale: animation,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(.17), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Container(
              width: 23, height: 23,
              decoration: BoxDecoration(
                color: widget.color, shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [BoxShadow(color: widget.color.withOpacity(.35),
                    blurRadius: 8)],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
