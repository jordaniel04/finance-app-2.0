# Esquema de Base de Datos (Cloud Firestore)

Diseño escalable y tipado para la gestión de finanzas bipersonales bajo Clean Architecture.

## Colecciones y Atributos

### 1. `users` (Colección de Perfiles)
- `uid` (String): ID único de Firebase Auth.
- `email` (String): Correo electrónico (validado contra whitelist).
- `displayName` (String): Nombre legible.
- `photoUrl` (String): URL de imagen de perfil.
- `metadata` (Map): 
  - `lastLogin` (Timestamp)
  - `role` (String: 'owner' | 'contributor')

### 2. `transactions` (Flujo de Caja)
- `userId` (String): Dueño del movimiento.
- `amount` (Double): Valor absoluto del movimiento.
- `description` (String): Concepto del gasto/ingreso.
- `date` (Timestamp): Fecha del registro.
- `categoryId` (String): Referencia a la categoría.
- `type` (String): `income` | `expense`.
- `loanId` (String, Opcional): Referencia si el movimiento pertenece al pago de un préstamo.

### 3. `categories` (Categorización)
- `userId` (String | null): Propietario o `null` para globales.
- `name` (String): Nombre visual.
- `iconCode` (Int): Punto de código de MaterialIcons.
- `colorValue` (Int): Valor entero del color ARGB.
- `type` (String): `income` | `expense`.

### 4. `loans` (Balance de Activos/Pasivos)
- `userId` (String): Usuario que registra la deuda.
- `targetPerson` (String): Nombre del deudor/acreedor.
- `amount` (Double): Monto total inicial.
- `balance` (Double): Saldo pendiente actual.
- `type` (String): `granted` (Activo) | `received` (Pasivo).
- `status` (String): `active` | `completed`.

## Índices Compuestos Requeridos
- `userId` (ASC) + `date` (DESC) -> Para el feed del Dashboard.
- `userId` (ASC) + `status` (ASC) -> Para el listado de deudas activas.

## Políticas de Seguridad (Security Rules)
```javascript
match /transactions/{id} {
  allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
}
```
