import 'dart:async';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:dart_amqp/dart_amqp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techviz/config.dart';
import 'package:vizexplorer_mobile_common/vizexplorer_mobile_common.dart';

class MessageClient {
  static final MessageClient _instance = MessageClient._internal();
  Client _rabbitmqClient;
  String _exchangeName;

  factory MessageClient() {
    return _instance;
  }

  MessageClient._internal() {}

  Future Init(String exchangeName) async {
    print('MessageClient: Init');

    _exchangeName = exchangeName;
    Completer<void> _completer = Completer<void>();
    _rabbitmqClient = null;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String host = prefs.getString(Config.SERVERURL);
    Uri hostURI = Uri.parse(host);

    ConnectionSettings settings = ConnectionSettings(host: hostURI.host, authProvider: AmqPlainAuthenticator("mobile", "mobile"));
    settings.maxConnectionAttempts = 1;

    _rabbitmqClient = Client(settings: settings);
    _rabbitmqClient.connect().then((dynamic client) {
      print('RabbitMQ connected');
      return _completer.complete();
    }).catchError((dynamic e) {
      print('RabbitMQ error: ' + e.toString());
      return _completer.completeError(e);
    });

    return _completer.future;
  }

  Future Close(){
    if(_rabbitmqClient!=null){
      return _rabbitmqClient.close();
    }
    return Future<dynamic>.value(true);
  }

  Future<Exchange> GetExchange() {
    return _rabbitmqClient.channel().then((Channel _channel) {
      return _channel.exchange(_exchangeName, ExchangeType.TOPIC, durable: true);
    });
  }

  Future<Consumer> GetConsumerForQueue(String queueName, String routingKeyPattern) {
    Exchange _exchange;
    return GetExchange().then((Exchange exchange) {
      _exchange = _exchange;
      return exchange.channel.queue(queueName, autoDelete: false, durable: true);
    }).then((Queue queue) {
      return queue.bind(_exchange, routingKeyPattern);
    }).then((Queue queueBinded) {
      return queueBinded.consume();
    });
  }

  Future PublishMessage(dynamic object, String routingKeyPattern, {Function callback, Function callbackError, Function parser}) async {
    Completer<void> _completer = Completer<void>();

    var _delayedFuture = Future<void>.delayed(Duration(seconds: 30));
    var _streamDelayed = Stream.fromFuture(_delayedFuture).listen((dynamic d){

      if(!_completer.isCompleted){
        var excp = Exception('Timeout reached after 30 seconds');
        if(callbackError!=null){
          callbackError(excp);
        }
        else {
          print('delayed completing error for ${routingKeyPattern} ${_completer.hashCode}');
          _completer.completeError(excp);
        }
      }
    });

    void _publishMessage(Exchange exchange, dynamic object){
      MessageProperties props = MessageProperties();
      props.persistent = true;
      props.contentType = 'application/json';

      exchange.publish(JsonEncoder().convert(object), "${routingKeyPattern}.update", properties: props);
    }

    _rabbitmqClient.channel().then((Channel _channel) {
      return _channel.exchange(_exchangeName, ExchangeType.TOPIC, durable: true);
    }).then((Exchange exchange) async {

      if (callback == null) {
        _streamDelayed.cancel();
        _publishMessage(exchange, object);
        _completer.complete();
      }
      else{

        var deviceInfo = await Utils.deviceInfo;

        String deviceRoutingKeyName = "${routingKeyPattern}.${deviceInfo.DeviceID}";
        String queueName = "mobile.${deviceInfo.DeviceID}";

        exchange.channel.queue(queueName, autoDelete: false).then((Queue queue) {
          return queue.bind(exchange, deviceRoutingKeyName);
        }).then((Queue queueBinded) {
          return queueBinded.consume();
        }).then((Consumer consumer){
          consumer.listen((AmqpMessage message) {

            if(_completer.isCompleted){
              _streamDelayed.cancel();
              consumer.cancel();
            }

            if(message.routingKey == deviceRoutingKeyName){
              _streamDelayed.cancel();
              consumer.cancel();

              callback(parser!=null ? parser(message.payloadAsJson): message.payloadAsJson);

              if (!_completer.isCompleted) {
                _completer.complete(message.payloadAsJson);
              }
            }

          }).onError((dynamic error) {
            _streamDelayed.cancel();
            callbackError(error);
          });

          _publishMessage(exchange, object);

        });
      }

    }).timeout(Duration(seconds: 30), onTimeout: () {
      throw TimeoutException('Timeout reached after 30 seconds.');
    }).catchError((dynamic e) {
      _streamDelayed.cancel();
      if(!_completer.isCompleted)
        _completer.completeError(e);
    });
    return _completer.future;
  }

  Future<Consumer> ListenQueue(String routingKeyPattern, Function onData, {Function onError, bool timeOutEnabled = true})  {
    Completer<Consumer> _completer = Completer<Consumer>();

    if (timeOutEnabled) {
      Future.delayed(Duration(seconds: 30), () {
        if (_completer.isCompleted)
          _completer.completeError(TimeoutException('timed out for listenqueue'));
      });
    }

    _rabbitmqClient.channel().then((Channel _channel) {
      return _channel.exchange(_exchangeName, ExchangeType.TOPIC, durable: true);
    }).then((Exchange exchange) async {
      if (onData != null) {
        var deviceInfo = await Utils.deviceInfo;

        String deviceRoutingKeyName = "${routingKeyPattern}.${deviceInfo.DeviceID}";
        String queueNameForCallback = "${routingKeyPattern}.update";

        Map<String, Object> args = Map<String, String>();
        args["x-dead-letter-exchange"] = "techViz.error";

        exchange.channel.queue(queueNameForCallback, autoDelete: false, durable: true, arguments: args).then((Queue queue) {
          return queue.bind(exchange, deviceRoutingKeyName);
        }).then((Queue queueBinded) {
          return queueBinded.consume();
        }).then((Consumer consumer) {

          consumer.listen((AmqpMessage message) {

            if(message.routingKey == deviceRoutingKeyName){
              print('RECEIVED with routingKey: ${message.routingKey}');
              print('PAYLOAD: ${message.payloadAsJson}');
              print('\n\n');

              onData(message.payloadAsJson);
            }
          }).onError((dynamic error) {
            onError(error);
          });
          _completer.complete(consumer);
        });
      }
    });

    return _completer.future;
  }

}
