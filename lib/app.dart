import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uz_app/providers/auth.dart';
import 'package:uz_app/screens/auth/enter_otp.dart';
import 'package:uz_app/utilities/styles.dart';

import 'screens/waiting_splash.dart';
import 'screens/auth/welcome.dart';
import 'screens/menu.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Auth()),
      ],
      child: Consumer<Auth>(
        builder: (context, auth, _) => MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          title: "Камера зберігання УЗ",
          theme: _theme(),
          home: auth.isAuth
              ? const MenuScreen()
              : FutureBuilder(
                  future: auth.tryAutoLogin(),
                  builder: (context, authResultSnapshot) =>
                      authResultSnapshot.connectionState ==
                              ConnectionState.waiting
                          ? const WaitingSplashScreen()
                          : const WelcomeScreen(),
                ),
          routes: {
            MenuScreen.routeName: (ctx) => const MenuScreen(),
            WelcomeScreen.routeName: (ctx) => const WelcomeScreen(),
          },
        ),
      ),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.backgroundColor,
      textTheme: GoogleFonts.openSansTextTheme(
        const TextTheme(
          headline4: AppStyles.titleSecondaryTextStyle,
          headline2: AppStyles.titleTextStyle,
          bodyText1: AppStyles.bodyText1,
        ),
      ),
      colorScheme: ThemeData().colorScheme.copyWith(
          primary: AppColors.secondaryColor,
          secondary: AppColors.secondaryColor),
    );
  }
}
