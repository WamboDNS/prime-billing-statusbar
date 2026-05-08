# prime-billing-statusbar

A tiny [SwiftBar](https://swiftbar.app) plugin that shows your live
[PrimeIntellect](https://www.primeintellect.ai) wallet balance in the macOS
menu bar. Refreshes every 5 seconds, click for an "open billing dashboard"
shortcut.

![Live PrimeIntellect wallet balance in the macOS menu bar, next to weather, Bluetooth, Wi-Fi and the clock](assets/screenshot.png)

## Requirements

- macOS (Darwin)
- [SwiftBar](https://swiftbar.app) — `brew install --cask swiftbar`
- `bash`, `curl`, and `/usr/bin/python3`
- A PrimeIntellect API key with read-only 'billing' permission.

## Install

```bash
git clone https://github.com/WamboDNS/prime-billing-statusbar.git
cd prime-billing-statusbar
./install.sh
```

The installer:

1. Copies the icon to `~/.config/prime-balance/assets/`.
2. Creates a placeholder API-key file at `~/.config/prime-balance/key`.
3. Symlinks the plugin into `~/Library/Application Support/SwiftBar/Plugins/`.
4. Points SwiftBar's plugin folder at that directory and refreshes it.

Then paste your key into the file:

```bash
# replace the placeholder text with your real key
$EDITOR ~/.config/prime-balance/key
open "swiftbar://refreshallplugins"
```
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

The bundled icon is a SwiftBar `templateImage` derived from PrimeIntellect's
own 256×256 favicon, downscaled to 58×37 px and tagged with 144 DPI so it
renders crisply at ~18 pt on Retina displays (and as plain text in dark mode
because templates inherit the menu-bar text color).

If you want to regenerate or resize it, `scripts/build-icon.sh` walks through
the pipeline (download → crop to logo bounding box → Lanczos downscale →
alpha-from-luminance → 144-DPI tag).

## License

MIT — see [LICENSE](LICENSE).
