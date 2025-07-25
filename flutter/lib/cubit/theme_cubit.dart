import 'package:bloc/bloc.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(InitialTheme());

  void lightThemeEvent() async {
    emit(LightTheme());
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
    saveTheme(LightTheme());
  }

  void darkThemeEvent() async {
    emit(DarkTheme());
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    );
    saveTheme(DarkTheme());
  }

  Future<void> saveTheme(ThemeState mode) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode is LightTheme ? 'light' : 'dark');
  }

  Future<void> loadTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode');

    if (theme == 'light') {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      );
      print('chạy hàm đổi màu');
      emit(LightTheme());
    } else {
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      );
      emit(DarkTheme());
    }
  }
}
