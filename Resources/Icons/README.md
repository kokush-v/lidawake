# Icons

`awake.svg` (coffee), `sleep.svg` (zzz), `blocked.svg` (lock) and `error.svg` (alert-triangle) are the source artwork:
outline icons from [Tabler Icons](https://tabler.io/icons), used under the MIT license (see
[`LICENSE-tabler.txt`](LICENSE-tabler.txt)).

`Menubar/*.png` are generated monochrome template images (18 pt, @1x and @2x) used by the app; `Panel/*-large.png` are
the same artwork at 48 pt, shown in the panel's hero circle:

```bash
swift scripts/make-icons.swift Resources/Icons
```

The script removes background rectangles and forces black fill/stroke, so macOS can tint the icons for light/dark mode.
The app icon (`Resources/AppIcon.icns`) is rendered from the same SVGs by `swift scripts/make-app-icon.swift Resources`.
