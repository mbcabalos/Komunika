import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/text_to_speech_screen/voice_message_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';
import 'package:photo_view/photo_view.dart';

class TextToSpeechScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc ttsBloc;
  const TextToSpeechScreen({
    super.key,
    required this.themeProvider,
    required this.ttsBloc,
  });

  @override
  State<TextToSpeechScreen> createState() => _TextToSpeechScreenState();
}

class _TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  Map<String, String> ttsSettings = {};
  bool _isMaleVoice = false;
  String selectedLangauge = '';
  String selectedVoice = '';
  bool currentlyPlaying = false;
  bool save = false;
  List<XFile> _selectedImages = [];
  int _currentProcessingIndex = 0;
  bool _isBatchProcessing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    widget.ttsBloc.add(TextToSpeechLoadingEvent());
    ttsSettings = await PreferencesUtils.getTTSSettings();
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("tts_select_source")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt),
              title: Text(context.translate("tts_camera")),
              onTap: () {
                Navigator.pop(context);
                _captureImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text(context.translate("tts_gallery")),
              onTap: () {
                Navigator.pop(context);
                _pickMultipleImages();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 70,
      );

      if (image != null) {
        await _cropAndPreviewImage(image);
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}", ColorsPalette.red);
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
        _showBatchProcessingDialog();
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}", ColorsPalette.red);
    }
  }

  Future<void> _cropAndPreviewImage(XFile image) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: context.translate("tts_image_processing_title"),
            toolbarColor: widget.themeProvider.themeData.primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
          IOSUiSettings(
            title: context.translate("tts_image_processing_title"),
            aspectRatioPresets: [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9,
            ],
          ),
        ],
      );

      if (croppedFile != null) {
        await _showImagePreviewDialog(croppedFile.path);
      }
    } catch (e) {
      showCustomSnackBar(
          context, "Error cropping image: ${e.toString()}", ColorsPalette.red);
    }
  }

  Future<void> _showImagePreviewDialog(String imagePath) async {
    bool proceedWithOCR = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("tts_image_preview")),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: PhotoView(
            imageProvider: FileImage(File(imagePath)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate("tts_cancel")),
          ),
          TextButton(
            onPressed: () {
              proceedWithOCR = true;
              Navigator.pop(context);
            },
            child: Text(context.translate("tts_process")),
          ),
        ],
      ),
    );

    if (proceedWithOCR) {
      await _extractTextFromImage(imagePath);
    }
  }

  Future<void> _extractTextFromImage(String imagePath) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.translate("tts_processing_image")),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(context.translate("tts_extracting_text")),
          ],
        ),
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final textRecognizer = TextRecognizer();
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;
      textRecognizer.close();

      if (mounted) Navigator.of(context).pop();

      if (extractedText.isNotEmpty) {
        setState(() {
          _textController.text = _textController.text.isNotEmpty
              ? '${_textController.text}\n\n$extractedText'
              : extractedText;
        });
      } else {
        showCustomSnackBar(
            context, "No text found in image", ColorsPalette.red);
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      showCustomSnackBar(context, "Error processing image: ${e.toString()}",
          ColorsPalette.red);
    }
  }

  Future<void> _showBatchProcessingDialog() async {
    bool confirmBatch = false;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate("tts_batch_process_title")),
        content: Text(
          context
              .translate("tts_batch_process_message")
              .replaceAll("{count}", _selectedImages.length.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate("tts_cancel")),
          ),
          TextButton(
            onPressed: () {
              confirmBatch = true;
              Navigator.pop(context);
            },
            child: Text(context.translate("tts_proceed")),
          ),
        ],
      ),
    );

    if (confirmBatch && mounted) {
      setState(() {
        _isBatchProcessing = true;
        _currentProcessingIndex = 0;
      });
      await _processBatchImages();
    }
  }

  Future<void> _processBatchImages() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(context.translate("tts_processing_batch")),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: _currentProcessingIndex / _selectedImages.length,
                ),
                SizedBox(height: 16),
                Text(
                  context
                      .translate("tts_processing_image_count")
                      .replaceAll(
                          "{current}", (_currentProcessingIndex + 1).toString())
                      .replaceAll("{total}", _selectedImages.length.toString()),
                ),
              ],
            ),
          );
        },
      ),
    );

    String combinedText = _textController.text;

    for (int i = 0; i < _selectedImages.length; i++) {
      if (!mounted) break;

      setState(() {
        _currentProcessingIndex = i;
      });

      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: _selectedImages[i].path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: context
                  .translate("tts_image_processing_title")
                  .replaceAll("{current}", (i + 1).toString())
                  .replaceAll("{total}", _selectedImages.length.toString()),
              toolbarColor: widget.themeProvider.themeData.primaryColor,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
            ),
          ],
        );

        if (croppedFile != null) {
          final inputImage = InputImage.fromFilePath(croppedFile.path);
          final textRecognizer = TextRecognizer();
          final RecognizedText recognizedText =
              await textRecognizer.processImage(inputImage);
          textRecognizer.close();

          if (recognizedText.text.isNotEmpty) {
            combinedText = combinedText.isEmpty
                ? recognizedText.text
                : '$combinedText\n\n${recognizedText.text}';
          }
        }
      } catch (e) {
        debugPrint("Error processing image ${i + 1}: $e");
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _textController.text = combinedText;
        _isBatchProcessing = false;
        _selectedImages.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.ttsBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        floatingActionButton: FloatingActionButton(
          onPressed: _showImageSourceDialog,
          backgroundColor: widget.themeProvider.themeData.primaryColor,
          child: Icon(
            Icons.camera_alt_rounded,
            color: widget.themeProvider.themeData.textTheme.bodySmall?.color,
          ),
          tooltip: context.translate("tts_image_processing_title"),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              context.translate("tts_title"),
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
                icon: Icon(
                  _isMaleVoice ? Icons.male_rounded : Icons.female_rounded,
                  color: _isMaleVoice ? ColorsPalette.blue : ColorsPalette.red,
                  size: ResponsiveUtils.getResponsiveSize(context, 25),
                ),
                onPressed: () async {
                  setState(() {
                    _isMaleVoice = !_isMaleVoice;
                  });

                  selectedVoice = _isMaleVoice
                      ? "fil-ph-x-fie-local"
                      : "fil-ph-x-fic-local";
                  await flutterTts.setLanguage('fil-PH');
                  await flutterTts
                      .setVoice({"name": selectedVoice, "locale": "fil-PH"});
                  print("Selected Voice: $selectedVoice");
                },
              ),
            ),
          ],
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is TextToSpeechErrorState) {
              showCustomSnackBar(
                  context, "Error, Please try again", ColorsPalette.red);
            }
            if (state is AudioPlaybackCompletedState) {
              setState(() {
                currentlyPlaying = false;
              });
            }
          },
          builder: (context, state) {
            if (state is TextToSpeechLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TextToSpeechLoadedSuccessState) {
              return _buildContent(widget.themeProvider);
            } else if (state is TextToSpeechErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(widget.themeProvider);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.7;
    final double phoneWidth = MediaQuery.of(context).size.width * 1.0;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveUtils.getResponsiveSize(context, 16),
        ),
        child: ListView(
          children: [
            SizedBox(
              width: phoneWidth,
              height: phoneHeight,
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _titleController,
                      style: TextStyle(
                        color:
                            themeProvider.themeData.textTheme.bodyMedium?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 20),
                      ),
                      decoration: InputDecoration(
                        hintText: context.translate("tts_hint1"),
                        border: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 12),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 16),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSize(context, 10)),
                  Container(
                    decoration: BoxDecoration(
                      color: themeProvider.themeData.cardColor,
                      borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 12),
                      ),
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
                          readOnly: false,
                          controller: _textController,
                          style: TextStyle(
                            color: themeProvider
                                .themeData.textTheme.bodyMedium?.color,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context, 20),
                          ),
                          decoration: InputDecoration(
                            hintText: context.translate("tts_hint2"),
                            border: InputBorder.none,
                            fillColor: Colors.transparent,
                            filled: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.getResponsiveSize(
                                  context, 12),
                              vertical: ResponsiveUtils.getResponsiveSize(
                                  context, 16),
                            ),
                          ),
                          textAlignVertical: TextAlignVertical.center,
                          maxLines: 15,
                          keyboardType: TextInputType.multiline,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              _buildIconButton(Icons.clear, ColorsPalette.grey,
                                  () {
                                _textController.clear();
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VoiceMessagePage(
                              themeProvider: widget.themeProvider,
                              textToSpeechBloc: widget.ttsBloc),
                        ),
                      );
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                      height: ResponsiveUtils.getResponsiveSize(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        Icons.list_rounded,
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        size: ResponsiveUtils.getResponsiveSize(context, 40),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: currentlyPlaying
                        ? null
                        : () {
                            _titleController.text.trim();
                            final text = _textController.text.trim();
                            if (text.isNotEmpty) {
                              setState(() {
                                currentlyPlaying = true;
                              });
                              widget.ttsBloc.add(FlutterTTSEvent(
                                  text: text,
                                  language: ttsSettings['language'].toString(),
                                  voice: ttsSettings['voice'].toString()));
                            } else {
                              showCustomSnackBar(
                                context,
                                "Text field is empty!",
                                ColorsPalette.red,
                              );
                            }
                          },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 80),
                      height: ResponsiveUtils.getResponsiveSize(context, 80),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: currentlyPlaying
                          ? Icon(
                              Icons.pause_outlined,
                              color: themeProvider
                                  .themeData.textTheme.bodySmall?.color,
                              size: ResponsiveUtils.getResponsiveSize(
                                  context, 60),
                            )
                          : Icon(
                              Icons.play_arrow_rounded,
                              color: themeProvider
                                  .themeData.textTheme.bodySmall?.color,
                              size: ResponsiveUtils.getResponsiveSize(
                                  context, 60),
                            ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () async {
                      final title = _titleController.text.trim();
                      final text = _textController.text.trim();
                      if (text.isNotEmpty) {
                        widget.ttsBloc.add(
                          CreateTextToSpeechEvent(
                              text: text, title: title, save: true),
                        );
                        _titleController.clear();
                        _textController.clear();
                        showCustomSnackBar(
                            context, "Saved!", ColorsPalette.green);
                      } else {
                        showCustomSnackBar(
                            context, "Text field is empty!", ColorsPalette.red);
                      }
                    },
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 50),
                      height: ResponsiveUtils.getResponsiveSize(context, 50),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: themeProvider.themeData.primaryColor,
                      ),
                      child: Icon(
                        Icons.save_alt_rounded,
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        size: ResponsiveUtils.getResponsiveSize(context, 35),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: Icon(icon, size: 15, color: Colors.grey),
        onPressed: onPressed,
      ),
    );
  }
}
