import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komunika/bloc/bloc_walkthrough/walkthrough_event.dart';
import 'package:komunika/bloc/bloc_walkthrough/walkthrough_state.dart';
import 'package:komunika/utils/shared_prefs.dart';

class WalkthroughBloc extends Bloc<WalkthroughEvent, WalkthroughState> {
  WalkthroughBloc() : super(WalkthroughInitialState());

  Stream<WalkthroughState> mapEventToState(WalkthroughEvent event) async* {
    if (event is LoadWalkthroughEvent) {
      yield* _mapLoadWalkthroughToState();
    } else if (event is CompleteWalkthroughEvent) {
      yield* _mapCompleteWalkthroughToState();
    }
  }

  Stream<WalkthroughState> _mapLoadWalkthroughToState() async* {
    yield WalkthroughLoadingState();
    final walkthroughCompleted = await PreferencesUtils.getWalkthrough();
    if (walkthroughCompleted == 'false') {
      yield WalkthroughLoadedState();
    } else {
      yield WalkthroughCompletedState();
    }
  }

  Stream<WalkthroughState> _mapCompleteWalkthroughToState() async* {
    yield WalkthroughCompletedState();
  }
}
