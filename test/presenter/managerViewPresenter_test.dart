import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:techviz/model/taskStatus.dart';
import 'package:techviz/model/taskType.dart';
import 'package:techviz/presenter/managerViewPresenter.dart';
import 'package:techviz/repository/local/taskStatusTable.dart';
import 'package:techviz/repository/local/taskTypeTable.dart';
import 'package:techviz/repository/repository.dart';
import 'package:techviz/repository/taskRepository.dart';
import 'package:techviz/repository/taskStatusRepository.dart';
import 'package:techviz/repository/taskTypeRepository.dart';

import '../repository/mock/localRepositoryMock.dart';

class IManagerViewPresenterView extends Mock implements IManagerViewPresenter{

}

class TaskRemoteRepositoryMock implements ITaskRemoteRepository{
  @override
  Future fetch() {
    throw UnimplementedError();
  }

  @override
  Future openTasksSummary() {

    List<Map<String,dynamic>> listToReturn = <Map<String,dynamic>>[];

    for(int i =0; i< 100; i++){
      Map<String,dynamic> mapEntry = <String,dynamic>{};
      mapEntry['_ID'] = i.toString();
      mapEntry['Location'] = i.toString();
      mapEntry['TaskTypeID'] = i.toString();
      mapEntry['TaskStatusID'] = i.toString();
      mapEntry['UserID'] = i.toString();
      mapEntry['ElapsedTime'] = i.toString();
      mapEntry['TaskUrgencyID'] = i.toString();
      mapEntry['ParentID'] = i.toString();
      mapEntry['IsTechTask'] = false;
    }
    return Future<List<Map<String,dynamic>>>.value(listToReturn);
  }
}

class TaskTypeTableMock implements ITaskTypeTable{
  @override
  Future<List<TaskType>> getAll({TaskTypeLookup lookup}) {
    return Future<List<TaskType>>.value([]);
  }

  @override
  Future<int> insertAll(List<Map<String, dynamic>> list) {
    return Future<int>.value(1);
  }
}

class TaskStatusTableMock implements ITaskStatusTable{
  @override
  Future<List<TaskStatus>> getAll() {
    return Future<List<TaskStatus>>.value([]);
  }

  @override
  Future<int> insertAll(List<Map<String, dynamic>> list) {
    return Future<int>.value(1);
  }
}

void main(){
  setUp((){
    Repository().taskRepository = TaskRepository(TaskRemoteRepositoryMock(), LocalRepositoryMock());
    Repository().taskTypeRepository = TaskTypeRepository(null, TaskTypeTableMock());
    Repository().taskStatusRepository = TaskStatusRepository(null, TaskStatusTableMock());
  });

  test('loadOpenTasks should call back onOpenTasksLoaded', () async{
    IManagerViewPresenter view = IManagerViewPresenterView();

    ManagerViewPresenter presenter = ManagerViewPresenter(view);
    presenter.loadOpenTasks();

    await untilCalled(view.onOpenTasksLoaded(any));

    VerificationResult result = verify(view.onOpenTasksLoaded(captureAny));//.callCount;
    expect(result.callCount, 1, reason: 'not called once');
    // TODO(rmathias): check the captured value ////// (result.captured, <DataEntryGroup>[], reason: 'not a list');
  });
}