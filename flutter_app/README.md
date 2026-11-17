# Wearcast

Wearcast recommends outfits from the clothing catalog using local weather, then lets signed-in users save outfits and favorite individual pieces.

## Run locally

1. Start MongoDB and, from `backend`, copy `.env.example` to `.env`; set `MONGO_URI` and replace `JWT_SECRET` with a long, private value.
2. From `backend`, run `npm install`, then `npm run seed` and `npm start`. Rerun the seed command after catalog metadata changes; it updates matching items by image URL and preserves their IDs.
3. From `flutter_app`, run `flutter pub get` and `flutter run`.

The app currently defaults to `http://localhost:5000/api`. Override it for an emulator, phone, or hosted backend with:

```sh
flutter run --dart-define=WEARCAST_API_URL=http://YOUR_MACHINE_ADDRESS:5000/api
```

Use HTTPS for deployed environments. Weather is provided by Open-Meteo; city lookup and approximate location use public geocoding and IP location services.
