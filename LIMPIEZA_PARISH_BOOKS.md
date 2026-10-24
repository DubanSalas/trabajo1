# Limpieza de Código: Eliminación de Parish Books

## Fecha
2026-10-19

## Motivo
Los **Libros Parroquiales (Parish Books)** ya no se utilizan en el módulo de solicitudes. Se eliminó toda la integración con el microservicio externo de libros para mantener el código limpio y sin dependencias innecesarias.

---

## Archivos Eliminados

### 1. Capa de Dominio (Domain Layer)

#### Puertos de Entrada (Input Ports)
- ✅ `requests/domain/port/in/ParishBookUseCase.java`
  - Interfaz que definía las operaciones de negocio para consultar libros parroquiales

#### Puertos de Salida (Output Ports)
- ✅ `requests/domain/port/out/ParishBookClientPort.java`
  - Interfaz para la comunicación con el microservicio externo de libros

---

### 2. Capa de Aplicación (Application Layer)

#### Servicios (Use Cases)
- ✅ `requests/application/usecase/ParishBookService.java`
  - Servicio que implementaba la lógica de negocio para Parish Books
  - Métodos eliminados:
    - `findAll(tenantId, bookType, activeOnly)`
    - `findById(id)`
    - `findByCode(bookCode, tenantId)`
    - `searchByYear(tenantId, bookType, year)`

---

### 3. Capa de Infraestructura (Infrastructure Layer)

#### Controladores REST (Adapters In)
- ✅ `requests/infrastructure/adapter/in/rest/controller/ParishBookRest.java`
  - Controlador REST que exponía los endpoints `/api/v1/parish-books/*`
  - Endpoints eliminados:
    - `GET /api/v1/parish-books` - Listar libros
    - `GET /api/v1/parish-books/{id}` - Obtener libro por ID
    - `GET /api/v1/parish-books/code/{bookCode}` - Buscar por código
    - `GET /api/v1/parish-books/search-by-year` - Filtrar por año

#### Mappers REST
- ✅ `requests/infrastructure/adapter/in/rest/mapper/ParishBookRestMapper.java`
  - Mapper para convertir entre modelos de dominio y DTOs REST

#### Clientes HTTP (Adapters Out)
- ✅ `requests/infrastructure/adapter/out/client/parishbooks/ParishBookClientAdapter.java`
  - Adaptador WebClient para consumir el microservicio externo de libros
  - Incluía autenticación JWT automática

#### DTOs y Mappers de Cliente
- ✅ `requests/infrastructure/adapter/out/client/parishbooks/dto/ParishBookExternalResponse.java`
  - DTO para recibir respuestas del microservicio externo
  
- ✅ `requests/infrastructure/adapter/out/client/parishbooks/mapper/ParishBookClientMapper.java`
  - Mapper para convertir respuestas externas a modelos del puerto

---

## Estructura de Carpetas Eliminadas

```
vg-ms-servicesservice-hexagonal/
└── src/main/java/pe/edu/vallegrande/fideinexus/requests/
    ├── domain/port/
    │   ├── in/
    │   │   └── ParishBookUseCase.java ❌
    │   └── out/
    │       └── ParishBookClientPort.java ❌
    ├── application/usecase/
    │   └── ParishBookService.java ❌
    └── infrastructure/adapter/
        ├── in/rest/
        │   ├── controller/
        │   │   └── ParishBookRest.java ❌
        │   └── mapper/
        │       └── ParishBookRestMapper.java ❌
        └── out/client/parishbooks/
            ├── ParishBookClientAdapter.java ❌
            ├── dto/
            │   └── ParishBookExternalResponse.java ❌
            └── mapper/
                └── ParishBookClientMapper.java ❌
```

---

## Verificación

### Compilación
```bash
mvn clean compile -DskipTests
```
**Resultado**: ✅ BUILD SUCCESS

### Total de Archivos Eliminados
- **8 archivos Java** relacionados con Parish Books

---

## Impacto

### ✅ Código más limpio
- Eliminada integración innecesaria con microservicio externo
- Reducción de complejidad arquitectónica

### ✅ Menos dependencias
- Ya no se requiere configuración `books.service.url`
- Eliminada dependencia de microservicio externo de libros

### ✅ Menor superficie de ataque
- Menos endpoints HTTP expuestos
- Menor código para mantener y asegurar

---

## Notas Técnicas

- **Arquitectura Hexagonal**: Se eliminaron componentes en las 3 capas (Domain, Application, Infrastructure)
- **WebClient**: Se eliminó cliente HTTP reactivo que consumía API externa
- **Autenticación JWT**: El adaptador propagaba tokens JWT automáticamente
- **Operaciones Reactivas**: Todos los métodos usaban `Mono` y `Flux` de Project Reactor

---

## Estado Actual

El microservicio `vg-ms-servicesservice-hexagonal` ahora **solo maneja Solicitudes de Servicios Sacramentales**, sin ninguna referencia a Libros Parroquiales.

### Funcionalidad Principal Mantenida
- ✅ Gestión de Services (Solicitudes)
- ✅ CRUD completo de servicios
- ✅ Integración con Preparation, Celebration y Certificate
- ✅ 4 tipos de servicio: BAPTISM, CONFIRMATION, MARRIAGE, MASS
