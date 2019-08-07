import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:techviz/components/dataEntry/dataEntry.dart';
import 'package:techviz/components/dataEntry/dataEntryCell.dart';
import 'package:techviz/components/dataEntry/dataEntryColumn.dart';
import 'package:techviz/components/vizActionBar.dart';
import 'package:techviz/components/vizElevated.dart';
import 'package:techviz/components/vizListView.dart';
import 'package:techviz/components/vizSnackbar.dart';
import 'package:techviz/model/slotMachine.dart';
import 'package:techviz/repository/repository.dart';
import 'package:techviz/repository/slotFloorRepository.dart';

import 'machineReservation.dart';

class SlotFloor extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SlotFloorState();
}

class SlotFloorState extends State<SlotFloor> {
  final TextEditingController _searchTextController = TextEditingController();
  final FocusNode _searchTextFocusNode = FocusNode();
  final SlotFloorRepository _slotFloorRepository = Repository().slotFloorRepository;
  String _searchKey;

  @override
  void initState() {
    _slotFloorRepository.listenAsync();
    _searchTextController.addListener(_searchDispatch);
    super.initState();
  }
  @override
  void dispose() {
    _slotFloorRepository.cancelAsync();
    _searchTextController.removeListener(_searchDispatch);
    _searchTextController.dispose();

    super.dispose();
  }

  void _searchDispatch() {
    setState(() {
      _searchKey = _searchTextController.text;
    });
  }

  List<DataEntry> _slotMachineToDataEntryParser(List<SlotMachine> slotMachineList){
    if(slotMachineList==null)
      return [];

    slotMachineList.sort((SlotMachine a, SlotMachine b) => a.standID.compareTo(b.standID));

    return slotMachineList.map<DataEntry>((SlotMachine slotMachine){
      return DataEntry(
        slotMachine.standID,
        [
          DataEntryCell('StandID', slotMachine.standID),
          DataEntryCell('Theme', slotMachine.machineTypeName),
          DataEntryCell('Denom', slotMachine.denom.toString()),
          DataEntryCell('Status', _widgetForMachineStatus(slotMachine))
        ]
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    Expanded _searchComponent = Expanded(
        child: VizElevated(
            customWidget: Row(
              children: <Widget>[
                Padding(padding: EdgeInsets.only(left: 5.0), child: ImageIcon(AssetImage("assets/images/ic_search.png"), size: 25.0)),
                Expanded(
                    child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0), color: Colors.black),
                        margin: EdgeInsets.only(left: 5.0, right: 5.0),
                        padding: EdgeInsets.only(left: 10.0),
                        child: TextField(
                            controller: _searchTextController,
                            focusNode: _searchTextFocusNode,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: 'Search for StandID or Theme/Game',
                                hintStyle: TextStyle(color: Colors.white70)))))
              ],
            )));

    StreamBuilder builder = StreamBuilder<List<SlotMachine>>(
        stream: _slotFloorRepository.slotMachineSubject.stream,
        builder: (BuildContext context, AsyncSnapshot<List<SlotMachine>> snapshot) {
            List<DataEntryColumn> columns = [];
            columns.add(DataEntryColumn('StandID', alignment: DataAlignment.center));
            columns.add(DataEntryColumn('Theme', alignment: DataAlignment.center, flex: 3));
            columns.add(DataEntryColumn('Denom', alignment: DataAlignment.center));
            columns.add(DataEntryColumn('Status', alignment: DataAlignment.center));


            List<SlotMachine> data = snapshot.data;

            if (_searchKey != null && _searchKey.isNotEmpty) {
              data = data.where((SlotMachine sm) => sm.standID.contains(_searchKey) || sm.machineTypeName.toLowerCase().contains(_searchKey.toLowerCase())).toList();
            }

            return VizListView(_slotMachineToDataEntryParser(data), columns, noDataMessage: 'Loading...');
    });

    Container body = Container(
      constraints: BoxConstraints.expand(),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: const [Color(0xFF586676), Color(0xFF8B9EA7)], begin: Alignment.topCenter, end: Alignment.bottomCenter, tileMode: TileMode.repeated)),
      child: builder,
    );

    return Scaffold(appBar: ActionBar(centralWidgets: [_searchComponent]), body: SafeArea(child: body));
  }

  Widget _widgetForMachineStatus(final SlotMachine slotMachine) {
    Size size = Size(25, 25);

    Widget content;
    if(slotMachine.dirty)
      content = CircularProgressIndicator(strokeWidth: 2);
    else{
      String iconName;
      Color color;
      switch (slotMachine.machineStatusID) {
        case "1":
          iconName = 'reserved';
          color = Colors.orange;
          break;
        case "2":
          iconName = 'inuse';
          color = null;
          break;
        case "3":
          iconName = 'available';
          color = Colors.green;
          break;
        default:
          iconName = 'offline';
          color = Colors.red;
          break;
      }

      content = GestureDetector(
        onTap: () {
          if(slotMachine.dirty)
            return;

          if(slotMachine.machineStatusID == '3'){
            _goToReservationView(slotMachine);
          }
          else if(slotMachine.machineStatusID == '1'){
            _showReservationCancelDialog(slotMachine);
          }
        },
        child: Image.asset("assets/images/ic_machine_$iconName.png", color: color),
      );
    }
    return Center(child: SizedBox.fromSize(child: content, size: size));
  }


  void _goToReservationView(final SlotMachine slotMachine){
    MachineReservation machineReservationView = MachineReservation(standID: slotMachine.standID);
    Navigator.push<dynamic>(context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => machineReservationView)).then((dynamic result){
      if(result==null)
        return;

      SlotMachine slotToPush = SlotMachine(
        standID: slotMachine.standID,
        denom: slotMachine.denom,
        machineTypeName: slotMachine.machineTypeName,
        reservationTime: slotMachine.reservationTime,
        updatedAt: result['updatedAt'],
        machineStatusID: result['reservationStatusId'] == '0' ? '1' : '3',
        machineStatusDescription: slotMachine.machineStatusDescription,
        playerID: slotMachine.playerID,
        dirty: true
      );

      _slotFloorRepository.updateLocalCache([slotToPush], 'RESERVATION');
    });
  }

  void _showReservationCancelDialog(final SlotMachine slotMachine){
    bool _isReserved = slotMachine.machineStatusID != '1';
    if (_isReserved)
      return;

    showDialog<bool>(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Cancel reservation'),
        content: Text("Cancel reservation for ${slotMachine.standID}?"),
        actions: <Widget>[
          FlatButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
          ),
          FlatButton(
            child: Text("Yes"),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          )
        ],
      );
    }).then((bool cancel){
      if(cancel){
        _cancelReservation(slotMachine);
      }
    });
  }

  void _cancelReservation(final SlotMachine slotMachine){
    final VizSnackbar _snackbar = VizSnackbar.Loading('Cancelling reservation...');
    _snackbar.show(context);

    _slotFloorRepository.cancelReservation(slotMachine.standID).then((dynamic result) {
      var reservationStatusId = result['reservationStatusId'].toString();
      var copy = slotMachine;
      copy.machineStatusID = reservationStatusId == '0' ? '1' : '3';
      copy.updatedAt = DateTime.parse(result['sentAt'].toString());
      copy.dirty = true;

      _slotFloorRepository.updateLocalCache([copy], 'CANCEL');

      _snackbar.dismiss();
    }).catchError((dynamic error){
      _snackbar.dismiss();
    });
  }
}