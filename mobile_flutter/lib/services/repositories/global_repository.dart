import 'package:flutter/material.dart';

abstract class GlobalRepository {
  Future<void> sendTextToSpeech(String text);
}