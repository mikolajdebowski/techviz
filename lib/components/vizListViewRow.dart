import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:techviz/components/vizListView.dart';
import 'package:techviz/components/vizShimmer.dart';

import 'dataEntry/dataEntry.dart';
import 'dataEntry/dataEntryCell.dart';
import 'dataEntry/dataEntryColumn.dart';

typedef onSwipingCallback = void Function(
    bool isOpen, GlobalKey<SlidableState> key);

class SwipeAction {
  final String title;
  final SwipeActionCallback callback;
  //final Swipable swipable;

  SwipeAction(this.title, this.callback);
}

class VizListViewRow extends StatefulWidget {
  static const double rowHeight = 35.0;
  final DataEntry dataEntry;
  final SwipeAction onSwipeLeft;
  final SwipeAction onSwipeRight;
  final onSwipingCallback onSwiping;
  final Swipable swipable;
  final List<DataEntryColumn> columnsDefinition;

  const VizListViewRow(
      this.dataEntry,
      this.columnsDefinition,
      {Key key,
      this.onSwipeLeft,
      this.onSwipeRight,
      this.onSwiping,
      this.swipable, })
      : super(key: key);

  @override
  State<StatefulWidget> createState() => VizListViewRowState();
}

class VizListViewRowState extends State<VizListViewRow> {
  static Color leftBtnColor = const Color(0xFF96CF96);
  static Color rightBtnColor = const Color(0xFFFFA500);
  static Color backgroundColor = Colors.white;


  bool isBeingPressed = false;
  final double rowHeight = 35.0;
  final GlobalKey<SlidableState> _slidableKey = GlobalKey<SlidableState>();
  SlidableController _slidableController;

  Color get bgRowColor {
    return isBeingPressed ? Colors.lightBlue : Colors.white;
  }

  BoxDecoration get decoration {
    return BoxDecoration(
        color: bgRowColor,
        border: Border(bottom: BorderSide(color: Colors.black, width: 1.0)));
  }

  @override
  void initState() {
    _slidableController = SlidableController(
        onSlideIsOpenChanged: (bool isOpen) {
          if (widget.onSwiping != null) {
            widget.onSwiping(isOpen, _slidableKey);
          }
        },
        onSlideAnimationChanged: (Animation<double> animation) {});
    super.initState();
  }

  Container createShimmer(String _txt, String _direction) {
    return Container(
        child: Shimmer.fromColors(
      direction: _direction,
      baseColor: Colors.white,
      highlightColor: Colors.grey,
      child: Text(
        _txt,
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 25.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    ));
  }

  Map toMapDic(List<DataEntryColumn> list) {
    Map<String,DataEntryColumn> map = {};
    list.forEach((DataEntryColumn column){ map[column.columnName] = column; });
    return map;
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration decoration = BoxDecoration(
        color: bgRowColor,
        border: Border(bottom: BorderSide(color: Color(0xFF898989), width: 1.0)));

    List<Widget> columns = <Widget>[];
    Map<String,DataEntryColumn> columnsMap = toMapDic(widget.columnsDefinition);

    widget.dataEntry.cell.forEach((DataEntryCell dataCell) {
      DataEntryColumn columnDefinition = columnsMap[dataCell.columnName];

      if(!columnDefinition.visible)
        return;

      Widget cellWidget;

      if(dataCell.value is Widget){
        cellWidget = dataCell.value;
      }
      else{

        String text = dataCell.value.toString();
        TextStyle style = TextStyle(fontSize: 12);

        TextAlign align = columnDefinition.alignment == DataAlignment.left
            ? TextAlign.left
            : (columnDefinition.alignment == DataAlignment.right
            ? TextAlign.right
            : TextAlign.center);


        cellWidget = AutoSizeText(
          text,
          textAlign: align,
          style: style,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          maxLines: 2,
        );
      }

      columns.add(Expanded(
        flex: columnDefinition.flex,
          child: Padding(padding: EdgeInsets.all(5), child: cellWidget)));
    });

    Row dataRow = Row(
      children: columns,
    );

    SwipeButton swipeLeftButton;
    if(widget.onSwipeLeft!=null){
      bool btnEnabled = widget.dataEntry.onSwipeLeftActionConditional == null || widget.dataEntry.onSwipeLeftActionConditional();
      swipeLeftButton = SwipeButton(
          color: leftBtnColor,
          text: widget.onSwipeLeft.title,
          onPressed: btnEnabled
              ? () {
            widget.onSwipeLeft.callback(widget.dataEntry);
          }
              : null);
    }
    Container leftButtonContainer = Container(
      decoration: decoration,
      child: swipeLeftButton,
    );

    SwipeButton swipeRightButton;
    if(widget.onSwipeRight!=null){
      bool btnEnabled = widget.dataEntry.onSwipeRightActionConditional == null || widget.dataEntry.onSwipeRightActionConditional();
      swipeRightButton = SwipeButton(
          color: rightBtnColor,
          text: widget.onSwipeRight.title,
          onPressed: btnEnabled
              ? () {
            widget.onSwipeRight.callback(widget.dataEntry);
          }
              : null);
    }

    Container rightButtonContainer = Container(
      decoration: decoration,
      child: swipeRightButton,
    );

    Slidable slidable = Slidable(
      key: _slidableKey,
      controller: _slidableController,
      actionPane: SlidableScrollActionPane(),
      actionExtentRatio: 0.25,
      child: Container(
        decoration: decoration,
        height: VizListViewRow.rowHeight,
        child: dataRow,
      ),
      actions: widget.onSwipeRight == null ? [] : [rightButtonContainer],
      secondaryActions: widget.onSwipeLeft == null ? [] : [leftButtonContainer],
      dismissal: SlidableDismissal(
        dismissThresholds: const <SlideActionType, double>{
          SlideActionType.secondary: 1.0,
          SlideActionType.primary: 1.0
        },
        child: SlidableDrawerDismissal(),
        onDismissed: (actionType) {},
      ),
    );

    GestureDetector gestureDetector = GestureDetector(
        child: slidable,
        onTap: () {
          SlidableState slidableState = _slidableKey.currentState;
          slidableState.close();
          setState(() {
            isBeingPressed = false;
          });
        });

    Listener listener = Listener(
      child: gestureDetector,
      onPointerDown: (PointerDownEvent event) {
        setState(() {
          isBeingPressed = true;
        });
      },
      onPointerUp: (PointerUpEvent event) {
        setState(() {
          isBeingPressed = false;
        });
      },
    );

    Stack stack = Stack(
      children: <Widget>[
        listener,
        Opacity(
          opacity: (isBeingPressed && (widget.onSwipeLeft != null)) ? 1.0 : 0.0,
          child: Align(
            child: createShimmer('<', 'rtl'),
            alignment: Alignment.centerLeft,
          ),
        ),
        Opacity(
            opacity:
                (isBeingPressed && (widget.onSwipeRight != null)) ? 1.0 : 0.0,
            child: Align(
              child: createShimmer('>', 'ltr'),
              alignment: Alignment.centerRight,
            ))
      ],
    );

    return stack;
  }
}
