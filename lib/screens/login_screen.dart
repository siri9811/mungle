import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  void _signIn(Future<void> Function(BuildContext) signInMethod) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    await signInMethod(context);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 버튼들의 통일된 너비를 변수로 지정하면 관리하기 편합니다.
    const double buttonWidth = 300.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Mungle', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              const SizedBox(height: 100),
              
              _isLoading
                  ? const SizedBox(
                      // 버튼 높이 + 간격과 비슷하게 맞춰줍니다.
                      height: 110, 
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      children: [
                        // ★★★ 구글 로그인 버튼 ★★★
                        SizedBox(
                          width: buttonWidth, // 너비 강제
                          child: InkWell(
                            onTap: () => _signIn(AuthService.signInWithGoogle),
                            child: Image.asset(
                              'assets/images/google_login_button.png',
                              // fit: 이미지가 주어진 공간 안에서 어떻게 보일지 결정
                              // BoxFit.fill: 꽉 채우지만 비율이 깨질 수 있음
                              // BoxFit.contain: 비율을 유지하며 공간 안에 모두 보임 (추천)
                              fit: BoxFit.fill, 
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        // ★★★ 카카오 로그인 버튼 ★★★
                        SizedBox(
                          width: buttonWidth, // 구글 버튼과 동일한 너비로 강제
                          child: InkWell(
                            onTap: () => _signIn(AuthService.signInWithKakao),
                            child: Image.asset(
                              'assets/images/kakao_login_button.png',
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

