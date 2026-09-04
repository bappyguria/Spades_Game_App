import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'game_service.dart';

class TurnService {
  Future<void> submitBid({
    required String roomId,
    required String uid,
    required int bid,
  }) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) return;

    final data = roomDoc.data() ?? {};
    final players = _normalizePlayers(data['players']);
    final status = data['status']?.toString() ?? '';
    final bids = Map<String, dynamic>.from(data['bids'] ?? {});
    final bidOrder = List<String>.from(data['bidOrder'] ?? []);
    final currentBidTurn = data['bidTurn']?.toString() ?? '';

    if (status != 'bidding' || currentBidTurn != uid) {
      throw Exception('It is not your turn to bid!');
    }

    bids[uid] = bid;
    final nextBidder = GameService.getNextBidder(bidOrder, uid);
    final allBidsDone = bids.length == players.length;

    final updateData = <String, dynamic>{'bids': bids};

    if (allBidsDone) {
      updateData['bidTurn'] = '';
      updateData['status'] = 'playing';
      updateData['currentTurn'] = bidOrder.isNotEmpty ? bidOrder.first : '';
    } else {
      updateData['bidTurn'] = nextBidder;
    }

    await roomRef.update(updateData);
  }

  Future<void> playCard({
    required String roomId,
    required String uid,
    required Map<String, dynamic> card,
  }) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) return;

    final data = roomDoc.data() ?? {};
    final players = _normalizePlayers(data['players']);
    final status = data['status']?.toString() ?? '';
    final currentTurn = data['currentTurn']?.toString() ?? '';
    final gameOver = data['gameOver'] == true;
    final bids = Map<String, dynamic>.from(data['bids'] ?? {});
    final tableCards = List<Map<String, dynamic>>.from(
      (data['tableCards'] is List ? data['tableCards'] as List : <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry)),
    );

    if (status != 'playing' ||
        currentTurn != uid ||
        gameOver ||
        bids.length < players.length) {
      return;
    }

    if (tableCards.any((entry) => entry['uid']?.toString() == uid)) {
      return;
    }

    final hands = <String, dynamic>{
      ...Map<String, dynamic>.from(data['hands'] ?? {}),
    };
    final playerCards = List<Map<String, dynamic>>.from(
      (hands[uid] is List ? hands[uid] as List : <dynamic>[])
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry)),
    );

    final cardSuit = card['suit']?.toString() ?? '';

    if (tableCards.isNotEmpty) {
      final leadSuit =
          (tableCards.first['card'] as Map<String, dynamic>? ?? {})['suit']
              ?.toString() ??
          '';

      final hasLeadSuit = playerCards.any(
        (c) => c['suit']?.toString() == leadSuit,
      );

      if (hasLeadSuit && cardSuit != leadSuit) {
        throw Exception('You must play $leadSuit!');
      }
    }

    playerCards.removeWhere((entry) => _cardKey(entry) == _cardKey(card));
    hands[uid] = playerCards;

    final newTableCards = <Map<String, dynamic>>[
      ...tableCards,
      {'uid': uid, 'card': card},
    ];

    if (newTableCards.length == players.length) {
      final winningUid = _determineTrickWinner(newTableCards);
      final tricks = <String, dynamic>{
        ...Map<String, dynamic>.from(data['tricks'] ?? {}),
      };
      tricks[winningUid] = ((tricks[winningUid] ?? 0) as num).toInt() + 1;

      await roomRef.update({
        'hands': hands,
        'tableCards': newTableCards,
        'trickWinner': winningUid,
        'tricks': tricks,
      });

      await Future.delayed(const Duration(milliseconds: 1200));

      final roundFinished = _isRoundFinished(hands, players);
      if (roundFinished) {
        await _handleRoundCompletion(roomRef, data, players, tricks, bids);
        return;
      }

      await roomRef.update({
        'tableCards': <Map<String, dynamic>>[],
        'trickWinner': '',
        'currentTurn': winningUid,
      });
      return;
    }

    await roomRef.update({
      'hands': hands,
      'tableCards': newTableCards,
      'currentTurn': _nextPlayer(players, uid),
    });
  }

  Future<void> _handleRoundCompletion(
    DocumentReference roomRef,
    Map<String, dynamic> data,
    List<Map<String, dynamic>> players,
    Map<String, dynamic> tricks,
    Map<String, dynamic> bids,
  ) async {
    final playerScores = Map<String, int>.from(data['playerScores'] ?? {});
    final roundNumber = ((data['roundNumber'] as num?)?.toInt() ?? 1) + 1;

    for (final player in players) {
      final uid = player['uid']?.toString() ?? '';
      final bid = int.tryParse(bids[uid]?.toString() ?? '0') ?? 0;
      final taken = int.tryParse(tricks[uid]?.toString() ?? '0') ?? 0;

      int scoreChange;
      if (taken >= bid) {
        scoreChange = bid * 10 + (taken - bid);
      } else {
        scoreChange = -(bid * 10);
      }

      final currentScore = playerScores[uid] ?? 0;
      playerScores[uid] = currentScore + scoreChange;
    }

    String winner = '';
    for (final player in players) {
      final uid = player['uid']?.toString() ?? '';
      if ((playerScores[uid] ?? 0) >= 100) {
        winner = player['name']?.toString() ?? 'Player';
        break;
      }
    }

    if (winner.isNotEmpty) {
      await roomRef.update({
        'playerScores': playerScores,
        'winner': winner,
        'gameOver': true,
        'roundNumber': roundNumber,
        'showSummary': false,
        'roundSummary': null,
        'currentTurn': '',
      });
      return;
    }

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

    final roundSummaryData = {
      'roundNumber': roundNumber,
      'playerScores': playerScores,
      'playerBids': bids,
      'playerTricks': tricks,
      'dealerUid': currentDealerId,
      'newDealerIndex': nextDealerIndex,
      'newDealerUid': nextDealerId,
      'newBidOrder': newBidOrder,
      'targetScore': 100,
    };

    await roomRef.update({
      'playerScores': playerScores,
      'roundSummary': roundSummaryData,
      'showSummary': true,
      'gameOver': false,
      'currentTurn': '',
      'status': 'round_complete',
      'canContinue': nextDealerId,
      'roundNumber': roundNumber,
    });

    await Future.delayed(const Duration(seconds: 5));
    await _startNextRound(
      roomId: roomRef.id,
      summary: roundSummaryData,
      players: players,
    );
  }

  Future<void> _startNextRound({
    required String roomId,
    required Map<String, dynamic> summary,
    required List<Map<String, dynamic>> players,
  }) async {
    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) return;

    final data = roomDoc.data() ?? {};
    if (data['showSummary'] != true) return;

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

    debugPrint('🎯 Starting next round automatically:');
    debugPrint('   New Dealer Index: $newDealerIndex');
    debugPrint('   New Dealer ID: $newDealerUid');
    debugPrint('   First Player Index: $firstPlayerIndex');
    debugPrint('   First Player ID: $firstPlayerUid');

    // ✅ distributeCards will handle dealer update using stable seatingOrder
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

  Future<void> startNextRoundAfterSuitCheck({
    required String roomId,
    required String uid,
    required List<Map<String, dynamic>> players,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final roomRef = firestore.collection('rooms').doc(roomId);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) return;

    final data = roomDoc.data() ?? {};
    final missingPlayers = (data['missingSpadePlayers'] as List<dynamic>? ?? [])
        .map((entry) => entry.toString())
        .toList();
    if (data['status'] != 'suit_check' || !missingPlayers.contains(uid)) {
      return;
    }

    final claimed = await firestore.runTransaction<bool>((transaction) async {
      final currentRoom = await transaction.get(roomRef);
      final currentData = currentRoom.data() ?? {};
      if (currentData['status'] != 'suit_check') return false;
      transaction.update(roomRef, {'status': 'redealing'});
      return true;
    });
    if (!claimed) return;

    final seatingOrder = (data['seatingOrder'] as List<dynamic>? ?? [])
        .map((entry) => entry.toString())
        .toList();
    if (seatingOrder.isEmpty) return;

    final currentDealerIndex =
        (data['currentDealerIndex'] as num?)?.toInt() ?? 0;
    final newDealerIndex = (currentDealerIndex + 1) % seatingOrder.length;
    final firstPlayerIndex = (newDealerIndex + 1) % seatingOrder.length;
    final newBidOrder = <String>[];
    for (int index = 0; index < seatingOrder.length; index++) {
      newBidOrder.add(
        seatingOrder[(newDealerIndex + 1 + index) % seatingOrder.length],
      );
    }

    await GameService.distributeCards(
      roomId,
      players,
      playerScores: Map<String, int>.from(data['playerScores'] ?? {}),
      round: ((data['round'] as num?)?.toInt() ?? 1) + 1,
      firstPlayerUid: seatingOrder[firstPlayerIndex],
      dealerIndex: newDealerIndex,
      bidOrder: newBidOrder,
    );
  }

  // ... বাকি হেল্পার মেথডগুলো একই থাকবে
  String _nextPlayer(List<Map<String, dynamic>> players, String currentUid) {
    final ids = players
        .map((p) => p['uid']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return '';
    final index = ids.indexOf(currentUid);
    return ids[(index + 1) % ids.length];
  }

  String _determineTrickWinner(List<Map<String, dynamic>> tableCards) {
    const rankOrder = {
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      '10': 10,
      'J': 11,
      'Q': 12,
      'K': 13,
      'A': 14,
    };
    final leadCard = (tableCards.first['card'] as Map<String, dynamic>? ?? {});
    final leadSuit = leadCard['suit']?.toString() ?? '';

    final hasSpade = tableCards.any(
      (e) =>
          (e['card'] as Map<String, dynamic>? ?? {})['suit']?.toString() == '♠',
    );

    if (hasSpade) {
      Map<String, dynamic>? winner;
      for (final entry in tableCards) {
        final card = entry['card'] as Map<String, dynamic>? ?? {};
        if (card['suit'] != '♠') continue;
        if (winner == null ||
            (rankOrder[card['rank']] ?? 0) >
                (rankOrder[(winner['card'] as Map)['rank']] ?? 0)) {
          winner = entry;
        }
      }
      return winner?['uid']?.toString() ?? '';
    }

    Map<String, dynamic>? winner;
    for (final entry in tableCards) {
      final card = entry['card'] as Map<String, dynamic>? ?? {};
      final suit = card['suit']?.toString() ?? '';
      final rank = card['rank']?.toString() ?? '';
      if (suit != leadSuit) continue;
      if (winner == null ||
          (rankOrder[rank] ?? 0) >
              (rankOrder[(winner['card'] as Map)['rank']] ?? 0)) {
        winner = entry;
      }
    }
    return winner?['uid']?.toString() ?? '';
  }

  bool _isRoundFinished(
    Map<String, dynamic> hands,
    List<Map<String, dynamic>> players,
  ) {
    for (final p in players) {
      final cards = hands[p['uid']] is List
          ? hands[p['uid']] as List
          : <dynamic>[];
      if (cards.isNotEmpty) return false;
    }
    return true;
  }

  String _cardKey(Map<String, dynamic> card) =>
      '${card['suit']}${card['rank']}';

  List<Map<String, dynamic>> _normalizePlayers(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }
}
