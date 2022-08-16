import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../models/order.dart';
import 'package:provider/provider.dart';

import '../menu.dart';
import '../../widgets/main_block.dart';
import '../../widgets/screen_title.dart';
import '../../widgets/order_tile.dart';
import '../history/detail_order_dialog.dart';

class ChooseOrderScreen extends StatelessWidget {
  static const routeName = 'choose-order/';

  final List<OrderData> orders;

  const ChooseOrderScreen({required this.orders, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(size: 32),
          actions: [
            IconButton(
              iconSize: 36,
              onPressed: () {
                //if (Navigator.canPop(context)) {
                //  Navigator.pop(context);
                //} else {
                //  Navigator.pushReplacementNamed(context, MenuScreen.routeName);
                //}
                Navigator.pushNamedAndRemoveUntil(
                    context, MenuScreen.routeName, (route) => false);
                //Navigator.pushReplacementNamed(context, MenuScreen.routeName);
              },
              icon: const Icon(Icons.home),
            ),
            const SizedBox(width: 10)
          ]),
      body: SafeArea(
        child: Column(children: [
          ScreenTitle(
            'history.select_order'.tr(),
            subTitle: "history.several_orders_select_you_want".tr(),
            height: 120,
          ),
          MainBlock(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: OrderTile(
                  title: "history.order_number"
                      .tr(namedArgs: {"id": orders[i].id.toString()}),
                  place: orders[i].place ?? "unknown",
                  //pointColor: pointColor,
                  date: orders[i].humanDate,
                  onPressed: () => showOrderDetail(context, orders[i]),
                ),
              ),
            ),
          )
        ]),
      ),
    );
  }

  void showOrderDetail(BuildContext context, OrderData order) async {
    await showDialog(
        barrierColor: Colors.transparent,
        context: context,
        builder: (ctx) => ChangeNotifierProvider.value(
              value: order,
              child: const DetailOrderNotifierDialog(),
            ));
  }
}
