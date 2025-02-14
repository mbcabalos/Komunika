import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';

part 'sign_transcriber_event.dart';
part 'sign_transcriber_state.dart';

class SignTranscriberBloc extends Bloc<SignTranscriberEvent, SignTranscriberState> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  Timer? _captureTimer;

  SignTranscriberBloc() : super(SignTranscriberInitial()) {
    on<InitializeCamera>(_onInitializeCamera);
    on<SwitchCamera>(_onSwitchCamera);
    on<StartTranslation>(_onStartTranslation);
    on<StopTranslation>(_onStopTranslation);
  }

  Future<void> _onInitializeCamera(InitializeCamera event, Emitter<SignTranscriberState> emit) async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        emit(const CameraError("No camera found"));
        return;
      }

      _currentCameraIndex = 0; // Start with the back camera
      await _setupCamera(_cameras[_currentCameraIndex], emit);
    } catch (e) {
      emit(CameraError("Failed to initialize camera: $e"));
    }
  }

  Future<void> _onSwitchCamera(SwitchCamera event, Emitter<SignTranscriberState> emit) async {
    if (_cameras.isEmpty) return;

    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length; // Toggle between front and back
    await _setupCamera(_cameras[_currentCameraIndex], emit);
  }

  Future<void> _setupCamera(CameraDescription cameraDescription, Emitter<SignTranscriberState> emit) async {
    try {
      await _cameraController?.dispose();

      _cameraController = CameraController(
        cameraDescription,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (_cameraController!.value.isInitialized) {
        emit(CameraInitialized(_cameraController!));
      }
    } catch (e) {
      emit(CameraError("Failed to switch camera: $e"));
    }
  }

  void _onStartTranslation(StartTranslation event, Emitter<SignTranscriberState> emit) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    emit(const TranscriptionInProgress("Starting transcription..."));

    // Start capturing frames every 3 seconds
    _captureTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      final transcription = await _processSignLanguage();
      emit(TranscriptionInProgress(transcription));
    });
  }

  void _onStopTranslation(StopTranslation event, Emitter<SignTranscriberState> emit) {
    _captureTimer?.cancel();
    emit(SignTranscriberInitial());
  }

  Future<String> _processSignLanguage() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time
    return "Recognized sign: Hello"; // Replace this with ML model output
  }

  @override
  Future<void> close() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    return super.close();
  }
}

