import 'dart:collection';

import 'package:flutter/material.dart';

class CountryFlag extends StatefulWidget {
  static HashSet<String> _missingFlagCountryIds = HashSet();

  static bool hasFlagIcon(String countryId) {
    countryId = countryId.toLowerCase();
    return !_missingFlagCountryIds.contains(countryId);
  }

  final String countryId;
  final double width;
  final double height;
  final double borderRadius;

  const CountryFlag({
    Key? key,
    this.width = 40.0,
    this.height = 25.0,
    this.borderRadius = 2.0,
    required this.countryId,
  }) : super(key: key);

  @override
  _CountryFlagState createState() => _CountryFlagState();
}

class _CountryFlagState extends State<CountryFlag> {
  String get _countryId {
    return widget.countryId.toLowerCase();
  }

  String get _flagPath {
    return 'flags/png/$_countryId.png';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(
            widget.borderRadius,
          ),
        ),
        image: DecorationImage(
          image: AssetImage(
            _flagPath,
            package: 'flutter_multi_formatter',
          ),
          onError: (e, s) {
            setState(() {
              CountryFlag._missingFlagCountryIds.add(_countryId);
            });
          },
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
