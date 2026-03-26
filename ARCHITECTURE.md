# LecCheck - System Architecture & Developer Guide 🏗️

This document outlines the technical architecture of the application, servers, and deployment processes to facilitate future maintenance and updates.

## 🌟 System Architecture
The system is split into 3 distinct environments to allow full support for both Web and Mobile simultaneously, utilizing free services from Google and GitHub.

### 1. Client Side - Browser (Frontend Web)
* **Hosting:** GitHub Pages (Free, static site).
* **URL:** `https://emanuel4100.github.io/LecCheck/`
* **How it works:** The Flet engine compiles the Python code into WebAssembly alongside static HTML/JS files. There is no active Python server running in the background here!
* **Limitations:** WebAssembly in the browser does not support libraries like `requests` or `threading`. Therefore, saving data to Firebase is executed as natively as possible using `urllib`.

### 2. Server Side (Backend / Auth Server)
* **Hosting:** Google Cloud Run (Always Free tier, Docker container).
* **Server URL:** `https://leccheck-655164797100.europe-west1.run.app`
* **Role:** Primarily handles authentication (Google OAuth2). Since GitHub Pages is completely static, a real backend server is required to receive the callback from Google with the authorization code and securely exchange it for a token.
* **Environment Variables (Configured in Cloud Run):**
  - `GOOGLE_CLIENT_SECRET`: The Google Client Secret.
  - `REDIRECT_URL`: `https://leccheck-655164797100.europe-west1.run.app/oauth_callback`

### 3. Database
* **Service:** Firebase Realtime Database.
* **Role:** Stores users' schedules persistently under the path `/users/{user_id}/schedule.json`.

### 4. Client Side - Mobile (Android APK)
* A standalone Frontend application that communicates directly with Google services and Firebase.
* Performs network requests using `threading` to prevent freezing the User Interface (UI) during data synchronization.

---

## 🚀 Deployment & Updates Guide

### Updating the Website (GitHub Pages)
Whenever you make code changes and want to update the live website, run the following commands:
```bash
# 1. Compile the app to a static site
flet publish src/main.py --base-url /LecCheck/

# 2. Move the output files to the docs folder
rm -rf docs
mv src/dist docs

# 3. Prevent GitHub Pages from ignoring system files
touch docs/.nojekyll

# 4. Commit and push to GitHub
git add .
git commit -m "Update website deployment"
git push origin main