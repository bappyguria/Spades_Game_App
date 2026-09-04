import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'card_service.dart';

class GameService {
  static const int targetScore = 100; // 🎯 টার্গেট ১০০

  static Future<void> distributeCards(
    String roomId,
    List players, {
    Map<String, int>? playerScores,
    int round = 1,
    String? firstPlayerUid,
    int? dealerIndex,
    List<String>? bidOrder,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // ✅ Always read latest players list from Firebase to ensure consistent order
    final roomDoc = await firestore.collection('rooms').doc(roomId).get();
    final roomData = roomDoc.data() ?? {};

    final List<dynamic> firebasePlayers = roomData['players'] ?? [];

    final normalizedPlayers = firebasePlayers
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();

    debugPrint('📋 distributeCards called:');
    debugPrint('   Round: $round');
    debugPrint('   Players from Firebase:');
    for (int i = 0; i < normalizedPlayers.length; i++) {
      debugPrint(
        '     [$i] ${normalizedPlayers[i]['uid']} - ${normalizedPlayers[i]['name']}',
      );
    }

    final deck = CardService.shuffleDeck();
    final hands = <String, dynamic>{};

    for (
      int index = 0;
      index < normalizedPlayers.length && index < 4;
      index++
    ) {
      final uid = normalizedPlayers[index]['uid']?.toString() ?? '';
      if (uid.isEmpty) continue;

      hands[uid] = deck
          .sublist(index * 13, (index + 1) * 13)
          .map((card) => card.toJson())
          .toList();
    }

    // ✅ Create seating order from Firebase players order (stable reference)
    final seatingOrder = normalizedPlayers
        .map((p) => p['uid']?.toString() ?? '')
        .where((uid) => uid.isNotEmpty)
        .toList();

    // ✅ ডিলারের ডান সাইডের প্লেয়ার প্রথম হবে
    final dealerIdx = dealerIndex ?? 0;

    if (dealerIdx < 0 || dealerIdx >= seatingOrder.length) {
      debugPrint(
        '❌ ERROR: Invalid dealer index $dealerIdx for seating order length ${seatingOrder.length}',
      );
      return;
    }

    final firstPlayerIndex = (dealerIdx + 1) % seatingOrder.length;
    final startPlayerUid = firstPlayerUid ?? seatingOrder[firstPlayerIndex];

    debugPrint('🎮 Seating & Bid Setup:');
    debugPrint('   Seating Order: $seatingOrder');
    debugPrint('   Dealer Index: $dealerIdx');
    debugPrint('   Dealer UID: ${seatingOrder[dealerIdx]}');
    debugPrint('   First Player Index (Bidder): $firstPlayerIndex');
    debugPrint('   First Player UID (Bidder): $startPlayerUid');

    // ✅ Bid Order (ডিলারের ডান দিক থেকে শুরু করে clockwise)
    final List<String> finalBidOrder;
    if (bidOrder != null && bidOrder.isNotEmpty) {
      finalBidOrder = bidOrder;
      debugPrint('   Using provided bid order: $finalBidOrder');
    } else {
      finalBidOrder = <String>[];
      for (int i = 0; i < seatingOrder.length; i++) {
        final idx = (dealerIdx + 1 + i) % seatingOrder.length;
        finalBidOrder.add(seatingOrder[idx]);
      }
      debugPrint('   Generated bid order: $finalBidOrder');
    }

    // ✅ Get dealer ID from seating order
    final currentDealerId = seatingOrder[dealerIdx];
    final missingSpadePlayers = <String>[];
    for (final entry in hands.entries) {
      final cards = (entry.value as List<dynamic>? ?? []).whereType<Map>().map(
        (card) => Map<String, dynamic>.from(card),
      );
      if (!cards.any((card) => card['suit']?.toString() == '♠')) {
        missingSpadePlayers.add(entry.key);
      }
    }

    final updateData = {
      'hands': hands,
      'currentTurn': startPlayerUid, // ✅ ডিলারের ডান পাশের প্লেয়ার প্রথম খেলবে
      'tableCards': [],
      'bids': {},
      'tricks': {},
      'playerScores': playerScores ?? {},
      'targetScore': targetScore,
      'winner': '',
      'gameOver': false,
      'status': missingSpadePlayers.isEmpty ? 'bidding' : 'suit_check',
      'round': round,
      'showSummary': false,
      'bidTurn': startPlayerUid, // ✅ ডিলারের ডান পাশের প্লেয়ার প্রথম বিড করবে
      'bidOrder': finalBidOrder,
      'roundSummary': null,
      'canContinue': '',
      // ✅ Store fixed seating order and current dealer info
      'seatingOrder': seatingOrder,
      'currentDealerIndex': dealerIdx,
      'currentDealerId': currentDealerId,
      'missingSpadePlayers': missingSpadePlayers,
    };

    debugPrint('✅ Updating Firebase with game data');
    await firestore.collection('rooms').doc(roomId).update(updateData);
  }

  static String getNextBidder(List<String> bidOrder, String currentBidder) {
    final index = bidOrder.indexOf(currentBidder);
    if (index < 0) return bidOrder.first;
    return bidOrder[(index + 1) % bidOrder.length];
  }
}
