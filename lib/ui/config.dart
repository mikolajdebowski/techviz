import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:techviz/common/LowerCaseTextFormatter.dart';
import 'package:techviz/components/VizButton.dart';
import 'package:flutter/services.dart';
import 'package:techviz/components/vizRainbow.dart';
import 'package:vizexplorer_mobile_common/vizexplorer_mobile_common.dart';

class Config extends StatefulWidget {
  static final String SERVERURL = 'SERVERURL';

  @override
  State<StatefulWidget> createState() => ConfigState();
}

class ConfigState extends State<Config> {
  SharedPreferences prefs;
  final serverAddressController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  var default_url_options = {
    'protocols': ['Http', 'http', 'Https', 'https'],
    'require_protocol': false,
  };

  @override
  void initState() {
    SharedPreferences.getInstance().then((onValue) {
      prefs = onValue;
      if (prefs.getKeys().contains(Config.SERVERURL)) {
        serverAddressController.text = prefs.getString(Config.SERVERURL);
      }
    });

    super.initState();
  }

  void onNextTap() async {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      if (!serverAddressController.text.toLowerCase().contains('http')) {
        serverAddressController.text = 'http://${serverAddressController.text}';
      }

      await prefs.setString(Config.SERVERURL, serverAddressController.text);
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    var textFieldStyle = TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 20.0,
        color: Color(0xFFffffff),
        fontWeight: FontWeight.w500,
        fontFamily: "Roboto");

    var textFieldBorder = OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4.0)));
    var defaultPadding = EdgeInsets.all(6.0);
    var textFieldContentPadding = new EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0);

    var backgroundDecoration = BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFFd6dfe3), Color(0xFFb1c2cb)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            tileMode: TileMode.repeated));

    var textField = Padding(
        padding: defaultPadding,
        child: TextFormField(
            inputFormatters: [LowerCaseTextFormatter()],
            onSaved: (String value) {
              print('saving url: $value');
            },
            autocorrect: false,
            validator: (String value) {
              if (!Validator.isUrl(value, default_url_options)) {
                return 'Please enter valid URL';
              }
            },
            controller: serverAddressController,
            decoration: InputDecoration(
                fillColor: Colors.black87,
                filled: true,
                hintStyle: textFieldStyle,
                hintText: 'Server Address',
                border: textFieldBorder,
                contentPadding: textFieldContentPadding),
            style: textFieldStyle));

    var btnNext = VizButton(title: 'Next', onTap: onNextTap, highlighted: true);

    var btnBox = Padding(
        padding: defaultPadding,
        child: SizedBox(
            height: 45.0,
            width: 100.0,
            child: Flex(direction: Axis.horizontal, children: <Widget>[btnNext])));

    var formColumn = Expanded(
      child: Column(
        children: <Widget>[
          Flexible(
              child: Form(
            key: _formKey,
            child: textField,
          )),
          Text(
            'Your server address needs to be set before you can login for the first time.',
            style: TextStyle(color: Color(0xff474f5b)),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );

    var row = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 40.0,
        ),
        formColumn,
        btnBox
      ],
    );

    var container = Container(
        decoration: backgroundDecoration,
        child: Stack(
          children: <Widget>[
            Align(
                alignment: Alignment.center,
                child: Container(
                  height: 110.0,
                  child: row,
                )),
            Align(alignment: Alignment.bottomCenter, child: VizRainbow()),
          ],
        ));

    return Scaffold(backgroundColor: Colors.black, body: SafeArea(child: container));
  }
}