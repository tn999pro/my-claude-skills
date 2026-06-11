# Flyway + MapStruct

## Flyway — migraciones versionadas

### Convenciones
```
src/main/resources/db/migration/
  V1__create_base_tables.sql
  V2__add_products_table.sql
  V3__add_index_products_name.sql
  R__views_reporting.sql          ← repeatable: se re-ejecuta si cambia
```
- `V{n}__descripcion_en_snake_case.sql` — número secuencial, doble guion bajo.
- **NUNCA editar una migración ya aplicada** (checksum mismatch rompe el
  arranque en todos los entornos). Corregir = nueva migración.
- Migración + cambio de entidad + código que lo usa: **mismo commit/PR**.
- Con Flyway activo: `spring.jpa.hibernate.ddl-auto=validate` (nunca `update`).

### application.properties
```properties
spring.flyway.enabled=true
spring.flyway.locations=classpath:db/migration
spring.jpa.hibernate.ddl-auto=validate
```

### Patrones de migración
```sql
-- V4__add_status_to_orders.sql
-- Columna nueva en tabla con datos: con DEFAULT o nullable + backfill
ALTER TABLE orders ADD COLUMN status VARCHAR(30) NOT NULL DEFAULT 'PENDING';

-- Índices y constraints SIEMPRE por migración (no confiar en JPA)
CREATE INDEX idx_products_empresa_name ON products (empresa_id, name);
ALTER TABLE products ADD CONSTRAINT uq_products_empresa_sku UNIQUE (empresa_id, sku);

-- Datos semilla idempotentes
INSERT INTO roles (name) VALUES ('SUPERADMIN'), ('ADMIN'), ('CLIENTE')
ON CONFLICT (name) DO NOTHING;
```

### Comandos útiles
```powershell
.\mvnw flyway:info      # estado de migraciones (cuáles aplicadas/pendientes)
.\mvnw flyway:validate  # detectar checksums rotos
.\mvnw flyway:repair    # reparar historial tras un fallo (usar con criterio)
```

### Equipo de 2 — evitar colisiones de versión
Si ambos crean `V5__...` en ramas paralelas, el segundo en mergear renombra la
suya al siguiente número. Antes de crear una migración: revisar `develop` por
la última versión (`git fetch` + mirar `db/migration/` en origin/develop).

---

## MapStruct — mapeo entidad <-> DTO

### Mapper básico
```java
@Mapper(componentModel = "spring")   // genera un bean inyectable
public interface ProductMapper {

    ProductDTO toDTO(Product entity);

    List<ProductDTO> toDTOList(List<Product> entities);

    @Mapping(target = "id", ignore = true)
    @Mapping(target = "createdAt", ignore = true)
    Product toEntity(ProductCreateDTO dto);
}
```

### Campos con nombre distinto o derivados
```java
@Mapper(componentModel = "spring")
public interface OrderMapper {

    @Mapping(target = "clientName", source = "cliente.nombre")
    @Mapping(target = "totalItems", expression = "java(order.getItems().size())")
    OrderDTO toDTO(Order order);
}
```

### Update parcial (PATCH) — ignorar nulls del DTO
```java
@BeanMapping(nullValuePropertyMappingStrategy = NullValuePropertyMappingStrategy.IGNORE)
@Mapping(target = "id", ignore = true)
void updateEntity(ProductUpdateDTO dto, @MappingTarget Product entity);

// En el service:
Product product = productRepository.findById(id)
    .orElseThrow(() -> new ApiException(Constants.PRODUCT_NOT_FOUND, HttpStatus.NOT_FOUND));
productMapper.updateEntity(dto, product);   // solo pisa campos no-null
```

### Mappers anidados
```java
@Mapper(componentModel = "spring", uses = {ItemMapper.class, ClienteMapper.class})
public interface OrderMapper { ... }   // delega items y cliente a sus mappers
```

### Integración Lombok + MapStruct (pom.xml)

El orden de annotation processors importa — Lombok debe correr ANTES:

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-compiler-plugin</artifactId>
  <configuration>
    <annotationProcessorPaths>
      <path>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <version>${lombok.version}</version>
      </path>
      <path>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok-mapstruct-binding</artifactId>
        <version>0.2.0</version>
      </path>
      <path>
        <groupId>org.mapstruct</groupId>
        <artifactId>mapstruct-processor</artifactId>
        <version>${mapstruct.version}</version>
      </path>
    </annotationProcessorPaths>
  </configuration>
</plugin>
```

### Errores frecuentes

| Síntoma | Causa / Fix |
|---|---|
| `Unknown property in result type` | Nombre de campo no coincide → `@Mapping(source/target)` |
| Mapper retorna null en tests unitarios | No es contexto Spring → `Mappers.getMapper(ProductMapper.class)` |
| Campos Lombok "no existen" al compilar | Orden de processors (ver pom arriba) |
| Relación lazy se serializa entera | El mapper navegó la relación → mapear solo id/nombre con `@Mapping` |
