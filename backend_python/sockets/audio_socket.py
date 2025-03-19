import io
import wave
from flask import json
import numpy as np
import speech_recognition as sr
from flask_socketio import SocketIO
from vosk import Model, KaldiRecognizer

import time

socketio = SocketIO()
print("Hello")
from vosk import Model

# vosk_model_path = r"D:\VS Code for Flutter\Large Project\Komunika\backend_python\models\vosk-model-tl-ph-generic-0.6"
vosk_model_path = "models/vosk-model-tl-ph-generic-0.6"

try:
    model = Model(vosk_model_path)
    print("✅ Model loaded successfully!")
except Exception as e:
    print(f"❌ Model loading failed: {e}")


recognizer = sr.Recognizer()
audio_buffer = bytearray()  # ✅ Collect chunks in a buffer

def denoise_audio(raw_audio, sample_rate=16000):

    # Convert raw audio bytes to a numpy array
    audio_np = np.frombuffer(raw_audio, dtype=np.int16)

    # Apply noise reduction using noisereduce library
    cleaned_audio_np = nr.reduce_noise(y=audio_np, sr=sample_rate)

    # Convert cleaned audio numpy array back to bytes
    cleaned_audio = cleaned_audio_np.tobytes()

    return cleaned_audio

def register_transcription_events(socketio):
    @socketio.on("audio_stream")
    def handle_audio_stream(audio_data):
        global audio_buffer

        # Append new chunk
        audio_buffer.extend(audio_data)

        # ✅ Process every 3 seconds of audio
        if len(audio_buffer) >= 16000 * 2 * 3:  

            try:
                # Convert raw PCM to WAV
                wav_data = io.BytesIO()
                with wave.open(wav_data, "wb") as wav_file:
                    wav_file.setnchannels(1)
                    wav_file.setsampwidth(2)  
                    wav_file.setframerate(16000)  
                    wav_file.writeframes(bytes(audio_buffer))

                # Reset buffer
                audio_buffer = bytearray()

                # Seek to start
                wav_data.seek(0)

                # ✅ Transcribe using Vosk
                recognizer = KaldiRecognizer(model, 16000)
                text = ""

                with wave.open(wav_data, "rb") as wf:
                    while True:
                        data = wf.readframes(3000)
                        if len(data) == 0:
                            break
                        if recognizer.AcceptWaveform(data):
                            result = json.loads(recognizer.Result())
                            text += " " + result.get("text", "")

                # ✅ Get final text result
                final_result = json.loads(recognizer.FinalResult())
                text += " " + final_result.get("text", "")

                text = text.strip() if text.strip() else ""

                print(f"📝 Transcription: {text}")
                if text != "" and text != "":
                    socketio.emit("transcription_result", {"text": text})
                else:
                    print("Audio is empty or no speech detected")

            except Exception as e:
                print(f"❌ Error processing audio: {e}")
                socketio.emit("server_error", {"message": str(e)})


    @socketio.on("audio_upload")  
    def handle_audio_upload(audio_data):
        try:
            print("📥 Received audio file for transcription...")

            # Convert received bytes to a WAV file
            wav_data = io.BytesIO(audio_data)
            with wave.open(wav_data, "wb") as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)  
                wav_file.setframerate(16000)  
                wav_file.writeframes(audio_data)

            # Transcribe audio
            recognizer = KaldiRecognizer(model, 16000)
            text = ""

            wav_data.seek(0)  # Reset pointer
            with wave.open(wav_data, "rb") as wf:
                while True:
                    data = wf.readframes(3000)
                    if len(data) == 0:
                        break
                    if recognizer.AcceptWaveform(data):
                        result = json.loads(recognizer.Result())
                        text += " " + result.get("text", "")

            # Final transcription result
            final_result = json.loads(recognizer.FinalResult())
            text += " " + final_result.get("text", "")

            text = text.strip() if text.strip() else ""
            print(f"📝 Transcription: {text}")

            # Send result to frontend
            if text != "" and text != "":
                socketio.emit("transcription_result", {"text": text})
            else:
                print("Audio is empty or no speech detected")

        except Exception as e:
            print(f"❌ Error processing audio: {e}")
            socketio.emit("server_error", {"message": str(e)})

    @socketio.on("caption_stream")
    def handle_audio_stream(audio_data):
        global audio_buffer

        # Append new chunk
        audio_buffer.extend(audio_data)

        # Process every 3 seconds of audio (16-bit PCM, 16 kHz, mono)
        if len(audio_buffer) >= 16000 * 2 * 3:  # 3 seconds of audio
            try:
                # Convert raw PCM to WAV
                wav_data = io.BytesIO()
                with wave.open(wav_data, "wb") as wav_file:
                    wav_file.setnchannels(1)  # Mono
                    wav_file.setsampwidth(2)  # 16-bit
                    wav_file.setframerate(16000)  # 16 kHz
                    wav_file.writeframes(bytes(audio_buffer))

                # Reset buffer
                audio_buffer = bytearray()

                # Seek to start
                wav_data.seek(0)

                # Transcribe using Vosk
                recognizer = KaldiRecognizer(model, 16000)
                text = ""

                with wave.open(wav_data, "rb") as wf:
                    while True:
                        data = wf.readframes(3000)  # Read 3000 frames at a time
                        if len(data) == 0:
                            break
                        if recognizer.AcceptWaveform(data):
                            result = json.loads(recognizer.Result())
                            text += " " + result.get("text", "")

                # Get final text result
                final_result = json.loads(recognizer.FinalResult())
                text += " " + final_result.get("text", "")

                # Clean up the transcription
                text = text.strip() if text.strip() else ""

                print(f"📝 Transcription: {text}")
                if text != "" and text != "":
                    socketio.emit("caption_result", {"text": text})
                else:
                    print("Audio is empty or no speech detected")

            except Exception as e:
                print(f"❌ Error processing audio: {e}")
                socketio.emit("server_error", {"message": str(e)})