import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

class Methods {
  double max = 0;
  bool isFinished = false;
  int audioDuration = 0;
  String pathToAudio = '/storage/emulated/0/Music/temp.wav';
  String currentAddr = '';

  final NoiseMeter _noiseMeter = NoiseMeter();
  final FlutterSoundRecorder _recordingSession = FlutterSoundRecorder();
  StreamSubscription<NoiseReading>? _noiseSubscription;
  final AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
  Position? position;
  bool permissionGranted = false;

  //! 1 recorder INITIALIZER===============>
  void initializer() async {
    pathToAudio = '/storage/emulated/0/Music/temp.wav';

    await _recordingSession.openAudioSession(
      focus: AudioFocus.requestFocusAndStopOthers,
      category: SessionCategory.playAndRecord,
      mode: SessionMode.modeDefault,
      device: AudioDevice.earPiece,
    );

    await _recordingSession
        .setSubscriptionDuration(const Duration(milliseconds: 10));

    await initializeDateFormatting();

    await Permission.microphone.request();
    await Permission.storage.request();
    await Permission.manageExternalStorage.request();
  }

  // ! to start recording
  Future startRecording() async {
    Directory directory = Directory(path.dirname(pathToAudio));

    // ? If the directory not present it will create new
    if (!directory.existsSync()) {
      directory.createSync();
    }

    _recordingSession.openAudioSession();
    await _recordingSession.startRecorder(
      toFile: pathToAudio,
      codec: Codec.pcm16WAV,
    );
    // ?
    // StreamSubscription _recordSubscription =
    //     _recordingSession.onProgress!.listen((event) {
    //   print('before date-----------');
    //   var date = DateTime.fromMillisecondsSinceEpoch(
    //     event.duration.inSeconds.toInt(),
    //     isUtc: true,
    //   );

    //   print('time text is :--------${date.runtimeType}');
    //   var timeText = DateFormat('mm:ss:SS', 'en_GB').format(date);

    //   setState(() {
    //     _timerText = timeText.substring(0, 8);
    //   });
    // });
    // _recordSubscription.cancel();
  }

  // ! to stop recording
  Future<String?> stopRecording() async {
    _recordingSession.closeAudioSession();
    return await _recordingSession.stopRecorder();
  }

  // ! star calculating decibles
  start() async {
    try {
      _noiseSubscription = _noiseMeter.noiseStream.listen(onData);
    } catch (err) {
      print(err);
    }
  }

  onData(NoiseReading noiseReading) {
    max = noiseReading.maxDecibel;
  }

  void onError(Object e) {
    print(e.toString());
  }

  stop() async {
    try {
      if (_noiseSubscription != null) {
        _noiseSubscription?.cancel();
        _noiseSubscription = null;
      }
    } catch (err) {
      print(err);
    }
  }

  // ! start Audio player -->
  Future playAudioFile() async {
    audioPlayer.open(
      Audio.file(pathToAudio),
      autoStart: true,
      showNotification: true,
    );
    // audioDuration = audioPlayer.current.listen((event) {
    //   event!.audio.duration;
    // }) as int;
    audioPlayer.playlistAudioFinished.listen((finished) {
      isFinished = true;
    });
  }

  // ! to stop the audio player -->
  Future stopAudioFilePlaying() async {
    audioPlayer.stop();
  }

  // ! To get the position i.e Latitude and Longitude  ------->
  Future<Position?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    print('${position.latitude} ${position.longitude}');
    GetAddFromLatLong(position);
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // ! To get the proper Address ---------->
  Future<String> GetAddFromLatLong(Position position) async {
    List<Placemark> placemark =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    // print(placemark[2]);

    Placemark place = placemark[0];
    currentAddr =
        '${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}';
    return currentAddr;
  }
}
