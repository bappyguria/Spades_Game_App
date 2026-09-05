abstract class RoomEvent {
  const RoomEvent();
}

class CreateRoomRequested extends RoomEvent {
  final String playerName;
  const CreateRoomRequested({required this.playerName});
}

class JoinRoomRequested extends RoomEvent {
  final String roomId;
  final String playerName;
  const JoinRoomRequested({
    required this.roomId,
    required this.playerName,
  });
}

class StartGameRequested extends RoomEvent {
  final String roomId;
  final int dealerIndex;
  final int roundNumber;
  const StartGameRequested({
    required this.roomId,
    this.dealerIndex = 0,
    this.roundNumber = 1,
  });
}

class RoomUpdated extends RoomEvent {
  final String roomId;
  final Map<String, dynamic> data;
  const RoomUpdated({
    required this.roomId,
    required this.data,
  });
}

class RoomReset extends RoomEvent {}
