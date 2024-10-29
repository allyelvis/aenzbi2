#!/bin/bash

# Script Configuration
PROJECT_NAME="hotel_restaurant_management"
BACKEND_DIR="${PROJECT_NAME}_backend"
FRONTEND_DIR="${PROJECT_NAME}_frontend"
ANDROID_DIR="${PROJECT_NAME}_android"
DATABASE_NAME="pms_pos_db"
DJANGO_ADMIN_USER="admin"
DJANGO_ADMIN_EMAIL="admin@example.com"
DJANGO_ADMIN_PASSWORD="password"

echo "Starting setup for $PROJECT_NAME..."

# Update and install required packages
echo "Updating system and installing dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip python3-venv postgresql postgresql-contrib \
                    nodejs npm openjdk-11-jdk curl

# Step 1: Backend Setup
echo "Setting up Django backend in $BACKEND_DIR..."
mkdir $BACKEND_DIR && cd $BACKEND_DIR
python3 -m venv env
source env/bin/activate

# Install Django and Django REST Framework
pip install django djangorestframework psycopg2-binary

# Initialize Django project
django-admin startproject backend .
python manage.py startapp hotel_pms
python manage.py startapp restaurant_pos

# Configure PostgreSQL Database
echo "Creating PostgreSQL database..."
sudo -u postgres psql -c "CREATE DATABASE $DATABASE_NAME;"
sudo -u postgres psql -c "CREATE USER $USER WITH ENCRYPTED PASSWORD 'password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DATABASE_NAME TO $USER;"

# Configure Django settings for PostgreSQL
sed -i "s/'ENGINE': 'django.db.backends.sqlite3'/'ENGINE': 'django.db.backends.postgresql'/" backend/settings.py
sed -i "/'ENGINE': 'django.db.backends.postgresql'/a \
        'NAME': '$DATABASE_NAME', \
        'USER': '$USER', \
        'PASSWORD': 'password', \
        'HOST': 'localhost', \
        'PORT': '5432'," backend/settings.py
#!/bin/bash

# Project setup variables
PROJECT_ID="your-firebase-project-id"  # **Replace with your actual project ID**
REGION="us-central1"  # Firebase region

# Securely retrieve sensitive data from environment variables
GEMINI_API_KEY=$(echo $GEMINI_API_KEY_ENV_VAR)
FIREBASE_CONFIG=$(echo $FIREBASE_CONFIG_ENV_VAR)  # If needed

# Function to display an error message and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# --- Project Setup ---
# Check if Firebase CLI is installed, install if necessary
if ! command -v firebase &> /dev/null; then
  echo "Firebase CLI not found. Installing..."
  npm install

# Migrate database and create superuser
echo "Migrating database..."
python manage.py migrate
echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('$DJANGO_ADMIN_USER', '$DJANGO_ADMIN_EMAIL', '$DJANGO_ADMIN_PASSWORD')" | python manage.py shell

# Run server to test
echo "Testing Django server..."
python manage.py runserver &

# Deactivate virtual environment
deactivate
cd ..

# Step 2: Frontend Setup
echo "Setting up React frontend in $FRONTEND_DIR..."
mkdir $FRONTEND_DIR && cd $FRONTEND_DIR
npx create-react-app .

# Install necessary packages for API requests and state management
npm install axios redux react-redux

# Set up example components and Redux structure
cat <<EOT > src/components/RoomManagement.js
import React, { useEffect, useState } from 'react';
import axios from 'axios';

const RoomManagement = () => {
  const [rooms, setRooms] = useState([]);

  useEffect(() => {
    axios.get('http://localhost:8000/api/hotel/rooms')
      .then(response => setRooms(response.data))
      .catch(error => console.error(error));
  }, []);

  return (
    <div>
      <h2>Room Management</h2>
      <ul>
        {rooms.map(room => (
          <li key={room.id}>{room.name} - {room.room_type}</li>
        ))}
      </ul>
    </div>
  );
};

export default RoomManagement;
EOT

# Run frontend to test
echo "Starting React app..."
npm start &

cd ..

# Step 3: Android App Setup
echo "Setting up Android app in $ANDROID_DIR..."
mkdir $ANDROID_DIR && cd $ANDROID_DIR

# Flutter initialization (if using Flutter)
flutter create .

# Update Android SDK path if necessary
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Create API Service example for Kotlin (replace with Flutter code if using Flutter)
mkdir -p app/src/main/java/com/example/$PROJECT_NAME/network/
cat <<EOT > app/src/main/java/com/example/$PROJECT_NAME/network/ApiService.kt
package com.example.$PROJECT_NAME.network

import retrofit2.Call
import retrofit2.http.GET

interface ApiService {
    @GET("api/hotel/rooms")
    fun getRooms(): Call<List<Room>>
}
EOT

# Build Android app
echo "Building Android app..."
./gradlew build

# Open Android Studio
echo "Opening Android Studio..."
studio .

# Step 4: Finishing Up
echo "Project setup complete! Here is the summary:"
echo "Backend: Django REST API with PostgreSQL, running on http://localhost:8000/"
echo "Frontend: React app, running on http://localhost:3000/"
echo "Android: Android app project at $ANDROID_DIR/"

# Kill Django server and React app processes after setup
trap 'kill $(jobs -p)' EXIT
