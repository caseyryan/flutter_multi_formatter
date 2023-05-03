import 'package:example/pages/bitcoin_validator_page.dart';
import 'package:example/pages/credit_card_format_page.dart';
import 'package:example/pages/masked_formatter_page.dart';
import 'package:example/pages/money_format_page.dart';
import 'package:example/pages/phone_format_page.dart';
import 'package:example/pages/pos_format_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

import 'pages/pinyin_formatter_page.dart';

typedef PageBuilder = Widget Function();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Multi formatter demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void openPage(Widget page) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    PhoneInputFormatter.addAlternativePhoneMasks(
      countryCode: 'NZ',
      alternativeMasks: [
        '+00 (0) 000 0000',
        '+00 (00) 000 0000',
        '+00 (000) 000 0000',
      ],
    );
  }

  Widget _buildButton({
    required Color color,
    required IconData iconData,
    required String label,
    required PageBuilder pageBuilder,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
      ),
      child: Container(
        height: 50,
        child: MaterialButton(
          textColor: Colors.white,
          color: color,
          onPressed: () {
            openPage(
              pageBuilder(),
            );
          },
          child: Row(
            children: <Widget>[
              Icon(iconData),
              Expanded(
                child: Center(
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Formatters Demo App'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            30.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildButton(
                color: Colors.lightGreen,
                iconData: Icons.phone,
                label: 'Phone Formatter Demo',
                pageBuilder: () => PhoneFormatPage(),
              ),
              _buildButton(
                color: Colors.lightBlue,
                iconData: Icons.credit_card,
                label: 'Credit Card Formatter Demo',
                pageBuilder: () => CreditCardFormatPage(),
              ),
              _buildButton(
                color: Colors.orange,
                iconData: Icons.masks_outlined,
                label: 'Masked input formatter Demo',
                pageBuilder: () => MaskedFormatterPage(),
              ),
              _buildButton(
                color: Colors.pink[400]!,
                iconData: Icons.attach_money,
                label: 'Money formatter',
                pageBuilder: () => MoneyFormatPage(),
              ),
              _buildButton(
                color: Colors.green[600]!,
                iconData: Icons.attach_money,
                label: 'Bitcoin Validator',
                pageBuilder: () => BitcoinValidatorPage(),
              ),
              _buildButton(
                color: Colors.purple,
                iconData: Icons.money_off,
                label: 'Pos Formatter',
                pageBuilder: () => PosFormatPage(),
              ),
              _buildButton(
                color: Colors.red,
                iconData: Icons.abc,
                label: 'Chinese Pinyin Formatter',
                pageBuilder: () => PinyinFormatterPage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
