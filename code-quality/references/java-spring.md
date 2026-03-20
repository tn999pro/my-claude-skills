# Reglas específicas — Java / Spring Boot

## 🔴 CRÍTICO

### JWT y Seguridad
```java
// ❌ Expiración de 720 minutos es muy larga para tokens sin refresh
// Revisar si hay refresh token implementado
.expiration(new Date(System.currentTimeMillis() + 720 * 60 * 1000))

// ✅ Con refresh token: access 15-60 min, refresh 7-30 días
// Sin refresh token: máximo 60-120 minutos

// ❌ BlackList en memoria — se pierde al reiniciar la app
// Si hay múltiples instancias del servicio, no se comparte
private final Set<String> blacklistedTokens = new HashSet<>();

// ✅ BlackList en Redis o en BD con TTL igual al JWT
@Repository
public interface TokenBlacklistRepository extends JpaRepository<BlacklistedToken, String> {
    boolean existsByTokenAndExpiresAtAfter(String token, LocalDateTime now);
}
```

### Transacciones
```java
// ❌ Sin @Transactional en operaciones que modifican múltiples tablas
public void createUserWithRoles(UserDTO dto) {
    User user = userRepository.save(mapToEntity(dto));
    roleRepository.assignRoles(user.getId(), dto.getRoles()); // si falla, user queda sin roles
}

// ✅ @Transactional garantiza rollback completo
@Transactional
public void createUserWithRoles(UserDTO dto) {
    User user = userRepository.save(mapToEntity(dto));
    roleRepository.assignRoles(user.getId(), dto.getRoles());
}
```

### SQL Injection
```java
// ❌ Query con concatenación de strings
@Query("SELECT u FROM User u WHERE u.name = '" + name + "'")

// ✅ Parámetros nombrados
@Query("SELECT u FROM User u WHERE u.name = :name")
User findByName(@Param("name") String name);
```

### Recursos no cerrados
```java
// ❌ Stream no cerrado
InputStream is = connection.getInputStream();
// ... usar is pero nunca cerrar

// ✅ try-with-resources
try (InputStream is = connection.getInputStream()) {
    // usar is
}
```

---

## 🟡 MEDIO

### N+1 Queries
```java
// ❌ Query por cada elemento del loop
List<User> users = userRepository.findAll();
for (User user : users) {
    List<Role> roles = roleRepository.findByUserId(user.getId()); // N queries extra
}

// ✅ JOIN FETCH en la query inicial
@Query("SELECT u FROM User u LEFT JOIN FETCH u.roles")
List<User> findAllWithRoles();
```

### Manejo de errores en Spring
```java
// ❌ Excepción genérica con stack trace en producción
try {
    externalApiService.call();
} catch (Exception e) {
    e.printStackTrace(); // expone info interna
    throw e;
}

// ✅ Handler centralizado con respuesta controlada
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(EntityNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(EntityNotFoundException e) {
        return ResponseEntity.status(404).body(new ErrorResponse(e.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleGeneric(Exception e) {
        log.error("Error inesperado", e); // log interno
        return ResponseEntity.status(500).body(new ErrorResponse("Error interno"));
    }
}
```

### Validación de entrada
```java
// ❌ Validación manual en el service
public UserDTO createUser(UserDTO dto) {
    if (dto.getEmail() == null || dto.getEmail().isEmpty()) {
        throw new IllegalArgumentException("Email requerido");
    }
}

// ✅ Bean Validation en el DTO + @Valid en el controller
public class UserDTO {
    @NotBlank(message = "Email requerido")
    @Email(message = "Email inválido")
    private String email;

    @NotBlank
    @Size(min = 8, message = "Mínimo 8 caracteres")
    private String password;
}

@PostMapping("/users")
public ResponseEntity<UserDTO> create(@Valid @RequestBody UserDTO dto) { ... }
```

### Servicios con múltiples responsabilidades
```java
// ❌ Service que hace todo
public class PersonService {
    public void createPerson(...) {
        // validar
        // guardar en BD
        // enviar email
        // notificar a InfoVotantes
        // generar reporte
    }
}

// ✅ Delegar responsabilidades
public class PersonService {
    private final PersonRepository repository;
    private final EmailService emailService;
    private final InfoVotantesService infoVotantesService;

    @Transactional
    public Person createPerson(PersonDTO dto) {
        Person person = repository.save(mapper.toEntity(dto));
        applicationEventPublisher.publishEvent(new UserCreatedEvent(person));
        return person;
    }
}
```

---

## 🟢 BAJO

### Paginación obligatoria
```java
// ❌ Retorna toda la tabla
public List<Person> getAllPersons() {
    return personRepository.findAll();
}

// ✅ Siempre paginar listas potencialmente grandes
public Page<PersonDTO> getAllPersons(Pageable pageable) {
    return personRepository.findAll(pageable).map(mapper::toDTO);
}

// Controller
@GetMapping("/persons")
public ResponseEntity<Page<PersonDTO>> list(
    @PageableDefault(size = 20, sort = "createdAt", direction = DESC) Pageable pageable
) { ... }
```

### Magic numbers
```java
// ❌ Números sin contexto
if (token.expiration > 43200000) { ... }
Thread.sleep(300000);

// ✅ Constantes nombradas
private static final long JWT_EXPIRATION_MS = 720 * 60 * 1000L; // 720 minutos
private static final long JOB_INTERVAL_MS = 5 * 60 * 1000L;    // 5 minutos
```

### Scheduled jobs — robustez
```java
// ❌ Job sin manejo de errores — si falla, no hay log útil
@Scheduled(cron = "${pending-data.job.cron}")
public void syncPendingData() {
    externalApiService.sync();
}

// ✅ Con logging, manejo de errores y lock para evitar solapamiento
@Scheduled(cron = "${pending-data.job.cron}")
@SchedulerLock(name = "syncPendingData", lockAtMostFor = "4m", lockAtLeastFor = "1m")
public void syncPendingData() {
    log.info("Iniciando sync de datos pendientes");
    try {
        int processed = externalApiService.sync();
        log.info("Sync completado. Procesados: {}", processed);
    } catch (Exception e) {
        log.error("Error en sync de datos pendientes", e);
        // No relanzar — el scheduler debe continuar en el siguiente ciclo
    }
}
```

### Tests unitarios en Spring Boot
```java
// Estructura mínima para un service test
@ExtendWith(MockitoExtension.class)
class PersonServiceTest {
    @Mock PersonRepository repository;
    @Mock EmailService emailService;
    @InjectMocks PersonService service;

    @Test
    void createPerson_shouldSaveAndPublishEvent() {
        // Arrange
        PersonDTO dto = new PersonDTO("Juan", "juan@test.com");
        Person saved = new Person(1L, "Juan", "juan@test.com");
        when(repository.save(any())).thenReturn(saved);

        // Act
        Person result = service.createPerson(dto);

        // Assert
        assertThat(result.getId()).isNotNull();
        verify(repository).save(any(Person.class));
    }

    @Test
    void createPerson_whenEmailExists_shouldThrowConflict() {
        when(repository.existsByEmail(any())).thenReturn(true);
        assertThatThrownBy(() -> service.createPerson(dto))
            .isInstanceOf(ConflictException.class);
    }
}
```
