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
        body: BlocConsumer<SignTranscriberBloc, SignTranscriberState>(
          listener: (context, state) {
            if (state is SignTranscriberErrorState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is SignTranscriberLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is SignTranscriberLoadedState) {
              return _buildContent(state);
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

  Widget _buildContent(state) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Stack(
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
                      ..rotateY(
                          state.cameraController.description.lensDirection ==
                                  CameraLensDirection.front
                              ? math.pi
                              : 0),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: CameraPreview(state.cameraController),
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
                    context.read<SignTranscriberBloc>().add(SwitchCamera());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BlocBuilder<SignTranscriberBloc, SignTranscriberState>(
            builder: (context, state) {
              String message = "Translated message will appear here...";
              if (state is TranscriptionInProgress) {
                message = state.message;
              }

              return Container(
                height: 130,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.themeProvider.themeData.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget
                          .themeProvider.themeData.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.read<SignTranscriberBloc>().add(StartTranslation());
                },
                child: const Text("Start"),
              ),
              ElevatedButton(
                onPressed: () {
                  context.read<SignTranscriberBloc>().add(StopTranslation());
                },
                child: const Text("Stop"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
