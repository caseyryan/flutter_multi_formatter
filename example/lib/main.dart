import 'package:example/pages/credit_card_format_page.dart';
import 'package:example/pages/phone_format_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


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
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (BuildContext context) {
        return page;
      }
    ));
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
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 50,
                child: RaisedButton(
                  textColor: Colors.white,
                  color: Colors.lightGreen,
                  onPressed: () {
                    openPage(PhoneFormatPage());
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.phone),
                      Expanded(child: Center(child: Text('Phone Formatter Demo'))),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 50.0,
              ),
              Container(
                height: 50,
                child: RaisedButton(
                  textColor: Colors.white,
                  color: Colors.lightBlue,
                  onPressed: () {
                    openPage(CreditCardFormatPage());
                  },
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.credit_card),
                      Expanded(child: Center(child: Text('Credit Card Formatter Demo'))),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
