import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:uz_app/screens/auth/enter_phone.dart';

import '../../utilities/locales.dart';
import '../../utilities/styles.dart';
import '../../widgets/buttons.dart';
import '../../widgets/image_banner.dart';

class WelcomeScreen extends StatefulWidget {
  static const routeName = '/welcome';
  final String? prevRouteName;

  const WelcomeScreen({this.prevRouteName, Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late LocaleObject currentLocale;
  bool isInit = false;

  @override
  void didChangeDependencies() {
    if (!isInit) {
      currentLocale =
          SupportedLocales.getLocaleByCode(context.locale.languageCode);
      isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: CustomScrollView(slivers: [
      SliverFillRemaining(
        hasScrollBody: false,
        child: Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 24),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 50,
                      width: 200,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/logos/uz_blue.png'),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      decoration: BoxDecoration(
                          color: AppColors.mainColor,
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    Container(
                      height: 50,
                      width: 200,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/logos/mvk.png'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Spacer(),
                const ImageBanner(
                  'assets/images/welcome.png',
                  imageFit: BoxFit.fitHeight,
                  hConstraint: 180,
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(10, 20, 10, 0),
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    'auth.welcome_title'.tr(),
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 20),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.public,
                        color: AppColors.mainColor,
                        size: 32,
                      ),
                      const SizedBox(width: 20),
                      LanguageDropDownWidget(
                          locale: currentLocale,
                          selectedLocale: (LocaleObject? localeObject) =>
                              changeLocale(context, localeObject)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: MainButton(
                    text: 'auth.welcome_start'.tr(),
                    icon: Icons.arrow_right_alt,
                    iconLocation: IconLocation.right,
                    onButtonPress: () async {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EnterPhoneScreen(
                                  prevRouteName: widget.prevRouteName)));
                    },
                  ),
                ),
                const SizedBox(
                  height: 10,
                )
              ],
            )),
      )
    ]));
  }

  void changeLocale(BuildContext context, LocaleObject? localeObject) async {
    if (localeObject != null) {
      setState(() {
        currentLocale = localeObject;
      });
      await context.setLocale(localeObject.locale);
    }
  }
}

class LanguageDropDownWidget extends StatelessWidget {
  final LocaleObject locale;
  final Function selectedLocale;

  const LanguageDropDownWidget(
      {required this.locale, required this.selectedLocale, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButton<LocaleObject>(
      value: locale,
      icon: const Icon(Icons.keyboard_arrow_down),
      elevation: 4,
      underline: null,
      style: const TextStyle(
          color: AppColors.mainColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.8),
      focusColor: Colors.white,
      onChanged: (LocaleObject? newValue) => selectedLocale(newValue),
      items: SupportedLocales.lockaleObjects.map((LocaleObject value) {
        return DropdownMenuItem(
          value: value,
          child: Text(value.title),
        );
      }).toList(),
    );
  }
}
