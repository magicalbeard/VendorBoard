# VendorBoard

Fallout 76 map-screen board listing every player on the server and their vendor stock: level, name, estimated fast-travel cost and shop contents, with filter and sort presets, hotkeys and an in-game settings menu. HUD Mod Loader addon.

Nexus Mods: https://www.nexusmods.com/fallout76/mods/4436

## Requirements

- [HUD Mod Loader](https://www.nexusmods.com/fallout76/mods/3144)
- [xScal](https://www.nexusmods.com/fallout76/mods/4183) or [ZFE](https://www.nexusmods.com/fallout76/mods/4065) for the hotkeys (optional)

## Install

1. Copy `VendorBoard.ba2` into `Data` and add it to `sResourceArchive2List` in `Fallout76Custom.ini`.
2. Copy `VendorBoard.json` into `Data`. It is re-read every 10 seconds while the game runs.
3. Add a line `VendorBoard` to `Data\hudmodloader.ini` (`extras/hudmodloader.ini` is an example).

The comments in `Config/VendorBoard.json` describe every setting.

## Layout

- `VendorBoard/scripts/VendorBoard.as` - the mod (document class)
- `VendorBoard/scripts/Shared/`, `Mobile/`, `scaleform/` - Fallout 76 interface classes
- `VendorBoard/scripts/SharedHUDTools.as` - HUD Mod Loader menu bridge
- `VendorBoard/scripts/com/adobe/` - as3corelib JSON decoder
- `Config/VendorBoard.json` - shipped config; `extras/hudmodloader.ini` - example loader list
- `build.py`, `tools/ba2pack.py` - build

## Build

Java 11+ and the [Apache Flex SDK](https://flex.apache.org/) 4.16 with `playerglobal.swc` (Flash Player 32) at `<SDK>/frameworks/libs/player/32.0/`.

```
set FLEX_HOME=<SDK>
python build.py
```

Output: `dist/VendorBoard.ba2` and `dist/VendorBoard-<version>.zip`.

## Licence

GPL-3.0, see [LICENSE](LICENSE). Based on [HUD-PlayerList](https://github.com/MsZelia/HUD-PlayerList) by MsZelia (GPL-3.0). Third-party notices in [NOTICE.txt](NOTICE.txt).
