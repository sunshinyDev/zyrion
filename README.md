# StreamHub 🎬

Modern mobile streaming app built with Flutter + Firebase.

## Features

- 🔐 **Firebase Auth** — Email/password login with auto-login via `authStateChanges`
- 🏠 **Home** — Featured carousel, Live TV, Movies, Series, Kids sections
- 📺 **Live TV** — Channel grid with category filters
- 🎬 **VOD** — Movies & Series tabs with poster grid
- ⚽ **Sports** — Live match banner + sport categories
- 👤 **Account** — Profile, subscription, preferences, logout
- 🔍 **Search** — Real-time content search
- ▶️ **Player** — Video player with Chewie controls (landscape mode)
- ⚙️ **Remote Config** — Dynamic server URLs without app updates
- 🔥 **Firestore** — Content metadata stored and streamed in real-time

## Setup

### 1. Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Enable **Authentication** → Email/Password
4. Enable **Firestore Database**
5. Enable **Remote Config**

### 2. Add Firebase to Flutter

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (run from project root)
flutterfire configure
```

This generates `lib/firebase_options.dart` automatically.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run

```bash
flutter run
```

## Firestore Data Structure

```
/content/{id}
  title: string
  description: string
  posterUrl: string
  backdropUrl: string
  logoUrl: string
  streamUrl: string
  type: "movie" | "series" | "liveChannel" | "sport"
  categories: string[]
  genres: string[]
  rating: number
  year: number
  duration: string
  isLive: boolean
  isFeatured: boolean
  isNew: boolean
  episodeCount: number (series only)
  seasonCount: number (series only)
  createdAt: timestamp
```

## Remote Config Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `api_base_url` | string | `https://api.streamhub.com/v1` | API base URL |
| `stream_base_url` | string | `https://stream.streamhub.com` | Stream server URL |
| `enable_sports` | bool | `true` | Show sports section |
| `enable_kids` | bool | `true` | Show kids section |
| `enable_downloads` | bool | `false` | Enable offline downloads |
| `maintenance_mode` | bool | `false` | Show maintenance screen |
| `featured_banner_enabled` | bool | `true` | Show home carousel |

## Architecture

```
lib/
├── main.dart
├── firebase_options.dart
├── core/
│   ├── models/          # ContentModel, etc.
│   ├── providers/       # Auth providers (Riverpod)
│   ├── router/          # GoRouter with auth redirect
│   ├── services/        # Firestore, Remote Config
│   ├── theme/           # AppTheme, AppColors
│   └── widgets/         # Shared UI components
└── features/
    ├── auth/            # Login, Splash
    ├── home/            # Home page
    ├── live_tv/         # Live TV page
    ├── vod/             # VOD + Content detail
    ├── sports/          # Sports page
    ├── account/         # Account/profile
    ├── search/          # Search page
    └── player/          # Video player
```

## Color Palette

| Token | Hex | Usage |
|-------|-----|-------|
| Background | `#0A0A0F` | Main background |
| Surface | `#12121A` | Cards, nav bar |
| Primary | `#3D8EFF` | Buttons, active states |
| Accent | `#00D4FF` | Highlights, glow |
| Live | `#FF3D3D` | Live TV badge |
| Text Primary | `#FFFFFF` | Headings |
| Text Secondary | `#B0B0C8` | Body text |
