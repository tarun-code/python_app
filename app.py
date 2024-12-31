from flask import Flask, jsonify
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

app = Flask(__name__)

# Set up AWS S3 client
s3 = boto3.client('s3')

# Specify your S3 bucket name
BUCKET_NAME = 'python-app-terraform'  # Replace with your actual bucket name

@app.route('/list-bucket-content', defaults={'path': ''})
@app.route('/list-bucket-content/<path:path>', methods=['GET'])
def list_bucket_content(path):
    try:
        # List the objects in the bucket
        objects = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=path)
        
        # Extract the file and directory names
        content = []
        if 'Contents' in objects:
            for obj in objects['Contents']:
                content.append(obj['Key'][len(path):].split('/')[0])  # Extracting first-level directories/files

        return jsonify({"content": content}), 200

    except NoCredentialsError:
        return jsonify({"error": "AWS credentials are missing"}), 403
    except PartialCredentialsError:
        return jsonify({"error": "Incomplete AWS credentials"}), 403
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
