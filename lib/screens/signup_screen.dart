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
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  String? _size;
  bool _vaccinated = false;
  XFile? _image;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _image = picked);
  }

  Future<void> _submitForm() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("로그인 정보가 없습니다.")),
      );
      return;
    }

    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _breedController.text.isEmpty ||
        _size == null ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 항목과 사진을 등록해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔹 이미지 Firebase Storage 업로드
      final file = File(_image!.path);
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles/${user.uid}.jpg');
      await storageRef.putFile(file);
      final imageUrl = await storageRef.getDownloadURL();

      // Dog 객체 생성
      final dog = Dog(
        id: user.uid,
        name: _nameController.text,
        age: int.tryParse(_ageController.text) ?? 0,
        breed: _breedController.text,
        imageUrl: imageUrl,
        lat: 0,
        lng: 0,
      );

      // Firestore users/{uid} 문서에 저장 (기존 데이터 덮어쓰기 방지)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        ...dog.toMap(),
        'size': _size,
        'vaccinated': _vaccinated,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: 기존 필드가 있으면 덮어쓰지 않음

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🐶 반려견 프로필 등록 완료!")),
      );

      // 🔹 메인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("🔥 등록 에러: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류 발생: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const pink = Colors.pinkAccent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "반려견 프로필 만들기",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 사진 업로드
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _image != null
                            ? FileImage(File(_image!.path))
                            : null,
                        child: _image == null
                            ? const Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 반려견 정보 입력
                  _buildLabel("이름"),
                  _buildTextField(_nameController, "반려견 이름"),
                  const SizedBox(height: 20),

                  _buildLabel("나이"),
                  _buildTextField(_ageController, "숫자로 입력", isNumber: true),
                  const SizedBox(height: 20),

                  _buildLabel("품종"),
                  _buildTextField(_breedController, "예: 말티즈, 시바견"),
                  const SizedBox(height: 20),

                  _buildLabel("크기"),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: [
                      _buildChoiceChip("소형"),
                      _buildChoiceChip("중형"),
                      _buildChoiceChip("대형"),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "예방접종 완료",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Switch(
                        value: _vaccinated,
                        onChanged: (v) => setState(() => _vaccinated = v),
                        activeColor: pink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // 가입 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: pink,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "가입하기",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ===== 재사용 위젯 =====
  Widget _buildLabel(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      );

  Widget _buildTextField(TextEditingController c, String hint,
      {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.pinkAccent),
        ),
      ),
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
