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
  late AutoCaptionBloc autoCaptionBloc;
  final TextEditingController _textController = TextEditingController();
  double _captionSize = 50.0;
  Color _captionTextColor = Colors.black;
  Color _captionBackgroundColor = Colors.white;
  final String _caption = "Caption here...";

  @override
  void initState() {
    super.initState();
    autoCaptionBloc = AutoCaptionBloc();
    autoCaptionBloc.add(AutoCaptionLoadingEvent());
    _loadCaptionPreferences();
  }

  Future<void> _updateCaptionSize(double size) async {
    setState(() => _captionSize = size);
    await PreferencesUtils.storeCaptionSize(size);
    _loadCaptionPreferences();
  }

  Future<void> _updateCaptionTextColor(Color color) async {
  String colorName = _getColorName(color);
  setState(() => _captionTextColor = color);
  await PreferencesUtils.storeCaptionTextColor(colorName);
  _loadCaptionPreferences();
}

Future<void> _updateCaptionBackgroundColor(Color color) async {
  String colorName = _getColorName(color);
  setState(() => _captionBackgroundColor = color);
  await PreferencesUtils.storeCaptionBackgroundColor(colorName);
  _loadCaptionPreferences();
}

String _getColorName(Color color) {
  if (color == Colors.red) return "red";
  if (color == Colors.blue) return "blue";
  if (color == Colors.black) return "black";
  if (color == Colors.white) return "white";
  if (color == Colors.grey) return "grey";
  return "black"; 
}

  Future<void> _sendCaptionPreferences() async {
    final platform = MethodChannel('com.example.komunika/recorder');
    await platform.invokeMethod('updateCaptionPreferences', {
      "size": _captionSize,
      "textColor": await PreferencesUtils.getCaptionTextColor(),
      "backgroundColor": await PreferencesUtils.getCaptionBackgroundColor(),
    });
  }

Future<void> _loadCaptionPreferences() async {
  _captionSize = await PreferencesUtils.getCaptionSize();
  String textColorName = await PreferencesUtils.getCaptionTextColor();
  String backgroundColorName = await PreferencesUtils.getCaptionBackgroundColor();

  _captionTextColor = _getColorFromName(textColorName);
  _captionBackgroundColor = _getColorFromName(backgroundColorName);

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
      return Colors.black; 
  }
}

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AutoCaptionBloc>(
      create: (context) => autoCaptionBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: context.translate('auto_caption_title'),
          titleSize: 20,
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
      ),
    );
  }

  Widget _buildContent(AutoCaptionLoadedSuccessState state) {
    return Container(
      margin: EdgeInsets.all(ResponsiveUtils.getResponsiveSize(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            //color: widget.themeProvider.themeData.cardColor,
            color: _captionBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                _caption,
                style: TextStyle(
                  fontSize: _captionSize,
                  color: _captionTextColor,
                ),
                maxLines: 5, 
                overflow: TextOverflow.ellipsis, 
              ),
            ),
            // child: TextField(
            //   readOnly: true,
            //   controller: _textController,
            //   style: TextStyle(
            //     //color: widget.themeProvider.themeData.textTheme.bodyMedium?.color,
            //     color: _captionTextColor, 
            //     fontSize: 20,
            //     //fontSize: _captionSize,
            //   ),
            //   decoration: const InputDecoration(
            //     hintText: "",
            //     border: InputBorder.none,
            //     fillColor: Colors.transparent,
            //     filled: true,
            //     contentPadding:
            //         EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            //   ),
            //   textAlignVertical: TextAlignVertical.center,
            //   maxLines: 5,
            //   keyboardType: TextInputType.multiline,
            // ),
          ),
          SizedBox(height: ResponsiveUtils.getResponsiveSize(context, 20)),
          BlocBuilder<AutoCaptionBloc, AutoCaptionState>(
            builder: (context, state) {
              bool isEnabled = false;
              if (state is AutoCaptionLoadedSuccessState) {
                isEnabled = state.isEnabled;
              }

              return SwitchListTile(
                title: Text(
                  "Enable",
                  style: TextStyle(
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      20,
                    ),
                    fontFamily: Fonts.main,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                value: isEnabled,
                onChanged: (value) {
                  // Dispatch the ToggleAutoCaptionEvent with the new value
                  context
                      .read<AutoCaptionBloc>()
                      .add(ToggleAutoCaptionEvent(value));
                },
              );
            },
          ),
          //_buildSwitch(state),
          _buildSizeSlider(),
          _buildDropdown("Color", _captionTextColor, [
            DropdownMenuItem(value: Colors.white, child: Text("White")),
            DropdownMenuItem(value: Colors.black, child: Text("Black")),
            DropdownMenuItem(value: Colors.red, child: Text("Red")),
            DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
          ], _updateCaptionTextColor),
          _buildDropdown("Background", _captionBackgroundColor, [
            DropdownMenuItem(value: Colors.black, child: Text("Black")),
            DropdownMenuItem(value: Colors.white, child: Text("White")),
            DropdownMenuItem(value: Colors.grey, child: Text("Grey")),
            DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
          ], _updateCaptionBackgroundColor),
        ],
      ),
    );
  }

  Widget _buildSwitch(AutoCaptionLoadedSuccessState state) {
    bool isEnabled = state.isEnabled;

    return SwitchListTile(
      title: Text(
        "Enable",
        style: TextStyle(
          fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
          fontFamily: Fonts.main,
          fontWeight: FontWeight.w600,
        ),
      ),
      value: isEnabled,
      onChanged: (value) {
        context.read<AutoCaptionBloc>().add(ToggleAutoCaptionEvent(value));
      },
    );
  }

  Widget _buildSizeSlider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          margin: EdgeInsets.only(left: ResponsiveUtils.getResponsiveSize(context, 17)),
          child: Text(
            "Size",
            style: TextStyle(
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              fontFamily: Fonts.main,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: _captionSize,
            min: 20.0,
            max: 100.0,
            divisions: 13,
            label: "${_captionSize.round()}",
            onChanged: (value) {
              _updateCaptionSize(value);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String title, Color selectedValue, List<DropdownMenuItem<Color>> items, Function(Color) onChanged,) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: EdgeInsets.only(
                left: ResponsiveUtils.getResponsiveSize(context, 17)),
            child: Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context,20,),
                fontFamily: Fonts.main,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: DropdownButton<Color>(
                value: selectedValue,
                items: items,
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
