import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sign_transcriber/sign_transcriber_bloc.dart';
import 'package:komunika/services/repositories/database_helper.dart';
import 'package:komunika/utils/app_localization_translate.dart';
import 'package:komunika/utils/responsive.dart';
import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/history.dart';

class SignTranscriberPage extends StatefulWidget {
  final ThemeProvider themeProvider;
  final SignTranscriberBloc signTranscriberBloc;

  const SignTranscriberPage({
    super.key,
    required this.themeProvider,
    required this.signTranscriberBloc,
  });

  @override
  State<SignTranscriberPage> createState() => _SignTranscriberPageState();
}

class _SignTranscriberPageState extends State<SignTranscriberPage>
    with WidgetsBindingObserver {
  final TextEditingController _textController = TextEditingController();
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.signTranscriberBloc.add(SignTranscriberLoadingEvent());
  }

  @override
  void dispose() {
    widget.signTranscriberBloc.add(StopTranslationEvent());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.signTranscriberBloc.add(StopTranslationEvent());
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    widget.signTranscriberBloc.add(SignTranscriberLoadingEvent());
    widget.signTranscriberBloc.add(RequestPermissionEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.signTranscriberBloc,
      child: Scaffold(
        backgroundColor: widget.themeProvider.themeData.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(top: 7.0),
            child: Text(
              context.translate("sign_transcribe_title"),
              style: TextStyle(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
              ),
            ),
          ),
          leading: Padding(
            padding: EdgeInsets.only(
              top: ResponsiveUtils.getResponsiveSize(context, 7),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: ResponsiveUtils.getResponsiveSize(context, 10),
              ),
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  dbHelper.saveSignTranscriberHistory(_textController.text);
                }
                _textController.clear();
                Navigator.pop(context);
              },
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(
                top: ResponsiveUtils.getResponsiveSize(context, 7),
                right: ResponsiveUtils.getResponsiveSize(context, 8),
              ),
              child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HistoryPage(
                          themeProvider: widget.themeProvider,
                          database: 'sign_transcriber',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history_rounded)),
            ),
          ],
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
                    widget.signTranscriberBloc.add(SwitchCameraEvent());
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
