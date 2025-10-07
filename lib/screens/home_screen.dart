import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../models/dog.dart';
import '../services/dog_service.dart';
import '../widgets/dog_card.dart'; // 분리한 위젯
import '../widgets/app_logo.dart'; // 추가한 AppLogo 위젯

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CardSwiperController controller = CardSwiperController();
  List<Dog> dogs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDogs();
  }

  Future<void> loadDogs() async {
    try {
      final fetchedDogs = await DogService.fetchDogs();
      setState(() {
        dogs = fetchedDogs;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading dogs: $e");
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

    if (dogs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("등록된 강아지가 없습니다")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(   // ✅ AppLogo 위젯으로 교체
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
              onSwipe: (previousIndex, currentIndex, direction) {
                if (previousIndex != null) {
                  if (direction == CardSwiperDirection.right) {
                    debugPrint("좋아요: ${dogs[previousIndex].name}");
                  } else if (direction == CardSwiperDirection.left) {
                    debugPrint("싫어요: ${dogs[previousIndex].name}");
                  }
                }
                return true;
              },
              cardBuilder: (context, index, percentX, percentY) {
                return DogCard(dog: dogs[index]); // ✅ 분리한 DogCard 위젯 사용
              },
            ),
          ),

          // ❤️ 좋아요/싫어요 버튼 (네비게이션바 위쪽 중간 지점)
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
