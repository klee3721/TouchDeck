# TouchDeck Beta QA Checklist

Use this checklist on a MacBook Pro with a physical Touch Bar.

## Build And Launch

- [ ] Run `scripts/package_app.sh`.
- [ ] Confirm `dist/TouchDeck.app` exists.
- [ ] Confirm `codesign --verify --deep --strict --verbose=2 dist/TouchDeck.app` passes.
- [ ] Open `dist/TouchDeck.app`.
- [ ] Confirm TouchDeck Studio appears.
- [ ] Confirm the menu bar item appears.
- [ ] Open the menu bar item and confirm Runtime status, Start Global Runtime, Stop Runtime, and Re-present Touch Bar are visible.
- [ ] Quit from the menu bar item.

## Onboarding

- [ ] Confirm the onboarding card appears on first launch.
- [ ] Confirm dismissing onboarding hides it.
- [ ] Confirm Permission Center is visible.
- [ ] Click Request Accessibility and confirm macOS shows or routes to the correct permission flow.
- [ ] Open Accessibility Settings from the Permission Center.

## Virtual Touch Bar Editor

- [ ] Drag a System button into the virtual Touch Bar.
- [ ] Drag an App Button into the virtual Touch Bar.
- [ ] Drag a Function Button into the virtual Touch Bar.
- [ ] Drag a Widget Button into the virtual Touch Bar.
- [ ] Reorder buttons inside the virtual Touch Bar.
- [ ] Drag a button into the remove zone.
- [ ] Resize a selected button to 1, 2, and 3 cells.
- [ ] Use Undo and Redo after add, move, resize, and delete.
- [ ] Save the profile.
- [ ] Reload the profile.

## Physical Touch Bar Runtime

- [ ] Confirm Runtime Status shows Global Active, or clearly explains Fallback/Unsupported.
- [ ] Open Compatibility Details and confirm macOS version, Mac model, Touch Bar status, DFRFoundation, System Tray API, System Modal API, and Accessibility status are visible.
- [ ] Confirm the physical Touch Bar shows the same layout as the virtual Touch Bar.
- [ ] Confirm changing layout in Studio updates the physical Touch Bar.
- [ ] Confirm widgets refresh on the physical Touch Bar.
- [ ] Confirm multi-cell buttons have the expected width.
- [ ] Confirm App Button icon uses the real app icon.
- [ ] Confirm App Button running/active indicators are understandable.
- [ ] Check Console for the TouchDeck process and confirm there are no AppKit Touch Bar `too large` or `not enough space` warnings after startup.

## Global Touch Bar Runtime

- [ ] Switch from TouchDeck to Finder and confirm TouchDeck layout remains on the physical Touch Bar.
- [ ] Switch from TouchDeck to Safari/Chrome and confirm TouchDeck layout remains on the physical Touch Bar.
- [ ] Switch from TouchDeck to Xcode/VS Code and confirm TouchDeck layout remains on the physical Touch Bar.
- [ ] Close the TouchDeck Studio window and confirm the menu bar runtime keeps the Touch Bar layout alive.
- [ ] Tap an App Button while another app is frontmost and confirm it launches/activates the configured app.
- [ ] Tap Copy/Paste while a text editor is frontmost and confirm the action affects the frontmost app, not TouchDeck Studio.
- [ ] Put the Mac to sleep, wake it, and confirm TouchDeck re-presents the global Touch Bar.
- [ ] Stop Runtime from Studio and confirm TouchDeck stops presenting the global Touch Bar.
- [ ] Start Runtime again and confirm the global Touch Bar returns.
- [ ] Stop Runtime from the menu bar item and confirm TouchDeck stops presenting the global Touch Bar.
- [ ] Start Global Runtime from the menu bar item and confirm the global Touch Bar returns.
- [ ] Click Re-present Touch Bar from the menu bar item and confirm the Touch Bar is restored if it was minimized or lost.

## App Button

- [ ] Choose an installed app in Inspector.
- [ ] Confirm the app icon updates in Studio.
- [ ] Tap App Button when the app is closed; it should launch.
- [ ] Tap App Button when the app is open; it should activate.
- [ ] Switch apps and confirm running/active state updates.

## Function Button

- [ ] Copy works in a text editor.
- [ ] Paste works in a text editor.
- [ ] Cut works in a text editor.
- [ ] Undo works in a text editor.
- [ ] Redo works in a text editor.
- [ ] Open URL opens the configured URL.
- [ ] Run Shell runs the configured command.
- [ ] Run AppleScript runs the configured script.

## System Button

- [ ] Escape works.
- [ ] Volume Up works.
- [ ] Volume Down works.
- [ ] Mute works.
- [ ] Brightness Up works, if supported by the machine.
- [ ] Brightness Down works, if supported by the machine.
- [ ] Play/Pause works.
- [ ] Next Track works.
- [ ] Previous Track works.
- [ ] Mission Control works after Accessibility permission is granted.
- [ ] Screenshot works after Accessibility permission is granted.
- [ ] Lock Screen works.

## Widgets

- [ ] RAM widget shows a percentage.
- [ ] SSD widget shows a percentage.
- [ ] Battery widget shows status on a MacBook.
- [ ] Clock widget updates.
- [ ] Weather widget shows current temperature for a configured location.
- [ ] Weather widget handles network failure without crashing.

## Profiles

- [ ] Create a default profile.
- [ ] Create an app-specific profile.
- [ ] Switch to another app and confirm TouchDeck selects the app-specific profile while that app remains frontmost.
- [ ] Switch to an app without a profile and confirm TouchDeck returns to the default profile while that app remains frontmost.
- [ ] Export profiles.
- [ ] Import profiles.
- [ ] Save imported profiles.

## Launch At Login

- [ ] Toggle Launch at Login on from Studio.
- [ ] Confirm macOS shows the correct status.
- [ ] Log out and back in.
- [ ] Confirm TouchDeck launches.
- [ ] Toggle Launch at Login off.

## Distribution Smoke Test

- [ ] Zip `dist/TouchDeck.app`.
- [ ] Move the zip to a clean macOS user account.
- [ ] Unzip and open the app.
- [ ] Confirm Gatekeeper behavior is understood for the current signing mode.
- [ ] Repeat after Developer ID signing and notarization.
