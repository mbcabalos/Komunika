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

  const AutoCaptionScreen({super.key, required this.themeProvider});

  @override
  State<AutoCaptionScreen> createState() => _AutoCaptionScreenState();
}

class _AutoCaptionScreenState extends State<AutoCaptionScreen> {
  late AutoCaptionBloc autoCaptionBloc;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    autoCaptionBloc = AutoCaptionBloc();
    autoCaptionBloc.add(AutoCaptionLoadingEvent());
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
                  context
                      .read<AutoCaptionBloc>()
                      .add(ToggleAutoCaptionEvent(value));
                },
              );
            },
          ),
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.start,
          //   children: [
          //     Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //       children: [
          //         Container(
          //           margin: EdgeInsets.only(
          //               left: ResponsiveUtils.getResponsiveSize(context, 17)),
          //           child: Text(
          //             "Size",
          //             style: TextStyle(
          //               fontSize: ResponsiveUtils.getResponsiveFontSize(
          //                 context,
          //                 20,
          //               ),
          //               fontFamily: Fonts.main,
          //               fontWeight: FontWeight.w600,
          //             ),
          //           ),
          //         ),
          //         Slider(
          //           value: 50.0,
          //           min: 50.0,
          //           max: 150.0,
          //           divisions: 10,
          //           label: "${25.round()}%",
          //           onChanged: (value) {},
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
          // _buildDropdown("Color", Colors.black, [
          //   DropdownMenuItem(value: Colors.white, child: Text("White")),
          //   DropdownMenuItem(value: Colors.black, child: Text("Black")),
          //   DropdownMenuItem(value: Colors.red, child: Text("Red")),
          //   DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
          // ]),
          // _buildDropdown("Background", Colors.black, [
          //   DropdownMenuItem(value: Colors.black, child: Text("Black")),
          //   DropdownMenuItem(value: Colors.white, child: Text("White")),
          //   DropdownMenuItem(value: Colors.grey, child: Text("Grey")),
          //   DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
          // ]),
        ],
      ),
    );
  }

  Widget _buildDropdown(
      String title, Color selectedValue, List<DropdownMenuItem<Color>> items) {
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
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  20,
                ),
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
                  if (value != null) {}
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
