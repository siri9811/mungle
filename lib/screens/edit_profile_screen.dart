import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _breedController = TextEditingController();
  final _introController = TextEditingController(); // ✅ 한줄소개 필드

  String? _size;
  bool _vaccinated = false;
  XFile? _newImage;
  String? _currentImageUrl;
  bool _isLoading = true;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  /// 🔹 Firestore에서 기존 유저 프로필 불러오기
  Future<void> _loadCurrentData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _breedController.text = data['breed'] ?? '';
          _introController.text = data['intro'] ?? ''; // ✅ 불러오기
          _size = data['size'];
          _vaccinated = data['vaccinated'] ?? false;
          _currentImageUrl = data['imageUrl'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("🔥 프로필 로드 실패: $e");
      setState(() => _isLoading = false);
    }
  }

  /// 🔹 이미지 변경
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _newImage = picked);
  }

  /// 🔹 변경 내용 Firestore에 저장
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이름을 입력해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _currentImageUrl ?? '';

      // ✅ 새 이미지 업로드
      if (_newImage != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('user_profiles/${user.uid}/profile.jpg');
        await ref.putFile(File(_newImage!.path));
        imageUrl = await ref.getDownloadURL();
      }

      // ✅ Firestore 업데이트
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'breed': _breedController.text.trim(),
        'intro': _introController.text.trim(), // ✅ 한줄소개 저장
        'size': _size,
        'vaccinated': _vaccinated,
        'imageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("프로필이 성공적으로 수정되었습니다 ✅")),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint("🔥 프로필 수정 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("수정 중 오류 발생: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "프로필 수정하기",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 프로필 이미지 변경
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 70,
                  backgroundImage: _newImage != null
                      ? FileImage(File(_newImage!.path))
                      : (_currentImageUrl != null &&
                              _currentImageUrl!.isNotEmpty
                          ? NetworkImage(_currentImageUrl!)
                          : null) as ImageProvider?,
                  backgroundColor: Colors.grey[200],
                  child: (_newImage == null &&
                          (_currentImageUrl == null ||
                              _currentImageUrl!.isEmpty))
                      ? const Icon(Icons.add_a_photo,
                          size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 이름 입력
            _buildLabel("이름"),
            _buildTextField(_nameController, "이름 입력"),
            const SizedBox(height: 20),

            // 나이 입력
            _buildLabel("나이"),
            _buildTextField(_ageController, "숫자로 입력", isNumber: true),
            const SizedBox(height: 20),

            // 품종 입력
            _buildLabel("품종"),
            _buildTextField(_breedController, "예: 말티즈, 시바견"),
            const SizedBox(height: 20),

            // ✅ 한줄소개 입력
            _buildLabel("한줄소개"),
            _buildTextField(_introController, "예: 산책을 좋아하는 귀여운 친구예요!", maxLines: 2),
            const SizedBox(height: 20),

            // 크기 선택
            _buildLabel("크기"),
            Wrap(
              spacing: 10,
              children: [
                _buildChoiceChip("소형"),
                _buildChoiceChip("중형"),
                _buildChoiceChip("대형"),
              ],
            ),
            const SizedBox(height: 20),

            // 예방접종 여부
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
                  activeColor: Colors.pinkAccent,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  "저장하기",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
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

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
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
