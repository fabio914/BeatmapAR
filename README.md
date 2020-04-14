![Blocks](Images/blocks.png)

# Beatmap AR

Beat Saber map (a.k.a beatmap) visualizer in AR for iOS.

## Requirements

- [Xcode 11.3.1](https://developer.apple.com/xcode/) or newer
- [Mint](https://github.com/yonaskolb/Mint) (optional)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) [2.15.1](https://github.com/yonaskolb/XcodeGen/releases/tag/2.15.1)
- [Carthage](https://github.com/Carthage/Carthage)
- [SwiftLint](https://github.com/realm/SwiftLint) (optional)

## Building

1. Run Carthage bootstrap to download and build the project dependencies

```shell
carthage bootstrap
```

2. Run XcodeGen to generate the Xcode project file:

```shell
xcodegen
```

3. Open the Xcode project:

```shell
open Beatmap.xcodeproj/
```

4. Set a "signing team" and create a new provisioning profile;

5. Build and run on an iOS device (**⌘ + R**).

## Contributors

[Fabio Dela Antonio](http://github.com/fabio914)

*This project isn't affiliated with Beat Games nor Beat Saber.*
