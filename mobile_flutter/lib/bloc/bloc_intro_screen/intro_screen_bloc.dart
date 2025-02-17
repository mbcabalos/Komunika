// intro_screen_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'intro_screen_event.dart';
import 'intro_screen_state.dart';

class IntroScreenBloc extends Bloc<IntroScreenEvent, IntroScreenState> {
  IntroScreenBloc() : super(IntroInitial()) {
    on<CheckIntroStatus>(_onCheckIntroStatus);
    on<CompleteIntro>(_onCompleteIntro);
  }

  Future<void> _onCheckIntroStatus(
      CheckIntroStatus event, Emitter<IntroScreenState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isIntroSeen = prefs.getBool('isIntroSeen') ?? false;
    if (isIntroSeen) {
      emit(IntroCompleted());
    } else {
      emit(IntroShowing());
    }
  }

  Future<void> _onCompleteIntro(
      CompleteIntro event, Emitter<IntroScreenState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isIntroSeen', true);
    emit(IntroCompleted());
  }
}
