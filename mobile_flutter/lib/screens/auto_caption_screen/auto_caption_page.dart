import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_auto_caption/auto_caption_bloc.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/app_bar.dart';

class AutoCaptionScreen extends StatefulWidget {
  final ThemeProvider themeProvider;

  const AutoCaptionScreen({super.key, required this.themeProvider});

  @override
  State<AutoCaptionScreen> createState() => _AutoCaptionScreenState();
}

class _AutoCaptionScreenState extends State<AutoCaptionScreen> {
  late AutoCaptionBloc autoCaptionBloc;

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
          title: "Screen Caption",
          titleSize: 20,
          isBackButton: true,
          isSettingButton: false,
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEnableSwitch(state),
          const SizedBox(height: 20),
          _buildCaptionSizeSlider(state),
          const SizedBox(height: 20),
          _buildCaptionColorPicker(state),
          const SizedBox(height: 20),
          _buildBackgroundColorPicker(state),
        ],
      ),
    );
  }

  Widget _buildEnableSwitch(AutoCaptionLoadedSuccessState state) {
    return SwitchListTile(
      title: const Text("Enable"),
      value: true,
      onChanged: (value) {},
    );
  }

  Widget _buildCaptionSizeSlider(AutoCaptionLoadedSuccessState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Size"),
        Slider(
          value: 50.0,
          min: 50.0,
          max: 150.0,
          divisions: 10,
          label: "${25.round()}%",
          onChanged: (value) {},
        ),
      ],
    );
  }

  Widget _buildCaptionColorPicker(AutoCaptionLoadedSuccessState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Color"),
        DropdownButton<Color>(
          value: Colors.black,
          items: [
            DropdownMenuItem(value: Colors.white, child: Text("White")),
            DropdownMenuItem(value: Colors.black, child: Text("Black")),
            DropdownMenuItem(value: Colors.red, child: Text("Red")),
            DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
          ],
          onChanged: (value) {
            if (value != null) {}
          },
        ),
      ],
    );
  }

  Widget _buildBackgroundColorPicker(AutoCaptionLoadedSuccessState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Background"),
        DropdownButton<Color>(
          value: Colors.black,
          items: [
            DropdownMenuItem(value: Colors.black, child: Text("Black")),
            DropdownMenuItem(value: Colors.white, child: Text("White")),
            DropdownMenuItem(value: Colors.grey, child: Text("Grey")),
            DropdownMenuItem(value: Colors.blue, child: Text("Blue")),
          ],
          onChanged: (value) {
            if (value != null) {}
          },
        ),
      ],
    );
  }
}
