import 'dart:async';
import 'package:techviz/repository/common/IRepository.dart';
import 'package:techviz/repository/remoteRepository.dart';

class StatsMonthRepository implements IRepository<dynamic> {
  IRemoteRepository remoteRepository;

  StatsMonthRepository({this.remoteRepository});

  @override
  Future fetch() {
    assert(remoteRepository != null);
    return remoteRepository.fetch();
  }
}
