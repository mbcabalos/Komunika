import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_sign_transcriber/sign_transcriber_bloc.dart';
import 'dart:math' as math;

import 'package:komunika/utils/themes.dart';
import 'package:komunika/widgets/global_widgets/app_bar.dart';

class SignTranscriberPage extends StatelessWidget {
  final ThemeProvider themeProvider;
  const SignTranscriberPage({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SignTranscriberBloc()..add(InitializeCamera()),
      child: Scaffold(
        appBar: const AppBarWidget(
          title: "Sign Transcriber",
          titleSize: 20,
          isBackButton: true,
          isSettingButton: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              BlocBuilder<SignTranscriberBloc, SignTranscriberState>(
                builder: (context, state) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 400,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: themeProvider.themeData.cardColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: state is CameraInitialized
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..rotateZ(math.pi / 2)
                                    ..rotateY(state.cameraController.description
                                                .lensDirection ==
                                            CameraLensDirection.front
                                        ? math.pi
                                        : 0),
                                  child: AspectRatio(
                                    aspectRatio: 9 / 16,
                                    child:
                                        CameraPreview(state.cameraController),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text("Live video feed",
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black54))),
                      ),
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: IconButton(
                          icon: const Icon(Icons.switch_camera,
                              color: Colors.white),
                          onPressed: () => context
                              .read<SignTranscriberBloc>()
                              .add(SwitchCamera()),
                        ),
                      ),
                    ],
                  );
                },
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
                        color: themeProvider.themeData.cardColor,
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                        child: Text(message,
                            style: TextStyle(
                                fontSize: 14,
                                color: themeProvider
                                    .themeData.textTheme.bodyMedium?.color))),
                  );
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => context
                        .read<SignTranscriberBloc>()
                        .add(StartTranslation()),
                    child: const Text("Start"),
                  ),
                  ElevatedButton(
                    onPressed: () => context
                        .read<SignTranscriberBloc>()
                        .add(StopTranslation()),
                    child: const Text("Stop"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
