#!/bin/bash

uv run python manage.py migrate --noinput
uv run python manage.py collectstatic --noinput

# Start your app (important: last process)
uv run gunicorn mysite.wsgi:application --bind 0.0.0.0:8000 &

# Keep container alive
wait