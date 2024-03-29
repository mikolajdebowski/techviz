import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:techviz/components/taskList/VizTaskItem.dart';
import 'package:techviz/components/vizTaskActionButton.dart';
import 'package:techviz/components/vizTimer.dart';
import 'package:techviz/model/task.dart';
import 'package:techviz/model/userSection.dart';
import 'package:techviz/model/userStatus.dart';
import 'package:techviz/service/taskService.dart';
import 'package:techviz/ui/home.dart';
import '../session.dart';
import 'escalation.dart';

class TaskView extends StatefulWidget {
  const TaskView(Key key) : super(key: key);

  @override
  State<StatefulWidget> createState() => TaskViewState();
}

class TaskViewState extends State<TaskView> with WidgetsBindingObserver implements TechVizHome {
  final String _taskListStatusIcon = "assets/images/ic_processing.png";
  Task _selectedTask;
  int _openTasksCount = 0;
  StreamSubscription<List<Task>> _streamSubscription;
  final List<int> _openTaskStatusIDs = [1,2,3,31,32,33];

  final defaultHeaderDecoration = BoxDecoration(
      border: Border.all(color: Colors.black, width: 0.5),
      gradient: LinearGradient(
          colors: const [Color(0xFF4D4D4D), Color(0xFF000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter, tileMode: TileMode.repeated));

  @override
  void initState() {
    _streamSubscription = TaskService().openTasks.listen(onTaskListReceived, onError: onTaskListenError);
    super.initState();
  }

  void onTaskListReceived(List<Task> openTasks) {
    setState(() {
      openTasks = openTasks.where((Task task)=> _openTaskStatusIDs.contains(task.taskStatusID) && task.userID == Session().user.userID).toList();

      _openTasksCount = openTasks.length;
      if (_selectedTask != null && _openTasksCount > 0) {
        Iterable<Task> exists = openTasks.where((Task _task) => _task.id == _selectedTask.id);
        if (exists != null && exists.isNotEmpty) {
          _selectedTask = exists.first;
        }
        else{
          _selectedTask = null;
        }
      } else {
        _selectedTask = null;
      }
    });
  }

  void onTaskListenError(dynamic error) {
    print('onError' + error.toString());
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void onTaskItemTapCallback(Task task) {
    if (!mounted) return;

    setState(() {
      _selectedTask = task;
    });
  }

  void updateTaskStatus(Task task, int statusID) {
    TaskService().update(task.id, statusID: statusID);
  }

  @override
  Widget build(BuildContext context) {

    VizTaskItem buildTaskItemBody(Task task, int index) {
      bool selected = _selectedTask != null && _selectedTask.id == task.id;
      return VizTaskItem(task, index + 1, onTaskItemTapCallback, selected, key: Key(task.id));
    }

    StreamBuilder streamBuilderListView = StreamBuilder<List<Task>>(
        stream: TaskService().openTasks,
        builder: (context, AsyncSnapshot<List<Task>> snapshot) {
          Iterable<Task> where;
          if(snapshot.hasData){ //filter user tasks
            where = snapshot.data.where((Task task)=> task.userID == Session().user.userID && _openTaskStatusIDs.contains(task.taskStatusID));
          }

          if (!snapshot.hasData || (where!=null && where.isEmpty)) {
            return Container(key: Key('taskViewEmptyContainer'));
          } else {
            List<Task> filtered = where.toList();
            filtered.sort((Task a, Task b)=> b.taskUrgencyID.compareTo(a.taskUrgencyID));
            return ListView.builder(
              key: Key('taskViewListView'),
                itemBuilder: (BuildContext builderCtx, int index) => buildTaskItemBody(filtered[index], index), itemCount: filtered.length);
          }
        });

    //TASK PANEL
    Flexible tasksContainer = Flexible(
      flex: 1,
      child: Column(
        children: <Widget>[
          Container(
            constraints: BoxConstraints.expand(height: 70.0),
            decoration: defaultHeaderDecoration,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('$_openTasksCount task(s)' , style: TextStyle(color: Colors.white)),
                      Padding(
                        padding: EdgeInsets.only(left: 10.0),
                        child: _taskListStatusIcon != null ? ImageIcon(AssetImage(_taskListStatusIcon), size: 15.0, color: Colors.blueGrey) : null,
                      )
                    ],
                  ),
                ),
                Text('0 Pending', style: TextStyle(color: Colors.orange)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Text('Priority', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                    ImageIcon(AssetImage("assets/images/ic_arrow_up.png"), size: 20.0, color: Colors.grey)
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border(right: BorderSide(color: Color(0x33000000)))),
              child: streamBuilderListView,
            ),
          )
        ],
      ),
    );

    //CENTER PANEL WIDGETS
    Padding rowCenterHeader = Padding(
        padding: EdgeInsets.only(left: 5.0, top: 7.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Active Task', style: TextStyle(color: Color(0xFF9aa8b0), fontSize: 12.0)),
                  Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text(
                        _selectedTask != null ? _selectedTask.location : '',
                        style: TextStyle(color: Colors.lightBlue, fontSize: 20.0),
                        softWrap: false,
                      ))
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Task Type', style: TextStyle(color: Color(0xFF9aa8b0), fontSize: 12.0)),
                  Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text(_selectedTask != null ? _selectedTask.taskType.description : '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 16.0),
                          softWrap: false))
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('Task Status', style: TextStyle(color: Color(0xFF9aa8b0), fontSize: 12.0)),
                  Padding(
                      padding: EdgeInsets.only(top: 5.0),
                      child: Text(_selectedTask != null ? _selectedTask.taskStatus.description : '',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold)))
                ],
              ),
            ),
          ],
        ));

    BoxDecoration actionBoxDecoration = BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: Color(0xFFFFFFFF)),
        gradient: LinearGradient(
            colors: const [Color(0xFF81919D), Color(0xFFAAB7BD)], begin: Alignment.topCenter, end: Alignment.bottomCenter, tileMode: TileMode.repeated));

    Widget taskBody;
    bool canTakeActions = _selectedTask?.dirty == 0;

    if (_selectedTask != null) {

      String taskInfoDescription = '';
      if (_selectedTask != null) {
        if (_selectedTask.amount > 0) {
          taskInfoDescription = '${_selectedTask.amount.toStringAsFixed(2)}';
        } else {
          taskInfoDescription = _selectedTask.eventDesc;
        }
      }

      Expanded taskInfo = Expanded(
          flex: 1,
          child: Container(
                  margin: EdgeInsets.all(5),
                  constraints: BoxConstraints.tightFor(height: 70.0),
                  padding: EdgeInsets.all(5),
                  decoration: actionBoxDecoration,
                  child: Column(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(top: 3.0),
                          child: Text('Task Info',
                              style: TextStyle(
                                color: Color(0xFF444444),
                                fontSize: 14.0,
                              ))),
                      Padding(
                          padding: EdgeInsets.only(top: 5.0),
                          child: Text(taskInfoDescription,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)))
                    ],
                  )));

      List<Widget> taskDetailsHeader = <Widget>[taskInfo];

      if(_selectedTask.playerID != null && _selectedTask.playerID.isNotEmpty) {
        String playerName = '${_selectedTask.playerFirstName} ${_selectedTask.playerLastName}';

        BoxDecoration boxDecoForTierWidget;
        String tier = _selectedTask.playerTier;
        String tierColorHexStr = _selectedTask.playerTierColorHEX;
        Color tierFontColor;

        if (tier != null && tierColorHexStr != null) {
          tierColorHexStr = tierColorHexStr.replaceAll('#', '');
          Color hexColor = Color(int.parse('0xFF$tierColorHexStr'));
          boxDecoForTierWidget = BoxDecoration(borderRadius: BorderRadius.circular(6.0), color: hexColor);
          tierFontColor = Colors.black;
        } else {
          boxDecoForTierWidget = BoxDecoration(borderRadius: BorderRadius.circular(6.0), border: Border.all(color: Colors.white));
          tierFontColor = Colors.white;
        }

        Expanded playerInfo = Expanded(
            flex: 1,
            child: Container(
                    margin: EdgeInsets.only(top: 5, right: 5, bottom: 5),
                    padding: EdgeInsets.all(5),
                    constraints: BoxConstraints.tightFor(height: 70.0),
                    decoration: actionBoxDecoration,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Player Info',
                            style: TextStyle(
                              color: Color(0xFF444444),
                              fontSize: 14.0,
                            )),
                        Text(playerName,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                            style: TextStyle(color: Colors.white, fontSize: 14.0, fontWeight: FontWeight.bold)),
                        Container(
                          padding: EdgeInsets.only(left: 10, right: 10, top: 1, bottom: 1),
                          decoration: boxDecoForTierWidget,
                          child: Text(tier.toUpperCase(), style: TextStyle(color: tierFontColor, fontSize: 12),),
                        )
                      ],
                    )));

        taskDetailsHeader.add(playerInfo);
      }

      //primary action
      String primaryActionImageSource;
      String primaryActionTextSource;
      VoidCallback primaryActionCallBack;

      switch(_selectedTask.taskStatus.id){

        case 1:
        case 31:
          primaryActionImageSource = "assets/images/ic_task_acknowledge.png";
          primaryActionTextSource = _selectedTask.isTechTask ? 'Tech Acknowledge' : 'Acknowledge';
          primaryActionCallBack = () => updateTaskStatus(_selectedTask, _selectedTask.isTechTask == false ? 2 : 32);
          break;
        case 2:
        case 32:
          primaryActionImageSource = "assets/images/ic_task_cardin.png";
          primaryActionTextSource = _selectedTask.isTechTask ? 'Tech Card in' : 'Card in';
          primaryActionCallBack = () => updateTaskStatus(_selectedTask, _selectedTask.isTechTask == false ? 3 : 33);
          break;
        case 3:
        case 33:
        case 5:
          primaryActionImageSource = "assets/images/ic_task_complete.png";
          primaryActionTextSource = _selectedTask.isTechTask ? 'Tech Complete' : 'Complete';
          primaryActionCallBack = () => updateTaskStatus(_selectedTask, 13);
          break;
      }

      VizTaskActionButton primaryAction = VizTaskActionButton(primaryActionTextSource, Colors.green, enabled: canTakeActions, onTapCallback: primaryActionCallBack, height: 140, icon: primaryActionImageSource);

      taskBody = Column(
          children: <Widget>[
            Row(
              children: taskDetailsHeader,
            ),
            Flexible(child: Padding(padding: EdgeInsets.only(left: 5, right: 5), child: primaryAction))
          ]
      );
    }

    Flexible centerContainer = Flexible(
      flex: 4,
      child: Column(
        children: <Widget>[
          Container(
            constraints: BoxConstraints.expand(height: 70.0),
            decoration: defaultHeaderDecoration,
            child: rowCenterHeader,
          ),
          Expanded(
              child: _selectedTask != null
                  ? taskBody
                  : Center(
                      child: Text(
                      _openTasksCount == 0 ? 'No tasks' : 'Select a Task',
                      style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                    )))
        ],
      ),
    );


    //RIGHT CONTAINER WIDGETS
    Padding timerWidget = Padding(
      padding: EdgeInsets.only(top: 7.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text('Time Taken', style: TextStyle(color: Colors.grey, fontSize: 12.0)),
          VizTimer(timeStarted: _selectedTask != null ? _selectedTask.taskCreated : null)
        ],
      ),
    );

    List<Widget> rightActionWidgets = <Widget>[];
    if (_selectedTask != null) {
      if ([2,3,32,33].contains(_selectedTask.taskStatus.id)) {
        Padding action = Padding(
          padding: EdgeInsets.only(top: 5, right: 5),
          child: VizTaskActionButton('Cancel', Colors.red, enabled: canTakeActions, icon: 'assets/images/ic_task_cancel.png' ,onTapCallback: () {
            _showCancellationDialog(_selectedTask.id);
          }),
        );
        rightActionWidgets.add(action);
      }

      if ([3,33].contains(_selectedTask.taskStatus.id)) {
        Padding action = Padding(
          padding: EdgeInsets.only(top: 5, right: 5),
          child: VizTaskActionButton('Escalate', Colors.orange, enabled: canTakeActions, icon: 'assets/images/ic_task_escalate.png' , onTapCallback: () {
            _goToEscalationPathView();
          }),
        );
        rightActionWidgets.add(action);
      }
    }

    Column rightActionsColumn = Column(children: rightActionWidgets);
    Flexible rightContainer = Flexible(
      flex: 1,
      child: Column(
        children: <Widget>[
          Container(
            constraints: BoxConstraints.expand(height: 70.0),
            decoration: defaultHeaderDecoration,
            child: timerWidget,
          ),
          SingleChildScrollView(
            child: rightActionsColumn,
          )
        ],
      ),
    );

    return Scaffold(
        resizeToAvoidBottomPadding: false,
        body: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: const [Color(0xFF586676), Color(0xFF8B9EA7)], begin: Alignment.topCenter, end: Alignment.bottomCenter, tileMode: TileMode.repeated)),
          child: Row(
            children: <Widget>[tasksContainer, centerContainer, rightContainer],
          ),
        ));
  }


  /* Cancellation */
  final GlobalKey<FormState> _cancellationFormKey = GlobalKey<FormState>();
  void _showCancellationDialog(final String taskID) {
    final TextEditingController _cancellationController = TextEditingController();

    bool btnEnbled = true;
    double _width = MediaQuery.of(context).size.width / 100 * 80;
    String location = _selectedTask.location.toString();



    Container container = Container(
      width: _width,
      decoration: BoxDecoration(shape: BoxShape.rectangle),
      child: SingleChildScrollView(
        child: Form(
          key: _cancellationFormKey,
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: Text('Cancel Task $location'),
              ),
              Divider(
                color: Colors.grey,
                height: 4.0,
              ),
              Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20.0),
                child: TextFormField(
                  controller: _cancellationController,
                  maxLength: 4000,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: "Cancellation reason",
                    border: InputBorder.none,
                  ),
                  maxLines: 6,
                  validator: (String value) {
                    if (value.isEmpty)
                      return 'Please inform the cancellation reason';
                    return null;
                  },
                ),
              ),
              Divider(
                color: Colors.grey,
                height: 4.0,
              ),
              Stack(
                children: <Widget>[
                  Align(
                      alignment: Alignment.centerLeft,
                      child: FlatButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: Text(
                          "Dismiss",
                        ),
                      )),
                  Align(
                      alignment: Alignment.centerRight,
                      child: FlatButton(
                        onPressed: () {
                          if (!btnEnbled) return;

                          if (!_cancellationFormKey.currentState.validate() || _selectedTask == null) {
                            return;
                          }

                          btnEnbled = false;

                          _onCancelTask(context, _selectedTask, _cancellationController.text);
                        },
                        child: Text(
                          "Cancel this task",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ))
                ],
              )
            ],
          ),
        ),
      ),
    );

    showDialog<bool>(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: container,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10.0))),
          );
        });
  }

  void _onCancelTask(BuildContext context, Task task, String cancellationReason){
    TaskService().update(task.id, statusID: 12, notes: base64.encode(utf8.encode(cancellationReason)));
    Navigator.of(context).pop(true);
  }

  /* EscalationPath */
  void _goToEscalationPathView() {
    if (_selectedTask == null) return;

    EscalationForm escalationForm = EscalationForm(_selectedTask);
    MaterialPageRoute<bool> mpr = MaterialPageRoute<bool>(builder: (BuildContext context) => escalationForm);
    Navigator.of(context).push(mpr);
  }

  @override
  void onUserStatusChanged(UserStatus us) {
    // TODO(rmathias): FORCE RELOAD TASKS?
  }

  @override
  void onUserSectionsChanged(List<UserSection> sections) {
    // TODO(rmathias): FORCE RELOAD TASKS?
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // TODO(rmathias): FORCE RELOAD TASKS?
    }
  }
}
