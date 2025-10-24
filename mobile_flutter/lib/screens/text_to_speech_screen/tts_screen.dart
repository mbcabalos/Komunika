import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/history_screen/history_screen.dart';
import 'package:komunika/services/repositories/database_helper.dart';
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
import 'package:komunika/utils/flutter_tts.dart';

class TextToSpeechScreen extends StatefulWidget {
  final TextToSpeechBloc ttsBloc;
  final GlobalKey? settingsNavKey;

  const TextToSpeechScreen(
      {super.key, required this.ttsBloc, this.settingsNavKey});

  @override
  State<TextToSpeechScreen> createState() => TextToSpeechScreenState();
}

class TextToSpeechScreenState extends State<TextToSpeechScreen>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final dbHelper = DatabaseHelper();
  final ImagePicker _imagePicker = ImagePicker();
  GlobalKey keyTextArea = GlobalKey();
  GlobalKey keyVoicePlayX = GlobalKey();
  GlobalKey keyImagePicker = GlobalKey();
  List<TargetFocus> ttsTargets = [];
  String _textFieldHint = "";

  // TTS Control Variables
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;
  bool currentlyPlaying = false;

  Map<String, String> ttsSettings = {};

  List<XFile> _selectedImages = [];
  int _currentProcessingIndex = 0;
  String? selectedlanguage;
  String? selectedVoice;
  String? historyMode;
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

  late TtsHelper ttsHelper;

  // Voice availability checker methods
  bool _isVoiceAvailable(String? voice) {
    if (voice == null) return false;
    // For now, we'll assume all voices are available
    // In a real implementation, you would check against FlutterTts.getVoices()
    return _voiceOptions.any((option) => option["voice"] == voice);
  }

  void _checkCurrentVoiceAvailability() {
    if (!_isVoiceAvailable(selectedVoice)) {
      // If current voice is not available, reset to first available voice
      final availableVoice = _voiceOptions.firstWhere(
        (option) => _isVoiceAvailable(option["voice"]),
        orElse: () => _voiceOptions.first,
      );

      setState(() {
        selectedlanguage = availableVoice["language"];
        selectedVoice = availableVoice["voice"];
      });

      // Save the new selection
      PreferencesUtils.storeTTSVoice(availableVoice["voice"]!);
      PreferencesUtils.storeTTSLanguage(availableVoice["language"]!);
    }
  }

  @override
  void initState() {
    super.initState();
    ttsHelper = TtsHelper();
    ttsHelper.setupHandlers(
      () => setState(() => currentlyPlaying = true),
      () => setState(() => currentlyPlaying = false),
      () => setState(() => currentlyPlaying = false),
      (msg) {
        setState(() => currentlyPlaying = false);
        showCustomSnackBar(context, "TTS Error: $msg", ColorsPalette.red);
      },
    );
    _initialize();
  }

  Future<void> _initialize() async {
    widget.ttsBloc.add(TextToSpeechLoadingEvent());
    selectedVoice = await PreferencesUtils.getTTSVoice();
    selectedlanguage = await PreferencesUtils.getTTSLanguage();
    rate = await PreferencesUtils.getTTSRate();
    historyMode = await PreferencesUtils.getTTSHistoryMode();
    _textFieldHint = context.translate("tts_hint2");

    // Check if current voice is available
    _checkCurrentVoiceAvailability();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check voice availability when screen comes into focus
    _checkCurrentVoiceAvailability();
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
        radius: ResponsiveUtils.getResponsiveSize(context, 12),
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Type your message here to convert it into speech.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) I-type ang iyong mensahe dito upang gawing pananalita.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "VoiceSelector",
        keyTarget: keyVoicePlayX,
        shape: ShapeLightFocus.RRect,
        radius: ResponsiveUtils.getResponsiveSize(context, 12),
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Choose voice, play audio, and adjust speed here.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) Pumili ng boses, patugtugin ang audio, at ayusin ang bilis dito.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "PlayButton",
        keyTarget: keyImagePicker,
        shape: ShapeLightFocus.RRect,
        radius: ResponsiveUtils.getResponsiveSize(context, 12),
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Scan text from an image using the camera or gallery.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "(FILIPINO) I-scan ang teksto mula sa larawan gamit ang kamera o gallery.",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: "GoToSettings",
        keyTarget: widget.settingsNavKey,
        shape: ShapeLightFocus.RRect,
        radius: ResponsiveUtils.getResponsiveSize(context, 12),
        enableTargetTab: true,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "(ENGLISH) Tap here to proceed...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Text(
                  "((FILIPINO) Pindutin dito upang magpatuloy...",
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 16)),
                ),
              ],
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
      paddingFocus: ResponsiveUtils.getResponsiveSize(context, 8),
      onSkip: () {
        PreferencesUtils.storeWalkthroughDone(true);
        return true;
      },
      alignSkip: Alignment.bottomLeft,
    ).show(context: context);
  }

  Future<void> _speak() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _textFieldHint = context.translate("tts_hint_empty");
      });
      // Add a small delay to reset hint back after a few seconds (optional)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _textFieldHint = context.translate("tts_hint2");
          });
        }
      });
      return;
    }

    setState(() {
      currentlyPlaying = true;
    });

    await ttsHelper.speak(
      text: text,
      language: selectedlanguage,
      voice: selectedVoice,
      rate: rate,
      pitch: 1.0,
      volume: 1.0,
    );
  }

  Future<void> _stop() async {
    await ttsHelper.stop();
    setState(() {
      currentlyPlaying = false;
    });
  }

  Future<void> _pause() async {
    await ttsHelper.pause();
    setState(() {
      currentlyPlaying = false;
    });
  }

  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  void stopTtsOnTabChange() {
    ttsHelper.stop();
    setState(() {
      currentlyPlaying = false;
    });
  }

  Future<void> saveTextToHistoryWhenClose() async {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      dbHelper.saveTextToSpeechHistory(_textController.text);
    }
  }

  void refresh() {
    if (mounted) {
      setState(() {
        _initialize();
        _checkCurrentVoiceAvailability();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Optionally save on inactive/detached too:
    if (state == AppLifecycleState.detached) {
      saveTextToHistoryWhenClose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    saveTextToHistoryWhenClose();
    ttsHelper.stop();
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
          customAction: IconButton(
            icon: Icon(
              Icons.history_rounded,
              color: themeProvider.themeData.textTheme.bodyLarge?.color,
              size: ResponsiveUtils.getResponsiveFontSize(context, 24),
            ),
            tooltip: context.translate("history_title"),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HistoryScreen(
                    themeProvider: themeProvider,
                    database: 'tts_history.db',
                  ),
                ),
              );
            },
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
    return RefreshIndicator.adaptive(
      onRefresh: _initialize,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  margin: EdgeInsets.all(
                      ResponsiveUtils.getResponsiveSize(context, 16)),
                  child: TextAreaCard(
                    key: keyTextArea,
                    themeProvider: themeProvider,
                    ttsBloc: widget.ttsBloc,
                    dbHelper: dbHelper,
                    contentController: _textController,
                    historyMode: historyMode.toString(),
                    onClear: () async {
                      await _stop();
                      _textController.clear();
                      setState(() {
                        currentlyPlaying = false;
                      });
                    },
                    textFieldHint: _textFieldHint,
                  ),
                ),

                // TTS Controls Section
                _buildTtsControls(themeProvider),
                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 20)),
              ],
            ),

            // Positioned widget for the scanner button
            Positioned(
              key: keyImagePicker,
              bottom: ResponsiveUtils.getResponsiveSize(context, 0),
              right: ResponsiveUtils.getResponsiveSize(context, 16),
              child: GestureDetector(
                onTap: () {
                  _showImageSourceDialog(themeProvider);
                },
                child: Container(
                  width: ResponsiveUtils.getResponsiveSize(context, 56),
                  height: ResponsiveUtils.getResponsiveSize(context, 56),
                  decoration: BoxDecoration(
                    color: themeProvider.themeData.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius:
                            ResponsiveUtils.getResponsiveSize(context, 8),
                        offset: Offset(
                            0, ResponsiveUtils.getResponsiveSize(context, 2)),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.document_scanner_rounded,
                    color: themeProvider.themeData.textTheme.bodySmall?.color,
                    size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                  ),
                ),
              ),
            ),
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
              absorbing: currentlyPlaying,
              child: Opacity(
                opacity: currentlyPlaying ? 0.5 : 1.0,
                child: _buildControlButton(
                  label: "Voice",
                  backgroundColor: themeProvider.themeData.cardColor,
                  textColor:
                      themeProvider.themeData.textTheme.bodyMedium?.color,
                  height: ResponsiveUtils.getResponsiveSize(context, 50),
                  width: ResponsiveUtils.getResponsiveSize(context, 100),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: themeProvider.themeData.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              ResponsiveUtils.getResponsiveSize(context, 12)),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.6,
                            maxWidth:
                                ResponsiveUtils.getResponsiveSize(context, 300),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(
                                ResponsiveUtils.getResponsiveSize(context, 16)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Select Voice",
                                  style: themeProvider
                                      .themeData.textTheme.titleMedium,
                                ),
                                SizedBox(
                                    height: ResponsiveUtils.getResponsiveSize(
                                        context, 12)),
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
          height: ResponsiveUtils.getResponsiveSize(context, 80),
          width: ResponsiveUtils.getResponsiveSize(context, 100),
          onPressed: currentlyPlaying ? _pause : _speak,
          themeProvider: themeProvider,
        ),

        SizedBox(width: ResponsiveUtils.getResponsiveSize(context, 20)),

        AbsorbPointer(
          absorbing: currentlyPlaying,
          child: Opacity(
            opacity: currentlyPlaying ? 0.5 : 1.0,
            child: _buildControlButton(
              label: "${(rate + 0.50).toStringAsFixed(2)}x",
              backgroundColor: themeProvider.themeData.cardColor,
              textColor: themeProvider.themeData.textTheme.bodyMedium?.color,
              height: ResponsiveUtils.getResponsiveSize(context, 50),
              width: ResponsiveUtils.getResponsiveSize(context, 100),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: themeProvider.themeData.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          ResponsiveUtils.getResponsiveSize(context, 12)),
                    ),
                    child: Container(
                      width: ResponsiveUtils.getResponsiveSize(context, 100),
                      height: ResponsiveUtils.getResponsiveSize(context, 200),
                      padding: EdgeInsets.all(
                          ResponsiveUtils.getResponsiveSize(context, 8)),
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
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                    context, 14),
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
    final isAvailable = _isVoiceAvailable(option["voice"]);

    return GestureDetector(
      onTap: isAvailable
          ? () async {
              setState(() {
                selectedlanguage = option["language"];
                selectedVoice = option["voice"];
              });
              await PreferencesUtils.storeTTSVoice(option["voice"]!);
              await PreferencesUtils.storeTTSLanguage(option["language"]!);
              Navigator.pop(context);
            }
          : null, // Disable tap if voice is not available
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: ResponsiveUtils.getResponsiveSize(context, 2),
              ),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: ResponsiveUtils.getResponsiveSize(context, 28),
                  backgroundImage: AssetImage(option["image"]!),
                ),
                if (!isAvailable) // Show overlay if voice is not available
                  Container(
                    width: ResponsiveUtils.getResponsiveSize(context, 56),
                    height: ResponsiveUtils.getResponsiveSize(context, 56),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.block,
                      color: Colors.white,
                      size: ResponsiveUtils.getResponsiveSize(context, 24),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 6)),
          Flexible(
            child: Column(
              children: [
                Text(
                  option["label"]!,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.blue
                        : isAvailable
                            ? themeProvider
                                .themeData.textTheme.bodyMedium?.color
                            : Colors.grey, // Grey out unavailable voices
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 12),
                  ),
                ),
                if (!isAvailable) // Show "Not Available" text
                  Text(
                    "Not Available",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 10),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
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
    final calculatedFontSize =
        fontSize ?? ResponsiveUtils.getResponsiveFontSize(context, 14);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: ResponsiveUtils.getResponsiveSize(context, 10),
            spreadRadius: ResponsiveUtils.getResponsiveSize(context, 2),
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
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 16)),
        ),
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
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
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 24)),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_rounded,
                  color: themeProvider.themeData.primaryColor,
                  size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                title: Text(
                  context.translate("tts_camera"),
                  style: themeProvider.themeData.textTheme.bodyMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveSize(context, 12)),
                ),
                tileColor: themeProvider.themeData.cardColor,
                onTap: () {
                  Navigator.pop(context);
                  widget.ttsBloc.add(
                    CaptureImageEvent(source: ImageSource.camera),
                  );
                },
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 12)),
              ListTile(
                leading: Icon(
                  Icons.photo_library_rounded,
                  color: themeProvider.themeData.primaryColor,
                  size: ResponsiveUtils.getResponsiveFontSize(context, 24),
                ),
                title: Text(
                  context.translate("tts_gallery"),
                  style: themeProvider.themeData.textTheme.bodyMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      ResponsiveUtils.getResponsiveSize(context, 12)),
                ),
                tileColor: themeProvider.themeData.cardColor,
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages(themeProvider);
                },
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
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
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 16)),
        ),
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 24)),
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
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 24)),
              const CircularProgressIndicator(),
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
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
          borderRadius: BorderRadius.circular(
              ResponsiveUtils.getResponsiveSize(context, 16)),
        ),
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
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
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 16)),
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
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 24)),
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
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveSize(context, 8)),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 8),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 8)),
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
                  SizedBox(
                      width: ResponsiveUtils.getResponsiveSize(context, 8)),
                  FilledButton(
                    onPressed: () {
                      confirmBatch = true;
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            ResponsiveUtils.getResponsiveSize(context, 8)),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal:
                              ResponsiveUtils.getResponsiveSize(context, 8),
                          vertical:
                              ResponsiveUtils.getResponsiveSize(context, 8)),
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
              borderRadius: BorderRadius.circular(
                  ResponsiveUtils.getResponsiveSize(context, 16)),
            ),
            child: Padding(
              padding: EdgeInsets.all(
                  ResponsiveUtils.getResponsiveSize(context, 24)),
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
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSize(context, 24)),
                  LinearProgressIndicator(
                    value: _currentProcessingIndex / _selectedImages.length,
                    minHeight: ResponsiveUtils.getResponsiveSize(context, 8),
                    borderRadius: BorderRadius.circular(
                        ResponsiveUtils.getResponsiveSize(context, 4)),
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSize(context, 16)),
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
