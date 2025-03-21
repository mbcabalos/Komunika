import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:komunika/services/endpoint.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/history.dart';

class GestureTranslator extends StatefulWidget {
  final ThemeProvider themeProvider;

  const GestureTranslator({super.key, required this.themeProvider});

  @override
  GestureTranslatorState createState() => GestureTranslatorState();
}

class GestureTranslatorState extends State<GestureTranslator>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 1;
  String predictedCharacter = "";
  bool isPredicting = false;
  String url = Endpoint.url;
  bool _isFlipping = false;
  bool _isMounted = true;
  bool _stopPrediction = false;
  final TextEditingController _textController = TextEditingController();
  final dbHelper = DatabaseHelper();
  bool _noHandDetected = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    _isMounted = false;
    _stopPrediction = true;
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopPrediction = true;
    } else if (state == AppLifecycleState.resumed) {
      _stopPrediction = false;
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _stopPrediction = true;

    if (_cameraController != null) {
      await _cameraController!.dispose();
    }

    _cameraController = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (!_isMounted) return;

      setState(() {
        _isFlipping = false;
        _stopPrediction = false;
      });

      Future.delayed(const Duration(milliseconds: 500), _startPrediction);
    } catch (e) {
      print("❌ Camera initialization failed: $e");
    }
  }

  void _flipCamera() async {
    if (_isFlipping || _cameras == null || _cameras!.isEmpty) return;

    setState(() {
      _isFlipping = true;
      _stopPrediction = true;
      _cameraIndex = (_cameraIndex == 0) ? 1 : 0;
    });

    await _initializeCamera();
  }

  void _startPrediction() async {
    while (_isMounted && !_stopPrediction) {
      if (!isPredicting &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        setState(() {
          isPredicting = true;
        });

        try {
          XFile? imageFile = await _cameraController!.takePicture();
          Uint8List imageBytes = await imageFile.readAsBytes();

          var request =
              http.MultipartRequest('POST', Uri.parse('$url/gesture/hands'));
          request.files.add(http.MultipartFile.fromBytes('file', imageBytes,
              filename: "gesture.jpg"));

          var response = await request.send();
          if (response.statusCode == 200) {
            var jsonResponse =
                jsonDecode(await response.stream.bytesToString());

            String newPredictedCharacter = jsonResponse["predicted_character"];

            setState(() {
              predictedCharacter = newPredictedCharacter;
              _noHandDetected =
                  newPredictedCharacter.toLowerCase() == "no hand detected";
            });

            // Delay before updating text controller
            Future.delayed(const Duration(seconds: 3), () {
              if (_isMounted && !_stopPrediction) {
                setState(() {
                  _textController.text += predictedCharacter;
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length));
                });
              }
            });
          } else {
            print("❌ API Error: ${response.statusCode}");
            setState(() {
              predictedCharacter = "";
            });
          }
        } catch (e) {
          print("❌ Prediction error: $e");
        }

        if (_isMounted && !_stopPrediction) {
          setState(() {
            isPredicting = false;
          });
        }

        await Future.delayed(const Duration(seconds: 2));
      } else {
        await Future.delayed(const Duration(milliseconds: 2000));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 7.0),
          child: Text(
            context.translate("sign_transcribe_title"),
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
            ),
          ),
        ),
        leading: Padding(
          padding: EdgeInsets.only(
            top: ResponsiveUtils.getResponsiveSize(context, 7),
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: ResponsiveUtils.getResponsiveSize(context, 10),
            ),
            onPressed: () {
              if (_textController.text.isNotEmpty) {
                dbHelper.saveSignTranscriberHistory(_textController.text);
              }
              _textController.clear();
              Navigator.pop(context);
            },
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.getResponsiveSize(context, 7),
              right: ResponsiveUtils.getResponsiveSize(context, 8),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(
                      themeProvider: widget.themeProvider,
                      database: 'sign_transcriber',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.history_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Circular Camera Preview
          Container(
            margin: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveSize(context, 40)),
            width: ResponsiveUtils.getResponsiveSize(context, 300),
            height: ResponsiveUtils.getResponsiveSize(context, 300),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _noHandDetected
                    ? ColorsPalette.red
                    : widget.themeProvider.themeData.primaryColor,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(math.pi / 2)
                  ..rotateY(_cameraController?.description.lensDirection ==
                          CameraLensDirection.front
                      ? math.pi
                      : 0),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: _cameraController != null &&
                          _cameraController!.value.isInitialized
                      ? CameraPreview(_cameraController!)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ),
          ),
          // Predicted Character Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Predicted Character Text with Background
              Container(
                margin: EdgeInsets.only(
                    top: ResponsiveUtils.getResponsiveSize(context, 16),
                    left: ResponsiveUtils.getResponsiveSize(context, 130)),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSize(context, 25),
                  vertical: ResponsiveUtils.getResponsiveSize(context, 10),
                ),
                decoration: BoxDecoration(
                  color: widget.themeProvider.themeData.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  predictedCharacter,
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 20),
                    fontWeight: FontWeight.bold,
                    color: widget
                        .themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 16)),
              // Switch Camera Button
              Container(
                margin: EdgeInsets.only(
                  top: ResponsiveUtils.getResponsiveSize(context, 16),
                ),
                child: FloatingActionButton(
                  backgroundColor: widget.themeProvider.themeData.primaryColor,
                  onPressed: _flipCamera,
                  child: const Icon(Icons.switch_camera, color: Colors.white),
                ),
              ),
            ],
          ),
          // Translated Text Display
          Container(
            margin: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveFontSize(context, 20)),
            child: _buildTextDisplay(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: widget.themeProvider.themeData.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          TextField(
            controller: _textController,
            readOnly: true,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
              fontWeight: FontWeight.w500,
              color: widget.themeProvider.themeData.textTheme.bodyMedium?.color,
            ),
            maxLines: 8,
            minLines: 5,
            expands: false,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: context.translate("sign_transcribe_hint"),
              hintStyle: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIconButton(Icons.space_bar, () {
                  _textController.text += ' ';
                  _textController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length),
                  );
                }),
                const SizedBox(width: 8),
                _buildIconButton(Icons.backspace, () {
                  if (_textController.text.isNotEmpty) {
                    _textController.text = _textController.text
                        .substring(0, _textController.text.length - 1);
                    _textController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _textController.text.length),
                    );
                  }
                }),
                const SizedBox(width: 8),
                _buildIconButton(Icons.clear, () {
                  dbHelper.saveSignTranscriberHistory(_textController.text);
                  _textController.clear();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: Icon(icon, size: 15, color: Colors.grey),
        onPressed: onPressed,
      ),
    );
  }
}
