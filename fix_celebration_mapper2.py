# -*- coding: utf-8 -*-
from pathlib import Path

mapper = '''package pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.mapper;

import org.springframework.stereotype.Component;
import pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.dto.CertificateGenerationRequest;

@Component
public class CertificateClientMapper {

    public CertificateGenerationRequest toRequest(Long serviceId, Long celebrationId) {
        return new CertificateGenerationRequest(serviceId, celebrationId);
    }
}
'''

base = Path(r'D:\vg-ms-arquitect-main\vg-ms-celebrationservice-hexagonal')
dir_path = base / 'src/main/java/pe/edu/vallegrande/fideinexus/celebration/infrastructure/adapter/out/client/certificate/mapper'
dir_path.mkdir(parents=True, exist_ok=True)
(dir_path / 'CertificateClientMapper.java').write_text(mapper, encoding='utf-8')
print("Recreado CertificateClientMapper")

# Actualizar CertificateClientAdapter para usar el mapper de nuevo
adapter_path = base / 'src/main/java/pe/edu/vallegrande/fideinexus/celebration/infrastructure/adapter/out/client/certificate/CertificateClientAdapter.java'
t = adapter_path.read_text(encoding='utf-8')

# Agregar import
t = t.replace('import pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.dto.CertificateGenerationRequest;\n',
              'import pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.dto.CertificateGenerationRequest;\nimport pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.mapper.CertificateClientMapper;\n')

# Agregar campo
t = t.replace('    private final WebClient webClient;\n', '    private final WebClient webClient;\n    private final CertificateClientMapper mapper;\n')

# Agregar parámetro del constructor
t = t.replace('''    public CertificateClientAdapter(WebClient.Builder webClientBuilder,
                                    @Value("${services.certificate.url:http://localhost:8099}") String url) {
        this.webClient = webClientBuilder.baseUrl(url).build();
''', '''    public CertificateClientAdapter(WebClient.Builder webClientBuilder,
                                    CertificateClientMapper mapper,
                                    @Value("${services.certificate.url:http://localhost:8099}") String url) {
        this.webClient = webClientBuilder.baseUrl(url).build();
        this.mapper = mapper;
''')

# Reemplazar uso directo del DTO por el mapper
t = t.replace('.bodyValue(new pe.edu.vallegrande.fideinexus.celebration.infrastructure.adapter.out.client.certificate.dto.CertificateGenerationRequest(serviceId, celebrationId))',
              '.bodyValue(mapper.toRequest(serviceId, celebrationId))')

adapter_path.write_text(t, encoding='utf-8')
print("CertificateClientAdapter actualizado para usar mapper")
