import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Independent experiment: test two browser windows connected to the SAME
/// local Python + SQLite server without changing the main WasteHotspot app.
/// Run: flutter run -d chrome --web-port 51515 -t lib/connected_demo_main.dart
const apiBase = 'http://127.0.0.1:5000';
const green = Color(0xFF16875B);
const darkGreen = Color(0xFF153B2A);

void main() => runApp(const WasteHotspotConnectedDemo());

class WasteHotspotConnectedDemo extends StatelessWidget {
  const WasteHotspotConnectedDemo({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'WasteHotspot AI • Connected Prototype',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: green),
          scaffoldBackgroundColor: const Color(0xFFF3F8F5),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        ),
        home: const ConnectedHome(),
      );
}

class ConnectedHome extends StatefulWidget {
  const ConnectedHome({super.key});

  @override
  State<ConnectedHome> createState() => _ConnectedHomeState();
}

class _ConnectedHomeState extends State<ConnectedHome> {
  final residentController = TextEditingController(text: 'residentA');
  final noteController = TextEditingController();
  Timer? timer;
  Map<String, dynamic>? report;
  bool admin = false;
  bool online = false;
  bool loading = false;
  bool fetching = false;
  String message = '';
  String team = 'Cleaning Team A';

  @override
  void initState() {
    super.initState();
    refresh();
    timer = Timer.periodic(const Duration(milliseconds: 1200), (_) => refresh());
  }

  @override
  void dispose() {
    timer?.cancel();
    residentController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> api(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$apiBase$path');
    late http.Response response;
    final headers = {'Content-Type': 'application/json'};
    if (method == 'POST') {
      response = await http.post(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 4));
    } else if (method == 'PATCH') {
      response = await http.patch(uri, headers: headers, body: jsonEncode(body ?? {})).timeout(const Duration(seconds: 4));
    } else {
      response = await http.get(uri).timeout(const Duration(seconds: 4));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(data['error'] ?? 'Server error ${response.statusCode}');
    }
    return data;
  }

  Future<void> refresh() async {
    if (fetching || loading) return;
    fetching = true;
    try {
      final result = await api('/api/state');
      if (mounted) {
        setState(() {
          online = true;
          report = result['report'] as Map<String, dynamic>?;
        });
      }
    } catch (_) {
      if (mounted) setState(() => online = false);
    } finally {
      fetching = false;
    }
  }

  Future<void> act(String path, {String method = 'POST', Map<String, dynamic>? body, String success = 'Updated'}) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final result = await api(path, method: method, body: body);
      if (mounted) {
        setState(() {
          online = true;
          report = result['report'] as Map<String, dynamic>?;
          message = path == '/api/reports'
              ? 'Report submitted • +${result['earned_points']} EcoPoints (demo)'
              : success;
        });
      }
    } catch (e) {
      if (mounted) setState(() => message = 'Error: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget action(String label, VoidCallback? onPressed, {IconData icon = Icons.check_circle_outline, bool outline = false}) =>
      SizedBox(width: double.infinity, child: outline
          ? OutlinedButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)))
          : FilledButton.icon(onPressed: onPressed, icon: Icon(icon), label: Text(label),
              style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14))));

  Widget section(String title, List<Widget> content) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 13),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(21),
            border: Border.all(color: const Color(0xFFE0EDE3)),
            boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 14, offset: Offset(0, 5))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: darkGreen, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12), ...content,
        ]),
      );

  Widget labelValue(String left, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 122, child: Text(left, style: const TextStyle(color: Colors.black54, fontSize: 12))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        ]),
      );

  Widget statusCard() {
    if (report == null) {
      return section('Zone D Report', [
        const Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
        const SizedBox(height: 8),
        const Text('No report yet. Submit one from Resident Mode.'),
      ]);
    }
    final r = report!;
    final resolved = r['resolved'] == true;
    final urgent = r['urgent'] == true;
    return section('Township Park — Zone D', [
      Align(alignment: Alignment.centerLeft,
        child: Chip(label: Text(resolved ? 'RESOLVED' : urgent ? 'URGENT' : 'ACTIVE'),
            backgroundColor: resolved ? const Color(0xFFDDF7E8) : urgent ? const Color(0xFFFFE8E8) : const Color(0xFFFFF3DE))),
      labelValue('Report status', '${r['status']}'),
      labelValue('Confirmations', '${r['confirmations']} resident(s)'),
      labelValue('Days unresolved', '${r['days']} day(s)'),
      labelValue('Assigned team', '${r['team']}'),
      if ((r['note'] as String? ?? '').isNotEmpty) labelValue('Admin note', '${r['note']}'),
      labelValue('Management alert', r['alert'] == true ? 'Triggered' : 'Not yet'),
    ]);
  }

  Widget residentView() => Column(children: [
    section('Report Public Waste', [
      const Text('Township Park — Zone D', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 5),
      const Text('This is a simulated waste scan for your NPD prototype.',
          style: TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 15),
      TextField(controller: residentController, decoration: const InputDecoration(
        prefixIcon: Icon(Icons.person_outline), labelText: 'Resident name (example: residentA)')),
      const SizedBox(height: 14),
      action('Submit Zone D Report', loading ? null : () => act('/api/reports', body: {'resident': residentController.text.trim()}),
          icon: Icons.photo_camera_outlined),
      const SizedBox(height: 8),
      const Text('Try a second resident name to confirm the same hotspot (+3 points).',
          style: TextStyle(fontSize: 11, color: Colors.black54)),
    ]),
    statusCard(),
  ]);

  Widget adminView() => Column(children: [
    section('Incoming Waste Alerts', [
      Text(report == null ? 'No active reports received yet.' :
        report!['alert'] == true ? 'Urgent or overdue waste needs attention.' :
        'A resident has reported waste at Zone D.',
        style: const TextStyle(fontSize: 13)),
      const SizedBox(height: 8),
      const Text('Updates appear automatically from the same laptop server.',
          style: TextStyle(fontSize: 12, color: Colors.black54)),
    ]),
    statusCard(),
    if (report != null && report!['resolved'] != true)
      section('Management Actions', [
        DropdownButtonFormField<String>(
          value: team,
          decoration: const InputDecoration(labelText: 'Assign cleaning team'),
          items: ['Cleaning Team A', 'Cleaning Team B', 'Maintenance Team']
              .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setState(() => team = v ?? team),
        ),
        const SizedBox(height: 12),
        TextField(controller: noteController,
            decoration: const InputDecoration(labelText: 'Admin note (optional)'), maxLines: 2),
        const SizedBox(height: 12),
        action('Mark Under Review', loading ? null : () => act('/api/report', method: 'PATCH',
            body: {'status': 'Under Review', 'team': team, 'note': noteController.text}, success: 'Under Review saved'),
            icon: Icons.search_outlined, outline: true),
        const SizedBox(height: 7),
        action('Mark In Progress', loading ? null : () => act('/api/report', method: 'PATCH',
            body: {'status': 'In Progress', 'team': team, 'note': noteController.text}, success: 'In Progress saved'),
            icon: Icons.handyman_outlined),
        const SizedBox(height: 7),
        action('Mark Resolved', loading ? null : () => act('/api/report', method: 'PATCH',
            body: {'status': 'Resolved', 'team': team, 'note': noteController.text}, success: 'Zone D resolved'),
            icon: Icons.verified_outlined, outline: true),
      ]),
    if (report != null && report!['resolved'] != true)
      section('Escalation Test', [
        action('Simulate Next Day', loading ? null : () => act('/api/next-day', success: 'One day added'),
            icon: Icons.schedule, outline: true),
      ]),
  ]);

  Future<void> confirmReset() async {
    final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Reset test reports?'),
      content: const Text('This deletes the local demo incident so you can try again.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
      ],
    ));
    if (yes == true) await act('/api/reset', success: 'Demo reset completed');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('WasteHotspot AI', style: TextStyle(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.white,
          actions: [
            IconButton(onPressed: refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
            IconButton(onPressed: confirmReset, icon: const Icon(Icons.restart_alt), tooltip: 'Reset demo'),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Container(padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [darkGreen, green]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [Icon(Icons.eco, color: Colors.white), SizedBox(width: 8),
                      Expanded(child: Text('WasteHotspot AI • Connected Demo',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)))]),
                    const SizedBox(height: 10),
                    Text(admin ? 'ADMIN MODE' : 'RESIDENT MODE',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFD6F9E4), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Row(children: [
                      Icon(online ? Icons.wifi : Icons.wifi_off,
                          color: online ? Colors.white : const Color(0xFFFFDD8F), size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text(online ? 'Connected to local Python server' : 'Server offline — start backend/server.py',
                          style: const TextStyle(color: Colors.white, fontSize: 11))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 14),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Resident'), icon: Icon(Icons.person_outline)),
                    ButtonSegment(value: true, label: Text('Admin'), icon: Icon(Icons.admin_panel_settings_outlined)),
                  ],
                  selected: {admin},
                  onSelectionChanged: (v) => setState(() { admin = v.first; message = ''; }),
                ),
                const SizedBox(height: 14),
                if (message.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(bottom: 12),
                    child: Text(message, style: const TextStyle(color: darkGreen, fontWeight: FontWeight.w600))),
                if (admin) adminView() else residentView(),
                const SizedBox(height: 18),
                const Text('Local demo only • no Firebase • no real GPS/AI • not secured for public access',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.black54)),
              ]),
            ),
          ),
        ),
      );
}
