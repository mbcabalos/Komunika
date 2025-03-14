import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/snack_bar.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';

class VoiceMessagePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc textToSpeechBloc;

  const VoiceMessagePage({
    super.key,
    required this.themeProvider,
    required this.textToSpeechBloc,
  });

  @override
  State<VoiceMessagePage> createState() => _VoiceMessagePageState();
}

class _VoiceMessagePageState extends State<VoiceMessagePage> {
  List<Map<String, dynamic>> audioItems = [];
  String? currentlyPlaying;

  @override
  void initState() {
    super.initState();
    _refreshScreen();
  }

  Future<void> _refreshScreen() async {
    print("Refreshing the screen..");
    widget.textToSpeechBloc.add(TextToSpeechLoadingEvent());
    widget.textToSpeechBloc.add(FetchAudioEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.textToSpeechBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: context.translate("tts_title"),
          titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          themeProvider: widget.themeProvider,
          isBackButton: true,
          isSettingButton: false,
          isHistoryButton: false,
          database: '',
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is TextToSpeechErrorState) {
              showCustomSnackBar(
                  context, "Errr, Please try again", ColorsPalette.red);
            }
            if (state is AudioPlaybackCompletedState) {
              setState(() {
                currentlyPlaying = null;
              });
            }
          },
          builder: (context, state) {
            if (state is TextToSpeechLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TextToSpeechLoadedSuccessState) {
              return _buildContent(widget.themeProvider, state);
            } else if (state is TextToSpeechErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(widget.themeProvider,
                  TextToSpeechLoadedSuccessState(audioItems: []));
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(
      ThemeProvider themeProvider, TextToSpeechLoadedSuccessState state) {
    audioItems = state.audioItems;
    return RefreshIndicator(
      onRefresh: () => _refreshScreen(),
      child: Center(
        child: Column(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.85,
              margin: EdgeInsets.all(
                ResponsiveUtils.getResponsiveSize(context, 8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child: ListView.builder(
                      key: ValueKey(audioItems.length),
                      itemCount: audioItems.length,
                      itemBuilder: (context, index) {
                        final id = audioItems[index]['id'];
                        final audioPath = audioItems[index]['audioName'];
                        final favorites = audioItems[index]['favorites'];
                        final isPlaying = currentlyPlaying == audioPath;

                        return GestureDetector(
                            onTap: currentlyPlaying != null
                                ? null
                                : () {
                                    setState(() {
                                      currentlyPlaying =
                                          isPlaying ? null : audioPath;
                                    });
                                    widget.textToSpeechBloc.add(
                                        PlayAudioEvent(audioName: audioPath));
                                  },
                            onLongPress: currentlyPlaying != null
                                ? null
                                : () {
                                    _showOptionsMenu(
                                        context, id, audioPath, favorites);
                                  },
                            child: TTSCard(
                              audioName: audioPath,
                              onTap: currentlyPlaying != null
                                  ? null
                                  : () {
                                      setState(() {
                                        currentlyPlaying =
                                            isPlaying ? null : audioPath;
                                      });
                                      widget.textToSpeechBloc.add(
                                          PlayAudioEvent(audioName: audioPath));
                                    },
                              onLongPress: currentlyPlaying != null
                                  ? null
                                  : () {
                                      _showOptionsMenu(
                                          context, id, audioPath, favorites);
                                    },
                              themeProvider: themeProvider,
                              isPlaying: isPlaying,
                              isFavorite:
                                  favorites == 1, // NEW: Pass favorite status
                            ));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context, id, audioPath, favorites) {
    final favoriteCount =
        audioItems.where((item) => item['favorites'] == 1).length;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.record_voice_over),
                title: Text(favorites == 1
                    ? "Remove From Quick Speech"
                    : "Add To Quick Speech"),
                onTap: () {
                  if (favorites == 1) {
                    widget.textToSpeechBloc
                        .add(RemoveFromFavoriteEvent(audioName: audioPath));
                  } else {
                    if (favoriteCount >= 5) {
                      showCustomSnackBar(
                        context,
                        "Quick Speech items can only be 5",
                        ColorsPalette.red,
                      );
                    } else {
                      widget.textToSpeechBloc
                          .add(AddToFavoriteEvent(audioName: audioPath));
                    }
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Delete"),
                onTap: () {
                  widget.textToSpeechBloc
                      .add(DeleteQuickSpeechEvent(audioId: id));
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
