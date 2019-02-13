
import 'package:flutter/material.dart';

typedef VizTaskListItemCallback = void Function(String id);

class VizTaskItem extends StatelessWidget{
  final String id;
  final String title;
  final VizTaskListItemCallback itemTapCallback;
  final int index;
  final bool selected;
  final String urgencyHEXColor;

  VizTaskItem(String this.id,
      String this.title,
      int this.index,
      VizTaskListItemCallback this.itemTapCallback,
      this.selected,
      this.urgencyHEXColor,);

  @override
  Widget build(BuildContext context) {

    var urgencyColorStart = this.urgencyHEXColor!= null ? Color(int.parse("0xFF${this.urgencyHEXColor}")) : Color(0xFF45505D);
    var urgencyColorEnd = this.urgencyHEXColor!= null ? Color(int.parse("0xAA${this.urgencyHEXColor}")) : Color(0xFF45505D);

    var mainBackgroundColor = this.selected ? [Color(0xFF65b1d9), Color(0xFF0268a2)] : [Color(0xFFB2C7CF), Color(0xFFE4EDEF)];
    var locationColor =  this.selected ? Colors.white : Colors.black45;

    return GestureDetector(
        onTap: () {
          this.itemTapCallback(this.id);
        },
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Container(
                height: 60.0,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [urgencyColorStart,urgencyColorEnd],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        tileMode: TileMode.repeated)),
                child: Center(child: Text(this.index.toString(), style: TextStyle(color: Colors.white))),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                height: 60.0,
                decoration:
                BoxDecoration(gradient: LinearGradient(colors: mainBackgroundColor, begin: Alignment.topCenter, end: Alignment.bottomCenter, tileMode: TileMode.repeated)),
                child: Center(
                    child: Text(
                      this.title,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15.0, color: locationColor),
                    )),
              ),
            ),
          ],
        ));
  }
}