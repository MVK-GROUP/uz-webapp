import 'package:flutter/material.dart';

class AppColors {
  static const mainColor = Color(0xFF5C5E62);
  static const grayColor = Color.fromARGB(255, 151, 152, 155);
  static const secondaryColor = Color(0xFF2B2D7F);
  static const dangerousColor = Color(0xFFDA534A);
  static const backgroundColor = Color(0xFFF7F7F9);
  static const successColor = Color(0xFF63C77F);
  static const textColor = Color(0xFF5C5E62);
}

class AppStyles {
  static const bodyText2 = TextStyle(
    color: AppColors.mainColor,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const titleTextStyle = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryColor,
  );

  static const titleSecondaryTextStyle = TextStyle(
    fontSize: 22,
    color: AppColors.mainColor,
    fontWeight: FontWeight.w600,
  );

  static const subtitleTextStyle = TextStyle(
    fontSize: 20,
    color: AppColors.mainColor,
  );

  static const bodyText1 = TextStyle(
    color: AppColors.mainColor,
    fontSize: 16,
  );

  static const bodySmallText = TextStyle(
    color: AppColors.mainColor,
    fontSize: 13,
  );
}

class AppShadows {
  static BoxShadow getShadow100() {
    return BoxShadow(
      color: const Color(0xFFA7B0C0).withOpacity(0.1),
      offset: const Offset(0, 8),
      blurRadius: 9,
    );
  }

  static BoxShadow getShadow200() {
    return BoxShadow(
      color: const Color(0xFFA7B0C0).withOpacity(0.2),
      spreadRadius: 0,
      blurRadius: 18,
      offset: const Offset(0, 3),
    );
  }
}
