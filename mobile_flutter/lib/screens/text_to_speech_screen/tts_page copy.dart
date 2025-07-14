import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TextToSpeechScreen2 extends StatefulWidget {
  const TextToSpeechScreen2({super.key});

  @override
  State<TextToSpeechScreen2> createState() => _TextToSpeechScreenState2();
}

class _TextToSpeechScreenState2 extends State<TextToSpeechScreen2> {
  final TextEditingController _textController = TextEditingController();
  final List<SavedItem> _savedItems = [
    SavedItem(
        title: "Meeting Notes",
        date: DateTime.now().subtract(const Duration(days: 2))),
    SavedItem(
        title: "Shopping List",
        date: DateTime.now().subtract(const Duration(days: 1))),
    SavedItem(title: "Ideas", date: DateTime.now()),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Text to Speech'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveText,
                    icon: const Icon(Icons.file_copy),
                    label: const Text('Type Here'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _scanText,
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Scan'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Saved items list
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saved Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _savedItems.length,
                itemBuilder: (context, index) {
                  final item = _savedItems[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(item.title),
                      subtitle: Text(
                        DateFormat('MMM dd, yyyy - hh:mm a').format(item.date),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _playItem(item),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _scanText() {
    // Implement text scanning functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Text'),
        content: const Text('This would open a text scanning feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveText() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _savedItems.insert(
        0,
        SavedItem(
          title: _textController.text.length > 20
              ? '${_textController.text.substring(0, 20)}...'
              : _textController.text,
          date: DateTime.now(),
        ),
      );
      _textController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text saved successfully')),
    );
  }

  void _playItem(SavedItem item) {
    // Implement text-to-speech playback
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Play ${item.title}'),
        content: const Text('This would play the text using TTS.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class SavedItem {
  final String title;
  final DateTime date;

  SavedItem({
    required this.title,
    required this.date,
  });
}
