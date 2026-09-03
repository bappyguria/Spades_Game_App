# Exact Code Changes - Dealer Rotation Fix

## File 1: lib/services/firebase_service.dart

### Change: Updated createRoom() method

**BEFORE:**
```dart
Future<String> createRoom(String playerName) async {
  await login();

  final uid = auth.currentUser!.uid;

  final roomId = const Uuid().v4().substring(0, 6).toUpperCase();

  await firestore.collection("rooms").doc(roomId).set({
    "roomId": roomId,
    "hostId": uid,
    "status": "waiting",
    "createdAt": FieldValue.serverTimestamp(),
    "dealerIndex": 0,
    "roundNumber": 0,
    "players": [
      {
        "uid": uid,
        "name": playerName.isEmpty ? "Player 1" : playerName,
        "position": 1,
      }
    ],
    // ✅ প্রাথমিক bidOrder সেট করুন
    "bidOrder": [],
  });

  return roomId;
}
```

**AFTER:**
```dart
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
```

---

## File 2: lib/services/game_service.dart

### Change: Updated distributeCards() method

**KEY ADDITIONS:**
```dart
// ✅ Fixed seating order - store UIDs in their positions
final seatingOrder = normalizedPlayers
    .map((p) => p['uid']?.toString() ?? '')
    .where((uid) => uid.isNotEmpty)
    .toList();

// ... in updateData ...
final currentDealerId = dealerIdx < normalizedPlayers.length 
    ? normalizedPlayers[dealerIdx]['uid']?.toString() ?? ''
    : '';

// ... in updateData map ...
'seatingOrder': seatingOrder,
'currentDealerIndex': dealerIdx,
'currentDealerId': currentDealerId,
```

---

## File 3: lib/services/turn_service.dart

### Change 1: Added import

**BEFORE:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'game_service.dart';
```

**AFTER:**
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'game_service.dart';
```

---

### Change 2: Updated _handleRoundCompletion() method

**KEY CHANGES:**
```dart
// ✅ Get fixed seating order and current dealer index
final seatingOrder = (data['seatingOrder'] as List<dynamic>? ?? [])
    .map((e) => e.toString())
    .toList();

if (seatingOrder.isEmpty) {
  debugPrint('❌ ERROR: seatingOrder is empty!');
  return;
}

final currentDealerIndex = (data['currentDealerIndex'] ?? 0) as int;

// ✅ Calculate next dealer using FIXED seating order
final nextDealerIndex = (currentDealerIndex + 1) % seatingOrder.length;
final nextDealerId = seatingOrder[nextDealerIndex];

debugPrint('🔄 Dealer Rotation:');
debugPrint('   Current Dealer Index: $currentDealerIndex');
debugPrint('   Next Dealer Index: $nextDealerIndex');
debugPrint('   Seating Order: $seatingOrder');
debugPrint('   Next Dealer ID: $nextDealerId');

// ✅ নতুন Bid Order (নতুন ডিলারের ডান দিক থেকে)
final newBidOrder = <String>[];
for (int i = 0; i < seatingOrder.length; i++) {
  final idx = (nextDealerIndex + 1 + i) % seatingOrder.length;
  newBidOrder.add(seatingOrder[idx]);
}

final currentDealerId = data['currentDealerId']?.toString() ?? '';
```

---

### Change 3: Updated continueToNextRound() method

**AFTER:**
```dart
Future<void> continueToNextRound({
  required String roomId,
  required String uid,
  required Map<String, dynamic> summary,
  required List<Map<String, dynamic>> players,
}) async {
  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
  final roomDoc = await roomRef.get();
  if (!roomDoc.exists) return;

  final data = roomDoc.data() ?? {};
  final canContinue = data['canContinue']?.toString() ?? '';

  if (canContinue.isEmpty) {
    final newDealerUid = summary['newDealerUid']?.toString() ?? '';
    if (newDealerUid.isNotEmpty) {
      await roomRef.update({'canContinue': newDealerUid});
    }
  }

  if (canContinue != uid) {
    throw Exception('Only the dealer can continue to the next round!');
  }

  await roomRef.update({
    'showSummary': false,
    'roundSummary': null,
    'canContinue': '',
  });

  final newDealerIndex = summary['newDealerIndex'] ?? 0;
  final newDealerUid = summary['newDealerUid']?.toString() ?? '';

  // ✅ নতুন Bid Order (List<dynamic> থেকে List<String> এ রূপান্তর)
  final newBidOrder = (summary['newBidOrder'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();

  // ✅ নতুন First Player (নতুন ডিলারের ডান পাশের প্লেয়ার)
  final seatingOrder = (data['seatingOrder'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  
  final firstPlayerIndex = (newDealerIndex + 1) % seatingOrder.length;
  final firstPlayerUid = firstPlayerIndex < seatingOrder.length 
      ? seatingOrder[firstPlayerIndex]
      : '';

  debugPrint('🎯 Continue to Next Round:');
  debugPrint('   New Dealer Index: $newDealerIndex');
  debugPrint('   New Dealer ID: $newDealerUid');
  debugPrint('   First Player Index: $firstPlayerIndex');
  debugPrint('   First Player ID: $firstPlayerUid');

  // ✅ Atomically update dealer info before distributing cards
  await rotateDealer(
    roomId: roomId,
    newDealerIndex: newDealerIndex,
    newDealerId: newDealerUid,
  );

  await GameService.distributeCards(
    roomId,
    players,
    playerScores: Map<String, int>.from(summary['playerScores'] ?? {}),
    round: summary['roundNumber'] ?? 1,
    firstPlayerUid: firstPlayerUid,
    dealerIndex: newDealerIndex,
    bidOrder: newBidOrder,
  );
}
```

---

### Change 4: Added NEW rotateDealer() method

**NEW METHOD:**
```dart
/// ✅ Dedicated method to rotate dealer to next player
/// Uses fixed seating order for reliable rotation
Future<void> rotateDealer({
  required String roomId,
  required int newDealerIndex,
  required String newDealerId,
}) async {
  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
  
  debugPrint('🔄 rotateDealer() called:');
  debugPrint('   Room ID: $roomId');
  debugPrint('   New Dealer Index: $newDealerIndex');
  debugPrint('   New Dealer ID: $newDealerId');

  try {
    // ✅ Atomic update using Firestore transaction
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomDoc = await transaction.get(roomRef);
      
      if (!roomDoc.exists) {
        throw Exception('Room not found');
      }

      final data = roomDoc.data() ?? {};
      final seatingOrder = (data['seatingOrder'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();

      if (seatingOrder.isEmpty) {
        throw Exception('Invalid seating order');
      }

      // ✅ Validate dealer index
      if (newDealerIndex < 0 || newDealerIndex >= seatingOrder.length) {
        throw Exception('Invalid dealer index: $newDealerIndex');
      }

      // ✅ Validate dealer ID
      final expectedDealerId = seatingOrder[newDealerIndex];
      if (newDealerId != expectedDealerId) {
        debugPrint('⚠️  WARNING: Dealer ID mismatch! Expected: $expectedDealerId, Got: $newDealerId');
      }

      // ✅ Update dealer info atomically
      transaction.update(roomRef, {
        'currentDealerIndex': newDealerIndex,
        'currentDealerId': newDealerId,
      });

      debugPrint('✅ Dealer rotated successfully:');
      debugPrint('   Dealer Index: $newDealerIndex');
      debugPrint('   Dealer ID: $newDealerId');
      debugPrint('   Seating Order: $seatingOrder');
    });
  } catch (e) {
    debugPrint('❌ Error in rotateDealer(): $e');
    rethrow;
  }
}
```

---

## File 4: lib/screens/game_screen.dart

### Change: Updated "Play Again" button to reset dealer

**BEFORE:**
```dart
await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
  'playerScores': {},
  'winner': '',
  'gameOver': false,
  'roundNumber': 0,
});
final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
final players = roomDoc['players'] as List;
await GameService.distributeCards(widget.roomId, players, round: 1, dealerIndex: 0);
```

**AFTER:**
```dart
await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
  'playerScores': {},
  'winner': '',
  'gameOver': false,
  'roundNumber': 0,
  'currentDealerIndex': 0,
});
final roomDoc = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
final players = roomDoc['players'] as List;
await GameService.distributeCards(widget.roomId, players, round: 1, dealerIndex: 0);
```

---

## Summary of Changes

| Field | Before | After |
|-------|--------|-------|
| Dealer tracking | `dealerIndex` (integer) | `currentDealerIndex` (integer) + `currentDealerId` (UID string) |
| Seating order | Derived from players list order (unstable) | Fixed `seatingOrder` array stored in Firebase |
| Dealer rotation location | Scattered logic in _handleRoundCompletion | Dedicated `rotateDealer()` method with transaction |
| Dealer ID lookup | By index in players array | By index in seatingOrder array |
| Bid order calculation | Based on players list order | Based on seatingOrder |

## Database Schema Changes

### Firebase Room Document - Before
```
{
  dealerIndex: 0,
  roundNumber: 0,
  ...
}
```

### Firebase Room Document - After
```
{
  currentDealerIndex: 0,
  currentDealerId: "uid1",
  seatingOrder: ["uid1", "uid2", "uid3", "uid4"],
  roundNumber: 0,
  ...
}
```
