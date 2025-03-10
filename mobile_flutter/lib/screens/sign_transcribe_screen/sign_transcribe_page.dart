import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sign_transcriber/sign_transcriber_bloc.dart';
import 'dart:math' as math;

import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class SignTranscriberPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SignTranscriberBloc signTranscriberBloc;

  const SignTranscriberPage(
      {super.key,
      required this.themeProvider,
      required this.signTranscriberBloc});
  @override
  State<SignTranscriberPage> createState() => _SignTranscriberPageState();
}

class _SignTranscriberPageState extends State<SignTranscriberPage> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    context.read<SignTranscriberBloc>().close();
  }

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  Future<void> _initialize() async {
    widget.signTranscriberBloc.add(SignTranscriberLoadingEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.signTranscriberBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBarWidget(
          title: "Sign Transcriber",
          titleSize: 20,
          themeProvider: widget.themeProvider,
          isBackButton: true,
          isSettingButton: false,
          isHistoryButton: true,
          database: 'sign_trancriber',
        ),
        body: BlocBuilder<SignTranscriberBloc, SignTranscriberState>(
          buildWhen: (previous, current) =>
              current is SignTranscriberLoadedState,
          builder: (context, state) {
            if (state is SignTranscriberLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SignTranscriberLoadedState) {
              return _buildCameraView(state.cameraController);
            } else if (state is SignTranscriberErrorState) {
              return Center(
                  child: Text('Failed to load camera: ${state.message}'));
            } else {
              return const Center(child: Text('Initializing...'));
            }
          },
        ),
      ),
    );
  }

  Widget _buildCameraView(CameraController cameraController) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.themeProvider.themeData.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(math.pi / 2)
                      ..rotateY(cameraController.description.lensDirection ==
                              CameraLensDirection.front
                          ? math.pi
                          : 0),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: CameraPreview(cameraController),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.switch_camera, color: Colors.white),
                  onPressed: () {
                    widget.signTranscriberBloc.add(SwitchCamera());
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        BlocBuilder<SignTranscriberBloc, SignTranscriberState>(
          buildWhen: (previous, current) {
            if (previous is SignTranscriberLoadedState &&
                current is SignTranscriberLoadedState) {
              return previous.translationText != current.translationText;
            }
            return false;
          },
          builder: (context, state) {
            if (state is SignTranscriberLoadedState) {
              _textController.text += state.translationText;
              _textController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _textController.text.length));
              return _buildTextDisplay();
            }
            return const Center(
                child: Text("Translated text will appear here..."));
          },
        ),
      ],
    );
  }

// ✅ Extracted Widget for Text Display
  Widget _buildTextDisplay() {
    return Container(
      height: 130,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.themeProvider.themeData.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: TextField(
          controller: _textController,
          readOnly: true,
          style: TextStyle(
            fontSize: 14,
            color: widget.themeProvider.themeData.textTheme.bodyMedium?.color,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: "Translated text will appear here...",
          ),
        ),
      ),
    );
  }
}
