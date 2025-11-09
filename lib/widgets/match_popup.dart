import 'package:flutter/material.dart';
import '../models/dog.dart';

/// 🐾 매칭 성공 팝업 (하트 + 반려견 이미지 + 닫기 버튼 포함)
void showMatchPopup(BuildContext context, Dog dog) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return _AnimatedMatchPopup(
        dog: dog,
        onFinish: () => entry.remove(),
      );
    },
  );

  overlay.insert(entry);
}

class _AnimatedMatchPopup extends StatefulWidget {
  final Dog dog;
  final VoidCallback onFinish;

  const _AnimatedMatchPopup({
    required this.dog,
    required this.onFinish,
  });

  @override
  State<_AnimatedMatchPopup> createState() => _AnimatedMatchPopupState();
}

class _AnimatedMatchPopupState extends State<_AnimatedMatchPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // ✅ 4초 후 자동 닫기
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onFinish();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.55),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Center(
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  // 🎀 메인 카드
                  Container(
                    width: MediaQuery.of(context).size.width * 0.75,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite,
                            color: Colors.pinkAccent, size: 64),
                        const SizedBox(height: 10),

                        // 🎉 매칭 성공
                        const Text(
                          "매칭  성공! 🐾",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.pinkAccent, // 💖 핑크 밑줄
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 🐶 반려견 이미지
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.dog.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.dog.imageUrl,
                                  width: 160,
                                  height: 160,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.pets,
                                  color: Colors.grey, size: 90),
                        ),
                        const SizedBox(height: 14),

                        // 🐾 이름
                        Text(
                          widget.dog.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.pinkAccent,
                            decorationThickness: 2,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // 📋 나이 / 품종
                        Text(
                          "${widget.dog.age}살 / ${widget.dog.breed}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.pinkAccent,
                            decorationThickness: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ❌ 닫기 버튼 (우측 상단)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.grey, size: 28),
                      onPressed: () => widget.onFinish(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
