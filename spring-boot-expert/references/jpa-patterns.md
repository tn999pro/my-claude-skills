# JPA / Hibernate — Patrones

## N+1 — el problema #1 de rendimiento

```java
// ❌ 1 query por la lista + N queries por los roles de cada usuario
List<User> users = userRepository.findAll();
users.forEach(u -> u.getRoles().size());

// ✅ JOIN FETCH
@Query("SELECT DISTINCT u FROM User u LEFT JOIN FETCH u.roles")
List<User> findAllWithRoles();

// ✅ @EntityGraph (mismo efecto, sin JPQL)
@EntityGraph(attributePaths = {"roles"})
Page<User> findAll(Pageable pageable);   // compatible con paginación
```

**Detectarlo:** activar en dev `spring.jpa.properties.hibernate.generate_statistics=true`
o revisar logs SQL — si una pantalla dispara decenas de queries iguales, es N+1.

⚠️ `JOIN FETCH` de colecciones + `Pageable` → Hibernate pagina en memoria
(warning `HHH90003004`). Para paginar con relaciones: `@EntityGraph` con
relaciones `@ManyToOne`, o dos queries (ids paginados + fetch por ids).

## Relaciones — defaults seguros

```java
// SIEMPRE LAZY en @ManyToOne (es EAGER por defecto — trampa)
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "empresa_id", nullable = false)
private Empresa empresa;

// Colecciones: LAZY por defecto (dejarlo así)
@OneToMany(mappedBy = "pedido", cascade = CascadeType.ALL, orphanRemoval = true)
private List<PedidoItem> items = new ArrayList<>();
```

## Transacciones

```java
@Transactional                      // escrituras multi-tabla: rollback completo
@Transactional(readOnly = true)     // lecturas: optimiza flush/dirty checking

// ❌ Self-invocation NO abre transacción (proxy de Spring no intercepta)
public void metodoA() { this.metodoTransaccional(); }

// ❌ Catch que se traga la excepción dentro de @Transactional
//    → la transacción NO hace rollback y se commitea a medias
@Transactional
public void crear(...) {
    try { repo.save(a); repo.save(b); }
    catch (Exception e) { log.error("...", e); }  // ¡b falló y a se commitea!
}
```

## Proyecciones — no traer la entidad completa para 2 campos

```java
// Record como proyección (Spring Data lo mapea solo)
public record ProductSummary(Long id, String name, BigDecimal price) {}

@Query("SELECT new com.app.dto.ProductSummary(p.id, p.name, p.price) " +
       "FROM Product p WHERE p.empresa.id = :empresaId")
Page<ProductSummary> findSummaries(Long empresaId, Pageable pageable);
```

## Filtros dinámicos con Specifications

```java
// Para búsquedas con filtros opcionales — evita explosión de findByXAndYAndZ
public static Specification<Product> withFilters(String name, Long categoryId) {
    return (root, query, cb) -> {
        List<Predicate> predicates = new ArrayList<>();
        if (name != null) predicates.add(cb.like(cb.lower(root.get("name")), "%" + name.toLowerCase() + "%"));
        if (categoryId != null) predicates.add(cb.equal(root.get("category").get("id"), categoryId));
        return cb.and(predicates.toArray(new Predicate[0]));
    };
}
// repository extends JpaSpecificationExecutor<Product>
productRepository.findAll(withFilters(name, categoryId), pageable);
```

## Soft delete

```java
@Entity
@SQLDelete(sql = "UPDATE products SET deleted_at = NOW() WHERE id = ?")
@SQLRestriction("deleted_at IS NULL")   // Hibernate 6.3+; antes: @Where
public class Product {
    private LocalDateTime deletedAt;
}
```
Usarlo cuando el negocio necesita historial (pedidos, clientes). Las tablas
puramente operativas pueden borrar de verdad.

## Auditoría de fechas

```java
@EnableJpaAuditing   // en una clase @Configuration

@MappedSuperclass
@EntityListeners(AuditingEntityListener.class)
public abstract class Auditable {
    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;
}
```

## equals/hashCode en entidades

```java
// ❌ @Data de Lombok en entidades — equals/hashCode con campos lazy + toString
//    que dispara queries. Usar @Getter/@Setter y equals por id:
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (!(o instanceof Product other)) return false;
    return id != null && id.equals(other.id);
}
@Override
public int hashCode() { return getClass().hashCode(); }
```

## Reglas rápidas

- `Optional<T>` en repos para búsquedas por id/único: `findById`, `findByEmail`
- Paginación SIEMPRE en listados (`Page<T>` / `Slice<T>`)
- Índices y constraints van en la migración Flyway, no solo en anotaciones JPA
- `saveAll()` + `spring.jpa.properties.hibernate.jdbc.batch_size=50` para inserts masivos
