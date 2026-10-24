# 🎨 Mejoras Necesarias - Frontend Solicitudes

**Fecha**: 2026-10-19  
**Módulo**: Solicitudes (vg-web-fideinexus-develop)  
**Estado**: Pendiente de implementación

---

## 📋 Problemas Identificados

### 1. ❌ **Bordes rojos agresivos en formulario**
**Problema**: Los campos muestran borde rojo grueso cuando hay validación  
**Solución**: Cambiar a validación más sutil (solo borde delgado sin ring)

### 2. ❌ **Texto "(opcional)" se ve feo**
**Problema**: Aparece "(opcional)" en gris al lado de campos no requeridos  
**Solución**: Ocultar el texto o hacerlo más sutil

### 3. ❌ **Confusión "Solicitud" vs "Inscripción"**
**Problema**: Usa ambos términos para lo mismo  
**Solución**: Unificar a "Solicitud" en toda la UI

### 4. ❌ **Botón "Agregar" en participantes (vista detalle)**
**Problema**: Permite agregar/eliminar participantes después de crear  
**Solución**: Quitar botones en vista detalle (solo lectura)

### 5. ❌ **Preparación incompleta**
**Problema**: Solo muestra formulario básico  
**Debe tener**:
- Lista de sesiones programadas
- Control de asistencia (Presente/Ausente/Justificado)
- Para Confirmación: Examen con nota (0-100) y aprobado/reprobado
- Mostrar estado de pago (debe estar pagado para asistir)

### 6. ❌ **Falta integración con Finanzas**
**Problema**: No muestra estado de pago en preparación  
**Solución**: 
- Mostrar si está pagado o pendiente
- Bloquear asistencia si no pagó
- Actualizar automáticamente cuando finanzas registra el pago

### 7. ❌ **Falta módulo "Actas"**
**Problema**: El módulo "Actas" está mal ubicado  
**Solución**: 
- Mover "Actas" al menú principal (al costado de Solicitudes y Calendario)
- Debe ser un módulo independiente para buscar y generar certificados

---

## 🔧 Cambios Necesarios por Archivo

### 1. `solicitud-form.html` - Formulario de Nueva Solicitud

#### 1.1 Quitar bordes rojos agresivos

**ANTES** (línea ~136):
```html
[class]="errors()['scheduledDate']
  ? 'border-red-400 ring-2 ring-red-100'
  : form.scheduledDate ? 'border-emerald-400 ring-2 ring-emerald-100' : 'border-slate-200 focus:border-amber-400 focus:ring-2 focus:ring-amber-100'"
```

**DESPUÉS**:
```html
[class]="errors()['scheduledDate']
  ? 'border-red-300'
  : form.scheduledDate ? 'border-emerald-400' : 'border-slate-200 focus:border-amber-400'"
```

#### 1.2 Quitar "(opcional)" de los labels

**ANTES** (línea ~287):
```html
<label class="text-xs font-semibold text-slate-600 flex items-center gap-1">
  {{ rf.label }}
  @if (rf.required) { <span class="text-red-500">*</span> }
  @else { <span class="text-slate-400 font-normal">(opcional)</span> }
</label>
```

**DESPUÉS**:
```html
<label class="text-xs font-semibold text-slate-600 flex items-center gap-1">
  {{ rf.label }}
  @if (rf.required) { <span class="text-red-500">*</span> }
</label>
```

#### 1.3 Cambiar "Inscripción" → "Solicitud"

**BUSCAR Y REEMPLAZAR**:
- `Inscripción de Participantes` → `Participantes de la Solicitud`
- `inscripción` → `solicitud`

---

### 2. `solicitud-detail.html` - Vista de Detalle

#### 2.1 Quitar botón "Agregar" de participantes

**ANTES**:
```html
<div class="flex items-center justify-between mb-4">
  <h3 class="text-sm font-bold text-slate-700">Inscripción de Participantes</h3>
  <button class="btn-primary">+ Agregar</button>
</div>
```

**DESPUÉS**:
```html
<div class="mb-4">
  <h3 class="text-sm font-bold text-slate-700">Participantes de la Solicitud</h3>
  <p class="text-xs text-slate-500 mt-1">Los participantes fueron registrados al crear la solicitud.</p>
</div>

<!-- Mostrar solo lista de participantes (sin botones agregar/eliminar) -->
<div class="space-y-2">
  @for (p of participants(); track p.id) {
    <div class="flex items-center gap-3 p-3 bg-slate-50 rounded-xl">
      <div class="w-10 h-10 rounded-full bg-blue-500 text-white flex items-center justify-center text-sm font-bold">
        {{ p.name.charAt(0) }}
      </div>
      <div class="flex-1">
        <p class="text-sm font-semibold text-slate-700">{{ p.name }} {{ p.lastname }}</p>
        <p class="text-xs text-slate-500">{{ p.roleName }}</p>
      </div>
      <!-- ❌ NO AGREGAR botón eliminar aquí -->
    </div>
  }
</div>
```

#### 2.2 Sección de Preparación COMPLETA

**REEMPLAZAR** la sección actual de "Sesiones de Preparación" con:

```html
<!-- ══════════════════════════════════════════════════════════════ -->
<!-- PREPARACIÓN SACRAMENTAL -->
<!-- ══════════════════════════════════════════════════════════════ -->
<div class="bg-white border border-slate-200 rounded-2xl p-5 space-y-4">
  <div class="flex items-center justify-between">
    <div>
      <h3 class="text-sm font-bold text-slate-700">Preparación Sacramental</h3>
      <p class="text-xs text-slate-500 mt-1">
        Gestión de asistencia
        @if (form.requestType === 'CONFIRMATION') { y examen de confirmación }
      </p>
    </div>
    <!-- Solo mostrar botón si está APROBADO y PAGADO -->
    @if (solicitud().status === 'APPROVED' && paymentStatus() === 'PAID') {
      <button (click)="openNewSessionModal()" class="btn-primary">
        + Agregar sesión
      </button>
    } @else if (paymentStatus() === 'PENDING') {
      <div class="flex items-center gap-2 bg-amber-50 border border-amber-200 rounded-xl px-3 py-2">
        <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
            d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"/>
        </svg>
        <span class="text-xs font-medium text-amber-700">Pago pendiente - Debe pagar en Finanzas para habilitar preparación</span>
      </div>
    }
  </div>

  <!-- Estado de pago -->
  <div class="flex items-center gap-3 p-3 rounded-xl"
    [class]="paymentStatus() === 'PAID' ? 'bg-emerald-50 border border-emerald-200' : 'bg-amber-50 border border-amber-200'">
    <svg class="w-5 h-5" 
      [class]="paymentStatus() === 'PAID' ? 'text-emerald-500' : 'text-amber-500'"
      fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
        d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
    </svg>
    <div class="flex-1">
      <p class="text-sm font-semibold"
        [class]="paymentStatus() === 'PAID' ? 'text-emerald-700' : 'text-amber-700'">
        Estado de Pago: {{ paymentStatus() === 'PAID' ? 'Pagado' : 'Pendiente' }}
      </p>
      @if (paymentAmount()) {
        <p class="text-xs text-slate-500 mt-0.5">
          Monto: S/ {{ paymentAmount() | number:'1.2-2' }}
          @if (paymentDate()) { · Pagado el {{ paymentDate() | date:'dd/MM/yyyy' }} }
        </p>
      }
    </div>
    @if (paymentStatus() === 'PENDING') {
      <a routerLink="/finanzas" class="text-xs font-semibold text-amber-700 hover:text-amber-800 underline">
        Ir a Finanzas
      </a>
    }
  </div>

  <!-- Lista de sesiones -->
  @if (preparations().length === 0) {
    <div class="text-center py-8">
      <svg class="w-12 h-12 text-slate-300 mx-auto mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
          d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"/>
      </svg>
      <p class="text-sm text-slate-500">No hay sesiones de preparación registradas</p>
      @if (solicitud().status !== 'APPROVED') {
        <p class="text-xs text-slate-400 mt-1">La solicitud debe estar aprobada primero</p>
      } @else if (paymentStatus() === 'PENDING') {
        <p class="text-xs text-amber-600 mt-1">Debe completar el pago en Finanzas</p>
      }
    </div>
  } @else {
    <div class="space-y-2">
      @for (prep of preparations(); track prep.id) {
        <div class="flex items-center gap-3 p-3 rounded-xl border"
          [class]="prep.attendanceStatus === 'PRESENT' ? 'bg-emerald-50 border-emerald-200'
            : prep.attendanceStatus === 'ABSENT' ? 'bg-red-50 border-red-200'
            : 'bg-slate-50 border-slate-200'">
          
          <!-- Ícono de asistencia -->
          <div class="w-10 h-10 rounded-full flex items-center justify-center"
            [class]="prep.attendanceStatus === 'PRESENT' ? 'bg-emerald-500'
              : prep.attendanceStatus === 'ABSENT' ? 'bg-red-500'
              : 'bg-slate-300'">
            <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              @if (prep.attendanceStatus === 'PRESENT') {
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
              } @else if (prep.attendanceStatus === 'ABSENT') {
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
              } @else {
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
              }
            </svg>
          </div>

          <!-- Info de la sesión -->
          <div class="flex-1">
            <div class="flex items-center gap-2">
              <p class="text-sm font-semibold text-slate-700">
                Sesión {{ prep.sessionDate | date:'dd/MM/yyyy' }}
              </p>
              <span class="text-xs font-medium px-2 py-0.5 rounded-full"
                [class]="prep.attendanceStatus === 'PRESENT' ? 'bg-emerald-100 text-emerald-700'
                  : prep.attendanceStatus === 'ABSENT' ? 'bg-red-100 text-red-700'
                  : 'bg-slate-100 text-slate-600'">
                {{ prep.attendanceStatus === 'PRESENT' ? 'Presente' 
                  : prep.attendanceStatus === 'ABSENT' ? 'Ausente' 
                  : 'Justificado' }}
              </span>
            </div>

            <!-- Para Confirmación: Mostrar nota del examen -->
            @if (form.requestType === 'CONFIRMATION' && prep.examScore !== null) {
              <div class="flex items-center gap-2 mt-1">
                <span class="text-xs text-slate-500">Nota del examen:</span>
                <span class="text-xs font-bold px-2 py-0.5 rounded"
                  [class]="prep.examPassed ? 'bg-emerald-100 text-emerald-700' : 'bg-red-100 text-red-700'">
                  {{ prep.examScore }}/100
                  {{ prep.examPassed ? '✓ Aprobado' : '✗ Reprobado' }}
                </span>
              </div>
            }

            @if (prep.notes) {
              <p class="text-xs text-slate-500 mt-1">{{ prep.notes }}</p>
            }
          </div>

          <!-- Acciones -->
          <button (click)="editPreparation(prep)" 
            class="w-8 h-8 rounded-lg hover:bg-slate-100 flex items-center justify-center text-slate-400 hover:text-slate-600">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"/>
            </svg>
          </button>
        </div>
      }
    </div>

    <!-- Resumen de asistencia -->
    <div class="grid grid-cols-3 gap-3 p-3 bg-slate-50 rounded-xl">
      <div class="text-center">
        <p class="text-2xl font-bold text-emerald-600">{{ attendanceSummary().present }}</p>
        <p class="text-xs text-slate-500">Presente</p>
      </div>
      <div class="text-center">
        <p class="text-2xl font-bold text-red-600">{{ attendanceSummary().absent }}</p>
        <p class="text-xs text-slate-500">Ausente</p>
      </div>
      <div class="text-center">
        <p class="text-2xl font-bold text-slate-600">{{ attendanceSummary().excused }}</p>
        <p class="text-xs text-slate-500">Justificado</p>
      </div>
    </div>
  }
</div>
```

---

### 3. `solicitud-detail.ts` - Lógica del Componente

Agregar signals y métodos necesarios:

```typescript
// Signals para preparación
paymentStatus = signal<'PAID' | 'PENDING'>('PENDING');
paymentAmount = signal<number | null>(null);
paymentDate = signal<string | null>(null);
preparations = signal<Preparation[]>([]);

// Resumen de asistencia
attendanceSummary = computed(() => {
  const preps = this.preparations();
  return {
    present: preps.filter(p => p.attendanceStatus === 'PRESENT').length,
    absent: preps.filter(p => p.attendanceStatus === 'ABSENT').length,
    excused: preps.filter(p => p.attendanceStatus === 'EXCUSED').length,
    total: preps.length
  };
});

// Método para cargar estado de pago (integración con finanzas)
async loadPaymentStatus() {
  try {
    const payment = await this.finanzasService.getPaymentByServiceId(this.solicitud().id);
    if (payment && payment.status === 'PAID') {
      this.paymentStatus.set('PAID');
      this.paymentAmount.set(payment.amount);
      this.paymentDate.set(payment.paymentDate);
    } else {
      this.paymentStatus.set('PENDING');
    }
  } catch (error) {
    console.error('Error al cargar estado de pago:', error);
    this.paymentStatus.set('PENDING');
  }
}

// Método para abrir modal de nueva sesión
openNewSessionModal() {
  if (this.paymentStatus() === 'PENDING') {
    alert('Debe completar el pago en Finanzas antes de agregar sesiones de preparación');
    return;
  }
  // Abrir modal para nueva sesión
}

// Método para editar preparación (incluye nota de examen para Confirmación)
editPreparation(prep: Preparation) {
  // Abrir modal de edición
  // Para Confirmación: mostrar campos de examen (examScore, examPassed)
}
```

---

### 4. Navegación Principal - Agregar "Actas"

**Archivo**: `app.routes.ts` o componente de navegación

**ANTES**:
```typescript
const routes = [
  { path: 'solicitudes', component: SolicitudesComponent },
  { path: 'calendario', component: CalendarioComponent },
  // ...
];
```

**DESPUÉS**:
```typescript
const routes = [
  { path: 'solicitudes', component: SolicitudesComponent },
  { path: 'calendario', component: CalendarioComponent },
  { path: 'actas', component: ActasComponent }, // ⭐ NUEVO
  // ...
];
```

**Navegación visual**:
```
┌─────────────────────────────────────────────────────────────┐
│  [📋 Solicitudes]  [📅 Calendario]  [📄 Actas]  [Finanzas]  │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Flujo Completo del Sistema

```
1. SOLICITUD (Service)
   ├── Usuario crea solicitud
   ├── Registra participantes
   └── Estado: PENDING

2. APROBACIÓN
   ├── Párroco/Secretario aprueba
   └── Estado: APPROVED

3. PAGO (Finanzas)
   ├── Feligrés paga en módulo Finanzas
   ├── Finanzas registra pago → payment.status = 'PAID'
   └── ⚡ Automático: paymentStatus() se actualiza

4. PREPARACIÓN (Preparation)
   ├── SOLO SI: status === 'APPROVED' Y paymentStatus === 'PAID'
   ├── Secretario/Párroco:
   │   ├── Agrega sesiones
   │   ├── Marca asistencia (Presente/Ausente/Justificado)
   │   └── Para Confirmación: Registra nota de examen (0-100)
   └── Completa todas las sesiones → READY

5. CELEBRACIÓN (Celebration)
   ├── Programa fecha de sacramento
   ├── Realiza el sacramento
   └── Estado: REALIZED

6. ACTA (Certificate)
   ├── Genera acta con número de libro
   ├── Párroco firma libro físico
   └── Marca como signed: true

7. BÚSQUEDA DE ACTAS
   ├── Módulo independiente "Actas"
   ├── Buscar por nombre, documento, tipo
   └── Generar PDF del certificado (jsPDF en frontend)
```

---

## 🔄 Integración Automática con Finanzas

### Backend: Notificación de Pago

**Opción 1**: WebSocket (Tiempo real)
```typescript
// finanzas registra pago → envía evento WebSocket
socket.emit('payment:completed', { serviceId: 123, amount: 150 });

// solicitud-detail escucha evento
socket.on('payment:completed', (data) => {
  if (data.serviceId === this.solicitud().id) {
    this.paymentStatus.set('PAID');
    this.paymentAmount.set(data.amount);
    this.paymentDate.set(new Date().toISOString());
  }
});
```

**Opción 2**: Polling (Cada 30 segundos)
```typescript
// En solicitud-detail.ts
ngOnInit() {
  this.loadPaymentStatus(); // Carga inicial
  
  // Recargar cada 30 segundos si está pendiente
  interval(30000).pipe(
    takeUntil(this.destroy$)
  ).subscribe(() => {
    if (this.paymentStatus() === 'PENDING') {
      this.loadPaymentStatus();
    }
  });
}
```

---

## ✅ Checklist de Implementación

### Formulario (solicitud-form)
- [ ] Quitar bordes rojos agresivos (`ring-2` → solo `border`)
- [ ] Ocultar texto "(opcional)" de labels
- [ ] Cambiar "Inscripción" → "Solicitud"

### Vista Detalle (solicitud-detail)
- [ ] Quitar botón "Agregar" de participantes
- [ ] Mostrar participantes en modo solo lectura
- [ ] Agregar signal `paymentStatus()`
- [ ] Agregar integración con finanzas
- [ ] Implementar lista de sesiones de preparación
- [ ] Agregar control de asistencia (Presente/Ausente/Justificado)
- [ ] Para Confirmación: Agregar campos de examen (nota, aprobado)
- [ ] Bloquear preparación si no está pagado
- [ ] Mostrar resumen de asistencia

### Navegación
- [ ] Agregar ruta `/actas`
- [ ] Crear componente `ActasComponent`
- [ ] Agregar al menú principal (entre Calendario y Finanzas)

### Backend (preparationservice)
- [x] Ya tiene campo `attendance_status` en BD
- [x] Ya tiene campo `exam_score` en BD
- [x] Ya tiene campo `exam_passed` en BD
- [ ] Validar que no se pueda crear sesión si payment.status !== 'PAID'

### Finanzas Integration
- [ ] Crear servicio `FinanzasService.getPaymentByServiceId()`
- [ ] Implementar actualización automática (WebSocket o Polling)

---

## 📝 Notas Finales

### Nomenclatura Unificada:
- ✅ **"Solicitud"** (no "Inscripción")
- ✅ **"Participantes"** (no "Inscritos")
- ✅ **"Preparación"** (no "Sesiones")
- ✅ **"Acta"** (no "Certificado" en la UI, aunque en BD es `certificate`)

### Campos Obligatorios:
- ❌ NO mostrar "(opcional)" en UI
- ✅ Solo mostrar `*` en campos requeridos

### Estados del flujo:
```
Service:
├── PENDING → Recién creada
├── APPROVED → Aprobada por párroco (puede pagar)
├── PREPARATION → En preparación (pagó + asistiendo)
├── READY → Lista para celebración (completó preparación)
└── COMPLETED → Sacramento realizado + acta generada
```

---

**Autor**: Kiro AI Assistant  
**Fecha**: 2026-10-19  
**Versión**: 1.0  
**Estado**: Documento de especificación - Pendiente de implementación
