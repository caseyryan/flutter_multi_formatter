import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class BitcoinValidatorPage extends StatefulWidget {
  @override
  _BitcoinValidatorPageState createState() => _BitcoinValidatorPageState();
}

class _BitcoinValidatorPageState extends State<BitcoinValidatorPage> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  BitcoinWalletDetails? _bitcoinWalletDetails;
  BitcoinWalletType? _bitcoinWalletType;
  bool? _isValid;
  FormFieldValidator<String?> _validator = (String? v) {
    return null;
  };

  Widget _getText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0),
      child: Text(text),
    );
  }

  Widget _buildButton({
    required IconData iconData,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
        bottom: 10,
      ),
      child: Container(
        height: 50,
        child: ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(
              color,
            ),
          ),
          onPressed: onPressed,
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

  /// A small hack to avoid warnings on flutter 2 and 3
  dynamic get _widgetsBinding {
    return WidgetsBinding.instance;
  }

  void _onValidatePressed() {
    _widgetsBinding?.addPostFrameCallback((timeStamp) {
      setState(() {
        _formKey.currentState!.save();
        _formKey.currentState!.validate();
      });
    });
  }

  Widget _buildWalletDetails() {
    String text = '';
    if (_isValid != null) {
      text = 'Is valid: $_isValid';
    } else if (_bitcoinWalletType != null) {
      text = 'Wallet type: ${enumToString(_bitcoinWalletType)}';
    } else if (_bitcoinWalletDetails != null) {
      text = _bitcoinWalletDetails.toString();
    } else {
      return SizedBox(height: 20.0);
    }
    return Padding(
      padding: const EdgeInsets.only(
        top: 20.0,
        bottom: 20.0,
      ),
      child: Text(text),
    );
  }

  void _reset() {
    _isValid = null;
    _bitcoinWalletType = null;
    _bitcoinWalletDetails = null;
  }

  String? _fullDetailsValidator(String? value) {
    _bitcoinWalletDetails = getBitcoinWalletDetails(value);
    if (_bitcoinWalletDetails?.isValid != true) {
      _bitcoinWalletDetails = null;
      return 'Invalid wallet address';
    }
    return null;
  }

  String? _typeValidator(String? value) {
    _bitcoinWalletType = getBitcoinWalletType(value);
    if (_bitcoinWalletType == BitcoinWalletType.None) {
      _bitcoinWalletType = null;
      return 'Invalid wallet address';
    }
    return null;
  }

  String? _simpleTrueFalseValidator(String? value) {
    _isValid = isBitcoinWalletValid(value);
    return null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Bitcoin Validator Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  _getText('BTC Wallet Details Check'),
                  TextFormField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter a BTC wallet address',
                      hintStyle: TextStyle(
                        color: Colors.black.withOpacity(.3),
                      ),
                      errorStyle: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    initialValue: '1BvBMSEYstWetqTFn5Au4m4GFg7xJaNVN2',
                    keyboardType: TextInputType.text,
                    validator: _validator,
                  ),
                  _buildWalletDetails(),
                  Text('Shows full details of a valid wallet'),
                  _buildButton(
                    color: Colors.red,
                    iconData: Icons.check,
                    label: 'Check Wallet Details',
                    onPressed: () {
                      _reset();
                      setState(() {
                        _validator = _fullDetailsValidator;
                        _onValidatePressed();
                      });
                    },
                  ),
                  Text('Only shows the type of a valid wallet'),
                  _buildButton(
                    color: Colors.pink[900]!,
                    iconData: Icons.check,
                    label: 'Simple Wallet Type Check',
                    onPressed: () {
                      _reset();
                      setState(() {
                        _validator = _typeValidator;
                        _onValidatePressed();
                      });
                    },
                  ),
                  Text('Simple validity check'),
                  _buildButton(
                    color: Colors.pink[500]!,
                    iconData: Icons.check,
                    label: 'Simple Wallet Type Check',
                    onPressed: () {
                      _reset();
                      setState(() {
                        _validator = _simpleTrueFalseValidator;
                        _onValidatePressed();
                      });
                    },
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
