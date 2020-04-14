![AppIcon](Images/AppIcon.png)

# Beatmap AR

Beat Saber map (a.k.a beatmap) visualizer in AR for iOS.

## Requirements

- [Xcode 11.3.1](https://developer.apple.com/xcode/) or newer
- [Mint](https://github.com/yonaskolb/Mint) (optional)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) [2.15.1](https://github.com/yonaskolb/XcodeGen/releases/tag/2.15.1)
- [Carthage](https://github.com/Carthage/Carthage)
- [SwiftLint](https://github.com/realm/SwiftLint) (optional)

## Building

1. Clone this repository

```shell
git clone https://github.com/fabio914/BeatmapAR.git
cd BeatmapAR/
```

2. Run Carthage bootstrap to download and build the project dependencies

```shell
carthage bootstrap
```

3. Run XcodeGen to generate the Xcode project file:

```shell
xcodegen
```

4. Open the Xcode project:

```shell
open Beatmap.xcodeproj/
```

5. Set a "signing team" and create a new provisioning profile;

6. Build and run on an iOS device (**⌘ + R**).

## Contributors

[Fabio Dela Antonio](http://github.com/fabio914)

![Blocks](Images/blocks.png)

*This project isn't affiliated with Beat Games nor Beat Saber.*
