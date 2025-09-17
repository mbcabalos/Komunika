import 'dart:async';
import 'package:bloc/bloc.dart';
part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeLoadingState()) {
    on<HomeLoadingEvent>(homeLoadingEvent);
  }

  FutureOr<void> homeLoadingEvent(
      HomeLoadingEvent event, Emitter<HomeState> emit) async {
    // if (!status.isGranted) {
    //   PermissionStatus newStatus = await Permission.storage.request();
    //   if (!newStatus.isGranted) {
    //     emit(HomeErrorState(message: "Storage permission denied"));
    //     return;
    //   }
    // }

    try {
      emit(HomeSuccessLoadedState());
    } catch (e) {
      emit(HomeErrorState(message: '$e'));
    }
  }
}
