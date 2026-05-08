# prime-billing-statusbar

A tiny [SwiftBar](https://swiftbar.app) plugin that shows your live
[Prime Intellect](https://www.primeintellect.ai) wallet balance in the macOS
menu bar. Refreshes every 5 seconds, click for an "open billing dashboard"
shortcut.

```
🦋 24.19    ← in your menu bar, next to Wi-Fi / clock / etc.
```

## Requirements

- macOS (Darwin)
- [SwiftBar](https://swiftbar.app) — `brew install --cask swiftbar`
- `bash`, `curl`, and `/usr/bin/python3` (all ship with macOS)
- A Prime Intellect API key

## Install

```bash
git clone https://github.com/<you>/prime-billing-statusbar.git
cd prime-billing-statusbar
./install.sh
```

The installer:

1. Copies the icon to `~/.config/prime-balance/assets/`.
2. Creates a placeholder API-key file at `~/.config/prime-balance/key` (mode 600).
3. Symlinks the plugin into `~/Library/Application Support/SwiftBar/Plugins/`.
4. Points SwiftBar's plugin folder at that directory and refreshes it.

Then paste your key into the file:

```bash
# replace the placeholder text with your real key
$EDITOR ~/.config/prime-balance/key
open "swiftbar://refreshallplugins"
```

## Where to get an API key

Generate one in your Prime Intellect dashboard
(Settings → API Keys → Create). The plugin only ever calls a single read-only
endpoint:

```
GET https://api.primeintellect.ai/api/v1/billing/wallet
Authorization: Bearer <key>
```

So a key with default permissions is enough; no write or admin scopes needed.

## Configuration

The plugin reads two things at runtime:

| Path                                                     | What it is                                          |
| -------------------------------------------------------- | --------------------------------------------------- |
| `~/.config/prime-balance/key`                            | Your API key (one line, no trailing newline).       |
| `~/.config/prime-balance/assets/prime-logo-template.png` | The menu-bar icon (alpha-only template, 144 DPI).   |

Both can be moved by setting `PRIME_CONFIG_DIR` before SwiftBar runs the
plugin (e.g. via SwiftBar's plugin-environment settings).

`PRIME_API_KEY` in the environment also overrides the key file if set.

### Refresh interval

The interval is encoded in the script's filename: `prime-balance.5s.sh` →
every 5 seconds. To change it, rename the symlink and the file:

```bash
mv prime-balance.5s.sh prime-balance.30s.sh
mv ~/Library/Application\ Support/SwiftBar/Plugins/prime-balance.{5s,30s}.sh
```

Supported suffixes: `Ns`, `Nm`, `Nh`, `Nd`. 5 s ≈ 17 k requests/day, which is
fine for normal use; bump it to `30s` or `1m` if you'd rather be gentler.

### Icon

The bundled icon is a SwiftBar `templateImage` derived from Prime Intellect's
own 256×256 favicon, downscaled to 58×37 px and tagged with 144 DPI so it
renders crisply at ~18 pt on Retina displays (and as plain text in dark mode
because templates inherit the menu-bar text color).

If you want to regenerate or resize it, `scripts/build-icon.sh` walks through
the pipeline (download → crop to logo bounding box → Lanczos downscale →
alpha-from-luminance → 144-DPI tag).

## Uninstall

```bash
rm "${HOME}/Library/Application Support/SwiftBar/Plugins/prime-balance.5s.sh"
rm -rf "${HOME}/.config/prime-balance"
open "swiftbar://refreshallplugins"
```

(Leaves SwiftBar itself and the cloned repo alone.)

## Troubleshooting

**"prime: no key" in the menu bar.** The key file is missing or unreadable.
Make sure `~/.config/prime-balance/key` exists with mode 600 and contains your
key.

**"prime: —" or "prime: ?".** Network or parse error. Click the menu-bar item
to see the raw response in the dropdown.

**Two `?` placeholders appear next to the icon.** SwiftBar is scanning a
folder that contains image files marked executable. Either move the assets
out of SwiftBar's plugin folder (the installer does this automatically) or
`chmod -x` them.

**Icon renders huge or blurry.** The PNG is missing its 144-DPI tag, so
NSImage treats it as @1x. Re-run `scripts/build-icon.sh` or apply the tag
manually:

```bash
sips -s dpiHeight 144 -s dpiWidth 144 assets/prime-logo-template.png
```

## How it works

Each refresh, the script:

1. Reads the key from `~/.config/prime-balance/key` (or `$PRIME_API_KEY`).
2. `GET`s `/api/v1/billing/wallet` with a 4-second timeout.
3. Parses `balance_usd` out of the JSON via stdlib Python.
4. Emits SwiftBar's two-section format: the menu-bar line (number + inline
   base64 `templateImage`), then `---`, then the dropdown menu.

That's the entire program — about 50 lines of bash.

## License

MIT — see [LICENSE](LICENSE).
