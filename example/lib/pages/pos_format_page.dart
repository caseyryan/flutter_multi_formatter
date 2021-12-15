import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class PosFormatPage extends StatelessWidget {
  const PosFormatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Pos Formatter Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter a numeric value',
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    errorStyle: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: const [PosInputFormatter()],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
