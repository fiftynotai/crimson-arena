# Crimson Arena

AI Engineering Dashboard for [Igris AI](https://github.com/fiftynotai/igris-ai).

A Flutter web dashboard that visualizes agent metrics, battle logs, brain health, and session tracking for Igris AI-managed projects.

## Structure

```
crimson-arena/       # Flutter web app (Dart)
server.py            # FastAPI backend (Python)
test_server.py       # Server tests
requirements.txt     # Python dependencies
static/              # Vanilla JS fallback
```

## Setup

### Server

```bash
pip install -r requirements.txt
python server.py
```

### Flutter App

```bash
cd crimson-arena
flutter pub get
flutter build web --release
```

## License

MIT
