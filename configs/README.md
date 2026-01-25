# Browser Profile Configuration

This directory contains browser profile configuration that gets restored during browser installation.

## Files

- **chromium-bookmarks.json**: Default bookmarks in Chromium's JSON format
- **chromium-extensions.txt**: Extension manifest (ID, name, URL)

## Usage

### Exporting Your Current Profile

To save your current browser bookmarks and extensions:

```bash
# Auto-detect installed browser
./lib/export-chromium-profile.sh

# Or specify browser explicitly
./lib/export-chromium-profile.sh ~/.config/chromium
./lib/export-chromium-profile.sh ~/.config/google-chrome
./lib/export-chromium-profile.sh ~/.config/BraveSoftware/Brave-Browser
```

This exports:
- All your bookmarks to `chromium-bookmarks.json`
- List of installed extensions to `chromium-extensions.txt`

### Customizing Extensions

Edit `chromium-extensions.txt` to add or remove extensions:

```
# Format: extension_id | extension_name | chrome_web_store_url

eiaeiblijfjekdanodkjadfinkhbfgcd | NordPass Password Manager | https://chromewebstore.google.com/detail/nordpass%C2%AE-password-manage/eiaeiblijfjekdanodkjadfinkhbfgcd
cjpalhdlnbpafiamejdnhcphjbkeiagm | uBlock Origin | https://chromewebstore.google.com/detail/ublock-origin/cjpalhdlnbpafiamejdnhcphjbkeiagm
```

### Customizing Bookmarks

Edit `chromium-bookmarks.json` directly or use the export script to capture your current bookmarks.

The format is Chromium's standard bookmark JSON format:

```json
{
  "roots": {
    "bookmark_bar": {
      "children": [
        {
          "name": "GitHub",
          "type": "url",
          "url": "https://github.com"
        }
      ]
    }
  }
}
```

## Restoration Behavior

When you run browser installation scripts:

1. **Bookmarks**: Restored only if no bookmarks file exists (preserves user data)
2. **Extensions**: Browser opens with all extension pages for one-click installation
3. **Compatible Browsers**: Works with Chromium, Chrome, Brave, Edge, Vivaldi, etc.

## Privacy Note

- Bookmarks are stored in plain text JSON
- Only extension IDs are stored (not extension data or settings)
- No passwords, cookies, or browsing history are included
- Safe to commit to version control
