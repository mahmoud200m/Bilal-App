# Bilal

Always-on tablet display for prayer times.

## Features

- **Tablet-optimized** landscape layout with large, readable typography
- **100% Mawaqit-powered** — uses actual mosque schedules, not calculations
- **Full yearly calendar** fetched once, works fully offline
- **Always-on display** with AMOLED-friendly true black theme
- **Smart brightness** — dims at night, brightens during day
- **Athan alerts** with distinct Fajr athan, per-prayer toggle
- **Countdown timer** to the next prayer
- **Hijri date** display
- **Weekly auto-refresh** of prayer schedule

## Getting Started

1. Install [Flutter](https://flutter.dev/docs/get-started/install) (3.2+)
2. Clone this project
3. Run:
   ```bash
   flutter pub get
   flutter run
   ```
4. On first launch, search for your mosque and select it
5. The app fetches the full yearly prayer calendar and caches it locally

## Architecture

```
lib/
  main.dart                      — App entry point
  app.dart                       — Root widget, routing (onboarding vs dashboard)
  providers.dart                 — Riverpod providers for state management
  models/
    timing_type.dart             — Fajr/Sunrise/Dhuhr/Asr/Maghrib/Isha enum
    prayer_times.dart            — Daily prayer times model
    yearly_calendar.dart         — 12-month calendar from Mawaqit confData
    mosque_info.dart             — Mosque metadata
    hijri_date.dart              — Tabular Islamic calendar conversion
  data/
    mawaqit_client.dart          — Search API + confData HTML scraper
    prayer_repository.dart       — Caching, daily lookups, refresh logic
    hive_storage.dart            — Local persistence (Hive)
  services/
    athan_service.dart           — Athan playback and scheduling
    wakelock_service.dart        — Screen always-on + brightness control
    refresh_service.dart         — Background weekly calendar sync
  ui/
    screens/
      onboarding_screen.dart     — Mosque search & selection
      dashboard_screen.dart      — Main always-on display
    widgets/
      clock_widget.dart          — Digital clock + Hijri/Gregorian date
      prayer_list_widget.dart    — 6 timings with highlight
      countdown_widget.dart      — Next prayer countdown
      mosque_search.dart         — Search UI component
    overlays/
      settings_overlay.dart      — Settings bottom sheet
```

## Data Source

The app scrapes Mawaqit's `confData` from mosque pages to extract the full
yearly prayer calendar — the same data structure that powers the Mawaqit
website and apps. This gives the exact times that mosques actually use
(unified schedule, not astronomical calculations).

## Usage

- Tap the **gear icon** (top-left) to open settings
- Settings allow changing mosque, adjusting brightness, toggling athan per prayer
- The app auto-refreshes the calendar weekly
