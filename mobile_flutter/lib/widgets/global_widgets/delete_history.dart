import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:komunika/services/repositories/database_helper.dart';

class DeleteHistoryWidget extends StatelessWidget {
  final DatabaseHelper dbHelper;
  final Function onDeleteAll;
  final Function(int) onDeleteSpecific;

  const DeleteHistoryWidget({
    super.key,
    required this.dbHelper,
    required this.onDeleteAll,
    required this.onDeleteSpecific,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Delete All Button
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text(
            'Delete All History',
            style: TextStyle(color: Colors.red),
          ),
          onTap: () async {
            // Show confirmation dialog
            final confirmed = await _showConfirmationDialog(
              context,
              'Are you sure you want to delete all history?',
            );
            if (confirmed) {
              await dbHelper.clearSpeechToTextHistory();
              onDeleteAll(); // Callback to refresh the UI
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.delete, color: Colors.orange),
          title: const Text(
            'Delete Specific Entry',
            style: TextStyle(color: Colors.orange),
          ),
          onTap: () async {
            final entryId = await _showDeleteSpecificDialog(context);
            if (entryId != null) {
              await dbHelper.deleteSpeechToTextHistory(entryId);
              onDeleteSpecific(entryId);
            }
          },
        ),
      ],
    );
  }

  // Confirmation Dialog
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
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // Dialog to Select a Specific Entry to Delete
  Future<int?> _showDeleteSpecificDialog(BuildContext context) async {
    final history = await dbHelper.getSpeechToTextHistory();

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
                return ListTile(
                  title: Text(entry['text']),
                  subtitle: Text(
                    DateFormat('h:mm a')
                        .format(DateTime.parse(entry['timestamp'])),
                  ),
                  onTap: () => Navigator.pop(context, entry['id']),
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
