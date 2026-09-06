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
					pageBuilder: (_, animation, _) => const HomeScreen(),
					transitionsBuilder: (_, animation, _, child) =>
							FadeTransition(opacity: animation, child: child),
				),
			);
		});
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: const Color(0xFF080C16),
			body: Stack(
				children: [
					Positioned.fill(
						child: DecoratedBox(
							decoration: BoxDecoration(
								gradient: RadialGradient(
									center: const Alignment(0, -0.35),
									radius: 1.15,
									colors: [
										const Color(0xFF173657).withValues(alpha: 0.75),
										const Color(0xFF0C1728).withValues(alpha: 0.7),
										const Color(0xFF080C16),
									],
								),
							),
						),
					),
					Positioned(
						top: 54,
						left: 28,
										child: Icon(Icons.auto_awesome, color: Colors.white.withValues(alpha: 0.16), size: 20),
					),
					Positioned(
						top: 116,
						right: 34,
										child: Icon(Icons.circle_outlined, color: const Color(0xFFFFD866).withValues(alpha: 0.25), size: 28),
					),
					Center(
						child: TweenAnimationBuilder<double>(
							duration: const Duration(milliseconds: 900),
							tween: Tween(begin: 0.92, end: 1),
							curve: Curves.easeOutBack,
							builder: (context, scale, child) => Transform.scale(
								scale: scale,
								child: child,
							),
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									Container(
										width: 148,
										height: 148,
										padding: const EdgeInsets.all(9),
										decoration: BoxDecoration(
											shape: BoxShape.circle,
											gradient: const LinearGradient(
												begin: Alignment.topLeft,
												end: Alignment.bottomRight,
												colors: [Color(0xFFFFE39A), Color(0xFFD4A017)],
											),
											boxShadow: [
														BoxShadow(color: const Color(0xFFD4A017).withValues(alpha: 0.3), blurRadius: 34, spreadRadius: 5),
											],
										),
										child: Container(
											padding: const EdgeInsets.all(18),
											decoration: const BoxDecoration(
												color: Color(0xFF101A29),
												shape: BoxShape.circle,
											),
											child: Image.asset('assets/images/Spades_logo.png', fit: BoxFit.contain),
										),
									),
									const SizedBox(height: 28),
									const Text(
										'SPADES GAME',
										style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w800, letterSpacing: 4),
									),
									const SizedBox(height: 10),
									Row(
										mainAxisSize: MainAxisSize.min,
										children: [
											Container(width: 28, height: 1, color: const Color(0xFFD4A017)),
											const Padding(
												padding: EdgeInsets.symmetric(horizontal: 10),
												child: Text('PLAY. BID. WIN.', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 2.2)),
											),
											Container(width: 28, height: 1, color: const Color(0xFFD4A017)),
										],
									),
									const SizedBox(height: 36),
									const SizedBox(
										width: 30,
										height: 30,
										child: CircularProgressIndicator(
											strokeWidth: 2.5,
											color: Color(0xFFFFD866),
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}
}
