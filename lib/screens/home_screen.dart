import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:geolocator/geolocator.dart';
import '../models/dog.dart';
import '../services/match_service.dart';
import '../widgets/dog_card.dart';
import '../widgets/app_logo.dart';
import '../utils/constants.dart';
import '../widgets/match_popup.dart';

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
        maxDistanceKm: AppConstants.maxMatchDistanceKm,
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
    /// 🔄 로딩 중
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// ❌ 권한 거부된 경우
    if (locationDenied) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  AppConstants.locationPermissionRequired,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "근처 반려견을 찾기 위해 위치 권한을 허용해주세요.",
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "설정에서 허용하기",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    /// 🐶 추천 강아지 없음
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

    /// 🟢 정상 카드 UI
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppLogo(fontSize: 28, color: Colors.black),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: dogs.length,
              numberOfCardsDisplayed: 1,
              isLoop: true,
              onSwipe: (previousIndex, currentIndex, direction) async {
                final dog = dogs[previousIndex];

                if (direction == CardSwiperDirection.right) {
                  await MatchService.handleSwipe(dog, true);
                  if (mounted) showMatchPopup(context, dog);
                } else if (direction == CardSwiperDirection.left) {
                  await MatchService.handleSwipe(dog, false);
                }

                return true;
              },
              cardBuilder: (_, index, __, ___) => DogCard(dog: dogs[index]),
            ),
          ),
        ],
      ),
    );
  }
}
