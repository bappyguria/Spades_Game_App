import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/app_orientation.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
	const SplashScreen({super.key});

	@override
	State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
	@override
	void initState() {
		super.initState();
		AppOrientation.setPortrait();
		Timer(const Duration(milliseconds: 1600), () {
			if (!mounted) return;
			Navigator.pushReplacement(
				context,
				PageRouteBuilder(
					transitionDuration: const Duration(milliseconds: 450),
					pageBuilder: (_, animation, __) => const HomeScreen(),
					transitionsBuilder: (_, animation, __, child) =>
							FadeTransition(opacity: animation, child: child),
				),
			);
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF0A1628),
			body: Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Container(
							width: 112,
							height: 112,
							decoration: BoxDecoration(
								gradient: const LinearGradient(
									colors: [Color(0xFFD4A017), Color(0xFFFFD866)],
								),
								shape: BoxShape.circle,
								boxShadow: [
									BoxShadow(
										color: const Color(0xFFD4A017).withOpacity(0.35),
										blurRadius: 30,
									),
								],
							),
							child: const Center(
								child: Text('🂡', style: TextStyle(fontSize: 52)),
							),
						),
						const SizedBox(height: 24),
						const Text(
							'SPADES GAME',
							style: TextStyle(
								color: Colors.white,
								fontSize: 28,
								fontWeight: FontWeight.bold,
								letterSpacing: 3,
							),
						),
						const SizedBox(height: 10),
						const Text(
							'Play with friends online',
							style: TextStyle(color: Colors.white54, fontSize: 14),
						),
						const SizedBox(height: 28),
						const SizedBox(
							width: 22,
							height: 22,
							child: CircularProgressIndicator(
								strokeWidth: 2,
								color: Color(0xFFD4A017),
							),
						),
					],
				),
			),
		);
	}
}
