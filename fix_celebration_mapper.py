# -*- coding: utf-8 -*-
from pathlib import Path

# 1. Modificar CertificateClientAdapter para no usar mapper
adapter_path = Path(r'D:\vg-ms-arquitect-main\vg-ms-celebrationservice-hexagonal\src\main\java\pe\edu\vallegrande\fideinexus\celebration\infrastructure\adapter\out\client\certificate\CertificateClientAdapter.java')
t = adapter_path.read_text(encoding='utf-8')

# Eliminar import del mapper
t = t.replace('import pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.mapper.CertificateClientMapper;\n', '')

# Eliminar campo mapper
t = t.replace('    private final CertificateClientMapper mapper;\n\n', '')

# Eliminar parámetro del constructor
t = t.replace('''    public CertificateClientAdapter(WebClient.Builder webClientBuilder,
                                    CertificateClientMapper mapper,
                                    @Value("${services.certificate.url:http://localhost:8099}") String url) {
        this.webClient = webClientBuilder.baseUrl(url).build();
        this.mapper = mapper;
''', '''    public CertificateClientAdapter(WebClient.Builder webClientBuilder,
                                    @Value("${services.certificate.url:http://localhost:8099}") String url) {
        this.webClient = webClientBuilder.baseUrl(url).build();
''')

# Reemplazar uso del mapper
t = t.replace('.bodyValue(mapper.toRequest(serviceId, celebrationId))', '.bodyValue(new pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.dto.CertificateGenerationRequest(serviceId, celebrationId))')

adapter_path.write_text(t, encoding='utf-8')
print("CertificateClientAdapter actualizado")

# 2. Eliminar el archivo CertificateClientMapper.java
mapper_path = Path(r'D:\vg-ms-arquitect-main\vg-ms-celebrationservice-hexagonal\src\main\java\pe\edu\vallegrande\fideinexus\celebration\infrastructure\adapter\out\client\certificate\mapper\CertificateClientMapper.java')
if mapper_path.exists():
    mapper_path.unlink()
    print("CertificateClientMapper.java eliminado")

# 3. Eliminar la carpeta mapper si queda vacía
mapper_dir = mapper_path.parent
if mapper_dir.exists() and not list(mapper_dir.iterdir()):
    mapper_dir.rmdir()
    print("Carpeta mapper/ eliminada")
