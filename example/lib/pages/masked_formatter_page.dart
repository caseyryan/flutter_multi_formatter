import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class MaskedFormatterPage extends StatefulWidget {
  @override
  _MaskedFormatterPageState createState() => _MaskedFormatterPageState();
}

class _MaskedFormatterPageState extends State<MaskedFormatterPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _result = '';

  Widget _getText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Masled Formatter Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _getText(
                    'Applies masked input formatter',
                  ),
                  SizedBox(height: 20.0),
                  _getText('Any char'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '#0# 0#0',
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
                        "#0# 0#0",
                        allowedCharMatcher: RegExp('[a-z]'),
                      ),
                    ],
                  ),
                  _getText('Retirement card(Numbers only)'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '000-000-000 00',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    // keyboardType: TextInputType.text,
                    inputFormatters: [
                      MaskedInputFormatter(
                        '000-000-000 00',
                        // anyCharMatcher: RegExp(r'[a-z]+'),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '(00) 00000-0000',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    // keyboardType: TextInputType.text,
                    inputFormatters: [
                      MaskedInputFormatter(
                        '(00) 00000-0000',
                        // anyCharMatcher: RegExp(r'[a-z]+'),
                      ),
                    ],
                  ),
                  _getText('Retirement card(Any chars)'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '###-###-### ##',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    // keyboardType: TextInputType.text,
                    inputFormatters: [
                      MaskedInputFormatter(
                        '###-###-### ##',
                        // anyCharMatcher: RegExp(r'[a-z]+'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(
                        () {
                          _result = MaskedInputFormatter('000-000-000 00')
                              .applyMask(
                                '12345678900',
                              )
                              .toString();
                        },
                      );
                    },
                    child: Text('Apply mask 000-000-000 00'),
                  ),
                  Text('12345678900'),
                  _getText('Result'),
                  Text(_result),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
