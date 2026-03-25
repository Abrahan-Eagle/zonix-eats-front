# Emulador Android para Zonix Eats (Linux)

Pasos probados para usar el emulador como “tercer dispositivo” al probar varios roles (users, commerce, delivery_company, delivery_agent, delivery, admin).

## Requisitos

- Android SDK en `$ANDROID_HOME` (p. ej. `/home/aipp/Android/Sdk`).
- AVD `flutter_emulator` (o configurar `AVD_NAME`).
- KVM cargado (en la mayoría de equipos Linux se carga al arranque; si no, `sudo modprobe kvm kvm_amd`).

## 1. KVM al arranque (ya configurado)

Se creó `/etc/modules-load.d/kvm.conf` con `kvm` y `kvm_amd`. Tras reiniciar, KVM se carga solo. Si no reiniciaste, ejecuta:

```bash
sudo modprobe kvm kvm_amd
```

## 2. Iniciar el emulador

Script recomendado (usa `-gpu mesa` para evitar segfault en algunas GPUs):

```bash
~/bin/start-zonix-emulator --wait
```

- Sin `--wait`: solo lanza el emulador en segundo plano.
- Con `--wait`: espera a que el dispositivo esté listo y muestra `adb devices`; luego puedes cerrar la terminal y el emulador sigue corriendo.

Si no tienes `~/bin` en el PATH:

```bash
export PATH="$HOME/bin:$PATH"
# o añade en ~/.bashrc: export PATH="$HOME/bin:$PATH"
```

Alternativa manual (misma configuración estable):

```bash
export ANDROID_HOME=/home/aipp/Android/Sdk
$ANDROID_HOME/emulator/emulator -avd flutter_emulator \
  -no-snapshot-load -no-snapshot-save -gpu mesa -no-audio -no-boot-anim &
```

El primer arranque puede tardar ~60–90 s. Cuando en `adb devices` aparezca `emulator-5554` como `device`, está listo.

## 3. Ejecutar la app en el emulador

Desde el repo del front:

```bash
cd /var/www/html/proyectos/AIPP/DESARROLLO/ZONIX-EAT/zonix-eats-front
flutter run -d emulator-5554
```

## Resumen de dispositivos para multi-rol

| Dispositivo      | Uso sugerido                          |
|------------------|----------------------------------------|
| Móvil 1          | users (comprador)                      |
| Móvil 2          | commerce (restaurante)                 |
| Emulador (PC)    | delivery_company, delivery_agent o admin |
| Opcional: Chrome | Otro rol (web)                         |

## Nota sobre rol delivery_company

Con usuario **delivery_company**, la app no debe llamar a endpoints `/api/delivery/*` (reservados a delivery_agent/delivery); de lo contrario el backend responde 403. Ese ajuste en el front sigue pendiente.

---

*Última actualización: 20 Mar 2026*
