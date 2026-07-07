# TouchDeck Distribution Notes

## Local App Bundle

Build a local `.app` bundle:

```bash
scripts/package_app.sh
```

The script creates:

```text
dist/TouchDeck.app
```

It uses SwiftPM release output and copies it into a macOS app bundle with `Packaging/Info.plist`.

## Signing

For local development, the script attempts ad-hoc signing.

For distribution, provide a Developer ID identity:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/package_app.sh
```

## Notarization Checklist

1. Build with a Developer ID certificate.
2. Zip the app:

```bash
ditto -c -k --keepParent dist/TouchDeck.app dist/TouchDeck.zip
```

3. Submit with `notarytool`.
4. Staple the notarization ticket.
5. Test on a clean macOS user account.

## Touch Bar Hardware QA

Test on a MacBook Pro with Touch Bar:

- The app opens as a normal macOS app.
- The menu bar item appears.
- TouchDeck Studio opens.
- Runtime Status and Compatibility Details are visible.
- Virtual Touch Bar drag/drop works.
- The physical Touch Bar renders the active profile.
- The physical Touch Bar keeps rendering TouchDeck when Finder, Safari/Chrome, Xcode/VS Code, or another app is frontmost.
- Console logs do not show AppKit Touch Bar `too large` or `not enough space` warnings after global runtime starts.
- Closing TouchDeck Studio does not stop the menu bar runtime.
- App Button launches and activates apps.
- Function Buttons run copy/paste/open URL/shell/AppleScript.
- Widgets refresh on the physical Touch Bar.
- App-specific profiles switch when the frontmost app changes.

## Known Distribution Caveats

- Global Touch Bar behavior depends on private/undocumented macOS Touch Bar presentation APIs, similar to MTMR-style apps.
- Current implementation relies on the system modal Touch Bar selector with `placement = 1` so the layout replaces the full Touch Bar instead of being constrained to the Control Strip area.
- Global Touch Bar builds should be distributed directly with Developer ID signing and notarization; App Store review is not a realistic target while this mode depends on private API.
- macOS updates may break Global Touch Bar mode. The app must keep App-Active fallback and clear compatibility diagnostics.
- Accessibility permission is required for keyboard/system control actions.
- Automation permission is required for AppleScript actions that control other apps.
- Launch at Login requires running as a proper `.app` bundle.
