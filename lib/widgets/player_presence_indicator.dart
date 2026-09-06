import 'package:flutter/material.dart';

class PlayerPresenceIndicator extends StatelessWidget {
  const PlayerPresenceIndicator({super.key, required this.isOnline});

  final bool? isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline == null
        ? Colors.white38
        : isOnline!
        ? Colors.greenAccent
        : Colors.redAccent;
    final icon = isOnline == null
        ? Icons.wifi_find_rounded
        : isOnline!
        ? Icons.wifi_rounded
        : Icons.wifi_off_rounded;

    return Tooltip(
      message: isOnline == null
          ? 'Checking connection'
          : isOnline!
          ? 'Online'
          : 'Offline',
      child: Icon(icon, color: color, size: 15),
    );
  }
}
