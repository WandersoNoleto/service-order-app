# App icon

| File | Use |
|---|---|
| `app_icon.svg` | Full icon (background + artwork). Source of truth. |
| `app_icon_foreground.svg` | Artwork only, transparent background (adaptive icon foreground and splash image). Keep in sync with the `foreground` group of `app_icon.svg`. |
| `*.png` | Generated from the SVGs, used by the generators below. |

Background color: `#508D6B` (also set in `flutter_launcher_icons.yaml` and `flutter_native_splash.yaml`).

## Regenerating

```bash
rsvg-convert -w 1024 -h 1024 assets/icon/app_icon.svg -o assets/icon/app_icon.png
rsvg-convert -w 1024 -h 1024 assets/icon/app_icon_foreground.svg -o assets/icon/app_icon_foreground.png
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`rsvg-convert` comes from the `librsvg2-bin` package.

## Client flavors

Each client keeps its own icon and splash in the private repo
(`clients/private/<client>/icon/`), with the generator configs symlinked
into the project root (`flutter_launcher_icons-<flavor>.yaml`,
`flutter_native_splash-<flavor>.yaml`, both git-ignored). Generated files go
to `android/app/src/<flavor>/res/` (git-ignored) and override the generic
ones only in that client's APK.
