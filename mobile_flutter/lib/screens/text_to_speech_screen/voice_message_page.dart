import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';
import 'package:showcaseview/showcaseview.dart';

class VoiceMessagePage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final TextToSpeechBloc textToSpeechBloc;
  const VoiceMessagePage(
      {super.key, required this.themeProvider, required this.textToSpeechBloc});

  @override
  State<VoiceMessagePage> createState() => VoiceMessagePageState();
}

class VoiceMessagePageState extends State<VoiceMessagePage> {
  List<Map<String, dynamic>> audioItems = [];
  GlobalKey _fabKey = GlobalKey();

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
          isBackButton: true,
          isSettingButton: false,
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: Showcase(
            key: _fabKey,
            description: "Tap to add voice message",
            child: FloatingActionButton(
              backgroundColor: widget.themeProvider.themeData.primaryColor,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TextToSpeechScreen(
                      themeProvider: widget.themeProvider,
                      ttsBloc: widget.textToSpeechBloc, // Pass the callback
                    ),
                  ),
                );
                print("Called");
                _refreshScreen(); // Refresh after returning
              },
              child: Image.asset(
                'assets/icons/text-to-speech.png',
                fit: BoxFit.contain,
                height: MediaQuery.of(context).size.width * 0.07,
                width: MediaQuery.of(context).size.width * 0.07,
              ),
            ),
          ),
        ),
        body: BlocConsumer<TextToSpeechBloc, TextToSpeechState>(
          listener: (context, state) {
            if (state is TextToSpeechErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
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
              margin: const EdgeInsets.all(16),
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
                        return GestureDetector(
                          onTap: () {
                            widget.textToSpeechBloc
                                .add(PlayAudioEvent(audioName: audioPath));
                          },
                          onLongPress: () {
                            _showOptionsMenu(context, id, audioPath, favorites);
                          },
                          child: TTSCard(
                            audioName: audioPath,
                            onTap: () {
                              widget.textToSpeechBloc
                                  .add(PlayAudioEvent(audioName: audioPath));
                            },
                            onLongPress: () {
                              _showOptionsMenu(
                                  context, id, audioPath, favorites);
                            },
                            themeProvider: themeProvider,
                          ),
                        );
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
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.record_voice_over),
                title: Text(favorites == 1
                    ? "Remove From Quick Speech"
                    : "Add To Quick Speech"),
                onTap: () {
                  if (favorites == 1) {
                    widget.textToSpeechBloc
                        .add(RemoveFromFavorite(audioName: audioPath));
                  } else {
                    widget.textToSpeechBloc.add(AddToFavorite(audioName: audioPath));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete"),
                onTap: () {
                  widget.textToSpeechBloc.add(DeleteQuickSpeech(audioId: id));
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
