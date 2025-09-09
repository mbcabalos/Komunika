import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
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
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/widgets/text_to_speech_widgets/text_area_card.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TextToSpeechScreen extends StatefulWidget {
  final TextToSpeechBloc ttsBloc;
  final GlobalKey? settingsNavKey;

  const TextToSpeechScreen(
      {super.key, required this.ttsBloc, this.settingsNavKey});

  @override
  State<TextToSpeechScreen> createState() => TextToSpeechScreenState();
}

class TextToSpeechScreenState extends State<TextToSpeechScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final FlutterTts flutterTts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();
  GlobalKey keyTextArea = GlobalKey();
  GlobalKey keyVoicePlayX = GlobalKey();
  GlobalKey keyImagePicker = GlobalKey();

  List<TargetFocus> ttsTargets = [];

  // TTS Control Variables
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  bool currentlyPlaying = false;

  Map<String, String> ttsSettings = {};

  List<XFile> _selectedImages = [];
  int _currentProcessingIndex = 0;
  String? language;
  String? selectedVoice;
  final List<Map<String, String>> _voiceOptions = [
    {
      "image": "assets/flags/us_male.png",
      "label": "Voice 1",
      "language": "en-GB",
      "voice": "en-gb-x-gbb-local",
    },
    {
      "image": "assets/flags/us_female.png",
      "label": "Voice 2",
      "language": "en-US",
      "voice": "en-us-x-sfg-local",
    },
    {
      "image": "assets/flags/ph_male.png",
      "label": "Voice 3",
      "language": "fil-PH",
      "voice": "fil-ph-x-fie-local",
    },
    {
      "image": "assets/flags/ph_female.png",
      "label": "Voice 4",
      "language": "fil-PH",
      "voice": "fil-ph-x-fic-local",
    },
    {
      "image": "assets/flags/uk_male.png",
      "label": "Voice 5",
      "language": "en-GB",
      "voice": "en-gb-x-rjs-local",
    },
    {
      "image": "assets/flags/uk_female.png",
      "label": "Voice 6",
      "language": "en-GB",
      "voice": "en-gb-x-gbc-local",
    },
  ];

  final List<double> _rateOptions = [0.5, 0.75, 1.0];

  @override
  void initState() {
    super.initState();
    _initialize();
    _initTts();
  }

  Future<void> checkWalkthrough() async {
    bool isDone = await PreferencesUtils.getWalkthroughDone();

    if (!isDone) {
      _initTargets();
      _showTutorial();
    }
  }

  void _initTargets() {
    ttsTargets = [
      TargetFocus(
        identify: "TextArea",
        keyTarget: keyTextArea,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const Text(
              "(ENGLISH) Type your message here to convert it into speech.\n\n(FILIPINO) I-type ang iyong mensahe dito upang gawing pananalita.",
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "VoiceSelector",
        keyTarget: keyVoicePlayX,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              "(ENGLISH) Choose voice, play audio, and adjust speed here.\n\n(FILIPINO) Pumili ng boses, patugtugin ang audio, at ayusin ang bilis dito.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "PlayButton",
        keyTarget: keyImagePicker,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              "(ENGLISH) Scan text from an image using the camera or gallery.\n\n(FILIPINO) I-scan ang teksto mula sa larawan gamit ang kamera o gallery.",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "GoToSettings",
        keyTarget: widget.settingsNavKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
              "(ENGLISH) Tap here to proceed...\n\n(FILIPINO) Pindutin dito upang magpatuloy...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    ];
  }

  void _showTutorial() {
    TutorialCoachMark(
      targets: ttsTargets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "SKIP",
      paddingFocus: 8,
      onSkip: () {
        PreferencesUtils.storeWalkthroughDone(true);
        return true;
      },
      alignSkip: Alignment.bottomLeft,
    ).show(context: context);
  }

  Future<void> _initialize() async {
    widget.ttsBloc.add(TextToSpeechLoadingEvent());
    ttsSettings = await PreferencesUtils.getTTSSettings();

    selectedVoice = await PreferencesUtils.getTTSVoice();
    rate = await PreferencesUtils.getTTSRate();

    // Set language based on selectedVoice
    if (selectedVoice != null) {
      final found = _voiceOptions.firstWhere(
        (v) => v["voice"] == selectedVoice,
        orElse: () => {},
      );
      language = found["language"];
    }
  }

  Future<void> _initTts() async {
    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultVoice();
    }

    flutterTts.setStartHandler(() {
      setState(() {
        currentlyPlaying = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        currentlyPlaying = false;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        currentlyPlaying = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        currentlyPlaying = false;
      });
      showCustomSnackBar(context, "TTS Error: $msg", ColorsPalette.red);
    });
  }

  Future<void> _getDefaultVoice() async {
    var voice = await flutterTts.getDefaultVoice;
    if (voice != null) {
      print(voice);
    }
  }

  Future<void> _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> _speak() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      showCustomSnackBar(context, "Text field is empty!", ColorsPalette.red);
      return;
    }

    setState(() {
      currentlyPlaying = true; // <-- Immediately set to playing
    });

    await flutterTts.setEngine("com.google.android.tts");
    await flutterTts.setVolume(1.0);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(1.0);

    if (language != null) {
      await flutterTts.setLanguage(language!);
    }
    if (selectedVoice != null) {
      await flutterTts.setVoice({"name": selectedVoice!, "locale": language!});
    }

    await flutterTts.speak(text);
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    setState(() {
      currentlyPlaying = false;
    });
  }

  Future<void> _pause() async {
    await flutterTts.pause();
    setState(() {
      currentlyPlaying = false; // <-- Immediately set to not playing
    });
  }

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return BlocProvider.value(
      value: widget.ttsBloc,
      child: Scaffold(
        backgroundColor: themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: context.translate("tts_title"),
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          themeProvider: themeProvider,
          isBackButton: false,
          // customAction: IconButton(
          //     tooltip: context.translate("tts_image_processing_title"),
          //     icon: Icon(
          //       Icons.storage_rounded,
          //       color: themeProvider.themeData.textTheme.bodySmall?.color,
          //     ),
          //     onPressed: () {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => VoiceMessagePage(
          //             themeProvider: themeProvider,
          //             textToSpeechBloc: widget.ttsBloc,
          //           ),
          //         ),
          //       );
          //     }),
        ),
        floatingActionButton: FloatingActionButton(
          key: keyImagePicker,
          onPressed: () {
            _showImageSourceDialog(themeProvider);
          },
          backgroundColor: themeProvider.themeData.primaryColor,
          child: Icon(
            Icons.document_scanner_rounded,
            color: themeProvider.themeData.textTheme.bodySmall?.color,
          ),
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is ImageCroppedState) {
              _extractTextFromImage(state.croppedImagePath, themeProvider);
            }
            if (state is TextExtractionSuccessState) {
              setState(() {
                _textController.text = _textController.text.isNotEmpty
                    ? '${_textController.text}\n\n${state.extractedText}'
                    : state.extractedText;
              });
            }
            if (state is TextToSpeechErrorState) {
              showCustomSnackBar(
                  context, "Error, Please try again", ColorsPalette.red);
            }
          },
          builder: (context, state) {
            if (state is TextToSpeechLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TextToSpeechLoadedSuccessState) {
              return _buildContent(themeProvider);
            } else if (state is TextToSpeechErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(themeProvider);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeProvider themeProvider) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.6;
    final double phoneWidth = MediaQuery.of(context).size.width * 1.0;
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSize(context, 16)),
              child: TextAreaCard(
                key: keyTextArea,
                themeProvider: themeProvider,
                ttsBloc: widget.ttsBloc,
                titleController: _titleController,
                contentController: _textController,
                width: phoneWidth,
                height: phoneHeight,
                onClear: () async {
                  await _stop();
                  _textController.clear();
                  setState(() {
                    currentlyPlaying = false;
                  });
                },
              ),
            ),

            // TTS Controls Section
            _buildTtsControls(themeProvider),

            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildTtsControls(ThemeProvider themeProvider) {
    return Row(
      key: keyVoicePlayX,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            AbsorbPointer(
              absorbing: currentlyPlaying, // Disable when playing
              child: Opacity(
                opacity: currentlyPlaying ? 0.5 : 1.0,
                child: _buildControlButton(
                  label: "Voice",
                  backgroundColor: themeProvider.themeData.cardColor,
                  textColor:
                      themeProvider.themeData.textTheme.bodyMedium?.color,
                  height: 50,
                  width: 100,
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: themeProvider.themeData.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                            maxWidth: 300,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Select Voice",
                                  style: themeProvider
                                      .themeData.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Flexible(
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 1.5,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                    itemCount: _voiceOptions.length,
                                    itemBuilder: (context, index) {
                                      final option = _voiceOptions[index];
                                      return _buildVoiceOption(
                                          option, themeProvider);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  themeProvider: themeProvider,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),

        // Play/Pause Button
        _buildControlButton(
          icon: currentlyPlaying
              ? Icons.pause_outlined
              : Icons.play_arrow_rounded,
          iconSize: ResponsiveUtils.getResponsiveSize(context, 50),
          height: 80,
          width: 100,
          onPressed: currentlyPlaying ? _pause : _speak,
          themeProvider: themeProvider,
        ),

        SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),

        AbsorbPointer(
          absorbing: currentlyPlaying, // Disable when playing
          child: Opacity(
            opacity: currentlyPlaying ? 0.5 : 1.0,
            child: _buildControlButton(
              label: "${(rate + 0.50).toStringAsFixed(2)}x",
              backgroundColor: themeProvider.themeData.cardColor,
              textColor: themeProvider.themeData.textTheme.bodyMedium?.color,
              height: 50,
              width: 100,
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: themeProvider.themeData.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      width: 100,
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      child: ListView.builder(
                        itemCount: _rateOptions.length,
                        itemBuilder: (context, index) {
                          final option = _rateOptions[index];
                          final isSelected = rate == option;
                          return ListTile(
                            title: Text(
                              "${(option + 0.50).toStringAsFixed(2)}x",
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blue
                                    : themeProvider
                                        .themeData.textTheme.bodyMedium?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            tileColor: isSelected
                                ? Colors.blue.withOpacity(0.15)
                                : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                rate = option;
                              });
                              PreferencesUtils.storeTTSRate(option);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
              themeProvider: themeProvider,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceOption(
      Map<String, String> option, ThemeProvider themeProvider) {
    final isSelected = selectedVoice == option["voice"];
    return GestureDetector(
      onTap: () async {
        setState(() {
          language = option["language"];
          selectedVoice = option["voice"];
        });
        await PreferencesUtils.storeTTSVoice(option["voice"]!);
        await flutterTts.setLanguage(option["language"]!);
        await flutterTts.setVoice({"name": option["voice"]!});
        Navigator.pop(context);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: AssetImage(option["image"]!),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            // prevent text overflow
            child: Text(
              option["label"]!,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.blue
                    : themeProvider.themeData.textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    IconData? icon,
    String? label,
    double? width,
    double? height,
    Color? backgroundColor,
    Color? textColor,
    Color? iconColor,
    double? iconSize,
    double? fontSize,
    required VoidCallback onPressed,
    required ThemeProvider themeProvider,
  }) {
    // Calculate font size if not provided
    final calculatedFontSize =
        fontSize ?? ResponsiveUtils.getResponsiveFontSize(context, 14);

    return Container(
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
        onTap: onPressed,
        child: Container(
          width: height,
          height: width,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: backgroundColor ?? themeProvider.themeData.primaryColor,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Icon(
                  icon,
                  color: iconColor ??
                      themeProvider.themeData.textTheme.bodySmall?.color,
                  size: iconSize,
                ),
              if (label != null && label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    color: textColor ??
                        themeProvider.themeData.textTheme.bodySmall?.color,
                    fontSize: calculatedFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImageSourceDialog(ThemeProvider themeProvider) async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: themeProvider.themeData.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate("tts_select_source"),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: themeProvider.themeData.primaryColor,
                ),
                title: Text(
                  context.translate("tts_camera"),
                  style: themeProvider.themeData.textTheme.bodyMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: themeProvider.themeData.cardColor,
                onTap: () {
                  Navigator.pop(context);
                  widget.ttsBloc.add(
                    CaptureImageEvent(source: ImageSource.camera),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: themeProvider.themeData.primaryColor,
                ),
                title: Text(
                  context.translate("tts_gallery"),
                  style: themeProvider.themeData.textTheme.bodyMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: themeProvider.themeData.cardColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages(themeProvider);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMultipleImages(ThemeProvider themeProvider) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
        _showBatchProcessingDialog(themeProvider);
      }
    } catch (e) {
      showCustomSnackBar(context, "Error: ${e.toString()}", ColorsPalette.red);
    }
  }

  Future<void> _extractTextFromImage(
      String imagePath, ThemeProvider themeProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate("tts_processing_image"),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.translate("tts_extracting_text"),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      widget.ttsBloc.add(
        ExtractTextFromImageEvent(imagePath: imagePath),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      showCustomSnackBar(
        context,
        "Error processing image: ${e.toString()}",
        ColorsPalette.red,
      );
    }
  }

  Future<void> _showBatchProcessingDialog(ThemeProvider themeProvider) async {
    bool confirmBatch = false;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: themeProvider.themeData.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.translate("tts_batch_process_title"),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context
                    .translate("tts_batch_process_message")
                    .replaceAll("{count}", _selectedImages.length.toString()),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodySmall?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate("tts_cancel"),
                      style: TextStyle(
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      confirmBatch = true;
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate("tts_proceed"),
                      style: TextStyle(
                        color:
                            themeProvider.themeData.textTheme.bodySmall?.color,
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmBatch && mounted) {
      setState(() {
        _currentProcessingIndex = 0;
      });
      await _processBatchImages(themeProvider);
    }
  }

  Future<void> _processBatchImages(ThemeProvider themeProvider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.translate("tts_processing_batch"),
                    style: TextStyle(
                      color:
                          themeProvider.themeData.textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.bold,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  LinearProgressIndicator(
                    value: _currentProcessingIndex / _selectedImages.length,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context
                        .translate("tts_processing_image_count")
                        .replaceAll("{current}",
                            (_currentProcessingIndex + 1).toString())
                        .replaceAll(
                            "{total}", _selectedImages.length.toString()),
                    style: TextStyle(
                      color:
                          themeProvider.themeData.textTheme.bodyMedium?.color,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    String combinedText = _textController.text;

    widget.ttsBloc.add(
      BatchExtractTextEvent(
          imagePaths: _selectedImages.map((e) => e.path).toList()),
    );

    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _textController.text = combinedText;
        _selectedImages.clear();
      });
    }
  }
}
