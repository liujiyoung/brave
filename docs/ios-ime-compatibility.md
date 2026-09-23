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

Full Brave build and integration verification remain pending while Chromium
and Brave dependencies are downloaded. These results do not validate the full
BrowserViewController or webpage integration.

The fixture `ios/brave-ios/Tests/ClientTests/Resources/html/ime-composition.html`
logs native composition/input/keyboard events for subsequent browser tests.
Check address-bar and webpage input in regular/private tabs, both orientations,
including candidate navigation, commit, cancel, backspace, focus changes and
language switching.
