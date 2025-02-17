// intro_screen_state.dart
import 'package:equatable/equatable.dart';

abstract class IntroScreenState extends Equatable {
  @override
  List<Object?> get props => [];
}

class IntroInitial extends IntroScreenState {}

class IntroCompleted extends IntroScreenState {}

class IntroShowing extends IntroScreenState {}
