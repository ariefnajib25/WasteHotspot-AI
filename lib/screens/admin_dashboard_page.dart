import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// This is the same document used by lib/data/zone_d_cloud_service.dart.
DocumentReference<Map<String, dynamic>> get _zoneDRef =>
    FirebaseFirestore.instance.collection('hotspots').doc('zone_d');

/// Data read from the shared Firestore hotspot document.
class _AdminZoneD {
  final bool exists;
  final String incidentId;
  final int confirmations;
  final int unresolvedDays;
  final bool resolved;
  final String status;
  final String assignedTeam;
  final String adminNote;

  const _AdminZoneD({
    this.exists = false,
    this.incidentId = '',
    this.confirmations = 0,
    this.unresolvedDays = 0,
    this.resolved = false,
    this.status = 'Pending Review',
    this.assignedTeam = 'Not assigned',
    this.adminNote = '',
  });

  factory _AdminZoneD.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) return const _AdminZoneD();

    final reporters = data['reporterUids'];
    final countFromList = reporters is List ? reporters.length : null;
    final countFromField = (data['confirmations'] as num?)?.toInt() ?? 0;

    return _AdminZoneD(
      exists: snapshot.exists,
      incidentId: data['incidentId'] as String? ?? '',
      confirmations: countFromList ?? countFromField,
      unresolvedDays: (data['unresolvedDays'] as num?)?.toInt() ?? 0,
      resolved: data['resolved'] == true,
      status: data['status'] as String? ?? 'Pending Review',
      assignedTeam: data['assignedTeam'] as String? ?? 'Not assigned',
      adminNote: data['adminNote'] as String? ?? '',
    );
  }

  bool get urgent => exists && !resolved &&
      (confirmations >= 3 || unresolvedDays >= 3);

  bool get managementAlert =>
      exists && !resolved && unresolvedDays >= 2;
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
  _AdminZoneD _report = const _AdminZoneD();
  bool _loading = true;
  String? _loadError;
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
      _reportSubscription;

  bool get _exists => _report.exists && _report.confirmations > 0;
  bool get _resolved => _report.resolved;
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

  void _showRealtimeNotification(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 9),
            Expanded(child: Text(message)),
          ]),
          backgroundColor: const Color(0xFF8A2B1A),
          duration: const Duration(seconds: 5),
        ));
    });
  }

  @override
  void initState() {
    super.initState();
    _reportSubscription = _zoneDRef.snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        final latest = _AdminZoneD.fromSnapshot(snapshot);
        String? newAlert;
        // Do not pop up a message on initial page load; the permanent
        // banner below already shows the current report's alert state.
        if (!_loading && latest.exists && !latest.resolved) {
          if (latest.incidentId != _report.incidentId &&
              latest.incidentId.isNotEmpty) {
            newAlert = 'New Zone D waste report received!';
          } else if (latest.confirmations > _report.confirmations) {
            newAlert = latest.confirmations >= 3
                ? 'URGENT! Zone D now has ${latest.confirmations} resident confirmations.'
                : 'Zone D now has ${latest.confirmations} unique resident confirmations.';
          } else if (latest.unresolvedDays > _report.unresolvedDays) {
            newAlert = latest.unresolvedDays >= 3
                ? 'URGENT! Zone D reached Demo Day ${latest.unresolvedDays}.'
                : latest.unresolvedDays == 2
                    ? 'MANAGEMENT ALERT: Resident simulated Day 2.'
                    : 'DAY 1 UPDATE: Resident simulated the next day.';
          }
        }
        setState(() {
          _report = latest;
          _loading = false;
          _loadError = null;
        });
        if (newAlert != null) _showRealtimeNotification(newAlert);
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
    _reportSubscription.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final snapshot = await _zoneDRef.get(
        const GetOptions(source: Source.server),
      );
      if (!mounted) return;
      setState(() {
        _report = _AdminZoneD.fromSnapshot(snapshot);
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
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: _green)),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Management Console')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: Colors.orange, size: 44),
                const SizedBox(height: 12),
                Text('Firestore connection error:\n$_loadError',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _refresh, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F5),
      appBar: AppBar(
        title: const Text('Management Console',
            style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            _hero(),
            const SizedBox(height: 18),
            _stats(),
            const SizedBox(height: 18),
            if (_needsAttention) ...[
              _alertBanner(),
              const SizedBox(height: 18),
            ],
            Row(
              children: [
                const Expanded(
                  child: Text('Waste Reports',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                          color: _dark)),
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.sync_rounded, color: _green),
                  tooltip: 'Reload',
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Active', 'Urgent', 'Resolved'].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: const Color(0xFFD8F2E4),
                      labelStyle: TextStyle(
                          color: selected ? _dark : const Color(0xFF53645B),
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500),
                      side: BorderSide(
                          color: selected ? _green : const Color(0xFFE1EAE4)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            if (_shouldShowReport)
              _reportCard()
            else
              _emptyState(),
            const SizedBox(height: 20),
            _demoInfo(),
          ],
        ),
      ),
    );
  }

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
      (title: 'Total Hotspots', value: _exists ? '1' : '0',
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
        'Alerts appear automatically here while the dashboard is open. '
        'Push notifications and scheduled day escalation are not enabled.',
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

  Future<void> _save() async {
    if (!_report.exists || _report.resolved || _busy) return;
    setState(() => _busy = true);
    try {
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
