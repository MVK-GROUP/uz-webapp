import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uz_app/screens/auth/welcome.dart';

import '../providers/auth.dart';
import '../utilities/styles.dart';

class MenuScreen extends StatefulWidget {
  static const routeName = '/menu';

  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          const SizedBox(width: 10),
          IconButton(
            iconSize: 26,
            color: AppColors.mainColor,
            onPressed: () async {
              Navigator.pushNamedAndRemoveUntil(
                  context, WelcomeScreen.routeName, (route) => false);
              Provider.of<Auth>(context, listen: false).logout();
            },
            icon: const Icon(Icons.exit_to_app),
          ),
          const Spacer(),
          const SizedBox(width: 10)
        ],
      ),
      body: Center(
          child: Text(
        "app_title".tr(),
      )),
    );
  }
}
