import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class Ble extends StatefulWidget {
  const Ble({super.key});

  @override
  State<Ble> createState() => _Ble();
}

class _Ble extends State<Ble> {
  final flutterReactiveBle = FlutterReactiveBle();
  final discoveredDevices = <DiscoveredDevice>[];
  StreamSubscription<DiscoveredDevice>? sub;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text("Bluetooth"),
      ),
      body: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                  onTap: () {
                    startScan();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * .5,
                    height: 50,
                    color: Colors.green,
                    child: const Center(child: Text("Start scan")),
                  )),
              GestureDetector(
                  onTap: () {
                    stopScan();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * .5,
                    height: 50,
                    color: Colors.red,
                    child: const Center(child: Text("Stop scan")),
                  )),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * .7,
            child: ListView.builder(
              itemCount: discoveredDevices.length,
              itemBuilder: (context, index) {
                return Container(
                    color: Colors.blue,
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Text("id: ${discoveredDevices[index].id}"),
                            Text("name: ${discoveredDevices[index].name}"),
                          ],
                        ),
                        const Spacer(),
                        ElevatedButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green)),
                            onPressed: () {
                              connectToDevice(index);
                            },
                            child: const Text("connect")),
                      ],
                    ));
              },
            ),
          )
        ],
      ),
    );
  }

  void startScan() {
    discoveredDevices.clear();
    sub?.cancel();
    flutterReactiveBle.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      if (discoveredDevices.every((element) => element.id != device.id)) {
        setState(() {
          discoveredDevices.add(device);
        });
      }
      //code for handling results
    }, onError: (Object error) {
      //code for handling error
      print("error");
    });
  }

  void stopScan() async {
    if (sub != null) {
      await sub?.cancel();
    }
    setState(() {
      discoveredDevices.clear();
    });
  }

  void connectToDevice(int index) {
    flutterReactiveBle
        .connectToAdvertisingDevice(
      id: discoveredDevices[index].id,
      withServices: [],
      prescanDuration: const Duration(seconds: 5),
      connectionTimeout: const Duration(seconds: 2),
    )
        .listen((connectionState) {
      if (connectionState.connectionState.name == "connected") {
        chatDialog(discoveredDevices[index]);
      }
      // Handle connection state updates
    }, onError: (dynamic error) {
      // Handle a possible error
    });
  }

  chatDialog(DiscoveredDevice device) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(30),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "name: ${device.id}",
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  "Bluetooth status: ${flutterReactiveBle.status.name}",
                  style: const TextStyle(color: Colors.white),
                ),
                Container(
                  color: Colors.grey.withOpacity(0.5),
                  width: MediaQuery.of(context).size.width * .8,
                  height: MediaQuery.of(context).size.height * .4,
                  child: const Center(child: Text("chat place")),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  width: MediaQuery.of(context).size.width * .6,
                  height: 30,
                  child: TextField(
                    controller: textController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    cursorColor: Colors.black,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.blueAccent,
                      border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(50)),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Spacer(),
                    SizedBox(
                      height: 30,
                      child: ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.purple)),
                          onPressed: () async {
                            List<DiscoveredService> service =
                                await flutterReactiveBle
                                    .discoverServices(device.id);

                            final characteristic = QualifiedCharacteristic(
                                serviceId:
                                    service[0].characteristics[0].serviceId,
                                characteristicId: service[0]
                                    .characteristics[0]
                                    .characteristicId,
                                deviceId: device.id);
                            try {
                              await flutterReactiveBle
                                  .writeCharacteristicWithoutResponse(
                                      characteristic,
                                      value: [0x00]);
                              print(
                                  'Write with response value : ${textController.text} to ${characteristic.characteristicId}');
                            } on Exception catch (e, s) {
                              print(
                                'Error occured when writing ${characteristic.characteristicId} : $e',
                              );
                              // ignore: avoid_print
                              print(s);
                              rethrow;
                            }
                          },
                          child: const Text("send message")),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
