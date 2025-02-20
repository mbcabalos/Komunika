import os
import gdown
import zipfile

# Replace with your actual ZIP file ID
FILE_ID = "1KBLLnzscTP1SjIZ5qmPFod7hVGQhbLiX"
OUTPUT_ZIP = "model.zip"
EXTRACT_PATH = "models/"

# Download the zip file
gdown.download(f"https://drive.google.com/uc?id={FILE_ID}", OUTPUT_ZIP, quiet=False)

# Extract the zip file
with zipfile.ZipFile(OUTPUT_ZIP, "r") as zip_ref:
    zip_ref.extractall(EXTRACT_PATH)

# Remove the zip file after extraction
os.remove(OUTPUT_ZIP)

print("Model folder downloaded and extracted successfully!")
