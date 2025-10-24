// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';

final DynamicLibrary speex = Platform.isAndroid
    ? DynamicLibrary.open('libspeexdsp.so')
    : throw UnsupportedError('Only supported on Android');

// ========== C Bindings ==========
typedef _PreprocessInitNative = Pointer<Void> Function(Int32, Int32);
typedef PreprocessInitDart = Pointer<Void> Function(int, int);

typedef _PreprocessRunNative = Int32 Function(Pointer<Void>, Pointer<Int16>);
typedef PreprocessRunDart = int Function(Pointer<Void>, Pointer<Int16>);

typedef _EchoInitNative = Pointer<Void> Function(Int32, Int32);
typedef EchoInitDart = Pointer<Void> Function(int, int);

typedef _EchoCancelNative = Void Function(
    Pointer<Void>, Pointer<Int16>, Pointer<Int16>, Pointer<Int16>);
typedef EchoCancelDart = void Function(
    Pointer<Void>, Pointer<Int16>, Pointer<Int16>, Pointer<Int16>);

typedef _DestroyFunc = Void Function(Pointer<Void>);
typedef DestroyDart = void Function(Pointer<Void>);

typedef _PreprocessCtlNative = Int32 Function(
    Pointer<Void>, Int32, Pointer<Void>);
typedef PreprocessCtlDart = int Function(Pointer<Void>, int, Pointer<Void>);

const int SPEEX_PREPROCESS_SET_DENOISE = 0;
const int SPEEX_PREPROCESS_SET_NOISE_SUPPRESS = 1;
const int SPEEX_PREPROCESS_SET_AGC = 2;
const int SPEEX_PREPROCESS_SET_AGC_LEVEL = 4;
const int SPEEX_PREPROCESS_SET_VAD = 3;
const int SPEEX_PREPROCESS_SET_PROB_START = 8;
const int SPEEX_PREPROCESS_SET_PROB_CONTINUE = 10;

// ========== Lookups ==========
final PreprocessCtlDart speexPreprocessCtl = speex
    .lookup<NativeFunction<_PreprocessCtlNative>>('speex_preprocess_ctl')
    .asFunction();

final PreprocessInitDart speexPreprocessInit = speex
    .lookup<NativeFunction<_PreprocessInitNative>>(
        'speex_preprocess_state_init')
    .asFunction();

final PreprocessRunDart speexPreprocessRun = speex
    .lookup<NativeFunction<_PreprocessRunNative>>('speex_preprocess_run')
    .asFunction();

final EchoInitDart speexEchoInit = speex
    .lookup<NativeFunction<_EchoInitNative>>('speex_echo_state_init')
    .asFunction();

final EchoCancelDart speexEchoCancel = speex
    .lookup<NativeFunction<_EchoCancelNative>>('speex_echo_cancellation')
    .asFunction();

final DestroyDart speexPreprocessDestroy = speex
    .lookup<NativeFunction<_DestroyFunc>>('speex_preprocess_state_destroy')
    .asFunction();

final DestroyDart speexEchoDestroy = speex
    .lookup<NativeFunction<_DestroyFunc>>('speex_echo_state_destroy')
    .asFunction();
