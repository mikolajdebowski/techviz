import 'dart:async';
import 'dart:convert';

import 'package:techviz/model/taskType.dart';
import 'package:techviz/repository/localRepository.dart';
import 'package:techviz/repository/processor/processorRepositoryFactory.dart';
import 'package:techviz/repository/taskTypeRepository.dart';
import 'package:vizexplorer_mobile_common/vizexplorer_mobile_common.dart';

class ProcessorTaskTypeRepository extends TaskTypeRepository{

  @override
  Future<List<dynamic>> fetch() {

    SessionClient client = SessionClient.getInstance();

    var config = ProcessorRepositoryConfig();
    String liveTableID = config.GetLiveTable(LiveTableType.TECHVIZ_MOBILE_TASK_TYPE.toString()).ID;
    String url = 'live/${config.DocumentID}/${liveTableID}/select.json';

    return client.get(url).then((String rawResult) async {

      List<TaskType> _toReturn = List<TaskType>();
      Map<String,dynamic> decoded = json.decode(rawResult);
      List<dynamic> rows = decoded['Rows'];

      var _columnNames = (decoded['ColumnNames'] as String).split(',');

      LocalRepository localRepo = LocalRepository();
      await localRepo.open();

      rows.forEach((dynamic d) {
        dynamic values = d['Values'];

        Map<String, dynamic> map = Map<String, dynamic>();
        map['_ID'] = values[_columnNames.indexOf("_ID")] as String;
        map['DefaultValue'] = values[_columnNames.indexOf("DefaultValue")] as String;
        map['LookupName'] = values[_columnNames.indexOf("LookupName")];
        map['TaskTypeID'] = values[_columnNames.indexOf("LookupKey")];
        map['TaskTypeDescription'] = values[_columnNames.indexOf("LookupValue")];
        localRepo.insert('TaskType', map);
      });

      return Future.value(_toReturn);

    }).catchError((Error onError)
    {
      print(onError.toString());
    });
  }


}