import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class PhoneFormatPage extends StatefulWidget {
  @override
  _PhoneFormatPageState createState() => _PhoneFormatPageState();
}

class _PhoneFormatPageState extends State<PhoneFormatPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  PhoneCountryData? _countryData;
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _russianPhoneController =
      TextEditingController(text: '9998887766');
  PhoneCountryData? _initialCountryData;
  PhoneCountryData? _initialCountryDataFiltered;

  @override
  void dispose() {
    _phoneController.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _getText('Type a phone number here and it will automatically' +
                      ' format and detect a country. If the number' +
                      ' does not format this means it\'s can\'t be validated\n\n' +
                      'The USA and Canada share the same phone code (+1) ' +
                      'and by default it\'s detected as the USA. In this case' +
                      ' you can apply your own mechanism to display a country'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type a phone number',
                      hintStyle: TextStyle(color: Colors.black.withOpacity(.3)),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      PhoneInputFormatter(
                        onCountrySelected: (PhoneCountryData? countryData) {
                          setState(() {
                            _countryData = countryData;
                          });
                        },
                        allowEndlessPhone: false,
                      )
                    ],
                  ),
                  _getText(
                    _countryData == null
                        ? 'A country is not detected'
                        : 'The country is: ${_countryData?.country}',
                  ),
                  SizedBox(height: 30.0),
                  _getText(
                    'The next input uses a predefined country code',
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CountryDropdown(
                          printCountryName: true,
                          initialCountryData:
                              PhoneCodes.getPhoneCountryDataByCountryCode(
                            'RU',
                          ),
                          onCountrySelected: (PhoneCountryData countryData) {
                            setState(() {
                              _initialCountryData = countryData;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          key: ValueKey(_initialCountryData),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: _initialCountryData
                                ?.phoneMaskWithoutCountryCode,
                            hintStyle:
                                TextStyle(color: Colors.black.withOpacity(.3)),
                            errorStyle: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            PhoneInputFormatter(
                              allowEndlessPhone: true,
                              defaultCountryCode:
                                  _initialCountryData?.countryCode,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 30.0),
                  _getText(
                    'The next input uses a predefined country code',
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: CountryDropdown(
                          printCountryName: true,
                          initialCountryData:
                              PhoneCodes.getPhoneCountryDataByCountryCode(
                            'RU',
                          ),
                          filter: PhoneCodes.findCountryDatasByCountryCodes(
                            countryIsoCodes: [
                              'RU',
                              'BR',
                              'DE',
                            ],
                          ),
                          onCountrySelected: (PhoneCountryData countryData) {
                            setState(() {
                              _initialCountryDataFiltered = countryData;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 10.0),
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          key: Key(_initialCountryDataFiltered?.countryCode ??
                              'country2'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: _initialCountryDataFiltered
                                ?.phoneMaskWithoutCountryCode,
                            hintStyle:
                                TextStyle(color: Colors.black.withOpacity(.3)),
                            errorStyle: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            PhoneInputFormatter(
                              allowEndlessPhone: true,
                              defaultCountryCode:
                                  _initialCountryDataFiltered?.countryCode,
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  _getText(
                    _initialCountryDataFiltered == null
                        ? 'A country is not detected'
                        : 'The country is: ${_initialCountryDataFiltered?.country}',
                  ),
                  SizedBox(
                    height: 10.0,
                  ),
                  _getText(
                    'You can also use formatAsPhoneNumber(string) ' +
                        'function to format a string containing a phone number. E.g ' +
                        '79998885544 will be formatted to +7 (999) 888-55-44',
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type a phone to format',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    controller: _phoneController,
                    validator: (String? value) {
                      if (!isPhoneValid(
                        value ?? '',
                        allowEndlessPhone: true,
                      )) {
                        return 'Phone is invalid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    height: 50,
                    child: MaterialButton(
                      textColor: Colors.white,
                      color: Colors.blue,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _phoneController.text = formatAsPhoneNumber(
                                _phoneController.text,
                                allowEndlessPhone: false,
                              ) ??
                              '';
                        }
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Center(
                              child: Text(
                                'Apply Format',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Type a phone to format',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    controller: _russianPhoneController,
                    validator: (String? value) {
                      if (!isPhoneValid(
                        value ?? '',
                        allowEndlessPhone: true,
                        defaultCountryCode: 'RU',
                      )) {
                        return 'Phone is invalid';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 50,
                    child: MaterialButton(
                      textColor: Colors.white,
                      color: Colors.pink,
                      onPressed: () {
                        _russianPhoneController.text = formatAsPhoneNumber(
                              _russianPhoneController.text,
                              allowEndlessPhone: false,
                              defaultCountryCode: 'RU',
                            ) ??
                            '';
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Center(
                              child: Text(
                                'Apply Format for RU +7',
                              ),
                            ),
                          ),
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
