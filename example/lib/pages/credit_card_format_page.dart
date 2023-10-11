import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class CreditCardFormatPage extends StatefulWidget {
  @override
  _CreditCardFormatPageState createState() => _CreditCardFormatPageState();
}

class _CreditCardFormatPageState extends State<CreditCardFormatPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  CardSystemData? _cardSystemData;

  Widget _getText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15.0,
      ),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Card Formatter Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _getText(
                      'This form allows you to easily type a credit / debit card data'),
                  SizedBox(height: 20.0),
                  _getText('Any small latin letter'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '#### #### #### ####',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      MaskedInputFormatter(
                        "#### #### #### ####",
                        allowedCharMatcher: RegExp(r'[a-z]+'),
                      ),
                    ],
                  ),
                  _getText('Card number'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'CARD NUMBER',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CreditCardNumberInputFormatter(
                        onCardSystemSelected: (CardSystemData? cardSystemData) {
                          setState(() {
                            _cardSystemData = cardSystemData;
                          });
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                    ),
                    child: Text(
                      _cardSystemData?.system ?? '',
                      textAlign: TextAlign.left,
                    ),
                  ),
                  _getText(
                    'Valid through\n (this formatter won\'t let you type the "month" part value larger than 12)',
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '00/00',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CreditCardExpirationDateFormatter(),
                    ],
                  ),
                  _getText('CVV code'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '000',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      CreditCardCvcInputFormatter(
                        isAmericanExpress: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
