/// Evita dependencia circular entre [fcm_bootstrap] y [NotificationService].
/// Se asigna desde el constructor de `NotificationService`.
void Function()? onFcmForegroundUnreadBump;
