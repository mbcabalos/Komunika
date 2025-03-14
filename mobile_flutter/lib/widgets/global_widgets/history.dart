import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/colors.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class HistoryPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final String database;
  const HistoryPage(
      {super.key, required this.themeProvider, required this.database});

  @override
  HistoryPageState createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _historyEntries = [];
  bool _isFabExpanded = false; 

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    switch (widget.database) {
      case "stt":
        final history = await _dbHelper.getSpeechToTextHistory();
        setState(() {
          _historyEntries = history;
        });
        break;
      case "sign_trancriber":
        final history = await _dbHelper.getSignTranscriberHistory();
        setState(() {
          _historyEntries = history;
        });
        break;
      case "auto_caption":
        final history = await _dbHelper.getAutoCaptionHistory();
        setState(() {
          _historyEntries = history;
        });
        break;
      default:
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> entries) {
    Map<String, List<Map<String, dynamic>>> groupedEntries = {};

    for (var entry in entries) {
      String date =
          DateFormat('yyyy-MM-dd').format(DateTime.parse(entry['timestamp']));
      groupedEntries.putIfAbsent(date, () => []).add(entry);
    }
    return groupedEntries;
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupByDate(_historyEntries);
    final sortedDates = groupedEntries.keys.toList()..sort();

    return Scaffold(
      appBar: AppBarWidget(
        title: context.translate('history_title'),
        titleSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
        themeProvider: widget.themeProvider,
        isBackButton: true,
        isSettingButton: false,
        isHistoryButton: false,
        database: '',
      ),
      body: ListView.builder(
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          final date = sortedDates[index];
          final entries = groupedEntries[date]!;

          entries.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.all(
                    ResponsiveUtils.getResponsiveSize(context, 8)),
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getResponsiveSize(context, 16),
                  vertical: ResponsiveUtils.getResponsiveSize(context, 8),
                ),
                child: Text(
                  DateFormat('MMMM d, yyyy').format(DateTime.parse(date)),
                  style: TextStyle(
                    fontSize:
                        ResponsiveUtils.getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: widget
                        .themeProvider.themeData.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: entries.length,
                itemBuilder: (context, entryIndex) {
                  final entry = entries[entryIndex];
                  final time = DateFormat('h:mm a')
                      .format(DateTime.parse(entry['timestamp']));

                  return Card(
                    margin: EdgeInsets.symmetric(
                      horizontal:
                          ResponsiveUtils.getResponsiveSize(context, 16),
                      vertical: ResponsiveUtils.getResponsiveSize(context, 4),
                    ),
                    elevation: 2,
                    color: widget.themeProvider.themeData.cardColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal:
                            ResponsiveUtils.getResponsiveSize(context, 16),
                        vertical: ResponsiveUtils.getResponsiveSize(context, 8),
                      ),
                      title: Text(
                        entry['text'],
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 8)),
              Divider(
                color: ColorsPalette.accent,
                thickness: 1,
                indent: ResponsiveUtils.getResponsiveSize(context, 16),
                endIndent: ResponsiveUtils.getResponsiveSize(context, 16),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isFabExpanded) ...[
          FloatingActionButton.extended(
            heroTag: "delete_all",
            backgroundColor: ColorsPalette.red,
            icon: const Icon(Icons.delete_forever),
            label: const Text("Delete All"),
            onPressed: () async {
              final confirmed =
                  await _showConfirmationDialog(context, "Delete all history?");
              if (confirmed) {
                await _dbHelper.clearSpeechToTextHistory();
                _loadHistory();
                _toggleFab();
              }
            },
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 10)),
          FloatingActionButton.extended(
            heroTag: "delete_specific",
            backgroundColor: ColorsPalette.orange,
            icon: const Icon(Icons.delete),
            label: const Text("Delete Specific"),
            onPressed: () async {
              final entryId = await _showDeleteSpecificDialog(context);
              if (entryId != null) {
                await _dbHelper.deleteSpeechToTextHistory(entryId);
                _loadHistory();
                _toggleFab();
              }
            },
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 10)),
        ],
        FloatingActionButton(
          backgroundColor: _isFabExpanded
              ? Colors.grey
              : widget.themeProvider.themeData.primaryColor,
          onPressed: _toggleFab,
          child: Icon(
            _isFabExpanded ? Icons.close : Icons.delete,
            color: ColorsPalette.white,
          ),
        ),
      ],
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            );
          },
        ) ??
        false;
  }

  Future<int?> _showDeleteSpecificDialog(BuildContext context) async {
    final history = await _dbHelper.getSpeechToTextHistory();

    return await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Specific Entry'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.themeProvider.themeData.cardColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(
                      entry['text'],
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(
                          context,
                          16,
                        ),
                        color: widget.themeProvider.themeData.textTheme
                            .bodyMedium?.color,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('h:mm a')
                          .format(DateTime.parse(entry['timestamp'])),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    onTap: () => Navigator.pop(context, entry['id']),
                    tileColor: Colors.white, // Background color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
