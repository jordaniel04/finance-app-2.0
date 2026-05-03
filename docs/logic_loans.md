# Lógica de Negocio: Préstamos (Loans)

Este módulo gestiona la complejidad contable de las deudas entre personas, diferenciando entre el flujo de caja (Cash Flow) y el Balance Patrimonial.

## Definiciones Contables

### 1. Préstamo Otorgado (Yo presto dinero)
- **Flujo de Caja**: Se registra como un **Egreso** (salida de dinero).
- **Balance**: Se registra como un **Activo** (derecho de cobro). El patrimonio neto no disminuye, solo cambia de forma (dinero por cuenta por cobrar).
- **Recuperación**: El cobro de una cuota genera un **Ingreso** en caja y disminuye el valor del **Activo**.

### 2. Préstamo Recibido (Me prestan dinero)
- **Flujo de Caja**: Se registra como un **Ingreso** (entrada de dinero).
- **Balance**: Se registra como un **Pasivo** (obligación de pago).
- **Amortización**: El pago de una cuota genera un **Egreso** en caja y disminuye el valor del **Pasivo**.

## Requerimientos de Implementación

- **Diferenciación de Saldo**: La app debe mostrar de forma separada el "Saldo Disponible" (Caja/Bancos) del "Valor Patrimonial" (Saldo + Activos - Pasivos).
- **Historial de Movimientos**: Cada interacción con un préstamo debe crear automáticamente una entrada en la colección `transactions` para mantener la integridad del flujo de caja.
- **Estado de Deuda**: 
  - `active`: Préstamo con saldo pendiente.
  - `settled`: Préstamo pagado en su totalidad.
  - `defaulted`: Préstamo incobrable o en mora.

## Estructura de Firestore (Colección `loans`)
- `userId`: ID del dueño del registro.
- `partyName`: Nombre de la otra persona involucrada.
- `initialAmount`: Monto original.
- `outstandingAmount`: Saldo pendiente actual.
- `type`: `granted` (otorgado) | `received` (recibido).
- `status`: Estado actual.
- `createdAt`: Fecha de creación.
