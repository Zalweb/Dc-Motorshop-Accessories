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
2. Under **Apple ID**, enter your personal Apple ID email address.
3. Click the **"Start"** button at the bottom.
4. If prompted, enter your Apple ID password (this is used solely by Apple servers to sign the binary with your free personal certificate).
5. Wait ~30–60 seconds. Sideloadly will output `Done.` and the **MoSPAMS** app icon will appear on your iPhone home screen!

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
