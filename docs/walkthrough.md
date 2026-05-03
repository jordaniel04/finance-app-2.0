# Walkthrough: Módulo de Transacciones y Dashboard

He completado la implementación de la gestión de transacciones. A continuación, un resumen de lo logrado:

## Cambios Realizados

### 1. Arquitectura de Datos (Capa de Dominio y Datos)
- Se crearon las entidades `TransactionEntity` y `CategoryEntity`.
- Implementación de `FirebaseTransactionRepositoryImpl` con soporte para Firestore.
- Modelos con serialización robusta para manejar `Timestamps` y enums.

### 2. Lógica de Aplicación (BLoC)
- `TransactionCubit`: Gestiona la carga de transacciones del usuario, el cálculo automático de balance (Ingresos - Gastos) y la eliminación de registros.
- `TransactionState`: Estados claros para carga, error y visualización de datos.

### 3. Interfaz de Usuario (Dashboard & Interacción)
- **Tarjeta de Balance**: Un diseño premium con degradados y resumen de ingresos/gastos.
- **Lista de Movimientos**: Feed cronológico de transacciones.
- **Formulario "Nuevo Movimiento"**: Diálogo modal con selector de tipo (Gasto/Ingreso) y categorías dinámicas.
- **Internacionalización**: Formateo de moneda (`es_CO`) y fechas en español.

## Cómo Probarlo
1.  **Inicia Sesión**: Usa tu cuenta de Google.
2.  **Dashboard**: Al entrar, verás el nuevo Dashboard.
3.  **Datos**: Como aún no hay transacciones en tu DB, verás el mensaje de bienvenida. 

> [!NOTE]
> He dejado configuradas categorías por defecto (Comida, Sueldo, etc.) para que la app sea funcional desde el primer momento en que empecemos a insertar datos en la siguiente tarea.

¡Echa un vistazo al código o lanza la app para verlo en acción! 🚀🏛️
