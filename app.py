from flask import Flask, request, jsonify
from flask_cors import CORS  
import torch
from PIL import Image
import io

app = Flask(__name__)
CORS(app)  


model = torch.hub.load(
    "ultralytics/yolov5", 
    "custom", 
    path=r"yolov5\runs\train\exp2\weights\best.pt"
)


@app.route("/predict", methods=["POST"])
def predict():
    if "image" not in request.files:
        return jsonify({"error": "No image file"}), 400

    image_file = request.files["image"]
    image_bytes = image_file.read()

    try:
        
        img = Image.open(io.BytesIO(image_bytes))

        
        results = model(img)

        
        predictions = results.pandas().xywh[0].to_dict(orient="records")
        return jsonify({"message": "Prediction successful", "predictions": predictions})
    except Exception as e:
        return jsonify({"error": f"Error processing image: {str(e)}"}), 500


if __name__ == "__main__":
    app.run(debug=True)
