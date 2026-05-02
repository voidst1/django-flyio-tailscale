FROM python:3.14-slim

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy dependency files first (better caching)
COPY pyproject.toml uv.lock ./

# Install dependencies via uv
RUN uv sync --frozen --no-cache

# Copy project
COPY . .

# Expose port
EXPOSE 8000

# Start script
RUN chmod +x start.sh
CMD ["./start.sh"]