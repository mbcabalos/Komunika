part of 'speech_to_text_bloc.dart';

abstract class SpeechToTextEvent {}
class SpeechToTextLoadingEvent extends SpeechToTextEvent {}

class CreateSpeechToTextEvent extends SpeechToTextEvent {}
