import 'package:cloud_firestore/cloud_firestore.dart';

const playerPresenceTimeout = Duration(seconds: 18);

bool? playerOnline(dynamic rawPresence) {
  if (rawPresence is! Map) return null;

  final lastSeen = rawPresence['lastSeen'];
  final lastSeenAt = lastSeen is Timestamp
      ? lastSeen.toDate()
      : lastSeen is DateTime
      ? lastSeen
      : null;
  if (lastSeenAt == null) return null;

  return DateTime.now().difference(lastSeenAt) <= playerPresenceTimeout;
}
