# Aerostar Edge

Student career app (Flutter, mock-data prototype): internships and jobs, applications tracker,
Career Quiz, courses, resume builder, bookings and a profile, on phone, tablet and web.

## Run

```bash
flutter pub get
flutter run -d chrome
```

## Build for the web

```bash
flutter build web --release --no-tree-shake-icons --pwa-strategy=none
```

The GitHub Pages workflow in `.github/workflows/deploy.yml` builds and publishes this on every
push to `main`, with `--base-href /Aerostarplacementapp/`.

## Design system

Colours, type, spacing and shadows live in `lib/theme/`; the rules are in
`.cursor/rules/design-system.mdc`. Blue `#0A2FFF` is the interactive accent, yellow `#FFC72C` is the
call to action, and pages are white.
