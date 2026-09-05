import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/firebase_service.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final FirebaseService _firebaseService;

  RoomBloc({FirebaseService? firebaseService})
      : _firebaseService = firebaseService ?? FirebaseService(),
        super(RoomIdle()) {
    on<CreateRoomRequested>(_onCreateRoom);
    on<JoinRoomRequested>(_onJoinRoom);
    on<StartGameRequested>(_onStartGame);
    on<RoomUpdated>(_onRoomUpdated);
    on<RoomReset>(_onReset);
  }

  Future<void> _onCreateRoom(
    CreateRoomRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());
    try {
      final roomId = await _firebaseService.createRoom(event.playerName);
      emit(RoomCreated(roomId: roomId));
    } catch (e) {
      emit(RoomError(message: e.toString()));
    }
  }

  Future<void> _onJoinRoom(
    JoinRoomRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());
    try {
      final success = await _firebaseService.joinRoom(
        event.roomId,
        event.playerName,
      );
      if (success) {
        emit(RoomJoined(roomId: event.roomId));
      } else {
        emit(const RoomError(message: 'Room not found or full'));
      }
    } catch (e) {
      emit(RoomError(message: e.toString()));
    }
  }

  Future<void> _onStartGame(
    StartGameRequested event,
    Emitter<RoomState> emit,
  ) async {
    emit(RoomLoading());
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(event.roomId)
          .update({
        'status': 'dealing',
        'dealerIndex': event.dealerIndex,
        'roundNumber': event.roundNumber,
        'bids': {},
        'tableCards': [],
        'roundWinner': '',
      });
      emit(RoomStarted(roomId: event.roomId));
    } catch (e) {
      emit(RoomError(message: e.toString()));
    }
  }

  void _onRoomUpdated(RoomUpdated event, Emitter<RoomState> emit) {
    emit(RoomLoaded(roomId: event.roomId, data: event.data));
  }

  void _onReset(RoomReset event, Emitter<RoomState> emit) {
    emit(RoomIdle());
  }

  Stream<RoomState> watchRoom(String roomId) {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return const RoomError(message: 'Room not found');
      return RoomLoaded(
        roomId: roomId,
        data: snapshot.data() as Map<String, dynamic>,
      );
    });
  }
}
