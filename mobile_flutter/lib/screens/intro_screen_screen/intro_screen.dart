// intro_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_intro_screen/intro_screen_bloc.dart';
import 'package:komunika/bloc/bloc_intro_screen/intro_screen_event.dart';
import 'package:komunika/bloc/bloc_intro_screen/intro_screen_state.dart';
import 'package:introduction_screen/introduction_screen.dart';

class IntroScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IntroScreenBloc()..add(CheckIntroStatus()),
      child: BlocListener<IntroScreenBloc, IntroScreenState>(
        listener: (context, state) {
          if (state is IntroCompleted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        child: BlocBuilder<IntroScreenBloc, IntroScreenState>(
          builder: (context, state) {
            if (state is IntroShowing) {
              return IntroductionScreen(
                pages: [
                  PageViewModel(
                    title: "Welcome",
                    body: "Discover the features of our app!",
                    image: Center(child: Icon(Icons.app_shortcut, size: 100)),
                  ),
                  PageViewModel(
                    title: "Get Started",
                    body: "Let's begin!",
                    image: Center(child: Icon(Icons.play_arrow, size: 100)),
                  ),
                ],
                onDone: () {
                  BlocProvider.of<IntroScreenBloc>(context).add(CompleteIntro());
                },
                showSkipButton: true,
                skip: Text("Skip"),
                next: Text("Next"),
                done: Text("Done"),
              );
            }
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        ),
      ),
    );
  }
}