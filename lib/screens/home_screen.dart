import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import '../models/dog.dart';
import '../services/match_service.dart';
import '../widgets/dog_card.dart';
import '../widgets/app_logo.dart';
import '../widgets/match_popup.dart'; // ✅ 매칭 팝업 위젯

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<Dog> dogs = [];
  bool isLoading = true;
  bool locationDenied = false;

  @override
  void initState() {
    super.initState();
    _requestLocationFirst();
    loadNearbyDogs();
  }

  /// 📍 위치 권한 요청
  Future<void> _requestLocationFirst() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  /// 🔍 근처 강아지 목록 불러오기
  Future<void> loadNearbyDogs() async {
    try {
      setState(() => isLoading = true);

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationDenied = true;
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            locationDenied = true;
            isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationDenied = true;
          isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final fetchedDogs = await MatchService.getNearbyDogs(
        userLat: position.latitude,
        userLng: position.longitude,
        maxDistanceKm: 1000,
      );

      setState(() {
        dogs = fetchedDogs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading nearby dogs: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 로딩 중
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// 위치 권한 거부
    if (locationDenied) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  "📍 위치 접근 권한이 필요합니다",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "근처 반려견을 찾기 위해 위치 접근 권한을 허용해주세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    "설정에서 허용하기",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// 주변 강아지 없음
    if (dogs.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            "근처에 등록된 강아지가 없습니다 🐾",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    /// ✅ 정상 화면
    return Scaffold(
      backgroundColor: Colors.white, // ✅ 전체 흰색 배경
      appBar: AppBar(
        title: const AppLogo(fontSize: 28, color: Colors.black),
        centerTitle: true,
        backgroundColor: Colors.white, // ✅ 상단도 흰색
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // ✅ body 내부까지 완전 흰색 통일
        child: Column(
          children: [
            // 🐶 카드 스와이프
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: dogs.length,
                numberOfCardsDisplayed: 1,
                isLoop: true,
                onSwipe: (previousIndex, currentIndex, direction) async {
                  final dog = dogs[previousIndex];

                  if (direction == CardSwiperDirection.right) {
                    debugPrint("❤️ 좋아요: ${dog.name}");
                    await MatchService.handleSwipe(dog, true);

                    // ✅ 매칭 성공 팝업
                    if (mounted) showMatchPopup(context, dog);
                  } else if (direction == CardSwiperDirection.left) {
                    debugPrint("💔 싫어요: ${dog.name}");
                    await MatchService.handleSwipe(dog, false);
                  }

                  return true;
                },
                cardBuilder: (context, index, percentX, percentY) {
                  return DogCard(dog: dogs[index]);
                },
              ),
            ),

            // ❤️ 좋아요 / 싫어요 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: "dislike",
                    backgroundColor: Colors.grey,
                    onPressed: () => controller.swipeLeft(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: "like",
                    backgroundColor: Colors.pinkAccent,
                    onPressed: () => controller.swipeRight(),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
