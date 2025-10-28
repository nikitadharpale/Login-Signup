import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sizer/sizer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer( Duration(seconds: 3), _checkUser);
  }

  void _checkUser(){
    final user = FirebaseAuth.instance.currentUser;
    if (user != null){
      Get.offAll(()=> HomeScreen());
    } else{
      Get.offAll(() => LoginScreen());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        color: Colors.deepPurple.shade50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flutter_dash, color: Colors.deepPurple, size: 25.w),
            SizedBox(height: 3.h),
            Text(
              "MyApp",
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 2.h,),
            CircularProgressIndicator(color: Colors.deepPurple,),
          ],
        ),
      ),
    );
  }
}
