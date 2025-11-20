import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dog.dart';
import 'main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  final _introController = TextEditingController();
  String? _size;
  bool _vaccinated = false;
  XFile? _image;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _nameController.addListener(() => setState(() {}));
    _ageController.addListener(() => setState(() {}));
    _breedController.addListener(() => setState(() {}));
    _introController.addListener(() => setState(() {}));
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack("로그인 정보가 없습니다.");
      return;
    }

    if (!_isStepValid()) {
      _showSnack("모든 항목을 입력해주세요.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final file = File(_image!.path);
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_profiles/${user.uid}/profile.jpg');
      await ref.putFile(file);
      final imageUrl = await ref.getDownloadURL();

      final dog = Dog(
        id: user.uid,
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text) ?? 0,
        breed: _breedController.text.trim(),
        imageUrl: imageUrl,
        lat: 0,
        lng: 0,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...dog.toMap(),
        'intro': _introController.text.trim(),
        'size': _size,
        'vaccinated': _vaccinated,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _showSnack("🐶 반려견 프로필 등록 완료!");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      _showSnack("등록 중 오류 발생: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isStepValid() {
    switch (_step) {
      case 0:
        return _nameController.text.trim().isNotEmpty;
      case 1:
        return _ageController.text.trim().isNotEmpty;
      case 2:
        return _breedController.text.trim().isNotEmpty;
      case 3:
        return _introController.text.trim().isNotEmpty;
      case 4:
        return _size != null;
      case 5:
        return true;
      case 6:
        return _image != null;
      default:
        return false;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _nextStep() {
    if (_isStepValid()) {
      if (_step < 6) setState(() => _step++);
    } else {
      _showSnack("입력값을 확인해주세요.");
    }
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    const pink = Colors.pinkAccent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),

                  /// 🔥🔥 자연스러운 페이드 + 슬라이드 애니메이션 적용
                  transitionBuilder: (child, animation) {
                    final fade = FadeTransition(opacity: animation, child: child);

                    final slide = SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0), // 아주 약하게 오른쪽에서 등장
                        end: Offset.zero,
                      ).animate(animation),
                      child: fade,
                    );

                    return slide;
                  },

                  child: _buildStepContent(pink),
                ),
              ),
            ),
    );
  }

  Widget _buildStepContent(Color pink) {
    switch (_step) {
      case 0:
        return _stepTemplate(
          key: const ValueKey(0),
          title: "이름이 무엇인가요?",
          description: "프로필에 표시될 이름입니다.",
          child: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "예: 동글이"),
          ),
        );

      case 1:
        return _stepTemplate(
          key: const ValueKey(1),
          title: "반려견의 나이는 몇 살인가요?",
          description: "프로필에는 생일이 아닌 나이가 표시됩니다.",
          child: TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "예: 3"),
          ),
        );

      case 2:
        return _stepTemplate(
          key: const ValueKey(2),
          title: "품종은 무엇인가요?",
          description: "예: 말티즈, 푸들, 시바견",
          child: TextField(
            controller: _breedController,
            decoration: const InputDecoration(hintText: "예: 토이푸들"),
          ),
        );

      case 3:
        return _stepTemplate(
          key: const ValueKey(3),
          title: "한줄소개를 입력해주세요",
          description: "자신과 반려견을 간단히 표현해보세요!",
          child: TextField(
            controller: _introController,
            maxLines: 2,
            decoration:
                const InputDecoration(hintText: "예: 산책을 좋아하는 귀여운 친구예요!"),
          ),
        );

      case 4:
        return _stepTemplate(
          key: const ValueKey(4),
          title: "크기를 선택해주세요",
          description: "반려견의 체형을 기준으로 선택해주세요.",
          child: Wrap(
            spacing: 10,
            children: [
              _buildChoiceChip("소형"),
              _buildChoiceChip("중형"),
              _buildChoiceChip("대형"),
            ],
          ),
        );

      case 5:
        return _stepTemplate(
          key: const ValueKey(5),
          title: "예방접종을 완료했나요?",
          description: "필수 접종이 완료되었는지 확인해주세요.",
          child: Switch(
            value: _vaccinated,
            onChanged: (v) => setState(() => _vaccinated = v),
            activeColor: pink,
          ),
        );

      case 6:
        return _stepTemplate(
          key: const ValueKey(6),
          title: "반려견의 사진을 등록해주세요",
          description: "가장 예쁜 사진 한 장을 선택해주세요.",
          child: GestureDetector(
            onTap: _pickImage,
            child: CircleAvatar(
              radius: 70,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  _image != null ? FileImage(File(_image!.path)) : null,
              child: _image == null
                  ? const Icon(Icons.add_a_photo,
                      color: Colors.grey, size: 40)
                  : null,
            ),
          ),
          buttonLabel: "등록하기",
          onPressed: _isStepValid() ? _submitForm : null,
        );

      default:
        return const SizedBox();
    }
  }

  Widget _stepTemplate({
    required Key key,
    required String title,
    required String description,
    required Widget child,
    String buttonLabel = "다음",
    VoidCallback? onPressed,
  }) {
    final bool isValid = _isStepValid();

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (_step + 1) / 7,
          backgroundColor: Colors.grey[200],
          color: Colors.pinkAccent,
        ),
        const SizedBox(height: 40),
        Text(title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(description,
            style: const TextStyle(color: Colors.grey, fontSize: 15)),
        const SizedBox(height: 40),
        child,
        const SizedBox(height: 60),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed ?? (isValid ? _nextStep : null),
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? Colors.black : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              buttonLabel,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceChip(String label) {
    const pink = Colors.pinkAccent;
    return ChoiceChip(
      label: Text(label),
      selectedColor: pink,
      selected: _size == label,
      labelStyle:
          TextStyle(color: _size == label ? Colors.white : Colors.black),
      onSelected: (_) => setState(() => _size = label),
    );
  }
}
