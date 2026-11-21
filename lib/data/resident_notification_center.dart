import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// In-app Resident notifications for the current login session.
/// The listener uses the existing hotspots/zone_d document, so no new
/// Firestore collection, index, or security rule is needed.
///
/// Important: this is NOT a background phone push-notification service.
class ResidentNotice {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime receivedAt;
  bool isRead;

  ResidentNotice({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.receivedAt,
    this.isRead = false,
  });
}

class ResidentNotificationCenter extends ChangeNotifier {
  static const green = Color(0xFF16875B);
  static const dark = Color(0xFF143D2C);

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _zoneSubscription;
  Map<String, dynamic>? _previousZone;
  String? _currentUid;
  bool _ready = false;
  bool _disposed = false;
  final List<ResidentNotice> _notices = <ResidentNotice>[];

  /// Called by the Resident shell to show a six-second TOP banner.
  ValueChanged<ResidentNotice>? onBanner;

  List<ResidentNotice> get notices => List<ResidentNotice>.unmodifiable(_notices);
  int get unreadCount => _notices.where((e) => !e.isRead).length;

  void start() {
    if (_ready) return;
    _ready = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _currentUid = uid;
    if (uid == null) return;

    _zoneSubscription = FirebaseFirestore.instance
        .collection('hotspots')
        .doc('zone_d')
        .snapshots()
        .listen((snapshot) {
      if (_disposed || FirebaseAuth.instance.currentUser?.uid != uid) return;
      final current = snapshot.data();
      final old = _previousZone;
      _previousZone = current == null
          ? null
          : Map<String, dynamic>.from(current);

      // First snapshot is a baseline, not a new event. This prevents a
      // misleading pop-up every time the Resident opens the application.
      if (old == null || current == null) return;
      final incidentId = (current['incidentId'] as String?) ?? '';
      final oldIncidentId = (old['incidentId'] as String?) ?? '';
      if (incidentId.isEmpty || incidentId != oldIncidentId) return;

      // Only the users who confirmed this incident can receive its private
      // management updates, even though the hotspot itself is public.
      final participants = List<String>.from(
          current['reporterUids'] ?? const <String>[]);
      if (!participants.contains(uid)) return;

      final nowResolved = current['resolved'] == true;
      final wasResolved = old['resolved'] == true;
      final oldStatus = (old['status'] as String?) ?? '';
      final newStatus = (current['status'] as String?) ?? '';
      final oldTeam = (old['assignedTeam'] as String?) ?? '';
      final newTeam = (current['assignedTeam'] as String?) ?? '';
      final oldNote = (old['adminNote'] as String?) ?? '';
      final newNote = (current['adminNote'] as String?) ?? '';

      // Build all useful bell entries; display only the highest-priority
      // banner for one Firestore change so messages do not flicker.
      ResidentNotice? primary;
      if (!wasResolved && nowResolved) {
        primary = _add(
          id: '$uid:$incidentId:resolved',
          title: 'REPORT RESOLVED',
          message: 'Township management has resolved your Zone D waste report.',
          type: 'resolved',
          banner: false,
        );
      }
      if (newStatus != oldStatus && newStatus.isNotEmpty &&
          !(nowResolved && !wasResolved)) {
        final item = _add(
          id: '$uid:$incidentId:status:$newStatus',
          title: 'REPORT STATUS UPDATED',
          message: 'Your Zone D report status is now "$newStatus".',
          type: 'status',
          banner: false,
        );
        primary ??= item;
      }
      if (newTeam != oldTeam && newTeam.trim().isNotEmpty &&
          newTeam != 'Not assigned') {
        final item = _add(
          id: '$uid:$incidentId:team:$newTeam',
          title: 'CLEANING TEAM ASSIGNED',
          message: '$newTeam has been assigned to your Zone D report.',
          type: 'team',
          banner: false,
        );
        primary ??= item;
      }
      if (newNote != oldNote && newNote.trim().isNotEmpty) {
        final item = _add(
          id: '$uid:$incidentId:note:${newNote.hashCode}',
          title: 'MESSAGE FROM MANAGEMENT',
          message: newNote,
          type: 'message',
          banner: false,
        );
        primary ??= item;
      }
      if (primary != null) onBanner?.call(primary);
    }, onError: (Object error) {
      // A missing connection should not interrupt Resident pages.
      debugPrint('Resident notification listener: $error');
    });
  }

  /// Call only after the Camera report dialog has completed successfully.
  /// This is deliberately separate from the Firestore stream to guarantee
  /// the success banner appears AFTER returning to Home from Camera.
  void reportSubmitted() {
    final uid = _currentUid;
    if (uid == null || _disposed) return;
    final incident = (_previousZone?['incidentId'] as String?) ?? '';
    final firstReporter = (_previousZone?['firstReporterUid'] as String?) ?? '';
    final merged = firstReporter.isNotEmpty && firstReporter != uid;
    _add(
      id: '$uid:${incident.isEmpty ? DateTime.now().millisecondsSinceEpoch : incident}:submitted',
      title: merged ? 'REPORT CONFIRMED' : 'REPORT SUBMITTED',
      message: merged
          ? 'Your confirmation was merged into the existing Zone D hotspot. You can track it under Progress.'
          : 'Your Zone D waste report was submitted successfully. You can track it under Progress.',
      type: merged ? 'merged' : 'submitted',
    );
  }

  ResidentNotice? _add({
    required String id,
    required String title,
    required String message,
    required String type,
    bool banner = true,
  }) {
    if (_disposed || _notices.any((e) => e.id == id)) return null;
    final notice = ResidentNotice(
      id: id,
      title: title,
      message: message,
      type: type,
      receivedAt: DateTime.now(),
    );
    _notices.insert(0, notice);
    if (_notices.length > 40) _notices.removeRange(40, _notices.length);
    notifyListeners();
    if (banner) onBanner?.call(notice);
    return notice;
  }

  void markRead(ResidentNotice notice) {
    if (notice.isRead || _disposed) return;
    notice.isRead = true;
    notifyListeners();
  }

  void markAllRead() {
    if (_disposed) return;
    for (final notice in _notices) {
      notice.isRead = true;
    }
    notifyListeners();
  }

  static Color colorFor(String type) {
    if (type == 'message') return const Color(0xFFB66D13);
    return green;
  }

  static IconData iconFor(String type) {
    switch (type) {
      case 'submitted': return Icons.add_location_alt_rounded;
      case 'merged': return Icons.groups_rounded;
      case 'status': return Icons.tune_rounded;
      case 'resolved': return Icons.verified_rounded;
      case 'team': return Icons.groups_rounded;
      case 'message': return Icons.mark_unread_chat_alt_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  static String formatTime(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.day)}/${two(time.month)}  ${two(time.hour)}:${two(time.minute)}';
  }

  @override
  void dispose() {
    _disposed = true;
    _zoneSubscription?.cancel();
    onBanner = null;
    super.dispose();
  }
}

/// Shared bell: placed by MainScreen over Home, Community, and Progress.
/// The bottom sheet receives updates while it is open.
class ResidentNotificationBell extends StatelessWidget {
  final ResidentNotificationCenter center;
  const ResidentNotificationBell({super.key, required this.center});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: center,
      builder: (context, child) => Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 1,
            child: IconButton(
              tooltip: 'Resident notifications',
              icon: const Icon(Icons.notifications_none_rounded,
                  color: ResidentNotificationCenter.green),
              onPressed: () => _openNotifications(context),
            ),
          ),
          if (center.unreadCount > 0)
            Positioned(
              top: -2,
              right: -3,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFB3261E),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    center.unreadCount > 99 ? '99+' : '${center.unreadCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    var showUnreadOnly = false;
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
                padding: const EdgeInsets.fromLTRB(18, 18, 10, 6),
                child: Row(children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: ResidentNotificationCenter.green),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('My Notifications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                          color: ResidentNotificationCenter.dark))),
                  TextButton(
                    onPressed: center.markAllRead,
                    child: const Text('Mark all read'),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !showUnreadOnly,
                    onSelected: (_) => setSheetState(() => showUnreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread'),
                    selected: showUnreadOnly,
                    onSelected: (_) => setSheetState(() => showUnreadOnly = true),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(child: AnimatedBuilder(
                animation: center,
                builder: (context, child) {
                  final visible = center.notices.where(
                      (n) => !showUnreadOnly || !n.isRead).toList();
                  if (visible.isEmpty) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No notifications to show.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    ));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 5, 14, 22),
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = visible[index];
                      return Material(
                        color: item.isRead ? Colors.white : const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => center.markRead(item),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(ResidentNotificationCenter.iconFor(item.type),
                                    color: ResidentNotificationCenter.colorFor(item.type)),
                                const SizedBox(width: 12),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Expanded(child: Text(item.title,
                                          style: const TextStyle(fontSize: 13,
                                              fontWeight: FontWeight.w800))),
                                      if (!item.isRead)
                                        const CircleAvatar(radius: 4,
                                            backgroundColor: Color(0xFF16875B)),
                                    ]),
                                    const SizedBox(height: 4),
                                    Text(item.message,
                                        style: const TextStyle(fontSize: 12,
                                            color: Color(0xFF52625A), height: 1.35)),
                                    const SizedBox(height: 6),
                                    Text(ResidentNotificationCenter.formatTime(item.receivedAt),
                                        style: const TextStyle(fontSize: 10,
                                            color: Colors.grey)),
                                  ],
                                )),
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
}
