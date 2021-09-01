import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:flutter/material.dart';

class Contract {
  Contract() {
    method();
  }

  method() async {



    const String privateKey = 'c12906d0afb54b9c1b6aa10e25d6a75ffffa6d0acc88c0372fa4c8cf2900e6f1';
    const String rpcUrl = 'https://rinkeby.infura.io/v3/addc098810374596927119403bf058df';

    final client = Web3Client(rpcUrl, Client());

    dynamic deployedAddress = '0xf1714aD04AD2a228cB354a615929aeebcE0e4860';

    final credentials = await client.credentialsFromPrivateKey(privateKey);
    final address = credentials.address;

    // final contract = DeployedContract(abi, deployedAddress);
    //
    // client.call(sender: address,contract: contract, function: abi[''], params: []);


    print(address.hexEip55);
    print('balance++${await client.getBalance(address)}');

    await client.sendTransaction(
      credentials,
      Transaction(
        to: EthereumAddress.fromHex(
            '0x56EcA1104B36A05b0f4C0c5b881C7a54dcE54c74'),
        gasPrice: EtherAmount.inWei(BigInt.one),
        maxGas: 100000,
        value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
      ),
    );

    await client.dispose();
  }
}

// final result = await ethCleint.sendTransaction(
//   credentials,
//   Transaction.callContract(
//     from: address,
//     contract: contract,
//     function: ethFunction,
//     parameters: args,
//     gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.ether, 2),
//     value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 2),
//     maxGas: 10000
//   ),
// );



// await ethCleint.sendTransaction(
//   credentials,
//
//   Transaction(
//     from: address,
//     gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.ether, 2),
//     maxGas: 1000000,
//     //data: Uint8List.,
//     value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 2),
//   ),
// );



//EtherAmount balance = await ethCleint.getBalance(credentials.address);
