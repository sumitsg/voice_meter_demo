import 'dart:async';

import 'package:audio_meter_demo/methods.dart';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';

class NewPage extends StatefulWidget {
  const NewPage({Key? key}) : super(key: key);

  @override
  _NewPageState createState() => _NewPageState();
}

class _NewPageState extends State<NewPage> {
  String recordingSts = 'Press Mic Button \n to Start';
  bool isRecordingStarted = false;
  bool averageCalculated = false;
  bool isAudioPlaying = false;
  double avgOfNoise = 0;
  double average = 0;
  int indexValue = 0;
  double? decibelValues;
  String? address;

  List<double> avgList = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> location = [];

  Methods methods = Methods();
  Timer? _timer;

  NoiseReading? noiseReading;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    methods.initializer();
    getGeolocationCordinates();
  }

  getGeolocationCordinates() async {
    var data = await methods.determinePosition();
    setState(() {
      address = methods.currentAddr;
      location.add(data!.latitude);
      location.add(data.longitude);
      print('cordinates are:-    $location');
    });

    // print('in GeoLocator $address');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ? 1> Text that show recording status
            Text(
              isRecordingStarted ? 'Recording Started' : recordingSts,
              style: const TextStyle(
                fontSize: 30,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            // ?2> To start recording....
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(8.0),
                side: const BorderSide(
                  color: Colors.red,
                  width: 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                primary: Colors.white,
                elevation: 9.0,
              ),
              onPressed: () {
                // ! IF RECORDING NOT STARTED ALREADY THEN ONLY IT WILL START
                if (isRecordingStarted == false) {
                  methods.startRecording();
                  methods.start();
                  setState(() {
                    isRecordingStarted = true;
                    decibelValues = 0;
                  });
                  // methods.max;

                  // ! to record for specified duration i.e 5 min.--->
                  _timer = Timer(
                    const Duration(minutes: 1, seconds: 1),
                    () {
                      methods.stopRecording();
                      methods.stop();
                      setState(() {
                        isRecordingStarted = false;
                        averageCalculated = true;
                        _timer?.cancel();
                        // ? it gets true when the timer get finished
                      });
                    },
                  );

                  // ! RESET THE AVERAGE VALUE AND UPDATE INDEX VALUE OF LIST TO STORE EVERY MINUTE'S
                  // ? CHANGE DURATION TO RESET THE SAME AFTER SPECIFIC INTERVAL-->
                  _timer = Timer.periodic(
                      const Duration(minutes: 1, seconds: 1), (timer) {
                    setState(() {
                      indexValue = indexValue + 1;
                      avgOfNoise = 0;
                      average = 0;
                    });
                  });

                  // ! CALCULATE AND STORE THE AVERAGE EVERY AFTER 12 SECOND'S
                  // ! ADD THAT AVG IN LISTS

                  _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
                    print(
                        ' every 12 sec decibel for index value $indexValue is--------->${methods.max.toStringAsFixed(2)}');
                    setState(() {
                      decibelValues =
                          double.parse(methods.max.toStringAsFixed(2));
                    });

                    average =
                        average + double.parse(methods.max.toStringAsFixed(2));

                    avgOfNoise = double.parse((average / 5).toStringAsFixed(2));
                    print('Average total for inde $indexValue is $avgOfNoise');

                    avgList.removeAt(indexValue);
                    avgList.insert(indexValue, avgOfNoise);
                    print(' list Of averages are ===> ${avgList}');
                  });
                }
                // ! if user pressed stop button then it will terminate the recording
                else if (isRecordingStarted == true) {
                  methods.stopRecording();
                  methods.stop();
                  setState(() {
                    isRecordingStarted = false;
                    _timer?.cancel();
                  });
                }
              },
              icon: isRecordingStarted
                  ? const Icon(
                      Icons.stop,
                      color: Colors.red,
                    )
                  : const Icon(
                      Icons.mic,
                      color: Colors.green,
                    ),
              label: const Text(''),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              methods.max != 0 ? '' : '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            Text(
              decibelValues != null
                  ? 'Decibel values after12 sec. are:- $decibelValues'
                  : 'start recording to see Decibel values',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(
              height: 70,
            ),
            Text(
              averageCalculated ? 'Average Decibel is $avgList ' : '',
              style: const TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(
              height: 40,
            ),

            // ! Button to play and stop audio
            ElevatedButton.icon(
              onPressed: () {
                if (isAudioPlaying == false) {
                  methods.playAudioFile();
                  setState(() {
                    isAudioPlaying = true;
                  });

                  methods.audioPlayer.playlistFinished.listen((finished) {
                    if (finished) {
                      print('song finished');
                      setState(() {
                        isAudioPlaying = false;
                      });
                    }
                  });
                  //  to check if audio is finished playing and still icon not has been changed
                  // if (methods.isFinished) {
                  //   setState(() {
                  //     isAudioPlaying = false;
                  //   });
                  // }
                } else {
                  methods.stopAudioFilePlaying();
                  setState(() {
                    isAudioPlaying = false;
                  });
                }
              },
              icon: isAudioPlaying
                  ? const Icon(Icons.stop)
                  : const Icon(Icons.play_arrow),
              label: const Text(''),
            ),
            const SizedBox(
              height: 30,
            ),
            address != null ? Text(address!) : const Text('waiting for address')
          ],
        ),
      ),
    );
  }
}
