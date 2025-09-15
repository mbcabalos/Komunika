import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class TranscriptionHistoryPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TranscriptionHistoryPage({super.key, required this.themeProvider});

  @override
  State<TranscriptionHistoryPage> createState() =>
      _TranscriptionHistoryPageState();
}

class _TranscriptionHistoryPageState extends State<TranscriptionHistoryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _historyEntries = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final historyRaw = await _dbHelper.getSpeechToTextHistory();
    final history = List<Map<String, dynamic>>.from(historyRaw);
    history.sort((a, b) => DateTime.parse(b['timestamp'])
        .compareTo(DateTime.parse(a['timestamp'])));
    setState(() {
      _historyEntries = history;
    });
  }

  Future<void> _deleteEntry(int id) async {
    await _dbHelper.deleteSpeechToTextHistory(id);
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
                context.translate('transcription_history_edit_title'),
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
                  hintText: context
                      .translate('transcription_history_enter_new_title'),
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
                      context.translate('transcription_history_cancel'),
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
                      context.translate('transcription_history_save'),
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
      await _dbHelper.updateSpeechToTextHistoryTitle(entry['id'], result);
      await _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: context.translate('transcription_history_title'),
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
                  SizedBox(height: 16),
                  Text(
                    context.translate(
                        'transcription_history_no_transcription_history'),
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
                final title = entry['title'] ??
                    context.translate('transcription_history_no_title');
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
                              builder: (_) => TranscriptionDetailPage(
                                themeProvider: widget.themeProvider,
                                entry: {
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

class TranscriptionDetailPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  final Map<String, dynamic> entry;
  const TranscriptionDetailPage(
      {super.key, required this.themeProvider, required this.entry});

  @override
  Widget build(BuildContext context) {
    final timestamp = entry['timestamp'] ?? DateTime.now().toIso8601String();
    final dateTime = DateTime.tryParse(timestamp)?.toLocal() ?? DateTime.now();
    final formattedDate = DateFormat('MMMM d, yyyy').format(dateTime);
    final formattedTime = DateFormat('h:mm a').format(dateTime);

    return Scaffold(
      appBar: AppBar(
        title: Text(entry['title'] ??
            context.translate('transcription_history_no_title')),
        backgroundColor: themeProvider.themeData.primaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
        child: Card(
          elevation: 4,
          color: themeProvider.themeData.cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding:
                EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry['title'] ??
                            context.translate('transcription_history_no_title'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 20),
                          color: themeProvider
                              .themeData.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                    height: ResponsiveUtils.getResponsiveSize(context, 12)),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    SizedBox(width: 6),
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
                      entry['content'] ?? '',
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 16),
                        height: 1.5,
                        color:
                            themeProvider.themeData.textTheme.bodyMedium?.color,
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
