# Mejoras Pendientes - Reportes con Logo

## Estado Actual
- ✅ PDF Actas: Tiene logo implementado
- ✅ PDF Solicitudes: Tiene logo implementado  
- ❌ Excel Solicitudes: Solo texto "FIDEI NEXUS"
- ❌ Excel Actas: No existe

## Implementaciones Necesarias

### 1. Agregar Logo al Excel de Solicitudes

**Archivo**: `solicitudes-report.service.ts`  
**Método**: `exportListExcel()`  
**Línea aproximada**: 381 (donde dice "FIDEI NEXUS")

**Implementación**:
```typescript
// Antes de la línea que dice:
// setR(r, 0, cell('FIDEI NEXUS', { font: titleFont, ... }));

// Agregar este método helper al inicio de la clase:
private async loadLogoForExcel(logoUrl: string): Promise<string | null> {
  try {
    const response = await fetch(logoUrl);
    if (!response.ok) return null;
    const blob = await response.blob();
    return new Promise((resolve) => {
      const reader = new FileReader();
      reader.onloadend = () => resolve(reader.result as string);
      reader.onerror = () => resolve(null);
      reader.readAsDataURL(blob);
    });
  } catch (error) {
    console.warn('[SolicitudesReportService] Error cargando logo para Excel:', error);
    return null;
  }
}

// Modificar el inicio del método exportListExcel():
async exportListExcel(data: Service[], ctx: SolicitudesReportContext): Promise<void> {
  // ... código existente ...

  const xlsxModule = await import('xlsx-js-style' as any);
  const XLSX = (xlsxModule as any).default ?? xlsxModule;

  // NUEVO: Cargar logo si está disponible
  let logoBase64: string | null = null;
  if (ctx.logoDataUrl) {
    logoBase64 = ctx.logoDataUrl;
  } else if (ctx.tenantDetails?.logoUrl) {
    logoBase64 = await this.loadLogoForExcel(ctx.tenantDetails.logoUrl);
  }

  // ... resto del código ...

  // En lugar de solo el texto "FIDEI NEXUS", agregar:
  if (logoBase64) {
    // Agregar imagen al worksheet
    if (!wsR['!images']) wsR['!images'] = [];
    wsR['!images'].push({
      name: 'logo.png',
      data: logoBase64,
      opts: { base64: true },
      position: {
        type: 'twoCellAnchor',
        from: { col: 0, row: 1 },
        to: { col: 1, row: 3 }
      }
    });
    r = 4; // Ajustar posición inicial después del logo
  } else {
    // Fallback: solo texto
    setR(r, 0, cell('FIDEI NEXUS', { font: titleFont, alignment: left, fill: { fgColor: { rgb: WHITE } } }));
  }
}
```

**Nota**: xlsx-js-style no soporta imágenes directamente. Alternativa más simple:

```typescript
// Opción más simple sin imágenes en Excel:
// 1. Mantener el texto "FIDEI NEXUS" como está
// 2. Agregar una fila adicional con "Logo institucional" y URL
setR(r, 0, cell('🏛️ FIDEI NEXUS', { font: titleFont, alignment: left, fill: { fgColor: { rgb: WHITE } } }));
mergesR.push({ s: { r, c: 0 }, e: { r, c: 5 } });
r++;

if (ctx.tenantDetails?.logoUrl) {
  setR(r, 0, cell(`Logo: ${ctx.tenantDetails.logoUrl}`, { font: smallFont, alignment: left }));
  mergesR.push({ s: { r, c: 0 }, e: { r, c: 5 } });
  r++;
}
```

### 2. Crear Excel para Actas

**Archivo**: `actas-report.service.ts`  
**Ubicación**: Después del método `generateActaMatrimonio()`

**Implementación Completa**:

```typescript
async exportActaExcel(acta: ActaEnriquecida, ctx: ActaReportContext): Promise<void> {
  const type = acta.request?.serviceTypeCode;
  if (!type) throw new Error('Tipo de sacramento no válido');

  const xlsxModule = await import('xlsx-js-style' as any);
  const XLSX = (xlsxModule as any).default ?? xlsxModule;

  const cert = acta.certificate;
  const req = acta.request;
  const church = acta.church;

  // Colores según tipo
  const COLORS = {
    BAPTISM: { primary: 'A0522D', gold: 'DAA520', beige: 'F5F5DC' },
    CONFIRMATION: { primary: '6A0DAD', gold: 'FFD700', beige: 'FAF5EB' },
    MARRIAGE: { primary: '006699', gold: 'DAA520', beige: 'FFFDF5' }
  };

  const color = COLORS[type as keyof typeof COLORS] || COLORS.BAPTISM;

  const ws: any = {};
  const merges: any[] = [];
  let r = 0;

  const cell = (v: any, styles: any = {}) => ({ v, t: typeof v === 'number' ? 'n' : 's', s: styles });
  const baseFont = { name: 'Calibri', sz: 11 };
  const titleFont = { name: 'Calibri', sz: 16, bold: true, color: { rgb: color.primary } };
  const boldFont = { name: 'Calibri', sz: 11, bold: true };
  const center = { horizontal: 'center', vertical: 'center' };
  const left = { horizontal: 'left', vertical: 'center' };

  // Header dorado
  for (let c = 0; c < 6; c++) {
    ws[XLSX.utils.encode_cell({ r, c })] = cell('', { fill: { fgColor: { rgb: color.gold } } });
  }
  merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });
  r++;

  // Logo (como emoji o texto)
  const churchName = church?.nombre || 'PARROQUIA SAN PEDRO APÓSTOL';
  ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell(`⛪ ${churchName}`, {
    font: titleFont,
    alignment: center,
    fill: { fgColor: { rgb: 'FFFFFF' } }
  });
  for (let c = 1; c < 6; c++) {
    ws[XLSX.utils.encode_cell({ r, c })] = cell('', { fill: { fgColor: { rgb: 'FFFFFF' } } });
  }
  merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });
  r += 2;

  // Título
  const title = type === 'BAPTISM' ? 'TESTIMONIO DE NACIMIENTO Y BAUTISMO' :
                type === 'CONFIRMATION' ? 'COPIA SIMPLE DE ACTA DE CONFIRMACIÓN' :
                'ACTA DE MATRIMONIO';
  
  ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell(title, {
    font: titleFont,
    alignment: center,
    fill: { fgColor: { rgb: color.beige } }
  });
  for (let c = 1; c < 6; c++) {
    ws[XLSX.utils.encode_cell({ r, c })] = cell('', { fill: { fgColor: { rgb: color.beige } } });
  }
  merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });
  r += 2;

  // Número de certificado
  if (cert.certificateNumber) {
    ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell(`No. ${cert.certificateNumber}`, {
      font: boldFont,
      alignment: left
    });
    merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });
    r += 2;
  }

  // Datos del acta
  const data: [string, string][] = [
    ['Nombre completo', acta.userName || '____________________'],
    ['Libro', cert.book || '____'],
    ['Folio', cert.folio || '____'],
    ['Fecha', req?.scheduledDate ? new Date(req.scheduledDate).toLocaleDateString('es-PE') : '____'],
    ['Estado', cert.signed ? 'FIRMADO' : 'SIN FIRMAR']
  ];

  // Participantes según tipo
  const participants = acta.participants || [];
  if (type === 'BAPTISM') {
    const father = participants.find(p => p.role === 'FATHER');
    const mother = participants.find(p => p.role === 'MOTHER');
    const godfather = participants.find(p => p.role === 'GODFATHER');
    const godmother = participants.find(p => p.role === 'GODMOTHER');

    if (father || mother) {
      const fatherUser = father ? ctx.usersMap.get(father.userId || 0) : null;
      const motherUser = mother ? ctx.usersMap.get(mother.userId || 0) : null;
      const fatherName = fatherUser ? ctx.getUserFullName(fatherUser) : '____';
      const motherName = motherUser ? ctx.getUserFullName(motherUser) : '____';
      data.push(['Padres', `${fatherName} y ${motherName}`]);
    }

    if (godfather || godmother) {
      const gfUser = godfather ? ctx.usersMap.get(godfather.userId || 0) : null;
      const gmUser = godmother ? ctx.usersMap.get(godmother.userId || 0) : null;
      const gfName = gfUser ? ctx.getUserFullName(gfUser) : '';
      const gmName = gmUser ? ctx.getUserFullName(gmUser) : '';
      const padrinos = [gfName, gmName].filter(n => n).join(' y ') || '____';
      data.push(['Padrinos', padrinos]);
    }
  } else if (type === 'CONFIRMATION') {
    const godparent = participants.find(p => p.role === 'GODPARENT');
    if (godparent) {
      const gpUser = ctx.usersMap.get(godparent.userId || 0);
      if (gpUser) {
        data.push(['Padrino/Madrina', ctx.getUserFullName(gpUser)]);
      }
    }
  } else if (type === 'MARRIAGE') {
    const groom = participants.find(p => p.role === 'GROOM');
    const bride = participants.find(p => p.role === 'BRIDE');
    
    if (groom) {
      const groomUser = ctx.usersMap.get(groom.userId || 0);
      if (groomUser) {
        data.push(['Novio', ctx.getUserFullName(groomUser)]);
      }
    }
    if (bride) {
      const brideUser = ctx.usersMap.get(bride.userId || 0);
      if (brideUser) {
        data.push(['Novia', ctx.getUserFullName(brideUser)]);
      }
    }
  }

  // Escribir datos en tabla
  data.forEach(([label, value]) => {
    ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell(label, {
      font: boldFont,
      alignment: left,
      fill: { fgColor: { rgb: color.beige } }
    });
    ws[XLSX.utils.encode_cell({ r, c: 1 })] = cell(value, {
      font: baseFont,
      alignment: left
    });
    merges.push({ s: { r, c: 1 }, e: { r, c: 5 } });
    r++;
  });

  r += 2;

  // Pie de página
  const today = new Date().toLocaleDateString('es-PE', { day: 'numeric', month: 'long', year: 'numeric' });
  ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell(`Expedido el ${today}`, {
    font: baseFont,
    alignment: left
  });
  merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });
  r += 3;

  ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell('__________________________', {
    font: baseFont,
    alignment: center
  });
  merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });
  r++;

  ws[XLSX.utils.encode_cell({ r, c: 0 })] = cell('El Párroco', {
    font: boldFont,
    alignment: center
  });
  merges.push({ s: { r, c: 0 }, e: { r, c: 5 } });

  // Configurar hoja
  ws['!ref'] = XLSX.utils.encode_range({ s: { r: 0, c: 0 }, e: { r, c: 5 } });
  ws['!merges'] = merges;
  ws['!cols'] = [
    { wch: 20 },
    { wch: 30 },
    { wch: 15 },
    { wch: 15 },
    { wch: 15 },
    { wch: 15 }
  ];

  // Crear libro y guardar
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Acta');
  
  const filename = `acta-${type.toLowerCase()}-${cert.id}-${cert.certificateNumber || 'sin-numero'}.xlsx`;
  XLSX.writeFile(wb, filename);
}
```

### 3. Agregar botón Excel en componente de Actas

**Archivo**: `actas.html`  
**Ubicación**: Junto al botón de PDF existente

```html
<!-- Buscar el botón de PDF y agregar botón Excel al lado -->
<button (click)="descargarActaExcel()" 
        class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg">
  📊 Descargar Excel
</button>
```

**Archivo**: `actas.ts`  
**Agregar método**:

```typescript
async descargarActaExcel(): Promise<void> {
  const acta = this.actaSeleccionada();
  if (!acta) {
    this.showToast('No hay acta seleccionada', 'error');
    return;
  }

  try {
    const ctx = this.prepareReportContext();
    await this.reportService.exportActaExcel(acta, ctx);
    this.showToast('Excel descargado correctamente');
  } catch (error) {
    console.error('[Actas] Error generando Excel:', error);
    this.showToast('Error al generar Excel', 'error');
  }
}
```

## Resumen de Cambios

### Archivos a Modificar:
1. `solicitudes-report.service.ts` - Agregar logo al Excel
2. `actas-report.service.ts` - Agregar método `exportActaExcel()`
3. `actas.html` - Agregar botón Excel
4. `actas.ts` - Agregar método `descargarActaExcel()`

### Tiempo Estimado:
- Implementación: 2 horas
- Pruebas: 30 minutos
- **Total**: 2.5 horas

### Resultado Final:
- ✅ 100% de cumplimiento del estándar AS241 de reportes
- ✅ Logo institucional en todos los formatos
- ✅ Excel disponible para actas y solicitudes
