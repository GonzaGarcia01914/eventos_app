# EventosPy

App Flutter para publicar y descubrir eventos.

## Deploy web en GitHub Pages

El deploy se ejecuta automaticamente con GitHub Actions al hacer push a `main`.

1. En GitHub, ir a `Settings > Secrets and variables > Actions`.
2. Crear el secret `GOOGLE_MAPS_API_KEY` con la clave web de Google Maps.
3. Ir a `Settings > Pages` y seleccionar `GitHub Actions` como source.
4. Hacer push a `main` o ejecutar manualmente el workflow `Deploy Flutter Web to GitHub Pages`.

Conviene restringir la clave de Google Maps al dominio `https://GonzaGarcia01914.github.io/eventos_app/*`.

URL esperada:

```text
https://GonzaGarcia01914.github.io/eventos_app/
```

Build local equivalente:

```bash
flutter build web --release --base-href /eventos_app/ --dart-define=GOOGLE_MAPS_API_KEY=tu_clave
```
