import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'waiting_room_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final nameController = TextEditingController();
  final FirebaseService service = FirebaseService();
  bool loading = false;
  bool _hasError = false;
  String? _errorText;

  // Design Tokens (Same as JoinRoomScreen)
  static const Color bgBase = Color(0xFF0B1220);
  static const Color bgElevated = Color(0xFF141D2E);
  static const Color bgSurface = Color(0xFF1B2740);
  static const Color accent = Color(0xFFE8A93B);
  static const Color accentSoft = Color(0xFFF3C877);
  static const Color danger = Color(0xFFEF5350);
  static const Color textPrimary = Color(0xFFF5F7FA);
  static const Color textSecondary = Color(0xFFA9B4C6);
  static const Color textMuted = Color(0xFF6B7690);
  static const Color borderSubtle = Color(0x1FFFFFFF);
  static const _radiusLg = 22.0;
  static const _radiusMd = 14.0;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> createRoom() async {
    final playerName = nameController.text.trim();

    if (playerName.isEmpty) {
      setState(() {
        _hasError = true;
        _errorText = "Please enter your name";
      });
      return;
    }

    setState(() {
      loading = true;
      _hasError = false;
      _errorText = null;
    });

    try {
      final roomId = await service.createRoom(playerName);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, __) => WaitingRoomScreen(roomId: roomId),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        _hasError = true;
        _errorText = "Something went wrong. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.height < 700;

    return Scaffold(
      backgroundColor: bgBase,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isSmall ? 20 : 28, vertical: isSmall ? 12 : 20),
              child: Column(
                children: [
                  _buildTopBar(),
                  SizedBox(height: isSmall ? 28 : 48),
                  _buildHeader(isSmall),
                  SizedBox(height: isSmall ? 32 : 44),
                  _buildCreateCard(isSmall),
                  SizedBox(height: isSmall ? 24 : 32),
                  _buildPrivacyNote(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: bgBase),
        child: Stack(
          children: [
            Positioned(top: -120, right: -80, child: _glow(280, accent.withOpacity(0.10))),
            Positioned(bottom: -140, left: -100, child: _glow(320, const Color(0xFF3A6EA5).withOpacity(0.08))),
          ],
        ),
      ),
    );
  }

  Widget _glow(double sizeVal, Color color) {
    return Container(
      width: sizeVal,
      height: sizeVal,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _CircleIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
        const Spacer(),
      ],
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Column(
      children: [
        Container(
          width: isSmall ? 68 : 84,
          height: isSmall ? 68 : 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isSmall ? 20 : 24),
            gradient: const LinearGradient(colors: [accent, accentSoft], begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [BoxShadow(color: accent.withOpacity(0.28), blurRadius: 28, offset: const Offset(0, 12))],
          ),
          child: Center(
            child: Icon(Icons.add_circle_outline_rounded, color: bgBase, size: isSmall ? 30 : 38),
          ),
        ),
        SizedBox(height: isSmall ? 18 : 24),
        Text(
          'Create a Room',
          style: TextStyle(color: textPrimary, fontSize: isSmall ? 24 : 28, fontWeight: FontWeight.w700, letterSpacing: 0.2, height: 1.1),
        ),
        SizedBox(height: isSmall ? 6 : 8),
        Text(
          'Enter your name and start a new game',
          textAlign: TextAlign.center,
          style: TextStyle(color: textSecondary, fontSize: isSmall ? 13 : 14.5, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildCreateCard(bool isSmall) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 20 : 26),
      decoration: BoxDecoration(
        color: bgElevated,
        borderRadius: BorderRadius.circular(_radiusLg),
        border: Border.all(color: borderSubtle, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 16))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player Name Input
          Text('PLAYER NAME', style: TextStyle(color: textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
          const SizedBox(height: 10),
          _buildNameField(isSmall),

          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _errorText != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: danger, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_errorText!, style: const TextStyle(color: danger, fontSize: 12.5, fontWeight: FontWeight.w500)),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(height: isSmall ? 22 : 28),
          _buildCreateButton(isSmall),
        ],
      ),
    );
  }

  Widget _buildNameField(bool isSmall) {
    return Container(
      decoration: BoxDecoration(
        color: bgSurface,
        borderRadius: BorderRadius.circular(_radiusMd),
        border: Border.all(color: _hasError ? danger.withOpacity(0.6) : borderSubtle, width: 1.2),
      ),
      child: TextField(
        controller: nameController,
        textCapitalization: TextCapitalization.words,
        cursorColor: accent,
        style: TextStyle(color: textPrimary, fontSize: isSmall ? 16 : 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: 'Enter your name',
          hintStyle: TextStyle(color: textMuted.withOpacity(0.6), fontSize: isSmall ? 16 : 18),
          counterText: '',
          prefixIcon: Icon(Icons.person_outline_rounded, color: accent, size: isSmall ? 20 : 22),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: isSmall ? 16 : 18, vertical: isSmall ? 14 : 16),
        ),
        onSubmitted: (_) => createRoom(),
      ),
    );
  }

  Widget _buildCreateButton(bool isSmall) {
    return SizedBox(
      width: double.infinity,
      height: isSmall ? 52 : 58,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          disabledBackgroundColor: accent.withOpacity(0.5),
          foregroundColor: bgBase,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusMd)),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(bgBase.withOpacity(0.06)),
        ),
        onPressed: loading ? null : createRoom,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: loading
              ? const SizedBox(key: ValueKey('loading'), width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: bgBase))
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Create Room', style: TextStyle(fontWeight: FontWeight.w700, fontSize: isSmall ? 15 : 16, letterSpacing: 0.3)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 19),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_outlined, color: textMuted, size: 14),
        const SizedBox(width: 6),
        Text('Your game data is secure & encrypted', style: TextStyle(color: textMuted, fontSize: 12, letterSpacing: 0.1)),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x14FFFFFF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, color: Colors.white, size: 18)),
      ),
    );
  }
}