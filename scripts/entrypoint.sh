#!/bin/sh

set -e
cd ./project/
python manage.py collectstatic --no-input
python manage.py migrate
gunicorn project.wsgi:application --bind 0.0.0.0:8000

