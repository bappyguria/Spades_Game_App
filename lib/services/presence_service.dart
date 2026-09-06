import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  static const _heartbeatInterval = Duration(seconds: 8);

  Timer? _heartbeatTimer;
  String? _roomId;
  String? _uid;
  String? _name;
  bool _writeInProgress = false;

  Future<void> start({
    required String roomId,
    required String uid,
    required String name,
  }) async {
    if (_roomId == roomId && _uid == uid && _name == name) return;

    _heartbeatTimer?.cancel();
    _roomId = roomId;
    _uid = uid;
    _name = name;

    await _writeHeartbeat();
    _heartbeatTimer = Timer.periodic(
      _heartbeatInterval,
      (_) => _writeHeartbeat(),
    );
  }

  Future<void> _writeHeartbeat() async {
    final roomId = _roomId;
    final uid = _uid;
    final name = _name;
    if (_writeInProgress || roomId == null || uid == null || name == null) {
      return;
    }

    _writeInProgress = true;
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'presence.$uid.name': name,
        'presence.$uid.lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Keep the last successful timestamp when the network is unavailable.
    } finally {
      _writeInProgress = false;
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _roomId = null;
    _uid = null;
    _name = null;
  }
}
