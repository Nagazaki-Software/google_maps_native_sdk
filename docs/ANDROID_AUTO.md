Android Auto (opt-in)

- By default, the Android Auto (Android for Cars App Library) scaffold is disabled to avoid build errors when `androidx.car.app` is not used.
- To enable it in the host app, set a Gradle property:

  - In `android/gradle.properties` of your app: `gmnsCarAppEnabled=true`
  - Or pass `-PgmnsCarAppEnabled=true` when building.

When enabled:
- The plugin adds `androidx.car.app:app` and `androidx.car.app:app-projected` dependencies.
- The `GmnsCarAppService` is enabled in the plugin manifest.

Next steps:
- Implement your real car UI using the Android for Cars App Library templates.
- Follow Google Play policies for Android Auto navigation apps.
