from flask import Flask, jsonify
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError, ClientError

app = Flask(__name__)

# Set up AWS S3 client
s3 = boto3.client('s3')

# Specify your S3 bucket name
BUCKET_NAME = 'python-app-terraform'  # Replace with your actual bucket name

@app.route('/')
def home():
    return "Welcome to the S3 Bucket Content Viewer!"

@app.route('/list-bucket-content/', defaults={'path': ''})
@app.route('/list-bucket-content/<path:path>', methods=['GET'])
def list_bucket_content(path):
    path = path.strip('/')  # Normalize path to remove leading/trailing slashes

    try:
        # List objects in the S3 bucket with the provided path prefix
        response = s3.list_objects_v2(Bucket=BUCKET_NAME, Prefix=path)

        # Check if the S3 bucket exists
        if 'Error' in response:
            return jsonify({"error": "Bucket does not exist or there was an issue accessing it"}), 404

        content = []
        if 'Contents' in response:
            for obj in response['Contents']:
                content.append(obj['Key'][len(path):].split('/')[0])  # Extract first-level dirs/files

        # Handle case where no content is found for the given path
        if not content:
            return jsonify({"error": f"No content found for path '{path}'"}), 404

        return jsonify({"content": content}), 200

    except NoCredentialsError:
        return jsonify({"error": "AWS credentials are missing"}), 403
    except PartialCredentialsError:
        return jsonify({"error": "Incomplete AWS credentials"}), 403
    except ClientError as e:
        # This will catch errors like permission issues, bucket not found, etc.
        error_code = e.response['Error']['Code']
        if error_code == 'NoSuchBucket':
            return jsonify({"error": f"Bucket '{BUCKET_NAME}' does not exist"}), 404
        elif error_code == 'AccessDenied':
            return jsonify({"error": "Access denied to the S3 bucket"}), 403
        else:
            return jsonify({"error": f"Client error: {str(e)}"}), 400
    except Exception as e:
        return jsonify({"error": f"An unexpected error occurred: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8000)
