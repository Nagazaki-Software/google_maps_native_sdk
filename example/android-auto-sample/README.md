Android Auto sample (reference only)

This folder contains a minimal reference for integrating a Car App (Android Auto) side-by-side with a Flutter app. Car apps use the `androidx.car.app` library and run as a separate service declared in the Android manifest. You typically create a new Android module (Java/Kotlin), add the car-app dependency, and register a `CarAppService` with templates.

High-level steps
- Create a new Android module `car-app` (Android Library) in the host app project.
- Add dependency: `implementation "androidx.car.app:app:1.3.0"` (or newer).
- Register service in `AndroidManifest.xml` of the `car-app` module:
  <service
    android:name=".AutoService"
    android:exported="true"
    android:enabled="true">
    <intent-filter>
      <action android:name="androidx.car.app.CarAppService" />
    </intent-filter>
    <meta-data
      android:name="androidx.car.app.minCarApiLevel"
      android:value="1" />
  </service>

- Implement a `CarAppService` and a `Session` that returns a `Screen` with a `NavigationTemplate`.

Skeleton code (Kotlin)
```
class AutoService : CarAppService() {
  override fun onCreateSession(): Session = object : Session() {
    override fun onCreateScreen(intent: Intent): Screen = NavScreen(carContext)
  }
}

class NavScreen(ctx: CarContext) : Screen(ctx) {
  override fun onGetTemplate(): Template {
    val nav = NavigationTemplate.Builder()
      .setNavigationInfo(Trip.Builder(Route.Builder("Overview").build()).build())
      .setActionStrip(ActionStrip.Builder()
        .addAction(Action.Builder()
          .setTitle("Recenter")
          .setOnClickListener { /* send command to phone via a binder/intent */ }
          .build()).build())
      .build()
    return nav
  }
}
```

Bridging with the Flutter app
- Use a simple local socket/Messenger/intent to send commands from the car app to the phone app (e.g., recenter/overview/start/stop navigation). Alternatively, integrate both in a single Android app module and communicate via a shared binder.
- On the Flutter side, expose methods that execute `GmnsNavHub.recenter()` / `overview()` / `startNavigation()` / `stopNavigation()` in response to intents from the car service.

Notes
- Google Play policies apply; test on Android Automotive OS or Android Auto desktop head unit.
- For full parity with Navigation SDK, you may render step cards and lane guidance using car templates.

