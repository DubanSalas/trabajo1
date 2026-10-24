# -*- coding: utf-8 -*-
from pathlib import Path

p = Path(r'D:\vg-ms-arquitect-main\vg-ms-celebrationservice-hexagonal\src\main\java\pe\edu\vallegrande\fideinexus\celebration\infrastructure\exception\GlobalExceptionHandler.java')
t = p.read_text(encoding='utf-8')

# 1. Unificar handlers 409 + mensajes genericos
old_block = """    @ExceptionHandler(RecordStateConflictException.class)
    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleStateConflict(RecordStateConflictException ex) {
        return respond(HttpStatus.CONFLICT, "La operaci??n no es v??lida para el estado actual del registro.");
    }

    @ExceptionHandler(DuplicateResourceException.class)
    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleDuplicate(DuplicateResourceException ex) {
        return respond(HttpStatus.CONFLICT, "Ya existe un registro con esos datos.");
    }

    @ExceptionHandler(PreparationNotCompletedException.class)
    public ResponseEntity<ApiResponse<ApiErrorResponse>> handlePreparationNotCompleted(PreparationNotCompletedException ex) {
        return respond(HttpStatus.CONFLICT, ex.getMessage());
    }

    @ExceptionHandler(CelebrationScheduleConflictException.class)
    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleScheduleConflict(CelebrationScheduleConflictException ex) {
        return respond(HttpStatus.CONFLICT, ex.getMessage());
    }"""

new_block = """    @ExceptionHandler({RecordStateConflictException.class, DuplicateResourceException.class,
            PreparationNotCompletedException.class, CelebrationScheduleConflictException.class})
    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleStateConflict(Exception ex) {
        log.warn("Conflicto de estado o recurso duplicado: {}", ex.getMessage());
        return respond(HttpStatus.CONFLICT, "La operaci??n no es v??lida para el estado actual del registro.");
    }"""

if old_block in t:
    t = t.replace(old_block, new_block, 1)
    print("Unificado handlers 409")
else:
    print("Bloque 409 no encontrado exactamente - intentando reemplazo parcial")
    t = t.replace('return respond(HttpStatus.CONFLICT, ex.getMessage());', 'return respond(HttpStatus.CONFLICT, "La operaci??n no es v??lida para el estado actual del registro.");')

# 2. Agregar log en handler de dependencias (registrar causa tecnica)
old_dep = 'log.error("Un servicio dependiente no respondi?? : {}", ex.getMessage());'
new_dep = 'log.error("Un servicio dependiente no respondi?? : {}", ex.getMessage(), ex);'
if old_dep in t:
    t = t.replace(old_dep, new_dep, 1)
    print("Agregado log en handler de dependencias")

# 3. Cambiar ex.getMessage() a mensaje generico en handlers que lo exponen
# PreparationNotCompleted y CelebrationScheduleConflict ya fueron unificados arriba

p.write_text(t, encoding='utf-8')
print("GlobalExceptionHandler actualizado")
