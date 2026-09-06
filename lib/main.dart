import 'package:app/core/bloc/auth_bloc.dart';
import 'package:app/core/bloc/auth_event.dart';
import 'package:app/core/bloc/auth_state.dart';
import 'package:app/core/bloc/game_bloc.dart';
import 'package:app/core/bloc/room_bloc.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/utils/app_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppOrientation.setPortrait();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(AuthInitialized()),
        ),
        BlocProvider<RoomBloc>(create: (context) => RoomBloc()),
        BlocProvider<GameBloc>(create: (context) => GameBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Real Spades Game",
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Scaffold(
                backgroundColor: Color(0xFF0A1628),
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4A017)),
                ),
              );
            }
            return const SplashScreen();
          },
        ),
      ),
    );
  }
}
