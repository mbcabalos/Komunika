import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_auto_caption/auto_caption_bloc.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/shared_prefs.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class AutoCaptionScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const AutoCaptionScreen({super.key, required this.themeProvider});

  @override
  State<AutoCaptionScreen> createState() => _AutoCaptionScreenState();
}

class _AutoCaptionScreenState extends State<AutoCaptionScreen> {
  double _captionSize = 50.0;
  Color _captionTextColor = Colors.black;
  Color _captionBackgroundColor = Colors.white;
  final String _caption = "Caption here...";
  bool _isEnabled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCaptionPreferences();
    final autoCaptionBloc = BlocProvider.of<AutoCaptionBloc>(context);
    if (!autoCaptionBloc.isInitialized) {
      autoCaptionBloc.add(AutoCaptionLoadingEvent());
      autoCaptionBloc.add(RequestPermissionEvent());
    }
  }

  Future<void> _updateCaptionSize(double size) async {
    setState(() => _captionSize = size);
    await PreferencesUtils.storeCaptionSize(size);
    _sendCaptionPreferences();
  }

  Future<void> _updateCaptionTextColor(Color color) async {
    String colorName = _getColorName(color);
    setState(() => _captionTextColor = color);
    await PreferencesUtils.storeCaptionTextColor(colorName);
    _sendCaptionPreferences();
  }

  Future<void> _updateCaptionBackgroundColor(Color color) async {
    String colorName = _getColorName(color);
    setState(() => _captionBackgroundColor = color);
    await PreferencesUtils.storeCaptionBackgroundColor(colorName);
    _sendCaptionPreferences();
  }

  Future<void> _updateEnableState(bool isEnabled) async {
    BlocProvider.of<AutoCaptionBloc>(context)
        .add(ToggleAutoCaptionEvent(isEnabled));
  }

  String _getColorName(Color color) {
    if (color == Colors.red) return "red";
    if (color == Colors.blue) return "blue";
    if (color == Colors.black) return "black";
    if (color == Colors.white) return "white";
    if (color == Colors.grey) return "grey";
    return "black"; // Default
  }

  Future<void> _sendCaptionPreferences() async {
    const platform = MethodChannel('com.example.komunika/recorder');
    await platform.invokeMethod('updateCaptionPreferences', {
      "size": _captionSize,
      "textColor": await PreferencesUtils.getCaptionTextColor(),
      "backgroundColor": await PreferencesUtils.getCaptionBackgroundColor(),
      "isEnabled": _isEnabled,
    });
  }

  Future<void> _loadCaptionPreferences() async {
    _captionSize = await PreferencesUtils.getCaptionSize();
    String textColorName = await PreferencesUtils.getCaptionTextColor();
    String backgroundColorName =
        await PreferencesUtils.getCaptionBackgroundColor();

    setState(() {
      _captionSize = _captionSize;
      _captionTextColor = _getColorFromName(textColorName);
      _captionBackgroundColor = _getColorFromName(backgroundColorName);
    });
    _sendCaptionPreferences();
  }

  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case "red":
        return Colors.red;
      case "blue":
        return Colors.blue;
      case "black":
        return Colors.black;
      case "white":
        return Colors.white;
      case "grey":
        return Colors.grey;
      default:
        return Colors.black; // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: context.translate('auto_caption_title'),
        titleSize: 16,
        themeProvider: widget.themeProvider,
        isBackButton: true,
        isSettingButton: false,
        isHistoryButton: true,
        database: 'auto_caption',
      ),
      body: BlocConsumer<AutoCaptionBloc, AutoCaptionState>(
        listener: (context, state) {
          if (state is AutoCaptionErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AutoCaptionLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AutoCaptionLoadedSuccessState) {
            return _buildContent(state);
          } else {
            return const Center(child: Text('Failed to load settings.'));
          }
        },
      ),
    );
  }

  Widget _buildContent(AutoCaptionLoadedSuccessState state) {
    return ListView(
      padding: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption Preview Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: _captionBackgroundColor,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  _caption,
                  style: TextStyle(
                    fontSize: _captionSize,
                    color: _captionTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 20)),
            // Enable Switch
            Card(
              color: widget.themeProvider.themeData.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlocBuilder<AutoCaptionBloc, AutoCaptionState>(
                builder: (context, state) {
                  if (state is AutoCaptionLoadedSuccessState) {
                    _isEnabled = state.isEnabled;
                  }
                  return SwitchListTile(
                    title: Text(
                      "Enable Auto Caption",
                      style: TextStyle(
                        fontSize:
                            ResponsiveUtils.getResponsiveFontSize(context, 18),
                        fontFamily: Fonts.main,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _isEnabled,
                    onChanged: (value) {
                      _updateEnableState(value);
                    },
                  );
                },
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 20)),
            // Size Slider
            Card(
              color: widget.themeProvider.themeData.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildSizeSlider(),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 20)),
            // Text Color Dropdown
            Card(
              color: widget.themeProvider.themeData.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildDropdown(
                  "Text Color",
                  _captionTextColor,
                  [
                    const DropdownMenuItem(
                        value: Colors.white, child: Text("White")),
                    const DropdownMenuItem(
                        value: Colors.black, child: Text("Black")),
                    const DropdownMenuItem(
                        value: Colors.red, child: Text("Red")),
                    const DropdownMenuItem(
                        value: Colors.blue, child: Text("Blue")),
                  ],
                  _updateCaptionTextColor,
                ),
              ),
            ),
            SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 20)),
            // Background Color Dropdown
            Card(
              color: widget.themeProvider.themeData.cardColor,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: _buildDropdown(
                  "Background Color",
                  _captionBackgroundColor,
                  [
                    const DropdownMenuItem(
                        value: Colors.black, child: Text("Black")),
                    const DropdownMenuItem(
                        value: Colors.white, child: Text("White")),
                    const DropdownMenuItem(
                        value: Colors.grey, child: Text("Grey")),
                    const DropdownMenuItem(
                        value: Colors.blue, child: Text("Blue")),
                  ],
                  _updateCaptionBackgroundColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Caption Size",
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
            fontFamily: Fonts.main,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: _captionSize,
          min: 10.0,
          max: 100.0,
          divisions: 17,
          label: "${_captionSize.round()}",
          onChanged: (value) {
            _updateCaptionSize(value);
          },
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String title,
    Color selectedValue,
    List<DropdownMenuItem<Color>> items,
    Function(Color) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 18),
            fontFamily: Fonts.main,
            fontWeight: FontWeight.w600,
          ),
        ),
        DropdownButton<Color>(
          value: selectedValue,
          items: items,
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
          isExpanded: true,
        ),
      ],
    );
  }
}
