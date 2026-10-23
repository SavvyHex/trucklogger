# Truck logger

Truck logger is a Flutter app for recording truck arrivals, the party receiving
the load, materials and quantities, ice weight, and a short truck video. The
current build is an Android-first working prototype with real camera features
and local sample data.

## What it can do

### Truck log

- Browse the daily truck list with plate number, party, time, driver, and upload
	status.
- Search by plate number or party name.
- Switch between Today, Yesterday, and a selected calendar date.
- See a compact notice when videos are still uploading.
- Open the pending uploads screen from that notice.
- Open a truck entry to view its details and material list.

### New truck entries

- Start a new entry from the Truck log screen.
- Enter or scan a plate number.
- Choose a party name.
- Add as many material rows as needed.
- Start new material rows with `Select Material` and choose from the available
	material list.
- Enter the number of boxes and ice weight.
- Add an optional note with a subtle placeholder.
- Record a truck video on a separate full-screen camera page.
- Save the entry and return to the log.

### Plate scanning

- Use the Android camera to scan a plate.
- Run on-device Latin text recognition with Google ML Kit.
- Restrict the high-quality OCR pass to the yellow guide area.
- Show a live yellow scan guide and a detected four-point outline when a valid
	plate-shaped text block is found.
- Follow plates viewed at an angle instead of forcing the outline into a fixed
	rectangle.
- Normalize common OCR output such as `gj-37-v-0562` to `GJ 37 V 0562`.
- Validate standard Indian registration formats and Bharat-series plates.
- Review, edit, retake, or manually type the detected plate before using it.

### Video recording

- Open a dedicated camera page from the truck entry form.
- Record video with microphone audio.
- Start in portrait mode and allow the camera to follow the phone into
	landscape orientation.
- Stop recording and return the captured file to the truck entry form.
- Retake a video before saving the entry.

### App information

The three-dot menu opens an App information page with the app name, icon,
version `0.0.1`, and a short description.

## Current scope

The app currently uses sample truck entries and in-memory form state. Firebase,
authentication, persistent local storage, real upload retries, and server-backed
reference data are not connected yet. The pending upload screen and statuses
are currently representative UI states rather than a live upload queue.

Camera, microphone, live OCR, and video recording require a physical Android
device. They are not fully testable in Flutter widget tests or on a simulator.

## Running the app

Install Flutter and the Android SDK, then run:

```bash
flutter pub get
flutter run
```

To see available devices:

```bash
flutter devices
```

For USB testing, enable **Developer options** and **USB debugging** on the
Android phone, connect it with a data cable, accept the debugging prompt, and
run `flutter devices` again. Start the app with the device ID if more than one
device is connected:

```bash
flutter run -d <device-id>
```

The Android app requests camera and microphone access when the relevant camera
flows are opened. Grant both permissions to test plate scanning and video
recording.

## Development checks

Run the test suite and analyzer before committing changes:

```bash
flutter test
flutter analyze
```

The tests cover plate normalization and validation, the main list, navigation,
date picker, app information, pending uploads, dynamic material rows, and the
dedicated recorder page. Physical-device testing is still needed for camera
permissions, OCR accuracy, orientation changes, and actual video capture.

## Main dependencies

- [`camera`](https://pub.dev/packages/camera) for Android preview, still capture,
	image streams, and video recording.
- [`google_mlkit_text_recognition`](https://pub.dev/packages/google_mlkit_text_recognition)
	for on-device plate text recognition.
- [`image`](https://pub.dev/packages/image) for cropping captured photos to the
	plate guide before the final OCR pass.
