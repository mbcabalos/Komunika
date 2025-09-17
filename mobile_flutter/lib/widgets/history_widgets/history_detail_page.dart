import 'package:intl/intl.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:flutter/material.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/flutter_tts.dart';

class HistoryDetailPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String database;
  final Map<String, dynamic> data;
  const HistoryDetailPage(
      {super.key,
      required this.themeProvider,
      required this.data,
      required this.database});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  late TtsHelper ttsHelper;
  bool isPlaying = false;
  String? selectedVoice;
  String? selectedlanguage;

  @override
  void initState() {
    super.initState();
    ttsHelper = TtsHelper();
    ttsHelper.setupHandlers(
      () => setState(() => isPlaying = true),
      () => setState(() => isPlaying = false),
      () => setState(() => isPlaying = false),
      (msg) => setState(() => isPlaying = false),
    );
    _loadTtsPrefs();
  }

  Future<void> _loadTtsPrefs() async {
    selectedVoice = await PreferencesUtils.getTTSVoice();
    selectedlanguage = await PreferencesUtils.getTTSLanguage();
    setState(() {});
  }

  Future<void> _playTts() async {
    final text = widget.data['content'] ?? '';
    if (text.trim().isEmpty) return;
    await ttsHelper.speak(
      text: text,
      language: selectedlanguage,
      voice: selectedVoice,
      rate: 0.5,
      pitch: 1.0,
      volume: 1.0,
    );
  }

  Future<void> _stopTts() async {
    await ttsHelper.stop();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  void dispose() {
    ttsHelper.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timestamp =
        widget.data['timestamp'] ?? DateTime.now().toIso8601String();
    final dateTime = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);

    return Scaffold(
      appBar: AppBarWidget(
        title: widget.database == "stt_history.db"
            ? context.translate("history_speech_to_text_title")
            : context.translate("history_text_to_speech_title"),
        titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
        themeProvider: widget.themeProvider,
        isBackButton: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 10)),
        child: Card(
          elevation: 2,
          color: widget.themeProvider.themeData.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding:
                EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.data['title'] ??
                            context.translate('history_no_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 20),
                          color: widget.themeProvider.themeData.textTheme
                              .bodyMedium?.color,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                        color: widget.themeProvider.themeData.primaryColor,
                        size: 32,
                      ),
                      tooltip: isPlaying
                          ? context.translate('tts_stop')
                          : context.translate('tts_play'),
                      onPressed: isPlaying ? _stopTts : _playTts,
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(
                        width: ResponsiveUtils.getResponsiveSize(context, 6)),
                    Text(
                      '$formattedDate • $formattedTime',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 14),
                      ),
                    ),
                  ],
                ),
                Divider(height: ResponsiveUtils.getResponsiveSize(context, 24)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      widget.data['content'] ?? '',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 16),
                        height: 1.5,
                        color: widget.themeProvider.themeData.textTheme
                            .bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
