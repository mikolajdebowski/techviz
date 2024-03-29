import 'package:observable/observable.dart';

class User extends PropertyChangeNotifier {
  String userID;
  String userName;
  int userRoleID;
  int userStatusID;
  String staffID;

  User({this.userID, this.userName, this.userRoleID, this.userStatusID, this.staffID});

  User.fromMap(Map map){
    userID = map['UserID'] as String;
    userName = map['UserName'] as String;
    userRoleID = map['UserRoleID'] == null ? 0: int.parse(map['UserRoleID'].toString());
    userStatusID = map['UserStatusID'] == null ? 0: int.parse(map['UserStatusID'].toString());
    staffID = map['StaffID'] as String;
  }
}