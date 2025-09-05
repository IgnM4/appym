# Web estática

## Publicación
1. Instalar [Firebase CLI](https://firebase.google.com/docs/cli) y autenticarse:
   ```bash
   firebase login
   ```
2. Si es la primera vez, inicializar hosting:
   ```bash
   cd web-app
   firebase init hosting
   ```
3. Publicar:
   ```bash
   cd web-app
   npm run deploy
   ```

El ID del proyecto se configura en `.firebaserc`.

## Desarrollo local
Para compilar la aplicación web de manera local:

```bash
cd web-app
npm ci
npm run build
```

Los CSV de datos se esperan en `public/data/` y pueden generarse con `scripts/publish_web.mjs`.
