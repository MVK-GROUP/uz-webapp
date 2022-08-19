import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../feedback.dart';
import '/providers/auth.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../utilities/styles.dart';
import '../../widgets/dialog.dart';
import '../../widgets/order_element_widget.dart';
import 'order_actions_widget.dart';

class OrderDetailNotifierDialog extends StatefulWidget {
  const OrderDetailNotifierDialog({Key? key}) : super(key: key);

  @override
  State<OrderDetailNotifierDialog> createState() =>
      _OrderDetailNotifierDialogState();
}

class _OrderDetailNotifierDialogState extends State<OrderDetailNotifierDialog> {
  late OrderData order;
  var _isInit = false;
  Timer? timer;
  var _isOrderLoading = false;
  String? token;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      token = Provider.of<Auth>(context, listen: false).token;
      order = Provider.of<OrderData>(context, listen: true);
      _isOrderLoading = false;
      if ([OrderStatus.created, OrderStatus.inProgress]
          .contains(order.status)) {
        setState(() {
          _isOrderLoading = true;
        });
        checkOrder();

        timer = Timer.periodic(const Duration(seconds: 2, milliseconds: 500),
            (timer) {
          checkOrder();
          if (![OrderStatus.created, OrderStatus.inProgress]
              .contains(order.status)) {
            timer.cancel();
            setState(() {
              _isOrderLoading = false;
            });
          }
          // GET ORDER STATUS
        });
      } else if (order.status == OrderStatus.error) {
        checkOrder();
        setState(() {
          _isOrderLoading = false;
        });
      }
    }
    _isInit = true;
    super.didChangeDependencies();
  }

  String get orderStatusText {
    var text = "history.order_status_title".tr();
    switch (order.status) {
      case OrderStatus.canceled:
        text += "history.order_status_canceled".tr();
        break;
      case OrderStatus.error:
        text += "history.order_status_error".tr();
        break;
      case OrderStatus.expired:
        text += "history.order_status_expired".tr();
        break;
      case OrderStatus.hold:
        text += "history.order_status_active".tr();
        break;
      case OrderStatus.active:
        text += "history.order_status_executed".tr();
        break;
      case OrderStatus.inProgress:
        text += "history.order_status_in_progress".tr();
        break;
      case OrderStatus.created:
        text += "history.order_status_created".tr();
        break;
      case OrderStatus.completed:
        text += "history.order_status_completed".tr();
        break;
      default:
    }
    if ([OrderStatus.created, OrderStatus.inProgress, OrderStatus.hold]
            .contains(order.status) &&
        order.isExpired) {
      text = "history.order_status_title".tr() +
          "history.order_status_expired".tr();
    }
    return text;
  }

  Color get orderStatusColor {
    if ([OrderStatus.created, OrderStatus.inProgress, OrderStatus.hold]
            .contains(order.status) &&
        order.isExpired) {
      return AppColors.dangerousColor;
    }
    if ([
      OrderStatus.hold,
      OrderStatus.inProgress,
      OrderStatus.created,
      OrderStatus.active,
      OrderStatus.completed
    ].contains(order.status)) {
      return AppColors.successColor;
    } else {
      return AppColors.dangerousColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultDialog(
      useProgressBar: _isOrderLoading,
      maxHeight: 600,
      title: "history.order_number".tr(namedArgs: {"id": order.id.toString()}),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: OrderElementWidget(
                  iconData: Icons.location_on,
                  text: order.place ?? "unknown".tr(),
                  iconSize: 26,
                  textStyle: AppStyles.bodyText2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: OrderElementWidget(
                  iconData: Icons.shopping_bag_outlined,
                  text: order.title,
                  iconSize: 26,
                  textStyle: AppStyles.bodyText2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: OrderElementWidget(
                  iconData: Icons.calendar_month,
                  text: order.humanDate,
                  iconSize: 26,
                  textStyle: AppStyles.bodyText2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: OrderElementWidget(
                  iconData: Icons.attach_money,
                  text: order.humanPrice,
                  iconSize: 26,
                  textStyle: AppStyles.bodyText2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: OrderElementWidget(
                  iconData: Icons.playlist_add_check_circle_outlined,
                  text: orderStatusText,
                  iconSize: 26,
                  textStyle:
                      AppStyles.bodyText2.copyWith(color: orderStatusColor),
                ),
              ),
              const OrderActionsWidget(),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(
                  child: Text(
                    "report_problem".tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.dangerousColor),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FeedbackScreen(order: order),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> checkOrder() async {
    try {
      var updated = await order.checkOrder(token);
      return updated;
    } catch (e) {
      print("error: $e");
      return false;
    }
  }
}
