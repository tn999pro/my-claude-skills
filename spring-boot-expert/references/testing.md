# Testing en Spring Boot

## Convención de nombres

```
metodo_escenario_resultadoEsperado

create_whenNameDuplicated_throwsConflict
list_whenEmpresaHasNoProducts_returnsEmptyPage
login_withInvalidPassword_returns401
```

## Test de service — unitario con Mockito (el más común)

```java
@ExtendWith(MockitoExtension.class)
class ProductServiceImplTest {

    @Mock ProductRepository productRepository;
    @Mock ProductMapper productMapper;
    @InjectMocks ProductServiceImpl productService;

    @Test
    void create_whenValid_savesAndReturnsDTO() {
        // Arrange
        ProductCreateDTO dto = new ProductCreateDTO("Nike Air", new BigDecimal("150000"), List.of());
        Product entity = new Product();
        when(productRepository.existsByName("Nike Air")).thenReturn(false);
        when(productMapper.toEntity(dto)).thenReturn(entity);
        when(productRepository.save(entity)).thenReturn(entity);
        when(productMapper.toDTO(entity)).thenReturn(new ProductDTO(1L, "Nike Air"));

        // Act
        ProductDTO result = productService.create(dto);

        // Assert (AssertJ)
        assertThat(result.name()).isEqualTo("Nike Air");
        verify(productRepository).save(entity);
    }

    @Test
    void create_whenNameDuplicated_throwsConflict() {
        when(productRepository.existsByName("Nike Air")).thenReturn(true);

        assertThatThrownBy(() -> productService.create(dto))
            .isInstanceOf(ApiException.class)
            .hasFieldOrPropertyWithValue("status", HttpStatus.CONFLICT);

        verify(productRepository, never()).save(any());   // verificar el NO-efecto
    }
}
```

**Regla:** testear siempre el caso de error, no solo el happy path.

## Test de controller — @WebMvcTest con security

```java
@WebMvcTest(ProductController.class)
@Import(SecurityConfig.class)
class ProductControllerTest {

    @Autowired MockMvc mockMvc;

    // Spring Boot 3.4+: @MockitoBean (reemplaza a @MockBean, deprecado)
    @MockitoBean ProductService productService;
    @MockitoBean JwtService jwtService;

    @Test
    @WithMockUser(authorities = "products:manage")
    void create_whenValid_returns201() throws Exception {
        when(productService.create(any())).thenReturn(new ProductDTO(1L, "Nike Air"));

        mockMvc.perform(post("/api/products")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"name": "Nike Air", "price": 150000}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.name").value("Nike Air"));
    }

    @Test
    @WithMockUser(authorities = "products:read")   // permiso insuficiente
    void create_withoutManagePermission_returns403() throws Exception {
        mockMvc.perform(post("/api/products")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\": \"X\", \"price\": 1}"))
            .andExpect(status().isForbidden());
    }

    @Test
    void create_withoutAuth_returns401() throws Exception {
        mockMvc.perform(post("/api/products")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
            .andExpect(status().isUnauthorized());
    }
}
```

## Test de repository — @DataJpaTest

```java
@DataJpaTest
// Por defecto usa H2 en memoria. Si las queries usan features de PostgreSQL
// (unaccent, jsonb), usar Testcontainers:
// @AutoConfigureTestDatabase(replace = Replace.NONE) + @Testcontainers
class ProductRepositoryTest {

    @Autowired ProductRepository productRepository;
    @Autowired TestEntityManager entityManager;

    @Test
    void findByEmpresaId_returnsOnlyThatCompanyProducts() {
        Empresa e1 = entityManager.persist(new Empresa("Tienda A"));
        Empresa e2 = entityManager.persist(new Empresa("Tienda B"));
        entityManager.persist(new Product("P1", e1));
        entityManager.persist(new Product("P2", e2));

        List<Product> result = productRepository.findByEmpresaId(e1.getId());

        assertThat(result).hasSize(1).extracting(Product::getName).containsExactly("P1");
    }
}
```

## Tests parametrizados — para validaciones y parsers

```java
@ParameterizedTest
@CsvSource({
    "'', false",
    "'a', false",
    "'nombre-valido', true",
})
void isValidName_coversEdgeCases(String name, boolean expected) {
    assertThat(validator.isValidName(name)).isEqualTo(expected);
}
```

## Qué testear (prioridad)

1. **Lógica de negocio en services** — unitario con mocks (rápido, la mayoría)
2. **Seguridad de endpoints** — 401/403/permiso correcto por rol
3. **Validación de DTOs** — campos requeridos, rangos, formatos (vía controller test)
4. **Queries custom** — `@DataJpaTest` solo para JPQL/SQL no trivial
5. NO testear getters/setters, mappers triviales ni el framework
