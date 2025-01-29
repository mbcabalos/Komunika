import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_event.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_state.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/widgets/app_bar.dart';
import 'package:komunika/widgets/text_to_speech_widgets/tts_card.dart';

class VoiceMessagePage extends StatefulWidget {
  const VoiceMessagePage({super.key});

  @override
  State<VoiceMessagePage> createState() => VoiceMessagePageState();
}

class VoiceMessagePageState extends State<VoiceMessagePage> {
  late TextToSpeechBloc textToSpeechBloc;
  // List to store the fetched audioPaths
  List<Map<String, dynamic>> audioItems = [];

  // Fetch audio paths from the database
  Future<void> fetchAudioPaths() async {
    List<Map<String, dynamic>> data =
        await DatabaseHelper().fetchAllAudioItems();
    setState(() {
      audioItems = data;
    });
  }

  @override
  void initState() {
    super.initState();
    final globalService = GlobalRepositoryImpl();
    final databaseHelper = DatabaseHelper();
    textToSpeechBloc = TextToSpeechBloc(globalService, databaseHelper);
    textToSpeechBloc.add(TextToSpeechLoadingEvent());
    fetchAudioPaths();
  }

  @override
  Widget build(BuildContext context) {
    final double phoneHeight = MediaQuery.of(context).size.height * 0.8;
    return BlocProvider<TextToSpeechBloc>(
      create: (context) => textToSpeechBloc,
      child: Scaffold(
        backgroundColor: ColorsPalette.background,
        appBar: AppBarWidget(
            title: "Text to Speech",
            titleSize: getResponsiveFontSize(context, 15),
            isBackButton: true,
            isSettingButton: false),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16.0, right: 16.0),
          child: FloatingActionButton(
            backgroundColor: ColorsPalette.accent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TextToSpeechScreen(),
                ),
              );
            },
            child: Image.asset(
              'assets/icons/text-to-speech.png',
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.width * 0.07,
              width: MediaQuery.of(context).size.width * 0.07,
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
              return _buildContent(phoneHeight);
            } else if (state is TextToSpeechErrorState) {
              return const Text('Error processing text to speech!');
            } else {
              return _buildContent(phoneHeight);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(double phoneHeight) {
    return Center(
      child: Column(
        children: [
          Container(
            height: phoneHeight,
            margin: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Display the fetched audio items in a ListView
                Expanded(
                  child: ListView.builder(
                    itemCount: audioItems.length,
                    itemBuilder: (context, index) {
                      final id = audioItems[index]['id'];
                      final audioPath = audioItems[index]['audioName'];
                      final favorites = audioItems[index]['favorites'];
                      return GestureDetector(
                        onTap: () {
                          textToSpeechBloc
                              .add(PlayAudioEvent(audioName: audioPath));
                        },
                        onLongPress: () {
                          _showOptionsMenu(context, audioPath, favorites);
                        },
                        child: TTSCard(
                          audioName: audioPath,
                          onTap: () {
                            textToSpeechBloc
                                .add(PlayAudioEvent(audioName: audioPath));
                          },
                          onLongPress: () {
                            _showOptionsMenu(context, audioPath, favorites);
                          },
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
    );
  }

  double getResponsiveFontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // Reference width (e.g., iPhone 11 Pro)
    double screenWidth = MediaQuery.of(context).size.width;
    return size * (screenWidth / baseWidth);
  }

  void _showOptionsMenu(BuildContext context, audioPath, favorites) {
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
                    textToSpeechBloc
                        .add(RemoveFromFavorite(audioName: audioPath));
                  } else {
                    textToSpeechBloc.add(AddToFavorite(audioName: audioPath));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Edit"),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete"),
                onTap: () {
                  Navigator.pop(context); // Close the menu
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
