abstract class WalkthroughState {}

class WalkthroughInitialState extends WalkthroughState {}

class WalkthroughLoadingState extends WalkthroughState {}

class WalkthroughLoadedState extends WalkthroughState {}

class WalkthroughCompletedState extends WalkthroughState {}

class WalkthroughErrorState extends WalkthroughState {
  final String errorMessage;
  WalkthroughErrorState({required this.errorMessage});
}
