import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_multi_formatter/widgets/country_flag.dart';

typedef CountryItemBuilder = Widget Function(PhoneCountryData);

class CountryDropdown extends StatefulWidget {
  final CountryItemBuilder? selectedItemBuilder;
  final CountryItemBuilder? listItemBuilder;
  final bool printCountryName;
  final PhoneCountryData? initialCountryData;
  final List<PhoneCountryData>? filter;
  final ValueChanged<PhoneCountryData> onCountrySelected;

  final int elevation;
  final TextStyle? style;
  final Widget? icon;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double iconSize;
  final double? itemHeight;
  final Color? focusColor;
  final FocusNode? focusNode;
  final bool autofocus;
  final Color? dropdownColor;
  final InputDecoration? decoration;
  final FormFieldValidator<PhoneCountryData>? validator;
  final AutovalidateMode? autovalidateMode;
  final double? menuMaxHeight;
  final bool? enableFeedback;
  final AlignmentGeometry alignment;
  final bool triggerOnCountrySelectedInitially;

  /// [filter] if you need a predefined list of countries only,
  /// pass it here
  /// [initialCountryData] initial country data to be selected
  /// [selectedItemBuilder] use this if you want to make
  /// the selected item look the way you want
  /// [listItemBuilder] the same as [selectedItemBuilder] but
  /// to present items in an open list
  /// [printCountryName] if true, it will display
  /// a country name under its flat and country code while
  /// the menu is open
  /// [triggerOnCountrySelectedInitially] if you don't want onCountrySelected
  /// to be triggered right away if you set an initialPhoneCode param,
  /// pass false here. Description is here https://github.com/caseyryan/flutter_multi_formatter/issues/122
  const CountryDropdown({
    Key? key,
    this.selectedItemBuilder,
    this.listItemBuilder,
    this.printCountryName = false,
    this.initialCountryData,
    this.triggerOnCountrySelectedInitially = true,
    this.filter,
    required this.onCountrySelected,
    this.elevation = 8,
    this.style,
    this.icon,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.iconSize = 24.0,
    this.itemHeight = 60.0,
    this.focusColor,
    this.focusNode,
    this.autofocus = false,
    this.dropdownColor,
    this.decoration,
    this.validator,
    this.autovalidateMode,
    this.menuMaxHeight,
    this.enableFeedback,
    this.alignment = AlignmentDirectional.centerStart,
  }) : super(key: key);

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  PhoneCountryData? _initialValue;
  late List<PhoneCountryData> _countryItems;

  @override
  void initState() {
    _countryItems = widget.filter ?? PhoneCodes.getAllCountryDatas();
    if (widget.initialCountryData != null) {
      _initialValue = _countryItems
              .firstWhereOrNull((c) => c == widget.initialCountryData) ??
          _countryItems.first;
    }
    if (widget.triggerOnCountrySelectedInitially && _initialValue != null) {
      _widgetsBinding.addPostFrameCallback((timeStamp) {
        if (_initialValue != null) {
          widget.onCountrySelected(_initialValue!);
        }
      });
    }
    super.initState();
  }

  dynamic get _widgetsBinding {
    return WidgetsBinding.instance;
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        widget.printCountryName
            ? Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 5.0,
                  ),
                  child: Text(
                    phoneCountryData.country ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                  ),
                ),
              )
            : SizedBox.shrink(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PhoneCountryData>(
      key: Key('countryDropdown'),
      isDense: true,
      alignment: widget.alignment,
      style: widget.style,
      iconDisabledColor: widget.iconDisabledColor,
      iconEnabledColor: widget.iconEnabledColor,
      focusNode: widget.focusNode,
      iconSize: widget.iconSize,
      focusColor: widget.focusColor,
      autofocus: widget.autofocus,
      dropdownColor: widget.dropdownColor,
      decoration: widget.decoration,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      menuMaxHeight: widget.menuMaxHeight,
      enableFeedback: widget.enableFeedback,
      icon: widget.icon,
      isExpanded: true,
      elevation: widget.elevation,
      itemHeight: widget.itemHeight,
      selectedItemBuilder: (c) {
        return _countryItems
            .map(
              (e) => DropdownMenuItem<PhoneCountryData>(
                child: _buildSelectedLabel(e),
                value: e,
              ),
            )
            .toList();
      },
      items: _countryItems
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
