# Privacy Policy for DualShots

**Last updated:** August 23, 2026

**DualShots** ("we", "our", or "the App") is developed with privacy as a foundational principle. This Privacy Policy outlines our data handling practices and discloses how device permissions are utilized in accordance with Google Play Developer Program Policies.

---

## 1. Zero Data Collection & 100% On-Device Processing

DualShots is designed to function entirely offline on your device:
- **No Personal Data Collection:** We do not collect, transmit, store, or sell any personally identifiable information (PII), names, email addresses, device identifiers, or location data.
- **No Cloud Uploads:** All camera capture, Picture-in-Picture compositing, photo stitching, and EXIF tagging occur **100% locally** in background isolate threads on your phone.
- **No Facial Recognition or Biometrics:** The application does not perform biometric analysis, facial recognition, or facial geometry extraction.

---

## 2. Device Permissions and Usage

To provide dual-camera photography features, DualShots requests the following runtime permissions:

### A. Camera (`android.permission.CAMERA`)
- **Purpose:** To access front and rear camera sensors simultaneously (or sequentially on fallback devices) and display the live viewfinder stream.
- **Data handling:** Frame data is processed in volatile device memory (RAM) solely for rendering the viewfinder and generating the final combined photo. No live feeds or raw stream buffers are transmitted outside the device.

### B. Microphone / Audio (`android.permission.RECORD_AUDIO`)
- **Purpose:** Requested by underlying Android camera hardware subsystem APIs for audio sync during camera lifecycle initialization.
- **Data handling:** DualShots does not record, listen to, store, or transmit any audio data.

### C. Storage & Photos (`android.permission.READ_MEDIA_IMAGES` / `android.permission.WRITE_EXTERNAL_STORAGE`)
- **Purpose:** To save your composited Dual Shot photos directly to your device's local photo gallery under the dedicated album **"DualShots"**.
- **Data handling:** The application only writes newly created photos to public media storage. It does not scan, index, read, or upload your existing private photo library.

---

## 3. Third-Party Libraries & Analytics

- DualShots does **NOT** contain third-party tracking SDKs, telemetry libraries, advertising networks, or user profiling tools (e.g., Google Analytics for Firebase, Meta Audience Network, or Crashlytics).
- The App makes zero network connections during standard operation.

---

## 4. Children's Privacy (COPPA & Google Play Families Policy)

DualShots complies fully with the Children’s Online Privacy Protection Act (COPPA) and Google Play Families Policies. Because the App collects no data from any user, it does not knowingly collect personal information from children under the age of 13.

---

## 5. User Control & Data Retention

You retain full ownership and control over all photos created using DualShots. You may delete any saved photos at any time directly through your phone's native Gallery application or file manager.

---

## 6. Changes to this Privacy Policy

We may update this Privacy Policy periodically. Any changes will be reflected with a revised "Last updated" date at the top of this document.

---

## 7. Contact Us

If you have questions, feedback, or concerns regarding this Privacy Policy, please contact:

- **Email:** support@dualshots.app
- **Developer GitHub:** [https://github.com/lukcza/dual-shots](https://github.com/lukcza/dual-shots)
