# Plan de Implementación: Formulario de Registro de Movimientos

Este sub-módulo permitirá la entrada de datos por parte del usuario mediante una interfaz intuitiva y validada.

## Cambios Propuestos

### Capa de Presentación (Presentation)

#### [NEW] [add_transaction_dialog.dart](file:///c:/Info/JD/Proyectos/finance-app-2.0/lib/presentation/widgets/add_transaction_dialog.dart)
Un diálogo modal (`showModalBottomSheet` o `showDialog`) que contendrá:
- **Toggle de Tipo**: Cambio rápido entre Ingreso y Gasto.
- **Campo de Monto**: Teclado numérico con validación.
- **Campo de Descripción**: Texto breve del movimiento.
- **Grid de Categorías**: Selección visual de la categoría con sus iconos y colores.

#### [MODIFY] [dashboard_page.dart](file:///c:/Info/JD/Proyectos/finance-app-2.0/lib/presentation/pages/dashboard_page.dart)
- Vincular el `FloatingActionButton` para abrir el nuevo diálogo.
- Añadir feedbacks visuales (SnackBars) tras el éxito o error del guardado.

---

### Capa de Datos (Data)

#### [MODIFY] [firebase_transaction_repository_impl.dart](file:///c:/Info/JD/Proyectos/finance-app-2.0/lib/data/repositories/firebase_transaction_repository_impl.dart)
- Asegurar que el método `addTransaction` genere un ID correcto si es necesario (Firestore lo hace automáticamente con `.add()`).

## Plan de Verificación

### Pruebas Funcionales
1.  **Registro de Gasto**: Añadir "$50.000 - Almuerzo" y verificar que el balance total disminuya.
2.  **Registro de Ingreso**: Añadir "$1.000.000 - Sueldo" y verificar que la lista se actualice cronológicamente.
3.  **Validación**: Intentar guardar sin monto o descripción y verificar los mensajes de error.

### Verificación de UI
- El selector de tipo de transacción debe cambiar el color temático del formulario (Rojo para gastos, Verde para ingresos).
