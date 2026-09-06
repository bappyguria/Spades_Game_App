import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/game_service.dart';
import '../../services/turn_service.dart';
import 'game_event.dart';
import 'game_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  final TurnService _turnService;

  GameBloc({
    TurnService? turnService,
  })  : _turnService = turnService ?? TurnService(),
        super(GameInitial()) {
    on<GameStarted>(_onGameStarted);
    on<GameUpdated>(_onGameUpdated);
    on<BidSubmitted>(_onBidSubmitted);
    on<CardPlayed>(_onCardPlayed);
    on<BidDialogDismissed>(_onBidDialogDismissed);
    on<RoundSummaryShown>(_onRoundSummaryShown);
    on<NextRoundRequested>(_onNextRoundRequested);
    on<InitialDistributionRequested>(_onInitialDistributionRequested);
    on<SuitCheckNextRoundRequested>(_onSuitCheckNextRoundRequested);
    on<MissingSuitReported>(_onMissingSuitReported);
    on<ReplayRequested>(_onReplayRequested);
    on<GameReset>(_onGameReset);
  }

  Future<void> _onGameStarted(
    GameStarted event,
    Emitter<GameState> emit,
  ) async {
    emit(GameLoading());
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(event.roomId)
          .get();
      if (snapshot.exists) {
        emit(GameLoaded(
          roomId: event.roomId,
          data: snapshot.data() as Map<String, dynamic>,
        ));
      } else {
        emit(const GameError(message: 'Room not found'));
      }
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  void _onGameUpdated(GameUpdated event, Emitter<GameState> emit) {
    if (state is GameLoaded) {
      emit((state as GameLoaded).copyWith(data: event.data));
    }
  }

  Future<void> _onBidSubmitted(
    BidSubmitted event,
    Emitter<GameState> emit,
  ) async {
    try {
      await _turnService.submitBid(
        roomId: event.roomId,
        uid: event.uid,
        bid: event.bid,
      );
      emit(BidSubmittedSuccess());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  Future<void> _onCardPlayed(
    CardPlayed event,
    Emitter<GameState> emit,
  ) async {
    try {
      await _turnService.playCard(
        roomId: event.roomId,
        uid: event.uid,
        card: event.card,
      );
      emit(CardPlayedSuccess());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  void _onBidDialogDismissed(
    BidDialogDismissed event,
    Emitter<GameState> emit,
  ) {
    if (state is GameLoaded) {
      emit((state as GameLoaded).copyWith(isBidDialogShowing: false));
    }
  }

  void _onRoundSummaryShown(
    RoundSummaryShown event,
    Emitter<GameState> emit,
  ) {
    if (state is GameLoaded) {
      emit((state as GameLoaded).copyWith(hasShownRoundSummary: true));
    }
  }

  Future<void> _onNextRoundRequested(
    NextRoundRequested event,
    Emitter<GameState> emit,
  ) async {
    try {
      await GameService.distributeCards(
        event.roomId,
        event.players,
        playerScores: event.playerScores,
        round: event.round,
        dealerIndex: event.dealerIndex,
        bidOrder: event.bidOrder,
      );
      emit(NextRoundStarted());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  Future<void> _onInitialDistributionRequested(
    InitialDistributionRequested event,
    Emitter<GameState> emit,
  ) async {
    try {
      final roomReference = FirebaseFirestore.instance
          .collection('rooms')
          .doc(event.roomId);
      final roomSnapshot = await roomReference.get();
      final roomData = roomSnapshot.data() ?? {};
      final players = roomData['players'] as List? ?? [];

      final claimedDistribution = await FirebaseFirestore.instance
          .runTransaction<bool>((transaction) async {
        final currentRoom = await transaction.get(roomReference);
        final status = currentRoom.data()?['status']?.toString() ?? '';
        if (status != 'dealing') return false;

        transaction.update(currentRoom.reference, {'status': 'distributing'});
        return true;
      });

      if (claimedDistribution) {
        await GameService.distributeCards(event.roomId, players);
      } else {
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(event.roomId)
            .snapshots()
            .firstWhere((snapshot) {
          final status = snapshot.data()?['status'];
          return status == 'bidding' || status == 'suit_check';
        });
      }

      emit(InitialDistributionCompleted());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  Future<void> _onSuitCheckNextRoundRequested(
    SuitCheckNextRoundRequested event,
    Emitter<GameState> emit,
  ) async {
    try {
      await _turnService.startNextRoundAfterSuitCheck(
        roomId: event.roomId,
        uid: event.uid,
        players: event.players,
      );
      emit(GameActionCompleted());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  Future<void> _onMissingSuitReported(
    MissingSuitReported event,
    Emitter<GameState> emit,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(event.roomId)
          .update({
        'roomMessage': {
          'id': DateTime.now().microsecondsSinceEpoch.toString(),
          'text': '${event.playerName} এর কাছে ১ কার্ড নেই।',
          'senderUid': event.uid,
        },
      });
      emit(GameActionCompleted());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  Future<void> _onReplayRequested(
    ReplayRequested event,
    Emitter<GameState> emit,
  ) async {
    try {
      final roomReference = FirebaseFirestore.instance
          .collection('rooms')
          .doc(event.roomId);
      await roomReference.update({
        'playerScores': {},
        'winner': '',
        'gameOver': false,
        'roundNumber': 0,
        'currentDealerIndex': 0,
      });
      final roomSnapshot = await roomReference.get();
      final players = roomSnapshot['players'] as List;
      await GameService.distributeCards(
        event.roomId,
        players,
        round: 1,
        dealerIndex: 0,
      );
      emit(GameActionCompleted());
    } catch (e) {
      emit(GameError(message: e.toString()));
    }
  }

  void _onGameReset(GameReset event, Emitter<GameState> emit) {
    emit(GameInitial());
  }

  Stream<GameState> watchGame(String roomId) {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return const GameError(message: 'Room not found');
      return GameLoaded(
        roomId: roomId,
        data: snapshot.data() as Map<String, dynamic>,
      );
    });
  }
}
