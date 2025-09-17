part of 'home_bloc.dart';

abstract class HomeState {}

final class HomeLoadingState extends HomeState {}

final class HomeSuccessLoadedState extends HomeState {}

final class HomeErrorState extends HomeState {
  final String message;

  HomeErrorState({required this.message});
}
