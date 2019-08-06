
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techviz/model/slotMachine.dart';
import 'package:techviz/repository/async/SlotMachineRouting.dart';
import 'package:techviz/repository/repository.dart';
import 'package:techviz/repository/slotFloorRepository.dart';
import 'package:techviz/ui/slotFloor.dart';

import '../_mocks/messageClientMock.dart';

void main() {
	testWidgets('Should pump SlotFloor view', (WidgetTester tester) async {

		StreamController<List<SlotMachine>> streamController = StreamController<List<SlotMachine>>();
		MessageClientMock messageClientMock = MessageClientMock<List<SlotMachine>>(streamController);
		Repository().slotFloorRepository = SlotFloorRepository(null, SlotMachineRouting(messageClientMock));

		await tester.pumpWidget(MaterialApp(home: SlotFloor()));

		streamController.add([
			SlotMachine(standID: '010101', denom: 0.1, machineStatusID: '1', machineTypeName: 'Machine 1', updatedAt: DateTime.now()),
			SlotMachine(standID: '020202', denom: 0.1, machineStatusID: '2', machineTypeName: 'Machine 2', updatedAt: DateTime.now()),
			SlotMachine(standID: '030303', denom: 0.1, machineStatusID: '3', machineTypeName: 'Machine 3', updatedAt: DateTime.now()),
			]);

		streamController.close();

	});


}