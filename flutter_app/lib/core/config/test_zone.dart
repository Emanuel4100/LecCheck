/// When `true` under [Zone.current], cold start skips waiting on
/// `FirebaseAuth.instance.authStateChanges()` (headless/widget tests).
const Symbol leccheckWidgetTestZoneKey = #leccheckWidgetTestZoneKey;
