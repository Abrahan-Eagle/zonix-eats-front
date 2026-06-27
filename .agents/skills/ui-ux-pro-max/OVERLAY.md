## Overlay Zonix Glasses Front — ui-ux-pro-max

Precede sobre BM25 genérico. Leer **`zonix-glasses-ui-patterns`** y **`../zonix-glasses-back/docs/BRAND_ZONIX_GLASSES.md`**.

### Producto

- **Nombre:** Zonix Glasses
- **Vertical:** Óptica online B2B2C (lentes a medida, try-on IA)
- **Stack:** Flutter (`zonix_glasses`, `com.zonix.glasses`)

### Precedencia

```
1. BRAND_ZONIX_GLASSES.md (Backend hub)
2. zonix-glasses-ui-patterns
3. ui-ux-pro-max (patrones UX; no override tokens brand)
4. flutter-expert
```

### Anti-patterns

- Copy smart-glasses / BLE / wearable HUD (pivot óptica)
- Purple AI-slop; emojis como iconos
- `Colors.*` hardcoded — usar `Theme` / `AppColors` tokens brand
- URLs fuera de `AppConfig.apiUrl`
