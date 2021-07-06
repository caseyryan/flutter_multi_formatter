import 'package:base58check/base58check.dart';
import 'package:bech32/bech32.dart';

import 'bitcoin_wallet_details.dart';

const Map<int, BitcoinAddressNetwork> _networkByVersion = {
  0: BitcoinAddressNetwork.Mainnet,
  5: BitcoinAddressNetwork.Mainnet,
  111: BitcoinAddressNetwork.Testnet,
  196: BitcoinAddressNetwork.Testnet,
};

const Map<int, BitcoinAddressType> _typeByVersion = {
  0: BitcoinAddressType.P2KSH,
  111: BitcoinAddressType.P2KSH,
  5: BitcoinAddressType.P2SH,
  196: BitcoinAddressType.P2SH,
};

/// A simplified wallet type check which only
/// returns a wallet type like SegWit, Regular, or None
/// if a wallet address is invalid
BitcoinWalletType getBitcoinWalletType(String? value) {
  return getBitcoinWalletDetails(value).walletType;
}

bool isBitcoinWalletValid(String? value) {
  return getBitcoinWalletDetails(value).isValid; 
}

/// Detailed wallet check. The returned object contains all 
/// the necessary info like address type, network, wallet type 
/// and address. Before using the returned object, use isValid 
/// getter to check if the result is valid
BitcoinWalletDetails getBitcoinWalletDetails(String? value) {
  if (value == null || value.length < 34) {
    return BitcoinWalletDetails.invalid();
  }
  final isSegwitTest = value.startsWith('tb');
  final isSegwit = value.startsWith('bc');
  if (isSegwit || isSegwitTest) {
    return _getSegWitDetails(
      value,
      isSegwitTest,
    );
  }

  final checkCodec = Base58CheckCodec.bitcoin();
  Base58CheckPayload decoded;
  try {
    decoded = checkCodec.decode(value);
  } catch (e) {
    return BitcoinWalletDetails.invalid();
  }
  if (decoded.payload.length != 20) {
    return BitcoinWalletDetails.invalid();
  }
  final version = decoded.version;
  BitcoinAddressType? type = _typeByVersion[version];
  BitcoinAddressNetwork? network = _networkByVersion[version];
  if (type == null) {
    return BitcoinWalletDetails.invalid();
  }
  return BitcoinWalletDetails(
    address: value,
    addressNetwork: network!,
    addressType: type,
    walletType: BitcoinWalletType.Regular,
  );
}

BitcoinWalletDetails _getSegWitDetails(
  String value,
  bool isSegwitTest,
) {
  int programLength = 0;
  try {
    Segwit decodedSegwit = segwit.decode(value);
    programLength = decodedSegwit.program.length;
  } catch (e) {
    
  }

  BitcoinAddressType type = BitcoinAddressType.None;
  switch (programLength) {
    case 20:
      {
        type = BitcoinAddressType.P2KSH;
      }
      break;
    case 32:
      {
        type = BitcoinAddressType.P2SH;
      }
  }

  BitcoinAddressNetwork network = isSegwitTest 
    ? BitcoinAddressNetwork.Testnet
    : BitcoinAddressNetwork.Mainnet; 

  return BitcoinWalletDetails(
    address: value,
    addressNetwork: network,
    addressType: type,
    walletType: BitcoinWalletType.SegWit,
  );
}
