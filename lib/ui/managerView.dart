import 'dart:async';

import 'package:flutter/material.dart';
import 'package:techviz/components/dataEntry/dataEntry.dart';
import 'package:techviz/components/dataEntry/dataEntryCell.dart';
import 'package:techviz/components/dataEntry/dataEntryGroup.dart';
import 'package:techviz/components/vizDialog.dart';
import 'package:techviz/components/vizListView.dart';
import 'package:techviz/components/vizListViewRow.dart';
import 'package:techviz/components/vizSelector.dart';
import 'package:techviz/components/vizSnackbar.dart';
import 'package:techviz/components/vizSummary.dart';
import 'package:techviz/model/userSection.dart';
import 'package:techviz/model/userStatus.dart';
import 'package:techviz/presenter/managerViewPresenter.dart';
import 'package:techviz/service/slotFloorService.dart';
import 'package:techviz/service/userService.dart';
import 'package:techviz/session.dart';
import 'package:techviz/ui/home.dart';
import 'package:techviz/ui/reassignTask.dart';
import 'package:techviz/viewmodel/managerViewUserStatus.dart';

import 'machineReservation.dart';

class ManagerView extends StatefulWidget {
  const ManagerView(Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() => ManagerViewState();
}

class ManagerViewState extends State<ManagerView> implements TechVizHome, IManagerViewPresenter {
  ManagerViewPresenter _presenter;

  List<DataEntryGroup> _openTasksList;
  List<DataEntryGroup> _teamAvailabilityList;
  List<DataEntryGroup> _slotFloorList;
  ScrollController _mainController;

  final GlobalKey _containerKey = GlobalKey();
  final GlobalKey _openTasksKey = GlobalKey();
  final GlobalKey _teamAvaKey = GlobalKey();
  final GlobalKey _slotFloorKey = GlobalKey();

  bool _openTasksLoading = true;
  bool _slotFloorLoading = true;
  bool _teamAvailabilityLoading = true;

  String teamAvailabilityCurrentUserSelected;

  @override
  void initState() {

    super.initState();
    _presenter = ManagerViewPresenter(this);
    _presenter.loadOpenTasks();
    _presenter.loadTeamAvailability();
    _presenter.loadSlotFloorSummary();

    _mainController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      key: _containerKey,
      constraints: BoxConstraints.expand(),
      decoration: BoxDecoration(gradient: LinearGradient(colors: const [Color(0xFF586676), Color(0xFF8B9EA7)], begin: Alignment.topCenter, end: Alignment.bottomCenter, tileMode: TileMode.repeated)),
      child: SingleChildScrollView(
        controller: _mainController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            VizSummary('OPEN TASKS',
                _openTasksList,
                key: _openTasksKey,
                onSwipeLeft: onOpenTasksSwipeLeft(),
                onSwipeRight: onOpenTasksSwipeRight(),
                onMetricTap: onOpenTasksMetricTap,
                isProcessing:  _openTasksLoading,
                onScroll: _onChildScroll),

            VizSummary('TEAM AVAILABILITY',
                _teamAvailabilityList,
                key: _teamAvaKey,
                isProcessing: _teamAvailabilityLoading,
                onSwipeLeft: onTeamAvailiblitySwipeLeft(),
                onMetricTap: onTeamAvailiblityMetricTap,
                onScroll: _onChildScroll
            ),

            VizSummary('SLOT FLOOR',
                _slotFloorList,
                key: _slotFloorKey,
                onSwipeRight: onSlotFloorSwipeRight(),
                onSwipeLeft: onSlotFloorSwipeLeft(),
                onMetricTap: onSlotFloorMetricTap,
                isProcessing: _slotFloorLoading,
                onScroll: _onChildScroll),
          ],
        ),
      ),
    );
  }

  void _onChildScroll(ScrollingStatus scroll){
    int maxOffset = 3;
    if(scroll==ScrollingStatus.ReachOnTop && _mainController.offset >= maxOffset){
      _mainController.jumpTo(_mainController.offset-maxOffset);
    }
    else if(scroll==ScrollingStatus.ReachOnBottom && _mainController.offset <= _mainController.position.maxScrollExtent-maxOffset) {
      _mainController.jumpTo(_mainController.offset+maxOffset);
    }
  }

  //OpenTasks
  SwipeAction onOpenTasksSwipeLeft(){ //action of the right of the view
    return SwipeAction('Reassign', (dynamic entry){

      DataEntry dataEntry = entry as DataEntry;
      DataEntryCell dataCell = dataEntry.cell.where((DataEntryCell dataCell) => dataCell.columnName == 'Location').first;
      String location = dataCell.value.toString();
      ReassignTask reassignTaskView = ReassignTask(dataEntry.id, location);

      Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (context) => reassignTaskView),
      ).then((bool isDone){
        if(isDone!=null && isDone){
            setState(() {
              _openTasksLoading = true;
              _openTasksList = null;
            });
            _presenter.loadOpenTasks();
          }
      });
    });
  }

  SwipeAction onOpenTasksSwipeRight(){

     Function reassignTaskCallback = (dynamic entry){

        DataEntry dataEntry = entry as DataEntry;
        String location = dataEntry.cell.where((DataEntryCell cell) => cell.columnName == 'Location').first.value.toString();

        GlobalKey dialogKey = GlobalKey();
        VizDialogButton btnYes = VizDialogButton('Yes', (){

          _presenter.reassign(dataEntry.id, Session().user.userID).then((dynamic d){

            Navigator.of(dialogKey.currentContext).pop(true);
            setState(() {
              _openTasksLoading = true;
              _openTasksList = null;
            });
            _presenter.loadOpenTasks();

          });
        });

        VizDialogButton btnNo = VizDialogButton('No', (){
          Navigator.of(dialogKey.currentContext).pop(true);
        }, highlighted: false);

        VizDialog.Confirm(dialogKey, context, 'Reassign task', 'Are you sure you want to reassign the task $location to yourself?', actions: [btnNo, btnYes]);
    };

    //action of the left of the view
    return SwipeAction('Take', reassignTaskCallback);
  }

  void onOpenTasksMetricTap(){
    setState(() {
      _openTasksLoading = true;
    });
    _presenter.loadOpenTasks();
  }


  //TeamAvailiblity
  SwipeAction onTeamAvailiblitySwipeLeft(){
    return SwipeAction('Change Status',(dynamic entry){
      DataEntry dataEntry = entry as DataEntry;
      setState(() {
        teamAvailabilityCurrentUserSelected = dataEntry.id;
      });
      String currentUserStatusID = dataEntry.cell.where((DataEntryCell cell) => cell.columnName == 'StatusID').first.value;
      _presenter.loadUserStatusList(currentUserStatusID);
    });
  }

  void goToUserListSelector(List<IVizSelectorOption> list){
    Future<bool> onTap(BuildContext context, List<IVizSelectorOption> selectedOptions){
      Completer _completer = Completer<bool>();

      UserService().update(teamAvailabilityCurrentUserSelected, statusID: selectedOptions.first.id).then((dynamic result){
        _completer.complete(true);
      }).catchError((dynamic error){
        _completer.completeError(error);
      });
      return _completer.future;
    }

    VizSelector selector = VizSelector('Select User\'s status', list, onTap);

    Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => selector),
    ).then((bool refresh){
      _teamAvailabilityLoading = true;
      _presenter.loadTeamAvailability();
    });
  }

  void onTeamAvailiblityMetricTap() {
    setState(() {
      _teamAvailabilityLoading = true;
    });
    _presenter.loadTeamAvailability();
  }

  //SlotFloor SECTION
  SwipeAction onSlotFloorSwipeRight(){

    Function onSlotActionButtonClickedCallback = (dynamic entry) {
      DataEntry dataEntry = entry as DataEntry;
      String standID = dataEntry.id;

      MachineReservation machineReservationContent = MachineReservation(standID: standID);

      Navigator.of(context).push<dynamic>(MaterialPageRoute<dynamic>(builder: (BuildContext context) => machineReservationContent)).then((dynamic result) {
        if (result != null) {
          setState(() {
            _slotFloorLoading = true;
            _slotFloorList = null;
          });
          _presenter.loadSlotFloorSummary();
        }
      });
    };

    return SwipeAction('Reserve', onSlotActionButtonClickedCallback);
  }

  SwipeAction onSlotFloorSwipeLeft(){
    Function onSlotActionButtonClickedCallback = (dynamic entry) {
      DataEntry dataEntry = entry as DataEntry;
      String standID = dataEntry.id;

      showDialog<bool>(context: context, builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text('Remove Reservation'),
          content: Text("Are you sure you want to remove the reservation for this slot ($standID)?"),
          actions: <Widget>[
            FlatButton(
              child: Text("No"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            RaisedButton(
              child: Text("Yes", style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            )
          ],
        );
      }).then((bool remove){
        if(remove !=null && remove){
          final VizSnackbar _snackbar = VizSnackbar.Processing('Removing reservation...');
          _snackbar.show(context);

          ISlotFloorService _slotMachineService = SlotFloorService();
          _slotMachineService.cancelReservation(standID).then((dynamic result) {
            setState(() {
              _slotFloorLoading = true;
              _slotFloorList = null;
            });
            _presenter.loadSlotFloorSummary();

            _snackbar.dismiss();
          }).catchError((dynamic error){
            _snackbar.dismiss();
          });
        }
      });
    };
    return SwipeAction('Unreserve', onSlotActionButtonClickedCallback);
  }

  void onSlotFloorMetricTap(){
    setState(() {
      _slotFloorLoading = true;
    });
    _presenter.loadSlotFloorSummary();
  }

  @override
  void onOpenTasksLoaded(List<DataEntryGroup> list) {
    if (mounted) {
      setState(() {
        _openTasksLoading = false;
        _openTasksList = list;
      });
    }
  }

  @override
  void onSlotFloorSummaryLoaded(List<DataEntryGroup> list) {
    if (mounted) {
      setState(() {
        _slotFloorLoading = false;
        _slotFloorList = list;
      });
    }
  }

  @override
  void onTeamAvailabilityLoaded(List<DataEntryGroup> list) {
    if (mounted) {
      setState(() {
        _teamAvailabilityLoading = false;
        _teamAvailabilityList = list;
      });
    }
  }

  @override
  void onUserStatusLoaded(List<ManagerViewUserStatus> list) {
    goToUserListSelector(list);
  }

  //MASTERVIEW EVENTS
  @override
  void onUserSectionsChanged(List<UserSection> sections) {
    _presenter.loadTeamAvailability();
  }

  @override
  void onUserStatusChanged(UserStatus us) {
    _presenter.loadTeamAvailability();
  }

  @override
  void onTeamAvailabilityError(dynamic error) {
    if (mounted) {
      VizDialog.Alert(context, 'Error', error.toString());
    }
  }

  @override
  void onOpenTasksError(dynamic error) {
    if (mounted) {
      VizDialog.Alert(context, 'Error', error.toString());
    }
  }

  @override
  void onSlotFloorError(dynamic error) {
    if (mounted) {
      VizDialog.Alert(context, 'Error', error.toString());
    }
  }
}

