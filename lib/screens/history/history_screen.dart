import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uz_app/screens/history/order_detail.dart';
import 'package:uz_app/widgets/button.dart';
import '/models/order.dart';
import 'package:provider/provider.dart';

import '../../providers/orders.dart';
import '../menu.dart';
import '../../utilities/styles.dart';
import '../../widgets/order_tile.dart';

class HistoryScreen extends StatefulWidget {
  static const routeName = 'history/';
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future _ordersFuture;
  var isInit = false;

  Future _obtainOrdersFuture() async {
    var data = Provider.of<OrdersNotifier>(context, listen: true);
    if (data.isTimeToUpdate) {
      await data.fetchAndSetOrders();
    } else {
      var isExistNewOrders = data.isExistOrdersWithStatus(
          [OrderStatus.created, OrderStatus.inProgress]);
      if (isExistNewOrders != null && isExistNewOrders) {
        await data.fetchAndSetOrders();
      }
    }
    return data;
  }

  @override
  void didChangeDependencies() {
    if (!isInit) {
      _ordersFuture = _obtainOrdersFuture();
      showOrderDetailFromArgs();
      isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0.0,
          iconTheme: const IconThemeData(size: 32),
          title: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              'history.title'.tr(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              iconSize: 36,
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, MenuScreen.routeName, (route) => false);
              },
              icon: const Icon(
                Icons.home,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10)
          ]),
      body: SafeArea(
        child: FutureBuilder(
          future: _ordersFuture,
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              if (dataSnapshot.error != null) {
                if (kDebugMode) {
                  print("Error: ${dataSnapshot.error.toString()}");
                }
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "history.technical_problems".tr(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                return SingleChildScrollView(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 40),
                    child: Consumer<OrdersNotifier>(
                        builder: (ctx, ordersData, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            ActiveOrdersDisplay(ordersData.activeOrders!),
                            CompletedOrdersDisplay(
                                ordersData.latestCompletedOrders!),
                          ],
                        ),
                      );
                    }),
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void showOrderDetail(OrderData order) async {
    await showDialog(
      barrierColor: Colors.transparent,
      context: context,
      builder: (ctx) => OrderDetailDialog(order),
    );
  }

  void showOrderDetailFromArgs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg != null) {
      showOrderDetail(arg as OrderData);
    }
  }
}

class OrderListTitle extends StatelessWidget {
  final String text;
  const OrderListTitle(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.roboto(
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 18),
    );
  }
}

class CompletedOrdersDisplay extends StatelessWidget {
  final List<OrderData> orders;
  const CompletedOrdersDisplay(this.orders, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return orders.isEmpty
        ? Container()
        : Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                OrderListTitle('history.completed_orders'.tr()),
                const SizedBox(height: 10),
                Center(
                  child: Opacity(
                    opacity: 0.7,
                    child: OrderList(
                      orders,
                      onPressed: (OrderData orderData) => showDialog(
                        barrierColor: Colors.black12,
                        context: context,
                        builder: (ctx) => OrderDetailDialog(orderData),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}

class ActiveOrdersDisplay extends StatelessWidget {
  final List<OrderData> orders;
  const ActiveOrdersDisplay(this.orders, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ordersQuantity = orders.length;
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ordersQuantity != 0) OrderListTitle('history.active_orders'.tr()),
          const SizedBox(height: 20),
          if (ordersQuantity == 0) const NoOrdersWidget(),
          if (ordersQuantity == 1)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: OrderDetail(orders.first),
              ),
            ),
          if (ordersQuantity > 1)
            Center(
              child: OrderList(
                orders,
                onPressed: (OrderData orderData) => showDialog(
                  barrierColor: Colors.black12,
                  context: context,
                  builder: (ctx) => OrderDetailDialog(orderData),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NoOrdersWidget extends StatelessWidget {
  const NoOrdersWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Image.asset(
            'assets/images/waiting.png',
            fit: BoxFit.fitWidth,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'history.no_order'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedDefaultButton(
            borderRadius: 12,
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, MenuScreen.routeName, (route) => false),
            child: Text(
              'acl.service_acl_action'.tr(),
              style: const TextStyle(fontSize: 16),
            )),
      ],
    );
  }
}

class OrderList extends StatelessWidget {
  final List<OrderData> orders;
  final Function(OrderData)? onPressed;
  final double maxWidth;
  const OrderList(this.orders, {this.onPressed, this.maxWidth = 400, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: OrderTile(
                title: "history.order_number"
                    .tr(namedArgs: {"id": orders[i].id.toString()}),
                place: orders[i].place ?? "unknown".tr(),
                containerColor: Colors.white,
                date: orders[i].humanDate,
                onPressed:
                    onPressed == null ? null : () => onPressed!(orders[i]),
              ),
            );
          }),
    );
  }
}