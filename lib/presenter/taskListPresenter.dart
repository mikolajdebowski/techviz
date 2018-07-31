import 'package:techviz/model/task.dart';
import 'package:techviz/repository/taskRepository.dart';
import 'package:techviz/repository/repository.dart';

abstract class TaskListPresenterContract<Task> {
  void onTaskListLoaded(List<Task> result);
  void onLoadError(Error error);
}

class TaskListPresenter{

  TaskListPresenterContract<Task> _view;
  ITaskRepository _repository;

  TaskListPresenter(this._view){
    _repository = new Repository().taskRepository;
  }

  void loadTaskList(){
    assert(_view != null);
    _repository.getTaskList().then((List<Task> list) {
      _view.onTaskListLoaded(list);

    }).catchError((Error onError) {
      print(onError);
      _view.onLoadError(onError);
    });
  }
}