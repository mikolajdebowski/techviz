import 'dart:async';
import 'package:techviz/common/deviceUtils.dart';
import 'package:techviz/common/model/deviceInfo.dart';
import 'client/MQTTClientService.dart';

abstract class IDeviceService{
	Future update(String userID);
}

class DeviceService implements IDeviceService{
	IMQTTClientService _mqttClientServiceInstance;
	IDeviceUtils _deviceUtils;
	DeviceService({IMQTTClientService mqttClientService, IDeviceUtils deviceUtils}){
		_mqttClientServiceInstance = mqttClientService!=null? mqttClientService : MQTTClientService();
		_deviceUtils = deviceUtils ??= DeviceUtils();
		assert(_mqttClientServiceInstance!=null);
		assert(_deviceUtils!=null);
	}

  @override
  Future update(String userID) async{
  	DeviceInfo deviceInfo = _deviceUtils.deviceInfo;

  	Completer _completer = Completer<void>();
		String routingKeyForPublish = 'mobile.device.update';
		String routingKeyForCallback = 'mobile.device.update.${deviceInfo.DeviceID}';

		_mqttClientServiceInstance.subscribe(routingKeyForCallback);
		_mqttClientServiceInstance.streams(routingKeyForCallback).listen((dynamic responseCallback){
			_mqttClientServiceInstance.unsubscribe(routingKeyForCallback);
			_completer.complete();
		});

		Map<String,dynamic> message = <String,dynamic>{};
		message['deviceID'] = deviceInfo.DeviceID;
		message['userID'] = userID;
		message['model'] = deviceInfo.Model;
		message['OSName'] = deviceInfo.OSName;
		message['OSVersion'] = deviceInfo.OSVersion;

		_mqttClientServiceInstance.publishMessage(routingKeyForPublish, message);

  	return _completer.future.timeout(Duration(seconds: 10));
  }
}

