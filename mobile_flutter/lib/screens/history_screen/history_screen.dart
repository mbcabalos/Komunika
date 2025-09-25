import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';
import 'package:komunika/widgets/history_widgets/history_detail_page.dart';

class HistoryScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String database;
  const HistoryScreen(
      {super.key, required this.themeProvider, required this.database});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _historyEntries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    List<Map<String, dynamic>> historyRaw = [];
    if (widget.database == "stt_history.db") {
      historyRaw = await _dbHelper.getSpeechToTextHistory();
    } else if (widget.database == "tts_history.db") {
      historyRaw = await _dbHelper.getTextToSpeechHistory();
    }
    final history = List<Map<String, dynamic>>.from(historyRaw);
    history.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
    setState(() {
      _historyEntries = history;
    });
  }

  Future<void> _deleteEntry(int id) async {
    if (widget.database == "stt_history.db") {
      await _dbHelper.deleteSpeechToTextHistory(id);
    } else if (widget.database == "tts_history.db") {
      await _dbHelper.deleteTextToSpeechHistory(id);
    }
    await _loadHistory();
  }

  Future<void> _editTitleDialog(Map<String, dynamic> entry) async {
    final controller = TextEditingController(text: entry['title'] ?? '');
    final themeProvider = widget.themeProvider;
    final result = await showDialog<String>(
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
                context.translate('history_edit_title'),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodySmall?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: context.translate('history_enter_new_title'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: themeProvider.themeData.cardColor,
                ),
                style: TextStyle(
                  color: themeProvider.themeData.textTheme.bodyMedium?.color,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 16),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context, null),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate('history_cancel'),
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
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorsPalette.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                    ),
                    child: Text(
                      context.translate('history_save'),
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
    if (result != null && result.isNotEmpty) {
      if (widget.database == "stt_history.db") {
        await _dbHelper.updateSpeechToTextHistoryTitle(entry['id'], result);
      } else if (widget.database == "tts_history.db") {
        await _dbHelper.updateTextToSpeechHistoryTitle(entry['id'], result);
      }
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.database == "stt_history.db"
            ? context.translate("history_speech_to_text_title")
            : context.translate("history_text_to_speech_title"),
        titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
        themeProvider: widget.themeProvider,
        isBackButton: true,
      ),
      body: _historyEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(
                      height: ResponsiveUtils.getResponsiveSize(context, 16)),
                  Text(
                    context.translate('history_no_history'),
                    style: TextStyle(
                      fontSize:
                          ResponsiveUtils.getResponsiveFontSize(context, 18),
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: ResponsiveUtils.getResponsiveSize(context, 8),
              ),
              itemCount: _historyEntries.length,
              itemBuilder: (context, index) {
                final entry = _historyEntries[index];
                final title =
                    entry['title'] ?? context.translate('history_no_title');
                final content = entry['content'] ?? '';
                final timestamp =
                    entry['timestamp'] ?? DateTime.now().toIso8601String();
                final dateTime =
                    DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
                final formattedDate =
                    DateFormat('MMMM d, yyyy').format(dateTime);
                final formattedTime = DateFormat('h:mm a').format(dateTime);

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.getResponsiveSize(context, 16),
                    vertical: ResponsiveUtils.getResponsiveSize(context, 6),
                  ),
                  child: Slidable(
                    key: ValueKey(entry['id']),
                    endActionPane: ActionPane(
                      motion: const ScrollMotion(),
                      extentRatio: 0.50,
                      children: [
                        SizedBox(
                            width:
                                ResponsiveUtils.getResponsiveSize(context, 8)),
                        SlidableAction(
                          onPressed: (_) => _editTitleDialog(entry),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          icon: Icons.edit,
                          borderRadius: BorderRadius.circular(12),
                          autoClose: true,
                        ),
                        SizedBox(
                            width:
                                ResponsiveUtils.getResponsiveSize(context, 8)),
                        SlidableAction(
                          onPressed: (_) => _deleteEntry(entry['id']),
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          icon: Icons.delete,
                          borderRadius: BorderRadius.circular(12),
                          autoClose: true,
                        ),
                      ],
                    ),
                    child: Card(
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      color: widget.themeProvider.themeData.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HistoryDetailPage(
                                themeProvider: widget.themeProvider,
                                database: widget.database,
                                data: {
                                  'title': title,
                                  'content': content,
                                  'timestamp': timestamp,
                                },
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: EdgeInsets.all(
                              ResponsiveUtils.getResponsiveSize(context, 16)),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: ResponsiveUtils
                                            .getResponsiveFontSize(context, 16),
                                        color: widget.themeProvider.themeData
                                            .textTheme.bodyMedium?.color,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                        height:
                                            ResponsiveUtils.getResponsiveSize(
                                                context, 4)),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Colors.grey[500],
                                        ),
                                        SizedBox(
                                            width: ResponsiveUtils
                                                .getResponsiveSize(context, 4)),
                                        Text(
                                          '$formattedDate • $formattedTime',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: ResponsiveUtils
                                                .getResponsiveFontSize(
                                                    context, 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
