import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class FirebaseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> login() async {
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
  }

 Future<String> createRoom(String playerName) async {
  await login();

  final uid = auth.currentUser!.uid;

  final roomId = const Uuid().v4().substring(0, 6).toUpperCase();

  await firestore.collection("rooms").doc(roomId).set({
    "roomId": roomId,
    "hostId": uid,
    "status": "waiting",
    "createdAt": FieldValue.serverTimestamp(),
    "currentDealerIndex": 0,
    "currentDealerId": uid,
    "roundNumber": 0,
    "players": [
      {
        "uid": uid,
        "name": playerName.isEmpty ? "Player 1" : playerName,
        "position": 1,
      }
    ],
    // ✅ Fixed seating order (will be populated when game starts)
    "seatingOrder": [uid],
    // ✅ প্রাথমিক bidOrder সেট করুন
    "bidOrder": [],
  });

  return roomId;
}

  Future<bool> joinRoom(String roomId, String playerName) async {
    await login();

    final uid = auth.currentUser!.uid;

    final doc = await firestore
        .collection("rooms")
        .doc(roomId)
        .get();

    if (!doc.exists) {
      return false;
    }

    final data = doc.data()!;

    List players = List.from(data["players"]);

    if (players.length >= 4) {
      return false;
    }

    bool alreadyJoined =
        players.any((e) => e["uid"] == uid);

    if (!alreadyJoined) {
      players.add({
        "uid": uid,
        "name": playerName.isEmpty ? "Player ${players.length + 1}" : playerName, // 👈 নাম
        "position": players.length + 1,
      });

      await firestore
          .collection("rooms")
          .doc(roomId)
          .update({
        "players": players,
      });
    }

    return true;
  }
}