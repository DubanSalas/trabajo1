# -*- coding: utf-8 -*-
import re
from pathlib import Path

p = Path(r'D:\vg-ms-arquitect-main\vg-ms-celebrationservice-hexagonal\src\main\java\pe\edu\vallegrande\fideinexus\celebration\infrastructure\exception\GlobalExceptionHandler.java')
t = p.read_text(encoding='utf-8')

# Usar regex para encontrar los 4 handlers 409 consecutivos y unificarlos
pattern = r'    @ExceptionHandler\(RecordStateConflictException\.class\)\n    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleStateConflict\(RecordStateConflictException ex\) \{\n        return respond\(HttpStatus\.CONFLICT, ".*?"\);\n    \}\n\n    @ExceptionHandler\(DuplicateResourceException\.class\)\n    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleDuplicate\(DuplicateResourceException ex\) \{\n        return respond\(HttpStatus\.CONFLICT, ".*?"\);\n    \}\n\n    @ExceptionHandler\(PreparationNotCompletedException\.class\)\n    public ResponseEntity<ApiResponse<ApiErrorResponse>> handlePreparationNotCompleted\(PreparationNotCompletedException ex\) \{\n        return respond\(HttpStatus\.CONFLICT, ".*?"\);\n    \}\n\n    @ExceptionHandler\(CelebrationScheduleConflictException\.class\)\n    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleScheduleConflict\(CelebrationScheduleConflictException ex\) \{\n        return respond\(HttpStatus\.CONFLICT, ".*?"\);\n    \}'

replacement = '''    @ExceptionHandler({RecordStateConflictException.class, DuplicateResourceException.class,
            PreparationNotCompletedException.class, CelebrationScheduleConflictException.class})
    public ResponseEntity<ApiResponse<ApiErrorResponse>> handleStateConflict(Exception ex) {
        log.warn("Conflicto de estado o recurso duplicado: {}", ex.getMessage());
        return respond(HttpStatus.CONFLICT, "La operaci??n no es v??lida para el estado actual del registro.");
    }'''

t2 = re.sub(pattern, replacement, t, count=1, flags=re.DOTALL)
if t2 != t:
    t = t2
    print("Unificado handlers 409 con regex")
else:
    print("Regex no matcheo")

# Agregar log en handler de dependencias
old_dep = 'log.error("Un servicio dependiente no respondi?? : {}", ex.getMessage());'
new_dep = 'log.error("Un servicio dependiente no respondi?? : {}", ex.getMessage(), ex);'
if old_dep in t:
    t = t.replace(old_dep, new_dep, 1)
    print("Agregado log en handler de dependencias")

p.write_text(t, encoding='utf-8')
print("GlobalExceptionHandler actualizado")
