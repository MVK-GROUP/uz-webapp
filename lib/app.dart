import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uz_app/providers/auth.dart';
import 'package:uz_app/screens/enter_lockerid_screen.dart';
import 'package:uz_app/screens/feedback.dart';
import 'package:uz_app/utilities/styles.dart';

import 'models/lockers.dart';
import 'providers/orders.dart';
import 'screens/acl/set_datetime.dart';
import 'screens/acl/size_selection_screen.dart';
import 'screens/check_payment_screen.dart';
import 'screens/confirm_locker_screen.dart';
import 'screens/history/history_screen.dart';
import 'screens/pay_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/success_order_screen.dart';
import 'screens/waiting_splash.dart';
import 'screens/auth/welcome.dart';
import 'screens/menu.dart';

class RouteGenerator {
  static Route<dynamic>? generateRoute(
      RouteSettings settings, BuildContext context, Auth auth) {
    Map? queryParameters;
    var uriData = Uri.parse(settings.name!);
    queryParameters = uriData.queryParameters;
    if (queryParameters.containsKey("locker_id") &&
        int.tryParse(queryParameters["locker_id"]) != null) {
      return MaterialPageRoute(
        builder: (context) {
          return auth.isAuth
              ? ConfirmLockerScreen(queryParameters!["locker_id"])
              : WelcomeScreen(prevRouteName: uriData.toString());
        },
        settings: settings,
      );
    }
    if (queryParameters.containsKey("payment-status") &&
        queryParameters.containsKey("order_id") &&
        int.tryParse(queryParameters["order_id"]) != null) {
      int orderId = int.parse(queryParameters["order_id"]);

      var paymentType = PaymentType.unknown;
      var isDebt = false;
      if (queryParameters.containsKey("type") &&
          queryParameters['type'] == 'debt') {
        isDebt = true;
      }

      if (queryParameters["payment-status"] == 'success') {
        paymentType = isDebt
            ? PaymentType.successDebtPayment
            : PaymentType.successPayment;
      }
      if (queryParameters["payment-status"] == 'error') {
        paymentType =
            isDebt ? PaymentType.errorDebtPayment : PaymentType.errorPayment;
      }

      if (paymentType != PaymentType.unknown) {
        return MaterialPageRoute(
          builder: (context) {
            return auth.isAuth
                ? CheckPaymentScreen(
                    type: paymentType,
                    orderId: orderId,
                  )
                : FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (context, authResultSnapshot) =>
                        authResultSnapshot.connectionState ==
                                ConnectionState.waiting
                            ? const WaitingSplashScreen()
                            : const WelcomeScreen(),
                  );
          },
          settings: settings,
        );
      }
    }
    return MaterialPageRoute(
      builder: (context) {
        return auth.isAuth
            ? const MenuScreen()
            : WelcomeScreen(prevRouteName: uriData.toString());
      },
      settings: settings,
    );
  }
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Auth()),
        ChangeNotifierProxyProvider<Auth, LockerNotifier>(
          create: (context) => LockerNotifier(null, null, lang: 'en'),
          update: (context, auth, previousOrders) => LockerNotifier(
              previousOrders?.locker, auth.token,
              lang: context.locale.languageCode),
        ),
        ChangeNotifierProvider.value(value: ServiceNotifier()),
        ChangeNotifierProxyProvider<Auth, OrdersNotifier>(
          create: (context) => OrdersNotifier(null, null, null),
          update: (context, auth, previousOrdersNotifier) => OrdersNotifier(
              auth.token,
              previousOrdersNotifier?.activeOrders,
              previousOrdersNotifier?.latestCompletedOrders),
        ),
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
            EnterLockerIdScreen.routeName: (ctx) => const EnterLockerIdScreen(),
            FeedbackScreen.routeName: (ctx) => const FeedbackScreen(),
            MenuScreen.routeName: (ctx) => const MenuScreen(),
            WelcomeScreen.routeName: (ctx) => const WelcomeScreen(),
            SizeSelectionScreen.routeName: (ctx) => const SizeSelectionScreen(),
            QrScannerScreen.routeName: (ctx) => QrScannerScreen(),
            PayScreen.routeName: (ctx) => const PayScreen(),
            SuccessOrderScreen.routeName: (ctx) => const SuccessOrderScreen(),
            HistoryScreen.routeName: (ctx) => const HistoryScreen(),
            SetACLDateTimeScreen.routeName: (ctx) =>
                const SetACLDateTimeScreen(),
          },
          onGenerateRoute: (RouteSettings settings) =>
              RouteGenerator.generateRoute(settings, context, auth),
        ),
      ),
    );
  }

  ThemeData _theme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.backgroundColor,
      iconTheme: const IconThemeData(color: AppColors.textColor),
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
