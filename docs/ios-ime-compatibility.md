# iPadOS 26 IME compatibility

Based on Brave Core 1.93.x, commit `5cf096d98914bd8a542eb8a0b1e46f39e14b1ad1`
(1.93.138).

## Changes

- Enable `UIDesignRequiresCompatibility` in the main app Info.plist to request
  the compatibility appearance, including the hardware-keyboard candidate UI.
- Avoid processing uncommitted marked text in debounced address-bar searches.
- Preserve IME arrow, Escape and Return behavior during composition.
- Resume search when composition ends, including commits without editingChanged.
- Avoid rebuilding the webpage keyboard assistant during composition and avoid
  duplicate custom search button groups.

## Validation

Xcode 27.0 (27A266a) built an isolated UIKit host using the production
AutocompleteTextField implementation. Brave-only services unrelated to text
composition were substituted in this host; it is not the full Brave browser.

The five AutocompleteTextFieldCompositionTests use UIKit marked-text APIs.
The unchanged upstream control failed four tests (eight assertions); the patched
control passed all five, including after the compatibility flag was enabled.
Simulator: iPadOS 26.5, iPad Pro 11-inch (M5).

After enabling the compatibility flag, the tester confirmed the expected
candidate appearance and normal input in the simulator and on a physical
iPad Pro 11-inch (3rd generation), iPadOS 26.7, using a hardware keyboard.
This is manual confirmation, not a quantitative latency benchmark.

The full BraveCore and Client app now build with Xcode 27 and launch on the
iPadOS 26.5 simulator. All five AutocompleteTextFieldCompositionTests also pass
in the full Brave test target (zero failures or skipped tests). The full device
app also builds and is installed on the iPad Pro 11-inch (3rd generation),
iPadOS 26.7. Its process remains running after launch. Interactive input checks
in the full browser remain for the tester.
These automated tests do not measure candidate-panel latency or validate
webpage keyboard-assistant integration.

The fixture `ios/brave-ios/Tests/ClientTests/Resources/html/ime-composition.html`
logs native composition/input/keyboard events for subsequent browser tests.
Check address-bar and webpage input in regular/private tabs, both orientations,
including candidate navigation, commit, cancel, backspace, focus changes and
language switching.

## Local Xcode 27 build

The pinned LLVM linker cannot read the Xcode 27 SDK's `arm64e.x1` TAPI targets.
Use `--gn use_lld:false` for local builds. The macOS host-toolchain patch lets
this existing GN option apply to iOS build tools as well. Cargo's host linker
also honors this choice, with symbol stripping disabled for its release tools
to avoid [Rust issue 157750](https://github.com/rust-lang/rust/issues/157750).

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  npm run build -- Debug --target_os ios --target_arch arm64 \
  --target_environment simulator --gn use_lld:false
```

Also put `use_lld = false` after the generated import in
`src/out/ios_Debug_arm64_simulator/args.gn`, so Xcode's pre-action preserves it.
Use `device` instead of `simulator` for an iPad build, with the corresponding
`src/out/ios_Debug_arm64/args.gn` override. The default hermetic-linker setting
is unchanged when this option is not supplied.

The Xcode scheme pre-action preserves `DEVELOPER_DIR`. The intents plugin
resolves `intentbuilderc` through SwiftPM's tool search paths, allowing builds
when the system-wide `xcode-select` still points to Command Line Tools.

Build the simulator Client with `CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-`.
Disabling signing entirely also removes its simulated application-group
entitlements and causes startup to abort in
`CredentialProviderSharedArchivableStoreURL()`. With ad-hoc signing enabled,
the full app reaches the first-run onboarding screen.

## Physical-device development install

The local device build uses a separate bundle identifier and the developer's
paid team. Its provisioning profile expires on September 24, 2027. The local
signing entitlements omit `com.apple.developer.carplay-audio`, which is not
approved for this team. The production entitlements remain unchanged; this
development install does not provide CarPlay audio integration.
