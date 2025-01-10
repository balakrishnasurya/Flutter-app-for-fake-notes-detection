import matplotlib
matplotlib.use('Agg')

from flask import Flask, request, jsonify
import pandas as pd
import numpy as np
import base64
import io
from PIL import Image
import cv2
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, confusion_matrix
from scipy.stats import kurtosis, skew, entropy
import matplotlib.pyplot as plt
# Make sure the model is globally accessible
global clf
global scaler

app = Flask(__name__)

# Test route to verify API is working
@app.route("/", methods=["GET"])
def home():
    return jsonify({
        "message": "Currency Authentication API is running",
        "status": "success"
    })

# Test route for API health check
@app.route("/api/health", methods=["GET"])
def health_check():
    return jsonify({
        "status": "healthy",
        "message": "API is running normally"
    })

# Load and preprocess the dataset
data = pd.read_csv('banknote_authentication.txt', header=None)
data.columns = ['var', 'skew', 'curt', 'entr', 'auth']
data = data.sample(frac=1, random_state=42).sort_values(by='auth')
target_count = data.auth.value_counts()
nb_to_delete = target_count[0] - target_count[1]
data = data[nb_to_delete:]

x = data.loc[:, data.columns != 'auth']
y = data.loc[:, data.columns == 'auth']
x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.2)


scaler = StandardScaler()
x_train = scaler.fit_transform(x_train)
x_test = scaler.transform(x_test)

clf = LogisticRegression(solver='lbfgs', random_state=42)
clf.fit(x_train, y_train.values.ravel())

# Evaluate the model
y_pred = clf.predict(x_test)
accuracy = accuracy_score(y_test, y_pred)

print(f"Model Accuracy: {accuracy * 100:.2f}%")

# After loading the dataset
print("Dataset shape:", data.shape)
print("Model accuracy:", accuracy * 100)



@app.route("/api/predict", methods=["POST"])
def predict():
    try:
        if 'image' not in request.files:
            return jsonify({
                'error': 'No image file provided'
            }), 400

        uploaded_file = request.files['image']
        if not uploaded_file.mimetype.startswith('image/'):
            return jsonify({
                'error': 'Invalid file type. Please upload an image file'
            }), 400

        # Add debug print statements
        print("File received:", uploaded_file.filename)
        
        # Read image using PIL first
        image = Image.open(uploaded_file)
        # Convert to RGB mode if not already
        image = image.convert('RGB')
        # Convert to numpy array
        img_array = np.array(image)
        print("Image shape:", img_array.shape)
        
        # Convert to grayscale if needed
        if len(img_array.shape) == 3:
            img_array = cv2.cvtColor(img_array, cv2.COLOR_RGB2GRAY)
        
        # Normalize the image
        norm_image = img_array.astype(np.float32) / 255.0
        print("Normalized image shape:", norm_image.shape)

        # Compute features
        var = np.var(norm_image)
        sk = skew(norm_image.ravel())
        kur = kurtosis(norm_image.ravel())
        ent = entropy(norm_image.ravel())
        print("Features computed:", var, sk, kur, ent)

        # Validate computed features
        if not np.isfinite(var) or not np.isfinite(sk) or not np.isfinite(kur) or not np.isfinite(ent):
            return jsonify({
                'error': 'Error: Computed features contain invalid values'
            }), 400

        # Scale features using the same scaler used during training
        features = np.array([[var, sk, kur, ent]])
        scaled_features = scaler.transform(features)

        # Predict using the trained model
        result = clf.predict(scaled_features)
        prediction = "Real Currency" if result[0] == 0 else "Fake Currency"

        # Generate edge image
        img_blur = cv2.GaussianBlur(img_array, (3, 3), 0)
        edge_img = cv2.Sobel(src=img_blur, ddepth=cv2.CV_64F, dx=1, dy=0, ksize=5)
        
        # Convert edge image to base64
        edge_img_normalized = cv2.normalize(edge_img, None, 0, 255, cv2.NORM_MINMAX).astype(np.uint8)
        _, buffer = cv2.imencode('.png', edge_img_normalized)
        edge_base64 = base64.b64encode(buffer).decode()

        return jsonify({
            'prediction': prediction,
            'features': {
                'variance': float(var),
                'skew': float(sk),
                'kurtosis': float(kur),
                'entropy': float(ent)
            },
            'edge_image': edge_base64,
            'success': True
        })

    except Exception as e:
        import traceback
        print("Error during processing:")
        print(traceback.format_exc())
        return jsonify({
            'error': f'An error occurred during processing: {str(e)}',
            'success': False
        }), 500

# Add CORS support
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE')
    return response

if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0", port=5000)
