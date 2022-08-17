import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uz_app/providers/auth.dart';
import 'package:uz_app/screens/sceleton_screen.dart';
import 'package:uz_app/utilities/styles.dart';
import 'package:uz_app/widgets/button.dart';

class FeedbackScreen extends StatelessWidget {
  static const routeName = '/feedback';
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return SkeletonScreen(
        title: "Зворотній зв'язок",
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              constraints: const BoxConstraints(maxWidth: 600),
              decoration: screenSize.width > 800 && screenSize.height > 600
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color.fromARGB(255, 226, 223, 217),
                    )
                  : null,
              child: FeedbackForm(
                orderId: 'some order',
              ),
            ),
          ),
        ));
  }
}

class FeedbackForm extends StatefulWidget {
  final String? orderId;
  const FeedbackForm({Key? key, this.orderId}) : super(key: key);

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  String _communicateMethod = 'email';
  String _currentOrder = 'Order 1';

  final List<String> orders = [
    'Order 1',
    'Order 2',
    'Order 3',
    'Order 4',
    'Order 5'
  ];
  late TextEditingController _emailController;
  late TextEditingController _telegramController;
  late TextEditingController _phoneController;
  late TextEditingController _messageController;

  bool _emailIsNotValid = false;
  bool _telegramIsNotValid = false;
  bool _phoneIsNotValid = false;
  bool _isSending = false;

  @override
  void initState() {
    _emailController = TextEditingController();
    _telegramController = TextEditingController();
    _phoneController = TextEditingController();
    _messageController = TextEditingController();
    Future.delayed(Duration.zero, () {
      _phoneController.text =
          Provider.of<Auth>(context, listen: false).phone ?? '';
    });
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _telegramController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              "Як з вами зв'язатись?",
              style: ThemeData().textTheme.headline3,
            ),
          ),
        ),
        Opacity(
          opacity: _communicateMethod == 'email' ? 1.0 : 0.5,
          child: RadioOption(
            text: 'e-mail',
            value: 'email',
            textField: TextField(
              onChanged: (value) {
                if (_emailIsNotValid) {
                  setState(() {
                    _emailIsNotValid = !_emailIsNotValid;
                  });
                }
              },
              readOnly: _communicateMethod != 'email',
              controller: _emailController,
              decoration: textFieldInputDecoration(
                  isError: _emailIsNotValid, hintText: "Ваш email"),
              autofillHints: const [AutofillHints.email],
            ),
            onChange: onChange,
            groupValue: _communicateMethod,
          ),
        ),
        Opacity(
          opacity: _communicateMethod == 'telegram' ? 1.0 : 0.5,
          child: RadioOption(
            text: 'telegram',
            value: 'telegram',
            textField: TextField(
              readOnly: _communicateMethod != 'telegram',
              controller: _telegramController,
              onChanged: (value) {
                if (_telegramIsNotValid) {
                  setState(() {
                    _telegramIsNotValid = !_telegramIsNotValid;
                  });
                }
              },
              decoration: textFieldInputDecoration(
                  isError: _telegramIsNotValid, hintText: "Ваш телеграм id"),
            ),
            onChange: onChange,
            groupValue: _communicateMethod,
          ),
        ),
        Opacity(
          opacity: _communicateMethod == 'call' ? 1.0 : 0.5,
          child: RadioOption(
            text: 'подзвонити на',
            value: 'call',
            textField: TextField(
              readOnly: _communicateMethod != 'call',
              controller: _phoneController,
              onChanged: (value) {
                if (_phoneIsNotValid) {
                  setState(() {
                    _phoneIsNotValid = !_phoneIsNotValid;
                  });
                }
              },
              decoration: textFieldInputDecoration(
                  isError: _phoneIsNotValid, hintText: "Номер телефону"),
            ),
            onChange: onChange,
            groupValue: _communicateMethod,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              "Оберіть проблемне замовлення",
              style: ThemeData().textTheme.headline3,
            ),
          ),
        ),
        ProblemOrderSelect(
          initText: _currentOrder,
          values: orders,
          onChange: (String? newValue) {
            setState(() {
              if (newValue != null) {
                _currentOrder = newValue;
              }
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 10),
          child: Align(
            alignment: Alignment.topLeft,
            child: Text(
              "Повідомлення (необов'язково)",
              style: ThemeData().textTheme.headline3,
            ),
          ),
        ),
        TextField(
          maxLines: 5,
          controller: _messageController,
          decoration: textFieldInputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              hintText: "Ваше повідомлення, наприклад, не відчинилась комірка"),
        ),
        const SizedBox(height: 40),
        ElevatedDefaultButton(
          onPressed: _isSending ? () {} : sendFeedback,
          child: _isSending
              ? Container(
                  padding: const EdgeInsets.all(5),
                  width: 26,
                  height: 26,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                  ))
              : const Text(
                  'Відправити',
                  style: TextStyle(fontSize: 20),
                ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void sendFeedback() async {
    String? isNotValidMessage;
    String? communicateMethodValue;
    switch (_communicateMethod) {
      case 'email':
        bool emailValid = RegExp(
                r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(_emailController.text);
        if (_emailController.text.isEmpty || !emailValid) {
          setState(() => _emailIsNotValid = true);
          isNotValidMessage = 'email not valid!';
        }
        communicateMethodValue = _emailController.text;
        break;
      case 'telegram':
        if (_telegramController.text.length < 5) {
          setState(() => _telegramIsNotValid = true);
          isNotValidMessage = 'telegram id is not valid!';
        }
        communicateMethodValue = _telegramController.text;
        break;
      case 'call':
        if (_phoneController.text.length < 5) {
          setState(() => _phoneIsNotValid = true);
          isNotValidMessage = 'phone is not valid!';
        }
        communicateMethodValue = _phoneController.text;
        break;
      default:
        return;
    }

    if (isNotValidMessage != null) {
      showSnackbarMessage(isNotValidMessage);
      return;
    }

    var data = {
      'type': _communicateMethod,
      'value': communicateMethodValue,
      'orderId': _currentOrder,
      'message': _messageController.text,
    };
    setState(() => _isSending = true);
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isSending = false);
    showSnackbarMessage(
        "Повідомлення відправлено, з вами зв'яжуться через декілька хвилин");
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void showSnackbarMessage(String text, {IconData? icon}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(buildSnackBar(text, icon: icon));
  }

  SnackBar buildSnackBar(String text, {IconData? icon}) {
    return SnackBar(
      backgroundColor: AppColors.secondaryColor,
      content: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void onChange(String? value) {
    setState(() {
      _communicateMethod = value!;
    });
  }

  InputDecoration textFieldInputDecoration({
    String hintText = "",
    contentPadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    isError = false,
  }) {
    return InputDecoration(
        contentPadding: contentPadding,
        fillColor: Colors.white,
        filled: true,
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              width: 2.0, color: Theme.of(context).colorScheme.background),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
              width: 0.0, color: isError ? Colors.red : Colors.transparent),
        ),
        hoverColor: Colors.white);
  }
}

class RadioOption extends StatelessWidget {
  final String text;
  final String groupValue;
  final String value;
  final Function(String?)? onChange;
  final TextField? textField;
  const RadioOption(
      {required this.text,
      this.textField,
      required this.value,
      this.onChange,
      required this.groupValue,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      horizontalTitleGap: 5,
      title: Row(
        children: [
          Text(text),
          const SizedBox(width: 15),
          Expanded(
            child: Material(
              elevation: 10,
              shadowColor: const Color(0x10A7B0C0),
              borderRadius: BorderRadius.circular(16),
              child: textField,
            ),
          ),
        ],
      ),
      leading: Radio(
        value: value,
        groupValue: groupValue,
        activeColor: const Color(0xFF6200EE),
        onChanged: onChange,
      ),
    );
  }
}

class ProblemOrderSelect extends StatelessWidget {
  final String initText;
  final List<String> values;
  final Function(String?) onChange;
  const ProblemOrderSelect({
    required this.initText,
    required this.values,
    required this.onChange,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      focusColor: Colors.transparent,
      decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          fillColor: Colors.white,
          filled: true,
          hintStyle: const TextStyle(color: Colors.grey),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
                width: 2.0, color: Theme.of(context).colorScheme.background),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(width: 0.0, color: Colors.transparent),
          ),
          hoverColor: Colors.white),
      value: initText,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      elevation: 16,
      isExpanded: true,
      onChanged: (String? newValue) => onChange(newValue),
      items: values.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
