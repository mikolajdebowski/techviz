import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:rxdart/subjects.dart';
import 'package:techviz/model/user.dart';
import 'package:techviz/service/client/MQTTClientService.dart';
import 'package:techviz/service/sectionService.dart';
import 'package:techviz/session.dart';

import '../_mocks/deviceUtilsMock.dart';

class MQTTClientServiceMock extends Mock implements IMQTTClientService{
  Map<String,BehaviorSubject<dynamic>> subjects = <String,BehaviorSubject<dynamic>>{};

  @override
  Stream<dynamic> subscribe(String routingKey){
    subjects[routingKey] = BehaviorSubject<dynamic>();
    return subjects[routingKey].stream;
  }

  @override
  Stream<dynamic> streams(String routingKey){
    return subjects[routingKey].stream;
  }

  void simulateStreamPayload(String routingKeyCallback, dynamic message){
    subjects[routingKeyCallback].add(message);
  }
}

void main() {
  SectionService _sectionService;
  MQTTClientServiceMock _clientServiceMock;
  List<String> sections = ['01', '02'];
  DeviceUtilsMock _deviceUtilsMock = DeviceUtilsMock();

  setUp(() async{
    Session().user = User(userID: 'dev2');
    _clientServiceMock = MQTTClientServiceMock();
    _sectionService = SectionService(mqttClientService: _clientServiceMock, deviceUtils: _deviceUtilsMock);
  });

  test('update Future should complete', () async {

    Future<void> updateFuture = _sectionService.update(Session().user.userID, sections);

    String routingKeyForPublish = 'mobile.section.update.${_deviceUtilsMock.deviceInfo.DeviceID}';
    _clientServiceMock.simulateStreamPayload(routingKeyForPublish, 'irrelevantPayload');

    expect(updateFuture, completion(anything));
  });
}
