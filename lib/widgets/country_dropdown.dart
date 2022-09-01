import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_multi_formatter/widgets/country_flag.dart';

typedef CountryItemBuilder = Widget Function(PhoneCountryData);

class CountryDropdown extends StatefulWidget {
  final CountryItemBuilder? selectedItemBuilder;
  final CountryItemBuilder? listItemBuilder;
  final bool printCountryName;
  final String? initialCountryCode;
  final ValueChanged<PhoneCountryData> onCountrySelected;

  /// [selectedItemBuilder] use this if you want to make
  /// the selected item look the way you want
  /// [listItemBuilder] the same as [selectedItemBuilder] but
  /// to present items in an open list
  /// [printCountryName] if true, it will display
  /// a country name under its flat and country code while
  /// the menu is open
  const CountryDropdown({
    Key? key,
    required this.onCountrySelected,
    this.selectedItemBuilder,
    this.listItemBuilder,
    this.initialCountryCode,
    this.printCountryName = false,
  }) : super(key: key);

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  @override
  void initState() {
    _widgetsBinding.addPostFrameCallback((timeStamp) {
      widget.onCountrySelected(_initialValue);
    });
    super.initState();
  }

  dynamic get _widgetsBinding {
    return WidgetsBinding.instance;
  }

  PhoneCountryData get _initialValue {
    if (widget.initialCountryCode != null) {
      return PhoneCodes.getAllCountryDatas().firstWhereOrNull(
              (c) => c.countryCode == widget.initialCountryCode!.toUpperCase()) ??
          PhoneCodes.getAllCountryDatas().first;
    }
    return PhoneCodes.getAllCountryDatas().first;
  }

  Widget _buildSelectedLabel(
    PhoneCountryData phoneCountryData,
  ) {
    if (widget.selectedItemBuilder != null) {
      return widget.selectedItemBuilder!.call(phoneCountryData);
    }
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: CountryFlag(
            countryId: phoneCountryData.countryCode!,
          ),
        ),
        Flexible(
          child: Text(
            '+${phoneCountryData.phoneCode}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildListLabel(
    PhoneCountryData phoneCountryData,
  ) {
    if (widget.listItemBuilder != null) {
      return widget.listItemBuilder!.call(phoneCountryData);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CountryFlag(
                countryId: phoneCountryData.countryCode!,
              ),
            ),
            Text('+${phoneCountryData.phoneCode}'),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PhoneCountryData>(
      key: Key('countryDropdown'),
      isDense: true,
      isExpanded: true,
      itemHeight: 48.0,
      selectedItemBuilder: (c) {
        return PhoneCodes.getAllCountryDatas()
            .map(
              (e) => DropdownMenuItem<PhoneCountryData>(
                child: _buildSelectedLabel(e),
                value: e,
              ),
            )
            .toList();
      },
      items: PhoneCodes.getAllCountryDatas()
          .map(
            (e) => DropdownMenuItem<PhoneCountryData>(
              child: _buildListLabel(e),
              value: e,
            ),
          )
          .toList(),
      onChanged: (PhoneCountryData? data) {
        if (data != null) {
          widget.onCountrySelected(data);
        }
      },
      value: _initialValue,
    );
  }
}
