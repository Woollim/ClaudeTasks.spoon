# Hammerspoon

## WebView HTML Generation

When generating `onclick` attributes in `hs.webview` HTML:
- Use **single-quoted** HTML attributes (`onclick='...'`) to avoid conflicts with JSON double quotes
- If double-quoted attributes are unavoidable, escape `"` to `&quot;` before embedding JSON strings
- `utils.jsonEncodeString()` returns double-quoted JSON — these break `onclick="..."` delimiters
