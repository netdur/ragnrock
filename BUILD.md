6) Running and debugging

Run in debug:

flutter run -d macos


Hot reload: press r in the terminal or click the hot-reload button in your IDE.

Build in profile/release to gauge performance:

flutter run -d macos --profile
flutter run -d macos --release

7) Build a release .app
flutter build macos --release
open build/macos/Build/Products/Release


You’ll see Ragnrock.app.

8) Code sign and notarize (to share safely)

If you plan to distribute outside your machine:

Get a Developer ID Application certificate in your Apple Developer account and install it in Keychain.

Sign the app (replace names with yours):

codesign --force --deep --options runtime \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  "build/macos/Build/Products/Release/Ragnrock.app"


Zip it:

cd build/macos/Build/Products/Release
zip -r Ragnrock.zip Ragnrock.app


Notarize (set up a keychain profile once via xcrun notarytool store-credentials):

xcrun notarytool submit Ragnrock.zip --keychain-profile "AC_NOTARY" --wait
xcrun stapler staple Ragnrock.app


Now you can share the .app (or create a DMG/PKG if you prefer).

To make a DMG quickly:

brew install create-dmg
create-dmg --overwrite --volname "Ragnrock" Ragnrock.dmg Ragnrock.app
