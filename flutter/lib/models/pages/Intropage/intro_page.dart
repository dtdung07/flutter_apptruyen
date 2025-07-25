import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:btl/models/pages/Intropage/register_page.dart';
import 'package:btl/models/pages/home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_page.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});
  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // Khởi tạo Google Sign-In và đăng xuất phiên trước đó
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      // Yêu cầu người dùng chọn tài khoản Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;
      // Lấy thông tin xác thực
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Đăng nhập với Firebase
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Kiểm tra xem user mới hay cũ
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // User mới - yêu cầu nhập nickname
        String? nickname;
        bool nicknameValid = false;

        while (!nicknameValid) {
          nickname = await showDialog<String>(
            context: context,
            builder: (context) {
              final textController = TextEditingController();
              return Dialog(
                backgroundColor: const Color(0xFF003E32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.greenAccent, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add,
                          size: 40, color: Colors.greenAccent),
                      const SizedBox(height: 16),
                      const Text(
                        "Chọn Nickname của bạn",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Nhập nickname duy nhất...',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.greenAccent,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        autofocus: true,
                        maxLength: 20,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text("HỦY"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (textController.text.trim().isNotEmpty) {
                                Navigator.pop(
                                    context, textController.text.trim());
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text(
                              "XÁC NHẬN",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          if (nickname == null || nickname.isEmpty) {
            // User hủy bỏ hoặc không nhập gì
            await userCredential.user?.delete();
            return;
          }

          // Kiểm tra nickname có sẵn
          final nicknameAvailable = await FirebaseFirestore.instance
              .collection('users')
              .where('nickname', isEqualTo: nickname)
              .get()
              .then((snapshot) => snapshot.docs.isEmpty);

          if (!nicknameAvailable) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Nickname đã tồn tại'),
                backgroundColor: Colors.red[400],
                content: const Text(
                    'Nickname này đã được sử dụng. Vui lòng chọn tên khác.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            continue;
          }

          nicknameValid = true;

          // Lưu thông tin user vào Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user?.email)
              .set({
            'uid': userCredential.user?.uid,
            'nickname': nickname,
            'email': userCredential.user?.email,
            'createdAt': FieldValue.serverTimestamp(),
            'authProvider': 'google',
          });
        }
      }

      // Hiển thị thông báo đăng nhập thành công
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Chuyển hướng đến trang HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print("Lỗi đăng nhập Google: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(
    //   SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    // );
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      // backgroundColor: Colors.blue,
      // appBar: AppBar(
      //   // backgroundColor: Colors.blue,
      //   automaticallyImplyLeading: false,
      //   elevation: 0,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.close, size: 30, color: Colors.white),
      //       onPressed: () {
      //         Navigator.push(
      //           context,
      //           MaterialPageRoute(builder: (context) => const HomePage()),
      //         ).whenComplete(() => Future.delayed(Duration(seconds: 2)).then(
      //               (_) => _updateAppbar(),
      //             )); // quay lại hoặc thoát
      //       },
      //     ),
      //   ],
      // ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon:
                        const Icon(Icons.close, size: 30, color: Colors.white),
                    onPressed: () {
                      final mode = context.read<ThemeCubit>().state;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HomePage()),
                      );
                    },
                  ),
                ],
              ),
              const Spacer(),

              const Icon(Icons.grid_view, size: 60, color: Colors.greenAccent),
              const SizedBox(height: 20),
              const Text(
                "Đăng nhập vào Apptruyen",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tạo tài khoản hoặc đăng nhập để lưu tiến trình đọc truyện.",
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              // Google button
              GestureDetector(
                onTap: () => signInWithGoogle(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/image/Google__G__logo.png',
                        height: 30,
                        width: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Tiếp tục với Google",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              //Email button
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () => (Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                )),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.email,
                        size: 30,
                        color: Colors.grey.shade700,
                      ),
                      SizedBox(width: 10),
                      Text("Tiếp tục với Email",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          )),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 15),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Chưa có tài khoản?  ",
                    style: const TextStyle(color: Colors.white70, fontSize: 23),
                    children: [
                      TextSpan(
                        text: "Đăng ký",
                        style: const TextStyle(color: Colors.greenAccent),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Bằng việc tiếp tục, bạn đồng ý với ",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                        text: "Điều khoản dịch vụ",
                        style: const TextStyle(color: Colors.blue),
                      ),
                      const TextSpan(text: " / "),
                      TextSpan(
                        text: "Chính sách bảo mật",
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}
