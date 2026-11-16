# Icons

Source artwork:

| File | Icon | Source | License |
|---|---|---|---|
| `blocked.svg` | lock | [Tabler Icons](https://tabler.io/icons) (outline) | MIT, see [`LICENSE-tabler.txt`](LICENSE-tabler.txt) |
| `error.svg` | alert-triangle | [Tabler Icons](https://tabler.io/icons) (outline) | MIT, see [`LICENSE-tabler.txt`](LICENSE-tabler.txt) |
| `awake.svg` | coffee cup | [SVG Repo](https://www.svgrepo.com) | **TODO: confirm the license and add the required attribution** |
| `sleep.svg` | zzz | [SVG Repo](https://www.svgrepo.com) | **TODO: confirm the license and add the required attribution** |
| `awake-menubar.svg` | coffee | [Tabler Icons](https://tabler.io/icons) (outline) | MIT, see [`LICENSE-tabler.txt`](LICENSE-tabler.txt) |
| `sleep-menubar.svg` | zzz | [Tabler Icons](https://tabler.io/icons) (outline) | MIT, see [`LICENSE-tabler.txt`](LICENSE-tabler.txt) |

The `-menubar` variants are simpler outline drawings used only for the 18 pt menu-bar icon, where fine detail (the
cup's saucer) does not stay crisp. The panel hero and the app icon use `awake.svg` and `sleep.svg`.

`Menubar/*.png` are generated monochrome template images (18 pt, @1x and @2x) used by the app; `Panel/*-large.png` are
the same artwork at 48 pt, shown in the panel's hero circle:

```bash
swift scripts/make-icons.swift Resources/Icons
```

The script removes background rectangles and forces black fill/stroke, so macOS can tint the icons for light/dark mode.
The app icon (`Resources/AppIcon.icns`) is rendered from the same SVGs by `swift scripts/make-app-icon.swift Resources`.
