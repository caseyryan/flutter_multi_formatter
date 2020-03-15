import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class PhoneFormatPage extends StatefulWidget {
  @override
  _PhoneFormatPageState createState() => _PhoneFormatPageState();
}

class _PhoneFormatPageState extends State<PhoneFormatPage> {

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PhoneCountryData _countryData;
  TextEditingController _phoneController = TextEditingController();
  /// this callback is called in PhoneInputFormatter when 
  /// a country is detected by a phone code
  void _onCountrySelected(PhoneCountryData countryData) {
    setState(() {
      _countryData = countryData;
    });
    
  }
  @override 
  void dispose() {
    _phoneController?.dispose();
    super.dispose();
  }
  
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
          title: Text('Phone Formatter Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _getText(
                    'Type a phone number here and it will automatically' + 
                    ' format and detect a country. If the number' + 
                    ' does not format this means it\'s can\'t be validated\n\n' +
                    'The USA and Canada share the same phone code (+1) ' + 
                    'and by default it\'s detected as the USA. In this case' + 
                    ' you can apply your own mechanism to display a country'
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type a phone number',
                      hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                      errorStyle: TextStyle(color: Colors.red)
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      PhoneInputFormatter(onCountrySelected: _onCountrySelected)
                    ],
                  ),
                  _getText(_countryData == null 
                    ? 'A country is not detected' 
                    : 'The country is: ${_countryData.country}'
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  _getText(
                    'You can also use formatAsPhoneNumber(string) ' + 
                    'function to format a string containing a phone number. E.g ' + 
                    '79998885544 will be formatted to +7 (999) 888-55-44'
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type a phone to format',
                      hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                      errorStyle: TextStyle(color: Colors.red)
                    ),
                    keyboardType: TextInputType.phone,
                    controller: _phoneController,
                    validator: (String value) {
                      if (!isPhoneValid(value)) {
                        return 'Phone is invalid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20,),
                  Container(
                    height: 50,
                    child: RaisedButton(
                      textColor: Colors.white,
                      color: Colors.blue,
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          _phoneController.text = formatAsPhoneNumber(_phoneController.text);
                        }
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Center(child: Text('Apply Format'))),
                        ],
                      ),
                    ),
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