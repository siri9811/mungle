import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import '../models/dog.dart';
import '../services/match_service.dart';
import '../widgets/dog_card.dart';
import '../widgets/app_logo.dart';

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
    loadNearbyDogs();
  }

  /// 📍 위치 권한 요청 + 거리 기반 강아지 리스트 불러오기
  Future<void> loadNearbyDogs() async {
    try {
      setState(() => isLoading = true);

      // 위치 권한 요청
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

      // ✅ 현재 위치 가져오기
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // ✅ MatchService에서 가까운 강아지 불러오기
      final fetchedDogs = await MatchService.getNearbyDogs(
        userLat: position.latitude,
        userLng: position.longitude,
        maxDistanceKm: 1000, // 10km 이내
      );

      setState(() {
        dogs = fetchedDogs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Error loading nearby dogs: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (locationDenied) {
      return const Scaffold(
        body: Center(
          child: Text("📍 위치 접근 권한이 필요합니다."),
        ),
      );
    }

    if (dogs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("근처에 등록된 강아지가 없습니다.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(
          fontSize: 28,
          color: Colors.black,
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🐶 카드 스와이프 영역
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

          // ❤️ 좋아요/싫어요 버튼 (하단)
          Padding(
            padding: const EdgeInsets.only(bottom: 60),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  heroTag: "dislike",
                  backgroundColor: Colors.redAccent,
                  onPressed: () => controller.swipeLeft(),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
                FloatingActionButton(
                  heroTag: "like",
                  backgroundColor: Colors.green,
                  onPressed: () => controller.swipeRight(),
                  child: const Icon(Icons.favorite, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
