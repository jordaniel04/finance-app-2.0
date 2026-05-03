# Arquitectura del Proyecto

Este proyecto sigue los principios de **Clean Architecture** para garantizar escalabilidad, testeabilidad e independencia de frameworks.

## Estructura de Capas

### 1. Domain (Dominio)
La capa más interna. Contiene las reglas de negocio puras.
- **Entities**: Objetos de negocio básicos (`User`, `Transaction`, `Category`).
- **Repositories (Interfaces)**: Contratos que deben cumplir los orígenes de datos.
- **Use Cases**: Lógica específica de la aplicación.

### 2. Data (Datos)
Implementación de los repositorios y fuentes de datos.
- **Models**: Extensiones de las entidades con lógica de serialización (`toJson`, `fromFirestore`).
- **Repositories (Impl)**: Implementaciones concretas (ej: `FirebaseTransactionRepositoryImpl`).
- **Data Sources**: APIs externas o bases de datos (Cloud Firestore, FirebaseAuth).

### 3. Presentation (Presentación)
Todo lo relacionado con la UI y la gestión del estado.
- **BLoCs/Cubits**: Gestión de estados reactivos usando `flutter_bloc`.
- **Pages**: Pantallas completas de la aplicación.
- **Widgets**: Componentes visuales reutilizables.

## Flujo de Datos
`UI` -> `Bloc` -> `Use Case` (opcional) -> `Repository Interface` -> `Repository Impl` -> `Data Source`
