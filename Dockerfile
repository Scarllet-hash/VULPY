FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./
# Install dependencies into the image (avoid --user so packages are available on PATH)
RUN python -m pip install --no-cache-dir -r requirements.txt

COPY . .

WORKDIR /app/bad

RUN python db_init.py || true

EXPOSE 5000

CMD ["python", "-u", "vulpy.py"]