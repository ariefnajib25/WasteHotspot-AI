import 'package:flutter/material.dart';

import '../data/report_store.dart';
import '../data/admin_store.dart';

/// WasteHotspot AI admin demonstration. No backend or real alerts are used.
/// Reads the existing ReportStore, so Zone D reports submitted in this app
/// appear here after a refresh or when the screen opens.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  static const _green = Color(0xFF16875B);
  static const _dark = Color(0xFF123C2D);
  String _filter = 'All';

  bool get _exists => ReportStore.zoneDReportCount > 0;
  bool get _resolved => ReportStore.zoneDResolved;
  bool get _urgent => ReportStore.zoneDIsUrgent && !_resolved;
  bool get _needsAttention =>
      _exists && !_resolved &&
      (_urgent || ReportStore.zoneDManagementAlert);

  @override
  void initState() {
    super.initState();
    AdminStore.syncWithReport();
  }

  void _refresh() {
    AdminStore.syncWithReport();
    setState(() {});
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
    AdminStore.syncWithReport();
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
        onRefresh: () async => _refresh(),
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
            child: const Text('DEMO MODE • SAME-APP DATA',
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

  Widget _alertBanner() => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1ED),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: const Color(0xFFF5BFB1)),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.notifications_active_outlined,
              color: Color(0xFFB83C25), size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_urgent ? 'URGENT WASTE ALERT' : 'MANAGEMENT ALERT',
                  style: const TextStyle(color: Color(0xFF8A2B1A),
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(_urgent
                  ? 'Township Park Zone D needs priority attention.'
                  : 'Zone D has remained unresolved for 2 or more days.',
                  style: const TextStyle(color: Color(0xFF8A2B1A), fontSize: 12)),
            ],
          )),
        ]),
      );

  Widget _reportCard() {
    final status = AdminStore.effectiveStatus;
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
                  '${ReportStore.zoneDReportCount} confirmations'),
              _smallInfo(Icons.schedule_outlined,
                  '${ReportStore.zoneDUnresolvedDays} day(s) unresolved'),
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
        'This dashboard shows Zone D from the in-memory ReportStore. '
        'It is a prototype: no real push notifications, shared database, '
        'separate-device syncing or secure admin sign-in yet.',
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
  late String _status;
  late String _team;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    AdminStore.syncWithReport();
    _status = ReportStore.zoneDResolved ? 'Resolved' :
        AdminStore.zoneDActionStatus;
    _team = AdminStore.zoneDAssignedTeam;
    _notes = TextEditingController(text: AdminStore.zoneDAdminNote);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    AdminStore.update(status: _status, team: _team, note: _notes.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo management update saved.')),
    );
    setState(() {});
  }

  Future<void> _resolve() async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark Zone D as resolved?'),
        content: const Text(
          'This will update the shared demo report. Residents who joined '
          'this hotspot will see it as completed the next time their view refreshes.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resolve')),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    AdminStore.resolve();
    setState(() => _status = 'Resolved');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zone D marked as resolved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exists = ReportStore.zoneDReportCount > 0;
    final resolved = ReportStore.zoneDResolved;
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
          _item('Confirmations', '${ReportStore.zoneDReportCount} unique residents'),
          _item('Days Unresolved', '${ReportStore.zoneDUnresolvedDays}'),
          _item('Priority', resolved ? 'Resolved' :
              ReportStore.zoneDIsUrgent ? 'Urgent' : 'High'),
          _item('Automatic Alert', ReportStore.zoneDManagementAlert ?
              'Triggered (demo)' : 'Not triggered'),
        ]),
        const SizedBox(height: 16),
        _section('Management Actions', [
          const Text('Case status', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: resolved ? 'Resolved' : _status,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: (resolved
                ? ['Resolved']
                : ['Pending Review', 'Under Review', 'In Progress'])
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: resolved || !exists ? null : (s) =>
                setState(() => _status = s ?? _status),
          ),
          const SizedBox(height: 15),
          const Text('Assigned cleaning team',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            value: _team,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: ['Not assigned', 'Cleaning Team A', 'Cleaning Team B',
                    'Maintenance Team']
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: resolved || !exists ? null : (s) =>
                setState(() => _team = s ?? _team),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _notes,
            enabled: !resolved && exists,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Admin notes (demo)',
              hintText: 'Example: Team A scheduled for cleanup',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: green,
                  padding: const EdgeInsets.symmetric(vertical: 13)),
              onPressed: resolved || !exists ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Management Update'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: resolved || !exists ? null : _resolve,
              icon: const Icon(Icons.verified_outlined),
              label: const Text('Mark Case as Resolved'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13)),
            ),
          ),
          if (resolved)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text('This incident is resolved. '
                  'Its record will appear in resident completed history.',
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
