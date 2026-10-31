# VendorBoard

Fallout 76 map-screen board listing every player on the server and their vendor stock: level, name, estimated fast-travel cost and shop contents, with filter and sort presets, hotkeys and an in-game settings menu. HUD Mod Loader addon.

Nexus Mods: https://www.nexusmods.com/fallout76/mods/4436

## Requirements

- [HUD Mod Loader](https://www.nexusmods.com/fallout76/mods/3144)
- [xScal](https://www.nexusmods.com/fallout76/mods/4183) or [ZFE](https://www.nexusmods.com/fallout76/mods/4065) for the hotkeys (optional)

## Install

1. Copy `VendorBoard.ba2` into `Data` and add it to `sResourceArchive2List` in `Fallout76Custom.ini`.
2. Add a line `VendorBoard` to `Data\hudmodloader.ini` (`extras/hudmodloader.example.ini` is an example).

Settings live in `Data\modsdata\vendorboard.json`, re-read every 10 seconds while the game runs. With xScal the file is created on first start (from an old `Data\VendorBoard.json` if there is one) and the in-game menu saves into it. ZFE only supports the older one-name form of that storage, so with ZFE the menu saves only when no other mod (such as Improved HUD) is using it, and the file is created on the first menu change; otherwise copy `modsdata\vendorboard.example.json` to `modsdata\vendorboard.json` to keep settings. The file is strict JSON; its `//` entries describe every setting.

## Layout

- `VendorBoard/scripts/VendorBoard.as` - the mod (document class)
- `VendorBoard/scripts/Shared/`, `Mobile/`, `scaleform/` - Fallout 76 interface classes
- `VendorBoard/scripts/SettingsJson.as` - settings file reader / writer
- `VendorBoard/scripts/SharedHUDTools.as` - HUD Mod Loader menu bridge
- `VendorBoard/scripts/com/adobe/` - as3corelib JSON decoder (used by the shared interface classes)
- `Config/vendorboard.json` - settings template: defaults, notes and layout, compiled into the SWF and shipped as `modsdata/vendorboard.example.json`
- `extras/hudmodloader.example.ini` - example loader list
- `build.py`, `tools/ba2pack.py` - build

## Build

Java 11+ and the [Apache Flex SDK](https://flex.apache.org/) 4.16 with `playerglobal.swc` (Flash Player 32) at `<SDK>/frameworks/libs/player/32.0/`.

```
set FLEX_HOME=<SDK>
python build.py
```

Output: `dist/VendorBoard.ba2` and `dist/VendorBoard-<version>.zip`.

## License

GPL-3.0, see [LICENSE](LICENSE). Based on [HUD-PlayerList](https://github.com/MsZelia/HUD-PlayerList) by MsZelia (GPL-3.0). Third-party notices in [NOTICE.txt](NOTICE.txt).
