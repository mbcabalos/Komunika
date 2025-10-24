from flask import Flask, request, jsonify
from openai import OpenAI
import os
from pydub import AudioSegment
from tempfile import NamedTemporaryFile
from dotenv import load_dotenv
import io
import logging

# ensure ffmpeg on PATH (you already have ffmpeg installed)
os.environ["PATH"] += os.pathsep + r"C:\ffmpeg\bin"

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("whisper-server")

app = Flask(__name__)
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

@app.route("/transcribe", methods=["POST"])
def transcribe_audio():
    try:
        if "audio" not in request.files:
            return jsonify({"error": "No audio file uploaded"}), 400

        file_storage = request.files["audio"]
        raw = file_storage.read()
        if not raw or len(raw) < 100:
            return jsonify({"error": "Uploaded audio is empty or too short"}), 400

        # Try to load without ffmpeg first if it's a proper WAV (faster, avoids ffmpeg issues)
        audio = None
        try:
            audio = AudioSegment.from_file(io.BytesIO(raw))
        except Exception as e1:
            logger.debug("from_file failed, trying from_wav fallback: %s", e1)
            try:
                audio = AudioSegment.from_wav(io.BytesIO(raw))
            except Exception as e2:
                logger.exception("pydub failed to parse uploaded audio. Check file header and ffmpeg.")
                return jsonify({"error": "Uploaded audio could not be decoded. Ensure client sends a valid WAV with proper header."}), 400

        # Normalize: ensure 16kHz, mono, 16-bit
        try:
            audio = audio.set_frame_rate(16000).set_sample_width(2).set_channels(1)
        except Exception:
            # continue — some formats may already match
            pass

        # export to a temp WAV file for OpenAI client
        with NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
            tmp_path = tmp.name
            audio.export(tmp_path, format="wav")

        try:
            with open(tmp_path, "rb") as af:
                # Force Tagalog (Filipino) transcription only
                # OpenAI/whisper language codes: 'tl' (Tagalog). Ignoring any client-sent language.
                kwargs = {"model": "whisper-1", "file": af, "language": "tl"}
                transcript = client.audio.transcriptions.create(**kwargs)
        except Exception as e:
            logger.exception("OpenAI transcription request failed")
            return jsonify({"error": str(e)}), 500
        finally:
            try:
                os.remove(tmp_path)
            except Exception:
                pass

        # normalize response
        text = None
        try:
            text = transcript.text if hasattr(transcript, "text") else (transcript.get("text") if isinstance(transcript, dict) else None)
        except Exception:
            text = str(transcript)

        return jsonify({"text": text or ""}), 200

    except Exception as e:
        logger.exception("Unexpected error in /transcribe")
        return jsonify({"error": str(e)}), 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
