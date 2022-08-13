import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';

enum BitcoinAddressType {
  P2KSH,
  P2SH,
  None,
}

enum BitcoinAddressNetwork {
  Mainnet,
  Testnet,
  None,
}

enum BitcoinWalletType {
  SegWit,
  Regular,
  None,
}

class BitcoinWalletDetails {
  final String? address;
  final BitcoinAddressType addressType;
  final BitcoinAddressNetwork addressNetwork;
  final BitcoinWalletType walletType;

  @override
  operator ==(covariant BitcoinWalletDetails other) {
    return other.address == address &&
        other.walletType == walletType &&
        other.addressNetwork == addressNetwork &&
        other.addressNetwork == addressNetwork;
  }

  @override
  String toString() {
    if (isValid) {
      var stringBuffer = StringBuffer();
      stringBuffer.write(this.runtimeType);
      stringBuffer.write('\n');
      stringBuffer.write('Address: ');
      stringBuffer.write(address);
      stringBuffer.write('\n');
      stringBuffer.write('Network: ');
      stringBuffer.write(enumToString(addressNetwork));
      stringBuffer.write('\n');
      stringBuffer.write('Address type: ');
      stringBuffer.write(enumToString(addressType));
      stringBuffer.write('\n');
      stringBuffer.write('Wallet type: ');
      stringBuffer.write(enumToString(walletType));
      stringBuffer.write('\n');
      return stringBuffer.toString();
    }
    return 'Invalid Bitcoin wallet';
  }

  @override
  int get hashCode {
    return '$address$addressNetwork$addressType$walletType'.hashCode;
  }

  bool get isValid {
    return address != null && addressNetwork != BitcoinWalletType.None;
  }

  BitcoinWalletDetails({
    required this.address,
    required this.addressType,
    required this.addressNetwork,
    required this.walletType,
  });

  factory BitcoinWalletDetails.invalid() {
    return BitcoinWalletDetails(
      address: null,
      addressNetwork: BitcoinAddressNetwork.None,
      addressType: BitcoinAddressType.None,
      walletType: BitcoinWalletType.None,
    );
  }
}
