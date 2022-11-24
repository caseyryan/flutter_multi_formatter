import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

class PinyinFormatterPage extends StatelessWidget {
  const PinyinFormatterPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text('Pinyin Formatter Demo'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: <Widget>[
                SelectableText(
                  "Example: \"wǒhěngāoxìngrènshinǐ\" must split into: \"wǒ'hěn'gāo'xìng'rèn'shi'nǐ\"\nYou can also type in plain english characters like \"wohengaoxingrenshini\" it will also work",
                ),
                SizedBox(height: 12.0),
                TextFormField(
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: 'Enter pinyin phrase',
                    hintStyle: TextStyle(
                      color: Colors.black.withOpacity(0.3),
                    ),
                    errorStyle: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: const [
                    PinyinFormatter(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
