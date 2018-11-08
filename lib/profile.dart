import 'package:flutter/material.dart';
import 'package:techviz/components/vizActionBar.dart';
import 'package:techviz/components/vizStepper.dart';

import 'package:techviz/presenter/roleListPresenter.dart';
import 'package:techviz/repository/session.dart';
import 'package:techviz/model/role.dart';
import 'package:techviz/model/userStatus.dart';
import 'package:techviz/presenter/statusListPresenter.dart';

class Profile extends StatefulWidget {
  Profile() {}

  @override
  State<StatefulWidget> createState() {
    return ProfileState();
  }
}

class ProfileState extends State<Profile>
    implements IRoleListPresenter<Role>, IStatusListPresenter<UserStatus> {
  List<ProfileItem> _userInfo = [];
  RoleListPresenter roleListPresenter;
  StatusListPresenter statusListPresenter;

  int current_step = 0;

  List<VizStep> my_steps = [
    VizStep(
        // Title of the Step
        title: Text("Graph 1"),
        // Content, it can be any widget here. Using basic Text for this example
        content: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(color: Colors.white),
        ),
        isActive: true),
    VizStep(
        title: Text("Graph 2"),
        content: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(color: Colors.red),
        ),
        // You can change the style of the step icon i.e number, editing, etc.
//        state: VizStepState.editing,
        isActive: true),
    VizStep(
        title: Text("Graph 3"),
        content: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(color: Colors.green),
        ),
        isActive: true),
    VizStep(
        title: Text("Graph 4"),
        content: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(color: Colors.blue),
        ),
        isActive: true),
  ];

  @override
  void initState() {
    Session session = Session();
    roleListPresenter = RoleListPresenter(this);
    roleListPresenter.loadUserRoles(session.user.UserID);

    statusListPresenter = StatusListPresenter(this);
    statusListPresenter.loadUserRoles(session.user.UserID);

    Map<String, String> usrMap = {
      'UserID': session.user.UserID,
      'UserName': session.user.UserName,
      'UserRoleID': session.user.UserRoleID.toString(),
      'UserStatusID': session.user.UserStatusID.toString(),
    };

    setState(() {
      usrMap.forEach((k, v) {
        var item = ProfileItem(columnName: '${k}', value: '${v}');
        _userInfo.add(item);
      });
    });

    super.initState();
  }

  Widget _buildProfileItem(BuildContext context, int index) {
    return Container(
      height: 70.0,
      margin: EdgeInsets.only(top: 0.0, bottom: 0.0, left: 0.0, right: 0.0),
      color: (index % 2 == 0 ? Color(0xFFeff4f5) : Color(0xFFffffff)),
      child: ListTile(
        title: Text(_userInfo[index].columnName),
        subtitle: Text(_userInfo[index].value),
      ),
    );
  }

  Widget _buildProfileList() {
    Widget list;
    if (_userInfo.length > 0) {
      list = ListView.builder(
        itemCount: _userInfo.length,
        itemBuilder: _buildProfileItem,
      );
    } else {
      list = Center(
        child: Text('No profile info to render'),
      );
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    var leftPanel = Expanded(flex: 1, child: _buildProfileList());

    var rightPanel = Expanded(
      flex: 1,
      child: Container(
          child: VizStepper(
//        controlsBuilder: (BuildContext context, {VoidCallback onStepContinue, VoidCallback onStepCancel}) {
//          return Row(
//            children: <Widget>[
//              Container(),
//              Container(),
//            ],
//          );
//        },

        // Using a variable here for handling the currentStep
        currentStep: this.current_step,
        // List the steps you would like to have
        steps: my_steps,
        // Define the type of Stepper style
        type: VizStepperType.horizontal,
        // Know the step that is tapped
        onStepTapped: (step) {
          // Log function callS
          print("onStepTapped : " + step.toString());
        },
        onStepCancel: () {
          // On hitting cancel button, change the state
          setState(() {
            // update the variable handling the current step value
            // going back one step i.e subtracting 1, until its 0
            if (current_step > 0) {
              current_step = current_step - 1;
            } else {
              current_step = 0;
            }
          });
          // Log function call
          print("onStepCancel : " + current_step.toString());
        },
        // On hitting continue button, change the state
        onStepContinue: () {
          setState(() {
            // update the variable handling the current step value
            // going back one step i.e adding 1, until its the length of the step
            if (current_step < my_steps.length - 1) {
              current_step = current_step + 1;
            } else {
              current_step = 0;
            }
          });
          // Log function call
          print("onStepContinue : " + current_step.toString());
        },
      )),
    );

    Container container = Container(
      child: Padding(
          padding: EdgeInsets.all(0.0),
          child: Row(
            children: <Widget>[leftPanel, rightPanel],
          )),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF586676), Color(0xFF8B9EA7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              tileMode: TileMode.repeated)),
    );

    var safe = SafeArea(child: container, top: false, bottom: false);

    return Scaffold(backgroundColor: Colors.black, appBar: ActionBar(title: 'My Profile'), body: safe);
  }

  @override
  void onLoadError(Error error) {
    // TODO: implement onLoadError
  }

  @override
  void onRoleListLoaded(List<Role> result) {
    if (result.length == 1) {
      return;
    }

//Session session = Session();
//var user = session.user;

    print("roles loaded");

//    setState(() {
//      roleList = result;
//    });
  }

  @override
  void onStatusListLoaded(List<UserStatus> result) {
// TODO: implement onStatusListLoaded
//
//    Session session = Session();
//    var user = session.user;

    print("statuses loaded");
//    setState(() {
//      roleList = result;
//    });
  }
}

abstract class ListItem {}

// A ListItem that contains data to display a message
class ProfileItem implements ListItem {
  final String columnName;
  final String value;

  ProfileItem({this.columnName, this.value});
}
