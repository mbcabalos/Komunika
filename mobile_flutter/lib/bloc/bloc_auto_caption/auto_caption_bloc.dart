import 'dart:async';

import 'package:bloc/bloc.dart';

part 'auto_caption_event.dart';
part 'auto_caption_state.dart';

class AutoCaptionBloc extends Bloc<AutoCaptionEvent, AutoCaptionState> {
  AutoCaptionBloc() : super(AutoCaptionLoadingState()) {
    on<AutoCaptionLoadingEvent>(autoCaptionLoadingEvent);
  }

  FutureOr<void> autoCaptionLoadingEvent(
      AutoCaptionLoadingEvent event, Emitter<AutoCaptionState> emit) async {
    emit(AutoCaptionLoadedSuccessState());
  }
}
