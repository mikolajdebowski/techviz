import 'dart:async';
import 'dart:convert';

import 'package:techviz/common/http/client/sessionClient.dart';
import 'package:techviz/model/taskStatus.dart';
import 'package:techviz/repository/local/localRepository.dart';
import 'package:techviz/repository/processor/processorRepositoryConfig.dart';
import 'package:techviz/repository/remoteRepository.dart';

class ProcessorTaskUrgencyRepository implements IRemoteRepository<TaskStatus>{

  @override
  Future fetch() {
    print('Fetching '+ toString());

    Completer _completer = Completer<void>();
    SessionClient client = SessionClient();

    var config = ProcessorRepositoryConfig();
    String liveTableID = config.GetLiveTable(LiveTableType.TECHVIZ_MOBILE_TASK_URGENCY.toString()).id;
    String url = 'live/${config.DocumentID}/$liveTableID/select.json';

    client.get(url).then((String rawResult) async {

      dynamic decoded = json.decode(rawResult);
      List<dynamic> rows = decoded['Rows'] as List<dynamic>;

      var _columnNames = (decoded['ColumnNames'] as String).split(',');

      LocalRepository localRepo = LocalRepository();
      await localRepo.open();

      rows.forEach((dynamic d) {
        dynamic values = d['Values'];

        Map<String, dynamic> map = <String, dynamic>{};
        map['ID'] = values[_columnNames.indexOf("TaskUrgencyID")];
        map['Description'] = values[_columnNames.indexOf("TaskUrgencyDescription")];
        map['ColorHex'] = values[_columnNames.indexOf("UrgencyColorHex")];
        localRepo.insert('TaskUrgency', map);
      });

      _completer.complete();

    }).catchError((dynamic onError)
    {
      print(onError.toString());
      _completer.completeError(onError);
    });

    return _completer.future;
  }

}