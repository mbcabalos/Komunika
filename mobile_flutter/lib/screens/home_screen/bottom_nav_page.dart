import 'package:flutter/material.dart';
import 'package:komunika/bloc/bloc_home/home_bloc.dart';
import 'package:komunika/bloc/bloc_sound_enhancer/sound_enhancer_bloc.dart';
import 'package:komunika/bloc/bloc_text_to_speech/text_to_speech_bloc.dart';
import 'package:komunika/screens/settings_screen/settings_page.dart';
import 'package:komunika/screens/sound_enhancer_screen/sound_enhancer_screen.dart';
import 'package:komunika/screens/text_to_speech_screen/tts_page.dart';
import 'package:komunika/services/api/global_repository_impl.dart';
import 'package:komunika/services/live-service-handler/socket_service.dart';
import 'package:komunika/services/live-service-handler/speexdsp_helper.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/themes.dart';

class BottomNavScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const BottomNavScreen({super.key, required this.themeProvider});

  @override
  State<BottomNavScreen> createState() => _BottomNavScreenState();
}

class _BottomNavScreenState extends State<BottomNavScreen> {
  late HomeBloc homeBloc;
  late SoundEnhancerBloc soundEnhancerBloc;
  late TextToSpeechBloc textToSpeechBloc;
  final socketService = SocketService();
  final speexDenoiser = SpeexDSP();
  final globalService = GlobalRepositoryImpl();
  final databaseHelper = DatabaseHelper();
  int _currentIndex = 0;
  late List<Widget> _screens;
  final GlobalKey ttsNavKey = GlobalKey();
  final GlobalKey settingsNavKey = GlobalKey();
  final GlobalKey<TextToSpeechScreenState> ttsScreenKey = GlobalKey();
  final GlobalKey<SoundEnhancerScreenState> sesScreenKey = GlobalKey();
  final GlobalKey<SettingScreenState> sScreenKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    homeBloc = HomeBloc(databaseHelper);
    soundEnhancerBloc = SoundEnhancerBloc(socketService, speexDenoiser);
    textToSpeechBloc = TextToSpeechBloc(globalService, databaseHelper);
    homeBloc.add(HomeLoadingEvent());

    // Initialize screens after BLoCs are created
    _screens = [
      SoundEnhancerScreen(
          key: sesScreenKey,
          soundEnhancerBloc: soundEnhancerBloc,
          ttsNavKey: ttsNavKey),
      TextToSpeechScreen(
          key: ttsScreenKey,
          ttsBloc: textToSpeechBloc,
          settingsNavKey: settingsNavKey),
      SettingScreen(key: sScreenKey, themeProvider: widget.themeProvider),
    ];
  }

  @override
  void dispose() {
    homeBloc.close();
    soundEnhancerBloc.close();
    textToSpeechBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) {
            // TTS tab
            ttsScreenKey.currentState?.checkWalkthrough();
          } else if (index == 0) {
            sesScreenKey.currentState?.checkWalkthrough();
          } else if (index == 2) {
            sScreenKey.currentState?.checkWalkthrough();
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq),
            label: 'Sound Enhancer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over, key: ttsNavKey),
            label: 'Text to Speech',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, key: settingsNavKey),
            label: 'Settings',
          ),
        ],
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        backgroundColor: widget.themeProvider.themeData.cardColor,
      ),
    );
  }
}
