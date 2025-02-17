// intro_screen_event.dart
import 'package:equatable/equatable.dart';

abstract class IntroScreenEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckIntroStatus extends IntroScreenEvent {}

class CompleteIntro extends IntroScreenEvent {}
