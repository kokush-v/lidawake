# Icons

`awake.svg`, `sleep.svg`, `blocked.svg`, `error.svg` are the source artwork (downloaded from SVG Repo).
`Menubar/*.png` are generated monochrome template images (18 pt, @1x and @2x) used by the app; `Panel/*-large.png` are the same artwork at 48 pt, shown in the panel's hero circle:

```bash
swift scripts/make-icons.swift Resources/Icons
```

The script removes background rectangles and forces black fill, so macOS can tint the icons for light/dark mode.

License: each icon has its own license on its SVG Repo page. TODO: confirm the license of each icon and add the
required attribution here before distributing the app.
