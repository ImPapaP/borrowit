# BorrowIT

Student equipment borrowing app built with **Flutter** and **Firebase** (Authentication + Cloud Firestore).
Students browse school equipment, request to borrow it, attach a photo, and track their requests.
Photos are stored **on the student's device**, not in Firebase Storage.

The same code runs as a **phone app** (Android/iOS) and as a **website** hosted on Render.

---

## Features (mapped to the requirements)

| # | Requirement | How it's done | File |
|---|---|---|---|
| 1 | Registration / Login | Firebase Authentication (email + password), with forgot-password | `lib/screens/auth/` |
| 2 | Equipment list | Grid showing image, name, category, short description and availability | `equipment_list_view.dart` |
| 3 | Search equipment | Search box (name, category, description) plus category filter chips | `equipment_list_view.dart` |
| 4 | Equipment details | Picture, description, category, quantity, pick-up location, condition | `equipment_detail_screen.dart` |
| 5 | Borrow request | Equipment, date needed, return date, purpose, optional photo | `borrow_request_screen.dart` |
| 6 | My Requests | All active requests with status counts | `my_requests_view.dart` |
| 7 | Request status | Pending → Approved → Borrowed → Returned (plus Rejected), with a progress bar | `request_detail_screen.dart` |
| 8 | Borrowing history | Completed (returned) borrowings | `history_view.dart` |
| — | Camera / gallery | Attach a photo when submitting a request; saved on the phone | `local_image_service.dart` |
| — | Local notifications | Status-change alerts, automatic pick-up/return reminders, custom reminders | `notification_service.dart` |

Extras: cancel a request while it's Pending, live updates everywhere, dark mode, tap a notification to open the request.

---

# Website on Render (GitHub + Firebase)

Render builds the web version straight from this GitHub repo. Every commit to `main` rebuilds the
site, so you can edit files on GitHub and see the change live a few minutes later.

### A. Create the Firebase project (one time)

1. Go to https://console.firebase.google.com → **Create a project** (Google Analytics can be off).
2. **Build → Authentication → Get started → Email/Password → Enable → Save.**
3. **Build → Firestore Database → Create database** → pick a location (`asia-southeast1` is close
   to the Philippines) → **Start in test mode**.
4. **Project settings** (gear icon) → **General** → under *Your apps* click the **Web** icon `</>`
   → nickname `BorrowIT Web` → **Register app**. Leave "Firebase Hosting" unchecked.
5. Firebase shows a `firebaseConfig` block. Keep that page open.

No Storage bucket is needed, so the free **Spark** plan is enough.

### B. Connect the code to Firebase

1. In this repo on GitHub, open **`lib/firebase_options.dart`** → click the pencil (Edit).
2. Copy each value from Firebase's `firebaseConfig` into the matching line of the `web` section:

   | Firebase console (`firebaseConfig`) | `lib/firebase_options.dart` |
   |---|---|
   | `apiKey: "AIza…"` | `apiKey: 'AIza…',` |
   | `authDomain: "…firebaseapp.com"` | `authDomain: '…firebaseapp.com',` |
   | `projectId: "…"` | `projectId: '…',` |
   | `storageBucket: "…"` | `storageBucket: '…',` |
   | `messagingSenderId: "…"` | `messagingSenderId: '…',` |
   | `appId: "1:…:web:…"` | `appId: '1:…:web:…',` |

3. **Commit changes.** These values are meant to be public; your data is protected by the Firestore rules.

### C. Deploy on Render (one time)

1. Sign in at https://render.com with **GitHub**.
2. Open **https://render.com/deploy?repo=https://github.com/ImPapaP/borrowit**
   If Render can't see the repo, click **Configure GitHub** and give Render access to `borrowit`.
3. Click **Deploy Blueprint**. The first build takes about 5–10 minutes (it downloads Flutter).
4. Your site will be at **`https://borrowit.onrender.com`** (or a similar address Render shows you).

### D. Allow the website's address in Firebase

Firebase console → **Authentication → Settings → Authorized domains → Add domain** →
enter your Render address without `https://` (for example `borrowit.onrender.com`).

### E. Try it

Open the site → **Create one** to register → on the empty Equipment tab tap **Load sample equipment**.
Then publish the security rules (step 6 below) and change request statuses in Firestore (see *Demo*).

### Making live edits

* **On GitHub:** open any file → pencil icon → edit → **Commit changes**. Or press `.` on the repo
  page to open the full web editor (github.dev), edit several files, then commit from the
  Source Control tab.
* Render rebuilds automatically. Watch progress on your Render dashboard under **Events / Logs**.
  The new version is live about 3–8 minutes after the commit; refresh the page to see it.
* If a build fails, the previous version stays online. Open the failed deploy's log to see the error.
* For instant feedback while coding, run it on your computer with `flutter run -d chrome`
  (hot reload with `r`), then commit when you're happy.

### How the website differs from the phone app

| Feature | Phone app | Website |
|---|---|---|
| Attached photos | Saved as a file on the phone | Saved in that browser's storage (about 20–30 photos fit) |
| Status changes | Phone notification | Message at the bottom of the screen, with a **View** button |
| Reminders | Automatic + "Set a reminder" | Not available (button hidden) |
| Camera | Opens the camera | Opens the camera on phones; file picker on computers |

---

# Phone app setup

## 1. What you need

* **Flutter 3.38.1 or newer** — check with `flutter --version`, update with `flutter upgrade`
* **Android Studio** (for the Android SDK and an emulator) or a real Android phone with USB debugging
* **Node.js** (for the Firebase CLI) — https://nodejs.org
* A Google account for Firebase

---

## 2. Set up the project

Open a terminal **inside the `borrowit` folder** and run:

```bash
# 1. Create the android/ and ios/ folders (your existing code is not overwritten)
flutter create --project-name borrowit --org com.borrowit --platforms android,ios .

# 2. Apply the Android/iOS settings needed for notifications and the camera
dart run tool/setup_platforms.dart

# 3. Download packages
flutter pub get
```

If step 2 prints any warnings, follow **Manual platform setup** at the bottom of this file.

---

## 3. Create the Firebase project

Skip this if you already did step A for the website; use the same project.

1. Go to https://console.firebase.google.com → **Add project** (Google Analytics can be off).
2. **Build → Authentication → Get started → Email/Password → Enable → Save.**
3. **Build → Firestore Database → Create database.**
   * Pick a location (for the Philippines, `asia-southeast1` is close).
   * Choose **Start in test mode** for now. You'll lock it down in step 6.

No Storage bucket is needed, so the free **Spark** plan is enough.

---

## 4. Connect the app to Firebase

```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
flutterfire configure
```

Choose your project and select **android**, **web** (and **ios** if you need it).
This replaces `lib/firebase_options.dart` and adds `android/app/google-services.json`.
Keep **web** selected so the website keeps working after you commit the new file.

> If the terminal says `flutterfire` is not found, add the Dart global bin folder to your PATH:
> Windows: `%LOCALAPPDATA%\Pub\Cache\bin` · macOS/Linux: `$HOME/.pub-cache/bin`

---

## 5. Run it

```bash
flutter run
```

1. Tap **Create one** and register a student account.
2. The Equipment tab says **No equipment yet** → tap **Load sample equipment**.
   (It only works while Firestore is still in test mode.)
3. Allow notifications when Android asks.

---

## 6. Lock down the database

In the Firebase console: **Firestore Database → Rules**, replace everything with the contents of
[`firestore.rules`](firestore.rules), then **Publish**.

The rules let students:

* read the equipment list
* create requests only for themselves, always starting as `Pending`
* see only their own requests
* cancel (delete) their own request while it's `Pending`

Changing a request's status is not allowed from the app; staff do that in the Firebase console
(the console isn't limited by these rules).

---

## Demo: approving, lending and returning

The app is for students only, so staff change the status in the Firebase console:

1. **Firestore Database → `requests`** → open a request.
2. Edit the **`status`** field to `Approved`, `Borrowed`, `Returned` or `Rejected`.
3. Optional: add a **`remarks`** field (string), for example why it was rejected.

What the student sees:

* a notification ("Request approved", "Equipment borrowed", …) while the app is open,
  or the next time it's opened
* the status and progress bar update live in **My Requests**
* `Returned` requests move to **History**

### Reminders

* **Automatic:** 8:00 AM on the date needed (when Approved) and on the return date (when Borrowed).
* **Custom (good for a quick demo):** open a request → **Set a reminder** → pick a time 2 minutes ahead.

On Android 12+, reminders arrive at the exact minute only if **Alarms & reminders** is allowed for
BorrowIT. Tap **Make exact** on the message that appears, or allow it in the phone's app settings.
Otherwise Android may deliver it a few minutes late.

> Status notifications are created by the app itself (local notifications), so they appear while the
> app is running or the next time it opens. Instant notifications while the app is fully closed
> would need Firebase Cloud Messaging plus Cloud Functions, which require the paid Blaze plan.

---

## Where the images are stored

| Image | Location |
|---|---|
| Equipment pictures | Bundled inside the app: `assets/equipment/` |
| Photo attached to a request (phone app) | The **phone's storage**, in the app's private folder `request_images/` |
| Photo attached to a request (website) | That **browser's storage** on the student's device |

When a student attaches a photo:

1. `image_picker` opens the camera or gallery.
2. The photo is copied into the app's documents folder on the phone (`getApplicationDocumentsDirectory()`).
3. Only the **file name** is saved in Firestore (`imageFileName`), never the photo itself.
4. When the request is opened, the app rebuilds the path on the phone and shows the photo.

Things to know:

* The photo only exists on the phone that took it. Logging in on another phone shows
  "The photo isn't on this phone".
* Uninstalling the app or clearing its data deletes the photos.
* No storage permission is needed, because the app writes only to its own folder.
* Cancelling a request also deletes its photo.

**Why not Firebase Storage?** Since February 3, 2026, Cloud Storage for Firebase requires the
pay-as-you-go Blaze plan (a linked billing account), even for small projects. The project
requirements mention Firebase Storage, so confirm this change with your instructor.

---

## Adding or editing equipment

In **Firestore Database → `equipment`**, add a document with these fields:

| Field | Type | Example |
|---|---|---|
| `name` | string | `Laptop` |
| `description` | string | `14-inch laptop with charger` |
| `category` | string | `Computers` |
| `image` | string | `laptop.png` (a file in `assets/equipment/`) or a full `https://` image link |
| `quantityAvailable` | number | `5` |
| `quantityTotal` | number | `8` |
| `location` | string | `IT Office, Room 101` |
| `condition` | string | `Good` |

To use a new picture file, put it in `assets/equipment/` and rebuild the app.
Set `quantityAvailable` to `0` to show the item as **Unavailable**.

---

## Firestore data

```
users/{uid}
  name, studentId, email, createdAt

equipment/{equipmentId}
  name, description, category, image, quantityAvailable, quantityTotal, location, condition

requests/{requestId}
  userId, equipmentId, equipmentName, equipmentCategory, equipmentImage,
  dateNeeded (timestamp), returnDate (timestamp), purpose,
  status ("Pending" | "Approved" | "Borrowed" | "Returned" | "Rejected"),
  imageFileName (file name on the student's phone, or null),
  remarks (optional note from staff), createdAt
```

---

## Project structure

```
lib/
  main.dart                     Starts Firebase and notifications
  app.dart                      MaterialApp, login/home switching
  theme.dart                    Colors, status colors and icons
  firebase_options.dart         Replaced by `flutterfire configure`
  data/sample_equipment.dart    Sample catalog for "Load sample equipment"
  models/                       Equipment, BorrowRequest, RequestStatus
  services/
    auth_service.dart           Register, login, logout, password reset
    firestore_service.dart      Equipment and requests
    local_image_service.dart    Camera/gallery + saving photos on the device
    image_store_io.dart         ...as files on the phone (Android/iOS)
    image_store_web.dart        ...in browser storage (website)
    notification_service.dart   Local notifications and reminders
    request_watcher.dart        Turns status changes into notifications
  screens/
    auth/                       Login and registration
    home_screen.dart            Bottom tabs + account sheet
    equipment/                  List/search and details
    requests/                   Borrow form, My Requests, details, History
  widgets/                      Shared UI pieces
assets/equipment/               Equipment pictures
web/                            Website shell (index.html, icons)
firestore.rules                 Database security rules
render.yaml                     Render settings (static site, auto-deploy)
render-build.sh                 Downloads Flutter and builds the website on Render
tool/setup_platforms.dart       One-time Android/iOS setup script
```

---

## Manual platform setup

Only needed if `dart run tool/setup_platforms.dart` reported a problem.

**`android/app/build.gradle.kts`**

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        minSdk = 24
        multiDexEnabled = true
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**`android/app/src/main/AndroidManifest.xml`** — above `<application`:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

and inside `<application>`, before `</application>`:

```xml
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false"
    android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
        <action android:name="android.intent.action.QUICKBOOT_POWERON" />
        <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
    </intent-filter>
</receiver>
```

**iOS** — `ios/Runner/Info.plist` needs `NSCameraUsageDescription` and
`NSPhotoLibraryUsageDescription`. In `ios/Runner/AppDelegate.swift`, inside
`didFinishLaunchingWithOptions`, add:

```swift
UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| App shows **Firebase setup needed** | Website: paste the web config (step B). Phone: run `flutterfire configure` (step 4), then restart the app. |
| Render build fails | Open the deploy log on Render and copy the error lines near the end. |
| Website still shows the old version | Wait for the Render deploy to say **Live**, then refresh the page. |
| `The current Dart SDK version is …` / version solving failed | Run `flutter upgrade` (Flutter 3.38.1+ is required). |
| Build error mentioning desugaring, `minSdk` or Java version | Run `dart run tool/setup_platforms.dart` again, or do the manual setup above. |
| **Load sample equipment** fails with `PERMISSION_DENIED` | The rules from step 6 are already published. Temporarily switch Firestore back to test mode, load the samples, then publish `firestore.rules` again — or add equipment by hand. |
| `PERMISSION_DENIED` when submitting a request | Make sure the published rules are exactly `firestore.rules`. |
| No notifications | Allow notifications for BorrowIT in the phone's settings. |
| Reminder came late | Allow **Alarms & reminders** for BorrowIT (see Reminders above). |
