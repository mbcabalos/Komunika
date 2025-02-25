part of 'home_bloc.dart';

abstract class HomeEvent {}

class HomeLoadingEvent extends HomeEvent {}

class RequestPermissionEvent extends HomeEvent {}
class FetchAudioEvent extends HomeEvent {}
class PlayAudioEvent extends HomeEvent {
  final String audioName;

  PlayAudioEvent({required this.audioName});
}
