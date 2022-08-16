import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../screens/menu.dart';
import '../../screens/pay_screen.dart';
import '../../screens/success_order_screen.dart';
import '../../api/http_exceptions.dart';
import '../../api/orders.dart';
import '../../api/lockers.dart';
import '../../providers/auth.dart';
import '../../providers/orders.dart';
import '../../utilities/styles.dart';
import '../../models/lockers.dart';
import '../../models/services.dart';
import '../../widgets/main_block.dart';
import '../../widgets/screen_title.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/tariff_dialog.dart';
import '../../widgets/sww_dialog.dart';

class SizeSelectionScreen extends StatefulWidget {
  static const routeName = '/size-selection';

  const SizeSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SizeSelectionScreen> createState() => _SizeSelectionScreenState();
}

class _SizeSelectionScreenState extends State<SizeSelectionScreen> {
  late bool _orderCreating;
  late Service? currentService;
  String? token;
  late Locker? locker;
  late List<ACLCellType> cellTypes;
  late Future _getFreeCellsFuture;
  var isInit = false;

  Future<List<CellStatus>?> _obtainGetFreeCellsFuture() async {
    token = Provider.of<Auth>(context, listen: false).token;
    currentService =
        Provider.of<ServiceNotifier>(context, listen: false).service;
    if (currentService == null) {
      Navigator.pushNamedAndRemoveUntil(
          context, MenuScreen.routeName, (route) => false);
      return null;
    }
    cellTypes = currentService?.data["cell_types"] as List<ACLCellType>;

    locker = Provider.of<LockerNotifier>(context, listen: false).locker;

    try {
      final freeCells = await LockerApi.getFreeCells(locker?.lockerId ?? 0,
          service: ServiceCategoryExt.typeToString(currentService!.category),
          token: token);
      if (freeCells.isEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => SomethingWentWrongDialog(
            title: "acl.no_free_cells".tr(),
            bodyMessage: "acl.no_free_cells_detail".tr(),
          ),
        ).then((value) => Navigator.pushNamedAndRemoveUntil(
            context, MenuScreen.routeName, (route) => false));

        return null;
      }
      return freeCells;
    } catch (e) {
      await showDialog(
        context: context,
        builder: (ctx) => SomethingWentWrongDialog(
          title: "acl.no_free_cells".tr(),
          bodyMessage: "acl.technical_error".tr(),
        ),
      ).then((value) => Navigator.pushNamedAndRemoveUntil(
          context, MenuScreen.routeName, (route) => false));
      return null;
    }
  }

  @override
  void initState() {
    _orderCreating = false;
    _getFreeCellsFuture = _obtainGetFreeCellsFuture();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
        appBar: AppBar(
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(size: 32),
        ),
        body: FutureBuilder(
          future: _getFreeCellsFuture,
          builder: (ctx, dataSnapshot) {
            if (dataSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else {
              if (dataSnapshot.error != null) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "history.cant_display_orders".tr(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              } else {
                final cellStatuses = dataSnapshot.data as List<CellStatus>?;
                if (cellStatuses == null || cellStatuses.isEmpty) {
                  return const Center();
                } else {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: ScreenTitle(
                          'acl.select_size'.tr(),
                          subTitle: 'acl.service'.tr(
                              namedArgs: {"service": currentService!.title}),
                        ),
                      ),
                      MainBlock(
                          child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: GridView(
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 250,
                                    childAspectRatio:
                                        mediaQuery.size.width <= 310 ? 2 : 1),
                            shrinkWrap: true,
                            children: cellTypes.map((size) {
                              final index = cellStatuses.indexWhere((element) =>
                                  element.isThisTypeId(size.id.toString()));
                              return cellSizeTile(
                                  context: context,
                                  mediaQuery: mediaQuery,
                                  serviceCategoryType:
                                      ServiceCategoryExt.typeToString(
                                          currentService!.category),
                                  algorithmType: currentService!
                                      .data["algorithm"] as AlgorithmType,
                                  tariffSelectionType: currentService!
                                          .data["tariff_selection_type"]
                                      as TariffSelectionType,
                                  locker: locker,
                                  cellType: size,
                                  color: currentService!.color,
                                  isExistFree: index > -1);
                            }).toList(),
                          ),
                        ),
                      )),
                    ],
                  );
                }
              }
            }
          },
        ));
  }

  void tariffSelection({
    required ACLCellType cellType,
    required Color tileColor,
    required int? lockerId,
    required String serviceCategoryType,
    required AlgorithmType algorithmType,
    required BuildContext context,
  }) async {
    var chosenTariff = await showDialog<Tariff>(
      context: context,
      builder: (ctx) => TariffDialog(
        cellType,
        tileColor: tileColor,
      ),
    );
    if (chosenTariff != null) {
      String? orderedCell;
      try {
        final res = await LockerApi.getFreeCells(lockerId ?? 0,
            service: serviceCategoryType, typeId: cellType.id, token: token);
        if (res.isEmpty) {
          await showDialog(
              context: context,
              builder: (ctx) => SomethingWentWrongDialog(
                    title: "acl.no_free_cells".tr(),
                    bodyMessage: "acl.no_free_cells__select_another_size".tr(),
                  ));
          return;
        } else {
          orderedCell = res.first.cellId;
        }
      } catch (e) {
        if (e is HttpException) {
          if (e.statusCode == 400) {
            await showDialog(
                context: context,
                builder: (ctx) => SomethingWentWrongDialog(
                    bodyMessage: "complex_offline".tr()));
            return;
          }
        }
        await showDialog(
            context: context,
            builder: (ctx) => const SomethingWentWrongDialog());
        return;
      }

      var helperText = "create_order.order_created_with_cell_N__pay"
          .tr(namedArgs: {"cell": orderedCell});

      Map<String, Object> extraData = {};
      extraData["type"] = "paid";
      extraData["time"] = chosenTariff.seconds;
      extraData["paid"] = chosenTariff.priceInCoins;
      extraData["hourly_pay"] = chosenTariff.priceInCoins;
      extraData["service"] = serviceCategoryType;
      extraData["algorithm"] = AlgorithmTypeExt.toStr(algorithmType);
      extraData["cell_id"] = orderedCell;
      if (cellType.overduePayment != null) {
        extraData["overdue_payment"] = {
          "time": cellType.overduePayment!.seconds,
          "price": cellType.overduePayment!.priceInCoins,
        };
      }

      final item = {"cell_type": cellType, "chosen_tariff": chosenTariff};
      try {
        OrderApi.createOrder(
                lockerId ?? 0, "acl.service_acl".tr(), extraData, token,
                isTempBook: true, lang: context.locale.languageCode)
            .then((value) => Navigator.pushNamedAndRemoveUntil(
                    context, PayScreen.routeName, (route) => false, arguments: {
                  "order": value,
                  "title": helperText,
                  "item": item
                }));
      } catch (e) {
        await showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                content: Text("ERROR: $e"),
              );
            });
      }
    }
  }

  void createFreeOrder(
      BuildContext context,
      int? lockerId,
      String serviceCategoryType,
      AlgorithmType algorithmType,
      ACLCellType cellType) async {
    var confirmDialog = await showDialog(
        context: context,
        builder: (ctx) {
          List<TextSpan> texts = [];

          if (cellType.tariff.isNotEmpty) {
            texts.add(TextSpan(text: 'create_order.max_free_time'.tr()));
            texts.add(TextSpan(
                text: '${cellType.tariff[0].humanEqualHours}. ',
                style: const TextStyle(fontWeight: FontWeight.bold)));
            texts.add(
                TextSpan(text: "create_order.confirm_or_cancel_order".tr()));
          } else {
            texts.add(TextSpan(
                text: "create_order.after_confirmation_open_cell__confirm_it"
                    .tr()));
          }
          if (cellType.overduePayment != null) {
            texts.add(TextSpan(
                text: '\n\n${'create_order.debt_information'.tr()}',
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textColor.withOpacity(0.6))));
            texts.add(
              TextSpan(
                text: 'create_order.debt_time_price'.tr(namedArgs: {
                  "time": cellType.overduePayment!.humanEqualHours,
                  "price": cellType.overduePayment!.priceWithCurrency("UAH")
                }),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textColor.withOpacity(0.6)),
              ),
            );
          }

          return ConfirmDialog(
            title: "attention_title".tr(),
            content: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                  style: const TextStyle(fontSize: 18, color: Colors.black45),
                  children: texts),
            ),
          );
        });

    if (confirmDialog != null) {
      String? orderedCell;
      try {
        final res = await LockerApi.getFreeCells(lockerId ?? 0,
            service: serviceCategoryType, typeId: cellType.id, token: token);
        if (res.isEmpty) {
          await showDialog(
              context: context,
              builder: (ctx) => SomethingWentWrongDialog(
                    title: "acl.no_free_cells".tr(),
                    bodyMessage: "acl.no_free_cells__select_another_size".tr(),
                  ));
          return;
        } else {
          orderedCell = res.first.cellId;
        }
      } catch (e) {
        if (e is HttpException) {
          if (e.statusCode == 400) {
            await showDialog(
                context: context,
                builder: (ctx) => SomethingWentWrongDialog(
                      bodyMessage: "complex_offline".tr(),
                    ));
            return;
          }
        }
        await showDialog(
            context: context,
            builder: (ctx) => const SomethingWentWrongDialog());
        return;
      }

      var helperText = "create_order.order_created_with_cell_N"
          .tr(namedArgs: {"cell": orderedCell.padLeft(2, '0')});
      if (algorithmType == AlgorithmType.qrReading) {
        helperText += ' ${"create_order.contain_qr_code_info".tr()}';
      } else if (algorithmType == AlgorithmType.enterPinOnComplex) {
        helperText += ' ${"create_order.contain_pin_code_info".tr()}';
      } else {
        helperText += ' ${"create_order.contain_all_needed_info".tr()}';
      }

      Map<String, Object> extraData = {};
      extraData["type"] = "free";
      extraData["time"] = cellType.tariff.first.seconds;
      extraData["paid"] = 0;
      extraData["hourly_pay"] = cellType.tariff.first.priceInCoins;
      extraData["service"] =
          ServiceCategoryExt.typeToString(ServiceCategory.acl);
      extraData["algorithm"] = AlgorithmTypeExt.toStr(algorithmType);
      extraData["cell_id"] = orderedCell;
      if (cellType.overduePayment != null) {
        extraData["overdue_payment"] = {
          "time": cellType.overduePayment!.seconds,
          "price": cellType.overduePayment!.priceInCoins,
        };
      }

      try {
        if (!mounted) return;
        final orderData =
            await Provider.of<OrdersNotifier>(context, listen: false).addOrder(
                lockerId ?? 0, "acl.service_acl".tr(),
                data: extraData, lang: context.locale.languageCode);
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
            context, SuccessOrderScreen.routeName, (route) => false,
            arguments: {"order": orderData, "title": helperText});
      } catch (e) {
        await showDialog(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                content: Text("ERROR: $e"),
              );
            });
      }
    }
  }

  Widget cellSizeTile(
      {required BuildContext context,
      required MediaQueryData mediaQuery,
      required String serviceCategoryType,
      required AlgorithmType algorithmType,
      required TariffSelectionType tariffSelectionType,
      required Locker? locker,
      required ACLCellType cellType,
      required Color color,
      bool isExistFree = true}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
            primary: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        onPressed: isExistFree
            ? () {
                if (locker?.type == LockerType.free) {
                  setState(() {
                    _orderCreating = true;
                  });
                  createFreeOrder(context, locker?.lockerId,
                      serviceCategoryType, algorithmType, cellType);
                  setState(() {
                    _orderCreating = false;
                  });
                } else {
                  tariffSelection(
                    cellType: cellType,
                    lockerId: locker?.lockerId,
                    serviceCategoryType: serviceCategoryType,
                    algorithmType: algorithmType,
                    tileColor: color,
                    context: context,
                  );
                }
              }
            : null,
        child: _orderCreating
            ? const Center(
                child: SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    )))
            : Center(
                child: mediaQuery.size.width <= 310
                    ? Row(
                        children: [
                          if (cellType.symbol != null)
                            Expanded(
                              flex: 1,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(
                                  cellType.symbol ?? "",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: FittedBox(
                                child: Text(
                                  cellType.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          if (cellType.symbol != null)
                            Expanded(
                              flex: 2,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: Text(
                                  cellType.symbol ?? "",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              child: FittedBox(
                                child: Text(
                                  cellType.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                        ],
                      ),
              ),
      ),
    );
  }
}
