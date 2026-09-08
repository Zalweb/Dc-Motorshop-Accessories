# iOS Installation Guide (iPhone 13 — No Mac, 100% Free)

This guide explains how to install **DC Motorcycle Inventory (MoSPAMS)** onto an **iPhone 13** from a **Windows PC** without owning a Mac and without paying for an Apple Developer account ($0).

---

## Prerequisites
1. **Windows PC** connected to the internet.
2. **iPhone 13** with Lightning USB cable.
3. A free, personal **Apple ID** (your standard iCloud email/account).
4. iTunes or iCloud for Windows installed (required by Windows to recognize iOS devices). If not installed, Sideloadly can automatically install the drivers.

---

## Step 1: Download the MoSPAMS iOS IPA File
Download the compiled `MoSPAMS.ipa` file:
* **Direct Download**: Available from the latest GitHub Release under [Releases](https://github.com/Zalweb/Dc-Motorshop-Accessories/releases/tag/v1.2.0) or from the GitHub Actions build artifacts.

---

## Step 2: Install Sideloadly on Windows
**Sideloadly** is the industry-standard free sideloading tool for Windows.
1. Download Sideloadly for Windows (64-bit): **https://sideloadly.io/**
2. Run the installer and launch Sideloadly.

---

## Step 3: Connect Your iPhone 13 to Windows PC
1. Connect your iPhone 13 to your computer using your USB cable.
2. Unlock your iPhone. If prompted with **"Trust This Computer?"**, tap **Trust** and enter your iPhone passcode.
3. In Sideloadly, you should see your iPhone 13 listed under **Connected Device**.

---

## Step 4: Sign and Install the App
1. Drag and drop the downloaded `MoSPAMS.ipa` file into the large **IPA icon** area on Sideloadly.
2. Under **Apple account**, enter your personal Apple ID email address (e.g. `yourname@icloud.com` or `yourname@gmail.com`).
   > ⚠️ **CRITICAL**: Do NOT leave the Apple account field blank, and do NOT use "Normal Install" or "Ad-hoc sign" mode. Sideloadly MUST be in **"Apple ID Sideload"** mode so it signs the app with your personal developer certificate.
3. Click **"Advanced Options"** in Sideloadly:
   - Ensure **Signing Mode** is set to **"Apple ID Sideload"**.
   - Check **"Change bundle ID"** and set it to: `com.zalweb.dcmotorshop` (or any custom identifier). *This prevents bundle ID conflicts with Apple's free developer provisioning service.*
   - Ensure **"Try unhiding app"** is checked.
4. Click the **"Start"** button at the bottom.
5. If prompted, enter your Apple ID password and 2-Factor Authentication (2FA) code sent to your iPhone.
6. Wait ~30–60 seconds as Sideloadly signs each framework and uploads the app. When it displays `Done.`, the **MoSPAMS** app icon will appear on your iPhone home screen!

---

## Step 5: Trust the Developer Certificate on iPhone
Before opening the app for the first time, iOS requires you to trust your own Apple ID certificate:
1. On your iPhone 13, open **Settings**.
2. Go to **General** $\rightarrow$ **VPN & Device Management**.
3. Under *Developer App*, tap your **Apple ID email**.
4. Tap **Trust "[your email]"**, then tap **Trust** again to confirm.

---

## Step 6: Enable Developer Mode (iOS 16, 17, and 18)
Apple requires Developer Mode enabled for sideloaded apps on iOS 16 and newer:
1. Open **Settings** on your iPhone.
2. Go to **Privacy & Security**.
3. Scroll all the way to the bottom and tap **Developer Mode**.
4. Toggle the switch to **On**.
5. Tap **Restart** when prompted.
6. After your iPhone reboots, unlock it and tap **Turn On** on the popup, then enter your passcode.

---

## 🎉 Done!
Open **MoSPAMS** on your iPhone 13. You have full native access to:
* Offline Isar database
* Camera barcode scanner
* Real-time Supabase cloud sync
* Sales & Inventory management

---

### Note on Free Apple ID (7-Day Renewal):
* Apple allows free personal Apple IDs to run sideloaded apps for **7 days**.
* **Automatic Renewal**: When your iPhone 13 is on the same Wi-Fi network as your PC with Sideloadly running in the background, Sideloadly will automatically refresh the app wirelessly before it expires.
* Alternatively, for an un-expiring setup that requires zero cables, remember that **Safari $\rightarrow$ Add to Home Screen** from `https://dcmotorshop.mospams.shop` runs in full-screen standalone mode and never expires.

---

## 🛠️ Troubleshooting

### Error: `ApplicationVerificationFailed : 0xe800801c (No code signature found)`
If you see this error:
1. **Download the latest `MoSPAMS.ipa`**: The IPA has been updated with pre-initialized ad-hoc signatures and preserved framework symlinks.
2. **Verify Apple account**: Make sure you entered your personal Apple ID email under the **"Apple account"** field at the top of Sideloadly. Sideloadly requires this to fetch signing certificates from Apple.
3. **Set Signing Mode**: In Sideloadly's **Advanced Options**, verify that **Signing Mode** is set to **"Apple ID Sideload"** (not "Normal Install" or "Export").
4. **Change Bundle ID**: In **Advanced Options**, check **"Change bundle ID"** and enter `com.zalweb.dcmotorshop` to prevent conflicts with Apple's developer provisioning.
5. **Install Standalone iTunes/iCloud**: If Sideloadly cannot communicate with Apple drivers, install the standard desktop (non-Microsoft Store) versions of iTunes and iCloud for Windows.
