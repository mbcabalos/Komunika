import io
import wave
from flask import json
import speech_recognition as sr
from flask_socketio import SocketIO
from vosk import Model, KaldiRecognizer

socketio = SocketIO()
vosk_model_path = "models/vosk-model-tl-ph-generic-0.6"  # Path to the downloaded Vosk model
model = Model(vosk_model_path)

recognizer = sr.Recognizer()
audio_buffer = bytearray()  # ✅ Collect chunks in a buffer

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

                text = text.strip() if text.strip() else "[No speech detected]"

                print(f"📝 Transcription: {text}")
                if text != "" or text != "[No speech detected]":
                    socketio.emit("transcription_result", {"text": text})
                else:
                    print("Audio is empty")

            except Exception as e:
                print(f"❌ Error processing audio: {e}")
                socketio.emit("server_error", {"message": str(e)})