# NK Simulator

A tiny headless Android app for testing Notification Keeper end to end without a
second phone. It behaves like a messaging app: it posts MessagingStyle
conversation notifications — including **photo messages whose picture travels as
message data behind a content URI, the way WhatsApp and Telegram send them** — and
it can withdraw a notification the way "delete for everyone" does.

It is not part of the Flutter build and is never shipped.

## Build and install

```bash
cd tools/notification_simulator
echo "sdk.dir=C:/Users/<you>/AppData/Local/Android/Sdk" > local.properties
../../android/gradlew assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell pm grant com.example.nksim android.permission.POST_NOTIFICATIONS
```

Then enable **NK Simulator** in Notification Keeper → Apps.

## Drive it

```bash
# A photo message (what the photo vault must keep)
adb shell am start -n com.example.nksim/.MainActivity --es action photo --es sender "Ayşe"

# A photo message the sender deletes 3 seconds later (photo vault + Recall Radar)
adb shell am start -n com.example.nksim/.MainActivity --es action photo_unsend --ei delay_ms 3000

# A text message, and withdrawing notification 42
adb shell am start -n com.example.nksim/.MainActivity --es action text --es text "Merhaba"
adb shell am start -n com.example.nksim/.MainActivity --es action unsend --ei id 42
```

`adb logcat -s NKSimulator NotificationListener NotificationImageStore` shows both
sides: the simulator logs every `openFile` on its provider together with the
caller's uid, which is how you can see Notification Keeper read the photo.

## What a passing run proves, and what it does not

It proves the listener-side mechanism: Android grants a notification listener
temporary read access to a MessagingStyle message's data URI, Notification
Keeper copies the photo at post time, and the copy survives the notification
being withdrawn.

It does not prove that a given messaging app attaches the photo to every
notification. WhatsApp, for example, only can when the photo has already been
downloaded (media auto-download), and some apps never include media in
notifications at all.
