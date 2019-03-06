import 'dart:async';
import 'dart:convert';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techviz/config.dart';
import 'package:vizexplorer_mobile_common/vizexplorer_mobile_common.dart';
import 'package:flutter/services.dart' show rootBundle;

class MessageClient {
  static final MessageClient _instance = MessageClient._internal();
  Client _rabbitmqClient;
  String _exchangeName = null;
  Duration _timeoutDuration = Duration(seconds: 10);
  Consumer _consumer;
  Exchange _exchange;

  Map<String, List<StreamController<AmqpMessage>>> _mapStreamControllers;
  String _deviceID;

  factory MessageClient() {
    return _instance;
  }

  MessageClient._internal() {}

  Future Init() async {
    print('MessageClient: Init');
    if(_exchangeName==null){
      //CONFIGURATION
      String loadedConfig = await rootBundle.loadString('assets/json/config.json');
      dynamic jsonConfig = jsonDecode(loadedConfig);
      _exchangeName = jsonConfig['rabbitmq']['exchange_name'] as String;
    }

    //DEVICEID
    DeviceInfo deviceInfo = await Utils.deviceInfo;
    _deviceID = deviceInfo.DeviceID;

    //UNIQUE DEVICE QUEUE
    String queueName = "mobile.${_deviceID}";

    Completer<void> _completer = Completer<void>();
    _rabbitmqClient = null;
    _mapStreamControllers = Map<String, List<StreamController<AmqpMessage>>>();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String host = prefs.getString(Config.SERVERURL);
    Uri hostURI = Uri.parse(host);

    ConnectionSettings settings = ConnectionSettings(host: hostURI.host, authProvider: AmqPlainAuthenticator("mobile", "mobile"));
    settings.maxConnectionAttempts = 1;

    _rabbitmqClient = Client(settings: settings);
    _rabbitmqClient.connect().then((dynamic whatever) {

      print('RabbitMQ connected');

      _rabbitmqClient.channel().then((Channel channel){
        return _getExchange(channel);
      }).then((Exchange exchange){
        print('Exchange/Channel OK');
        _exchange = exchange;
        return _exchange.channel.queue(queueName, autoDelete: true);
      }).then((Queue queue){
        return queue.consume();
      }).then((Consumer consumer){
        _consumer = consumer;
        _consumer.listen((AmqpMessage message){
          //print('RoutingKey: ${message.routingKey}');
          //print('Payload: ${message.payloadAsString}');
          var mapEntry = _mapStreamControllers[message.routingKey];
          if(mapEntry!=null){
            mapEntry.forEach((StreamController ss){
              ss.add(message);
            });
          }
        });

        print('Listening to the queue : ${_consumer.queue.name}');

        return _completer.complete();
      });

    }).catchError((dynamic e) {
      print('RabbitMQ error: ' + e.toString());
      return _completer.completeError(e);
    });
    _rabbitmqClient.errorListener((dynamic error){
      print(error);
    });
    return _completer.future;
  }

  void ResetChannel() async{
    Channel channel = await _rabbitmqClient.channel();
    _exchange = await _getExchange(channel);
  }

  void _bindQueue(String routingKey) async{

    try{
      await _consumer.queue.bind(_exchange, routingKey);
    }
    catch(e){
      if(e.runtimeType == StateError){
        await Init();
        return await _bindQueue(routingKey);
      }
      else throw e;
    }
  }

  void _addRoutingKeyListener(String routingKey, StreamController<AmqpMessage> subscription) async{
    print('_addRoutingKeyListener  ${routingKey}');
    await _bindQueue(routingKey);

    if(!_mapStreamControllers.containsKey(routingKey)){
      _mapStreamControllers[routingKey] = [];
    }
    _mapStreamControllers[routingKey].add(subscription);
  }

  void _removeRoutingKeyListener(String routingKey){
    print('_removeRoutingKeyListener  ${routingKey}');
    _consumer.queue.unbind(_exchange, routingKey);
    if(_mapStreamControllers.containsKey(routingKey)){
      _mapStreamControllers.remove(routingKey);
    }
  }

  Future<Exchange> _getDefaultExchange(Channel channel){
    return channel.exchange(_exchangeName, ExchangeType.TOPIC, durable: true);
  }

  Future<Exchange> _getExchange(Channel _channel)  {
    return _getDefaultExchange(_channel).timeout(_timeoutDuration).then((Exchange exchange) {
      print('channel OK');
      return Future.value(exchange);
    }).catchError((dynamic connError){
      print(connError);
      print('getting second channel');

      if(connError.runtimeType == TimeoutException || connError.runtimeType == ChannelException){
        return _rabbitmqClient.channel().timeout(_timeoutDuration, onTimeout: (){
          throw TimeoutException('Timeout after trying to create channel');
        }).then((Channel channel) {
          print('new channel instance');
          _channel = channel;
          return _getDefaultExchange(_channel).timeout(_timeoutDuration);
        });
      }
      else{
        throw connError;
      }
    });
  }

  Future PublishMessage(dynamic object, String routingKeyPattern, {bool wait : false, Function parser}) async {
    Completer<void> _completer = Completer<void>();
    _completer.future.timeout(_timeoutDuration, onTimeout: (){
      _completer.completeError(TimeoutException('Max connect timeout reached after ${_timeoutDuration.inSeconds} seconds.'));
    });

    String routingKey = '${routingKeyPattern}.${_deviceID}';

    if(wait!=null && wait){
      StreamController<AmqpMessage> sc = StreamController<AmqpMessage>();
      sc.stream.listen((AmqpMessage message){
        _removeRoutingKeyListener(routingKey);
        _completer.complete(parser == null ? message.payloadAsJson : parser(message.payloadAsJson));
      });
      _addRoutingKeyListener(routingKey, sc);
    }

    MessageProperties props = MessageProperties();
    props.persistent = true;
    props.contentType = 'application/json';
    _exchange.publish(JsonEncoder().convert(object), "${routingKeyPattern}.update", properties: props);

    if(!wait){
      _completer.complete();
    }

    return _completer.future;
  }

  StreamController ListenQueue(String routingKeyPattern, Function onData, {Function onError, bool timeOutEnabled = true, Function parser, bool appendDeviceID : true}) {
    String routingKey = '${routingKeyPattern}';
    if(appendDeviceID!=null && appendDeviceID){
      routingKey += '.${_deviceID}';
    }

    void onCancel(){
      _removeRoutingKeyListener(routingKey);
    }

    StreamController<AmqpMessage> sc = StreamController<AmqpMessage>(onCancel: onCancel);
    sc.stream.listen((AmqpMessage message){
      onData(parser!=null ? parser(message.payloadAsString): message.payloadAsString);
    });
    _addRoutingKeyListener(routingKey, sc);
    return sc;
  }

  Future Close(){
    if(_rabbitmqClient!=null){
      return _rabbitmqClient.close();
    }
    return Future<dynamic>.value(true);
  }
}