# Lógica de Autenticación (Web Bypass)

Debido a restricciones y tiempos de propagación de la People API de Google, hemos implementado una solución robusta para la plataforma Web.

## Flujo de Inicio de Sesión
1. **Firebase Native Popup**: Utilizamos `_firebaseAuth.signInWithPopup(GoogleAuthProvider())` en lugar del plugin de Google Sign-In tradicional.
2. **Ventajas**:
   - Evita el error 403 de la People API.
   - Proporciona el correo y perfil básico de forma inmediata.
   - Compatible con las políticas de seguridad de navegadores modernos (GIS).

## Whitelist (Lista Blanca)
Para garantizar que solo usuarios autorizados accedan a la aplicación:
1. El `AuthCubit` intercepta el estado de éxito de Firebase.
2. Compara el email obtenido contra una lista definida en variables de entorno (`--dart-define`).
3. Si el email no está en la lista, se fuerza un `signOut` y se muestra un error de acceso denegado.

## Requerimientos
- **OAuth Consent Screen**: El proyecto debe estar en modo "Producción" o el usuario debe estar añadido manualmente como "Test User" en la consola de Google Cloud.
- **Authorized Domains**: `localhost` y el dominio de producción deben estar en la lista de dominios autorizados de Firebase.
