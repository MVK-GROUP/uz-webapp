import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uz_app/screens/auth/welcome.dart';
import 'package:uz_app/screens/feedback.dart';
import 'package:uz_app/screens/history/components/order_detail_manage.dart';

import 'choose_order_screen.dart';
import 'acl/size_selection_screen.dart';
import 'auth/enter_phone.dart';
import 'history/history_screen.dart';
import 'enter_lockerid_screen.dart';
import '../api/http_exceptions.dart';
import '../models/order.dart';
import '../providers/orders.dart';
import '../providers/auth.dart';
import '../utilities/styles.dart';
import '../models/lockers.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/photo_tile.dart';
import '../widgets/icon_tile.dart';
import '../widgets/main_block.dart';

class MenuScreen extends StatefulWidget {
  static const routeName = '/menu';

  const MenuScreen({Key? key}) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Locker? locker;
  late Future<OrdersNotifier?> _initOrdersFuture;
  bool _isInit = false;
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      _initOrdersFuture = _obtainInitOrdersFuture();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  Future<OrdersNotifier?> _obtainInitOrdersFuture() async {
    locker = Provider.of<LockerNotifier>(context, listen: false).locker;
    if (locker == null) {
      return null;
    } else {
      _showFloatingButton = true;
    }

    final ordersNotifier = Provider.of<OrdersNotifier>(context, listen: false);
    if (ordersNotifier.isTimeToUpdate) {
      try {
        await ordersNotifier.fetchAndSetOrders();
      } catch (e) {
        if (e is HttpException && e.statusCode == 401) {
          Navigator.pushNamed(context, EnterPhoneScreen.routeName);
        }
        return Future.error(e.toString());
      }
    }
    return ordersNotifier;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //floatingActionButton: _showFloatingButton
      //    ? FloatingActionButton(
      //        onPressed: () =>
      //            Navigator.pushNamed(context, FeedbackScreen.routeName),
      //        child: const Icon(Icons.question_mark),
      //      )
      //    : null,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        actions: [
          const SizedBox(width: 10),
          IconButton(
            iconSize: 26,
            color: AppColors.textColor,
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => ConfirmDialog(
                    title: "home.logout".tr(),
                    text: "home.logout_confirm".tr()),
              ).then((value) {
                if (value != null) {
                  Navigator.pushNamed(context, WelcomeScreen.routeName);
                  Provider.of<Auth>(context, listen: false).logout();
                  Provider.of<OrdersNotifier>(context, listen: false)
                      .resetOrders();
                  Provider.of<LockerNotifier>(context, listen: false)
                      .resetLocker();
                }
              });
            },
            icon: const Icon(Icons.exit_to_app),
          ),
          const Spacer(),
          if (_showFloatingButton)
            IconButton(
              iconSize: 26,
              color: AppColors.textColor,
              onPressed: () =>
                  Navigator.pushNamed(context, FeedbackScreen.routeName),
              icon: const Icon(Icons.question_mark),
            ),
          const SizedBox(width: 10),
          IconButton(
            iconSize: 36,
            color: AppColors.textColor,
            onPressed: () {
              Navigator.of(context).pushNamed(HistoryScreen.routeName);
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            iconSize: 36,
            color: AppColors.textColor,
            onPressed: () {
              Navigator.of(context).pushNamed(EnterLockerIdScreen.routeName);
            },
            icon: const Icon(Icons.qr_code),
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: SizedBox(
          width: double.infinity,
          child: FutureBuilder(
              future: _initOrdersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center();
                } else {
                  if (snapshot.error != null) {
                    print("Error: ${snapshot.error.toString()}");
                    return Center(
                      child: Text("home.unknown_error".tr()),
                    );
                  }

                  final notifier = snapshot.data as OrdersNotifier?;

                  final List<OrderData> activeOrders = notifier == null
                      ? []
                      : notifier
                          .getActiveAclsOrdersByLockerId(locker!.lockerId);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Image.asset(
                          "assets/logos/uz_blue.png",
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: Text(
                          locker == null
                              ? "home.no_locker".tr()
                              : locker?.fullLockerName ?? "",
                          textAlign: TextAlign.center,
                          style: AppStyles.subtitleTextStyle,
                        ),
                      ),
                      if (locker == null)
                        MainBlock(
                          maxWidth: 400,
                          child: ListView(children: iconTiles(context)),
                        ),
                      if (locker != null)
                        MainBlock(
                          child: ListView(
                              shrinkWrap: true,
                              children:
                                  menuItems(context, locker, activeOrders)),
                        ),
                    ],
                  );
                }
              })),
    );
  }

  void onTap(BuildContext context, Service service) {
    String routeName;
    switch (service.category) {
      case ServiceCategory.acl:
        routeName = SizeSelectionScreen.routeName;
        break;
      default:
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text("home.not_implemented_title".tr()),
                  content: Text("home.not_implemented_text".tr()),
                ));
        return;
    }
    Provider.of<ServiceNotifier>(context, listen: false).setService(service);
    Navigator.pushNamed(context, routeName);
  }

  List<PhotoTile> menuItems(
      BuildContext context, Locker? lckr, List<OrderData>? activeOrders) {
    List<PhotoTile> items = [];
    for (var element in lckr!.services) {
      items.add(PhotoTile(
        imageUrl: element.imageUrl,
        backgroundColor: element.color,
        title: element.action,
        onTap: () => onTap(context, element),
      ));
    }

    if (lckr.services.isNotEmpty &&
        activeOrders != null &&
        activeOrders.isNotEmpty) {
      items.add(PhotoTile(
        backgroundColor: lckr.services.first.color,
        title: "home.pick_up_stuff".tr(),
        onTap: () {
          if (activeOrders.length > 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ChooseOrderScreen(
                        orders: activeOrders,
                      )),
            );
          } else {
            showOrderDetail(context, activeOrders.first);
          }
        },
      ));
    }

    return items;
  }

  void showOrderDetail(BuildContext context, OrderData order) async {
    await showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: order,
        child: const OrderDetailManageDialog(),
      ),
    );
  }

  List<Widget> iconTiles(BuildContext context) {
    return [
      const SizedBox(height: 20),
      IconTile(
        text: "home.find_locker".tr(),
        icon: Icons.qr_code_scanner_outlined,
        onTap: () {
          Navigator.pushNamed(context, EnterLockerIdScreen.routeName);
        },
      ),
      const SizedBox(height: 20),
      IconTile(
        text: "home.history".tr(),
        icon: Icons.history,
        onTap: () {
          Navigator.pushNamed(context, HistoryScreen.routeName);
        },
      ),
    ];
  }
}
