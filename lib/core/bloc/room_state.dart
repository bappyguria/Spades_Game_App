abstract class RoomState {
  const RoomState();
}

class RoomIdle extends RoomState {}

class RoomLoading extends RoomState {}

class RoomCreated extends RoomState {
  final String roomId;
  const RoomCreated({required this.roomId});
}

class RoomJoined extends RoomState {
  final String roomId;
  const RoomJoined({required this.roomId});
}

class RoomLoaded extends RoomState {
  final String roomId;
  final Map<String, dynamic> data;
  const RoomLoaded({
    required this.roomId,
    required this.data,
  });
}

class RoomStarted extends RoomState {
  final String roomId;
  const RoomStarted({required this.roomId});
}

class RoomError extends RoomState {
  final String message;
  const RoomError({required this.message});
}
