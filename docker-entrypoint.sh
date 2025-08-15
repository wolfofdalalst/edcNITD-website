#!/bin/bash

# Exit on any error
set -e

echo "Starting Django application..."

# Change to the correct directory
cd /app/website

# Make migrations for all apps (as mentioned for older Django versions)
echo "Making migrations for all apps..."
for app in campus_ambassador EQuest esummit events forum innovationcell sotm sponsors team web_team; do
  echo "Making migrations for $app..."
  python manage.py makemigrations $app
done

# Run general makemigrations
echo "Running general makemigrations..."
python manage.py makemigrations

# Apply migrations
echo "Applying migrations..."
python manage.py migrate --run-syncdb

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Start the Django server
if [ "$DJANGO_ENV" = "production" ]; then
  echo "Starting Gunicorn server..."
  exec gunicorn website.wsgi:application --bind 0.0.0.0:8000 
else
  echo "Starting Django development server..."
  exec python manage.py runserver 0.0.0.0:8000
fi