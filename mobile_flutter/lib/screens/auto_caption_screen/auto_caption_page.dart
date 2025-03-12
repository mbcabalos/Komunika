import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_auto_caption/auto_caption_bloc.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/fonts.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class AutoCaptionScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  final AutoCaptionBloc autoCaptionBloc;
  const AutoCaptionScreen(
      {super.key, required this.themeProvider, required this.autoCaptionBloc});

  @override
  State<AutoCaptionScreen> createState() => _AutoCaptionScreenState();
}

class _AutoCaptionScreenState extends State<AutoCaptionScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.autoCaptionBloc.add(AutoCaptionLoadingEvent());
    widget.autoCaptionBloc.add(RequestPermissionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.autoCaptionBloc,
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
            color: widget.themeProvider.themeData.cardColor,
            child: TextField(
              readOnly: true,
              controller: _textController,
              style: TextStyle(
                color:
                    widget.themeProvider.themeData.textTheme.bodyMedium?.color,
                fontSize: 20,
              ),
              decoration: const InputDecoration(
                hintText: "",
                border: InputBorder.none,
                fillColor: Colors.transparent,
                filled: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
              textAlignVertical: TextAlignVertical.center,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
            ),
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
                  widget.autoCaptionBloc.add(ToggleAutoCaptionEvent(value));
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
