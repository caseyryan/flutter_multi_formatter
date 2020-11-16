import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class MoneyFormatPage extends StatefulWidget {
  @override
  _MoneyFormatPageState createState() => _MoneyFormatPageState();
}

class _MoneyFormatPageState extends State<MoneyFormatPage> {

 
  
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
          title: Text('Money Formatter Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: <Widget>[
                _getText(
                  'Enter a number and it will be automatically formatted ' + 
                  'as a value in the US dollars with a leading \$ sign' + 
                  'When you need to switch to a fractional side, simply tap a (.) ' + 
                  ' period sign when the selection is right in front of a period'
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a numeric value',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                    errorStyle: TextStyle(color: Colors.red)
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MoneyInputFormatter(
                      trailingSymbol: MoneySymbols.DOLLAR_SIGN,
                      thousandSeparator: ThousandSeparator.Period,
                      // thousandSeparator: ThousandSeparator.Comma
                    )
                  ],
                ),
                
                _getText(
                  'This input adds a EUR sign at the end'
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a numeric value',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                    errorStyle: TextStyle(color: Colors.red)
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MoneyInputFormatter(
                      trailingSymbol: MoneySymbols.EURO_SIGN
                    )
                  ],
                ),
                _getText(
                  'When you need to add a space between a currency sign and' + 
                  ' your value, simply set a [useSymbolPadding] parameter to true' + 
                  '\nThis works for both the leading and the trailing symbols'
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a numeric value',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                    errorStyle: TextStyle(color: Colors.red)
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MoneyInputFormatter(
                      trailingSymbol: MoneySymbols.EURO_SIGN,
                      useSymbolPadding: true
                    )
                  ],
                ),
                _getText(
                  'You can also use another thousand separators by setting a [thousandSeparator] param ' + 
                  ' to one of the predefined enum values. This example uses ThousandSeparator.Space'
                ),
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter a numeric value',
                    hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                    errorStyle: TextStyle(color: Colors.red)
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    MoneyInputFormatter(
                      leadingSymbol: MoneySymbols.DOLLAR_SIGN,
                      useSymbolPadding: true,
                      thousandSeparator: ThousandSeparator.SpaceAndPeriodMantissa
                    )
                  ],
                ),
                _getText(
                  'You can also format a static string value like 123456' + 
                  ' to currency string by using toCurrencyString(...) function ' + 
                  'toCurrencyString("123456", leadingSymbol: "\$") -> ${toCurrencyString('123456', leadingSymbol: '\$')}'
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}