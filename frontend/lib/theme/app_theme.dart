import 'package:flutter/material.dart';

class AppTheme {

  static const Color primary = Color(0xffE6C4A4);
  static const Color background = Color(0xffEFE7DF);
  static const Color field = Color(0xffF5F5F5);

  static ThemeData lightTheme = ThemeData(

    fontFamily: "Poppins",

    scaffoldBackgroundColor: background,

    elevatedButtonTheme: ElevatedButtonThemeData(

      style: ElevatedButton.styleFrom(

        backgroundColor: primary,
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),

        minimumSize: const Size(double.infinity, 50),

      ),

    ),

    inputDecorationTheme: InputDecorationTheme(

      filled: true,
      fillColor: field,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),

    ),

  );

}