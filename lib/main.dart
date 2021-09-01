import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:houserent/operations.dart';
import 'package:http/http.dart';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:web3dart/web3dart.dart';

import 'Theme/AppTheme.dart';
import 'Theme/AppThemeNotifier.dart';
import 'Theme/SizeConfig.dart';
import 'contract.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(ChangeNotifierProvider(
      create: (context) => AppThemeNotifier(),
      child: MyApp(),
    ));
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Consumer<AppThemeNotifier>(
        builder: (BuildContext context, AppThemeNotifier value, Widget? child) {
      return MaterialApp(
        theme: AppTheme.getThemeFromThemeMode(value.themeMode()),
        debugShowCheckedModeBanner: false,
        home: MyHomePage(),
      );
    });
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic data;
  late ThemeData themeData;

  final myAddress = '0xafb5c15365EbCAb6C74634bf743e61d9a4fB8D0B';
  late Web3Client ethCleint;
  Client? httpClient;
  int? Ether;
  var manager;
  var credentials;
  var _balanceOf;
  String? _symbol;
  String? _name;
  int? _value;
  String? _addressTransfer;
  bool txComplet = false;
  late Timer _timer;
  GlobalKey<ScaffoldState>? refreshKey;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    txComplet = false;
    httpClient = Client();
    ethCleint = Web3Client(
      'https://rinkeby.infura.io/v3/29d899431d4e4c37b302449f048d0508',
      httpClient!,
    );
    getSymbol();
    getName();
    EthereumAddress address = getAddress(myAddress);
    getBalanceOf(address);
    refreshKey = GlobalKey();
  }

  Future<String> refreshList() async {
    //refreshKey.currentState?.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      //initState();
      getSymbol();
      getName();
      EthereumAddress address = getAddress(myAddress);
      getBalanceOf(address);
    });
    refreshKey!.currentState!.showSnackBar(
      SnackBar(
        content: const Text('Page Refreshed'),
      ),
    );

    return 'success';
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString('assets/abi.json');
    String contractAddress = '0xBA89545e2A42aE34401Fbd88c693Bd1A0eb206b2';
    final contract = DeployedContract(ContractAbi.fromJson(abi, "ERC20Basic"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  //Operations.of(context);
  Future query(String functionName, List<dynamic> args) async {
    EthereumAddress address = EthereumAddress.fromHex(myAddress);
    print('args: $args');
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethCleint.call(
        contract: contract, function: ethFunction, params: args);
    print(result);

    return result;
  }

  EthereumAddress getAddress(String myAddress) {
    EthereumAddress address = EthereumAddress.fromHex(myAddress);
    return address;
  }

  getBalanceOf(EthereumAddress address) async {
    var result = await query("balanceOf", [address]);
    print('$result');
    setState(() {
      _balanceOf = result[0];
    });
    return result;
  }

  getSymbol() async {
    var result = await query("symbol", []);
    setState(() {
      _symbol = result[0];
    });
    return result[0];
  }

  getName() async {
    var result = await query("name", []);
    setState(() {
      _name = result[0];
    });
    return result[0];
  }

  // transfer(EthereumAddress address, BigInt numTokens) async {
  //   //var result = await query("transfer", [address,numTokens]);
  //   final contract = await loadContract();

  //   const String privateKey =
  //       '52f5a16a5b799334d7f7223c6f6a7339e07451efc7749958259e87c9bcfc25d5';
  //   final credentials = EthPrivateKey.fromHex(privateKey);
  //   //await ethCleint.credentialsFromPrivateKey(privateKey);
  //   print(await ethCleint.getBalance(await credentials.extractAddress()));

  //   final voteFunction = contract.function('transfer');

  //   // final result = ethCleint.call(
  //   //     contract: contract, function: voteFunction, params: [EthereumAddress.fromHex('0x56EcA1104B36A05b0f4C0c5b881C7a54dcE54c74'),numTokens]);
  //   // return result;

  //   var res = await ethCleint.sendTransaction(
  //     credentials,

  //     Transaction(
  //       to: EthereumAddress.fromHex(
  //           '0xafb5c15365EbCAb6C74634bf743e61d9a4fB8D0B'),
  //       gasPrice: EtherAmount.inWei(BigInt.one),
  //       maxGas: 3000000,
  //       value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
  //     ),
  //     // Transaction.callContract(
  //     //   contract: contract,
  //     //   function: voteFunction,
  //     //   parameters: [EthereumAddress.fromHex('0xafb5c15365EbCAb6C74634bf743e61d9a4fB8D0B'),BigInt.from(10000)],
  //     //   //gasPrice: EtherAmount.fromUnitAndValue(EtherUnit.wei, 200000),
  //     //   value: EtherAmount.fromUnitAndValue(EtherUnit.wei, 3000000),
  //     //  // from: await credentials.extractAddress()
  //     // ),
  //   );
  // }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "c12906d0afb54b9c1b6aa10e25d6a75ffffa6d0acc88c0372fa4c8cf2900e6f1");

    DeployedContract contract = await loadContract();

    final ethFunction = contract.function(functionName);

    var result = await ethCleint.sendTransaction(
        credentials,
        Transaction.callContract(
          contract: contract,
          function: ethFunction,
          parameters: args,
        ),
        fetchChainIdFromNetworkId: true,
        chainId: null);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    themeData = Theme.of(context);
    MySize().init(context);

    return Consumer<AppThemeNotifier>(
        builder: (BuildContext context, AppThemeNotifier value, Widget? child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
            key: refreshKey,
            appBar: AppBar(
              backgroundColor: themeData.scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: true,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Icon(
                  MdiIcons.chevronLeft,
                ),
              ),
              title: Text("${_name ?? "--"}",
                  style: AppTheme.getTextStyle(themeData.textTheme.headline6,
                      fontWeight: 600)),
              actions: <Widget>[
                Container(
                    margin: EdgeInsets.only(right: MySize.size16!),
                    child: Icon(
                      MdiIcons.qrcode,
                      color: themeData.colorScheme.onBackground,
                      size: 24,
                    ))
              ],
            ),
            body: RefreshIndicator(
              onRefresh: refreshList,
              child: ListView(
                children: [
                  Container(
                    //key: refreshKey,
                    color: themeData.backgroundColor,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image(
                            image: AssetImage("assets/pranab.JPG"),
                            height: 100,
                            width: 100,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: MySize.size16!),
                          alignment: Alignment.center,
                          child: Container(
                            padding: EdgeInsets.only(
                                top: MySize.size36!,
                                bottom: MySize.size36!,
                                right: MySize.size40!,
                                left: MySize.size40!),
                            decoration: BoxDecoration(
                              color: themeData.cardTheme.color,
                              borderRadius: BorderRadius.all(
                                  Radius.circular(MySize.size8!)),
                              boxShadow: [
                                BoxShadow(
                                  color: themeData.cardTheme.shadowColor!
                                      .withAlpha(24),
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text("Balance",
                                        style: AppTheme.getTextStyle(
                                            themeData.textTheme.headline5,
                                            fontWeight: 600)),
                                    // Icon(
                                    //   MdiIcons.arrowUp,
                                    //   color: themeData.colorScheme.primary,
                                    //   size: 18,
                                    // )
                                  ],
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: <TextSpan>[
                                      TextSpan(
                                          text: "${_symbol ?? "--"}  ",
                                          style: AppTheme.getTextStyle(
                                              themeData.textTheme.headline6,
                                              letterSpacing: 0)),
                                      TextSpan(
                                          text: "${_balanceOf ?? '--'}",
                                          style: AppTheme.getTextStyle(
                                              themeData.textTheme.headline5,
                                              letterSpacing: 0)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MySize.size16,
                        ),
                        Container(
                          padding:
                              EdgeInsets.only(top: 16, left: 16, right: 16),
                          child: Column(
                            children: <Widget>[
                              Container(
                                decoration: BoxDecoration(
                                    color: themeData.colorScheme.background,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(MySize.size16!))),
                                padding: EdgeInsets.all(MySize.size12!),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(MySize.size4!),
                                      decoration: BoxDecoration(
                                          color: themeData.colorScheme.primary,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(MySize.size8!))),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            MySize.size8!),
                                        child: Icon(
                                          MdiIcons.accountOutline,
                                          color:
                                              themeData.colorScheme.onPrimary,
                                          size: MySize.size22,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            left: MySize.size16!),
                                        child: TextFormField(
                                          onChanged: (value) {
                                            _addressTransfer = value;
                                            print(_addressTransfer);
                                          },
                                          style: AppTheme.getTextStyle(
                                              themeData.textTheme.bodyText1,
                                              letterSpacing: 0.1,
                                              color: themeData
                                                  .colorScheme.onBackground,
                                              fontWeight: 500),
                                          decoration: InputDecoration(
                                            hintText: "Address",
                                            hintStyle: AppTheme.getTextStyle(
                                                themeData.textTheme.subtitle2,
                                                letterSpacing: 0.1,
                                                color: themeData
                                                    .colorScheme.onBackground,
                                                fontWeight: 500),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      MySize.size8!),
                                                ),
                                                borderSide: BorderSide.none),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      MySize.size8!),
                                                ),
                                                borderSide: BorderSide.none),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      MySize.size8!),
                                                ),
                                                borderSide: BorderSide.none),
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(0),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: MySize.size16!),
                                decoration: BoxDecoration(
                                    color: themeData.colorScheme.background,
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(MySize.size16!))),
                                padding: EdgeInsets.all(MySize.size12!),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.all(MySize.size4!),
                                      decoration: BoxDecoration(
                                          color: themeData.colorScheme.primary,
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(MySize.size8!))),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                            MySize.size8!),
                                        child: Icon(
                                          MdiIcons.currencyBtc,
                                          color:
                                              themeData.colorScheme.onPrimary,
                                          size: MySize.size22,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Container(
                                        margin: EdgeInsets.only(
                                            left: MySize.size16!),
                                        child: TextFormField(
                                          onChanged: (value) {
                                            _value = int.parse(value);
                                            print(_value);
                                          },
                                          style: AppTheme.getTextStyle(
                                              themeData.textTheme.bodyText1,
                                              letterSpacing: 0.1,
                                              color: themeData
                                                  .colorScheme.onBackground,
                                              fontWeight: 500),
                                          decoration: InputDecoration(
                                            hintText: "Amount",
                                            hintStyle: AppTheme.getTextStyle(
                                                themeData.textTheme.subtitle2,
                                                letterSpacing: 0.1,
                                                color: themeData
                                                    .colorScheme.onBackground,
                                                fontWeight: 500),
                                            border: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      MySize.size8!),
                                                ),
                                                borderSide: BorderSide.none),
                                            enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      MySize.size8!),
                                                ),
                                                borderSide: BorderSide.none),
                                            focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(
                                                      MySize.size8!),
                                                ),
                                                borderSide: BorderSide.none),
                                            isDense: true,
                                            contentPadding: EdgeInsets.all(0),
                                          ),
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          themeData.primaryColor.withAlpha(24),
                                      blurRadius: 5,
                                      offset: Offset(
                                          0, 2), // changes position of shadow
                                    ),
                                  ],
                                ),
                                margin: EdgeInsets.all(24),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    EthereumAddress add =
                                        getAddress(_addressTransfer!);
                                    BigInt val = BigInt.from(_value! * 100);
                                    String tnxHash =
                                        await submit('transfer', [add, val]);
                                    setState(() {
                                      if (tnxHash != null) {
                                        txComplet = true;
                                      }
                                    });
                                    txComplet
                                        ? showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return TnxSucessDialog(
                                                  tnxHash: tnxHash);
                                            })
                                        : showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Loader();
                                            });

                                    // await submit("transfer", [
                                    //   EthereumAddress.fromHex(
                                    //       '0x56EcA1104B36A05b0f4C0c5b881C7a54dcE54c74'),
                                    //   BigInt.from(300000)
                                    // ]);
                                  },
                                  child: Text(
                                    "Press \& Hold to Transfer Money",
                                    style: AppTheme.getTextStyle(
                                        themeData.textTheme.bodyText2,
                                        fontWeight: 600,
                                        color: themeData.colorScheme.onPrimary,
                                        letterSpacing: 0.3),
                                  ),
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                          Spacing.xy(16, 0))),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                ],
                //child: ,
              ),
            )),
      );
    });
  }
}

class Loader extends StatelessWidget {
  const Loader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Dialog(
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        height: 180,
        width: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator()],
        ),
      ),
    );
  }
}

class TnxSucessDialog extends StatelessWidget {
  final String? tnxHash;
  const TnxSucessDialog({Key? key, this.tnxHash}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Dialog(
      child: Container(
        height: 250,
        width: 100,
        padding: EdgeInsets.only(top: 16, bottom: 16, left: 24, right: 24),
        decoration: new BoxDecoration(
            color: themeData.backgroundColor,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10.0,
                offset: const Offset(0.0, 10.0),
              )
            ]),
        child: Column(
          children: [
            Container(
              child: Center(
                  child: Icon(
                MdiIcons.accountCheckOutline,
                size: 40,
                color: themeData.colorScheme.onBackground.withAlpha(220),
              )),
            ),
            Container(
                margin: EdgeInsets.only(top: 16),
                child: Center(
                  child: Text("Transaction Done!",
                      style: AppTheme.getTextStyle(
                          themeData.textTheme.subtitle1,
                          fontWeight: 700)),
                )),
            Container(
              margin: EdgeInsets.only(top: 16),
              child: Center(
                  child: Text(
                "$tnxHash",
                style: AppTheme.getTextStyle(themeData.textTheme.caption,
                    fontWeight: 500, height: 1.15),
                textAlign: TextAlign.center,
              )),
            ),
            SizedBox(
              height: MySize.size10,
            ),
            Container(
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Close")),
            )
          ],
        ),
      ),
    );
  }
}
