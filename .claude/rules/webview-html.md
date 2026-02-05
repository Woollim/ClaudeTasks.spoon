# WebView HTML Generation

When generating `onclick` attributes in `hs.webview` HTML:
- Use **single-quoted** HTML attributes (`onclick='...'`) to avoid conflicts with JSON double quotes
- `utils.jsonEncodeString()` returns double-quoted JSON — these break `onclick="..."` delimiters
