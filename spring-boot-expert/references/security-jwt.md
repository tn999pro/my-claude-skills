# Spring Security — JWT stateless

## SecurityConfig (Spring Security 6 / Boot 3.x)

```java
@Configuration
@EnableWebSecurity
@EnableMethodSecurity   // habilita @PreAuthorize
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        return http
            .csrf(AbstractHttpConfigurer::disable)              // API stateless: sin CSRF
            .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**").permitAll()
                .requestMatchers(HttpMethod.GET, "/api/public/**").permitAll()
                .anyRequest().authenticated())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)
            .build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();   // nunca texto plano ni MD5/SHA1
    }
}
```

## Filtro JWT

```java
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header == null || !header.startsWith("Bearer ")) {
            chain.doFilter(request, response);
            return;
        }
        try {
            String token = header.substring(7);
            String username = jwtService.extractUsername(token);
            if (username != null && SecurityContextHolder.getContext().getAuthentication() == null) {
                UserDetails user = userDetailsService.loadUserByUsername(username);
                if (jwtService.isValid(token, user)) {
                    var auth = new UsernamePasswordAuthenticationToken(
                        user, null, user.getAuthorities());
                    auth.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(auth);
                }
            }
        } catch (JwtException e) {
            // token inválido/expirado → seguir sin autenticar; el endpoint
            // protegido responderá 401. NO lanzar excepción desde el filtro.
        }
        chain.doFilter(request, response);
    }
}
```

## Catálogo de permisos por rol

Permisos granulares (`recurso:acción`) en un solo lugar — no esparcir strings:

```java
public final class RolePermissionCatalog {
    public static final String PRODUCTS_READ = "products:read";
    public static final String PRODUCTS_MANAGE = "products:manage";
    public static final String ORDERS_MANAGE = "orders:manage";
    public static final String USERS_MANAGE = "users:manage";

    public static Set<String> forRole(String role) {
        return switch (role) {
            case "SUPERADMIN" -> Set.of(PRODUCTS_READ, PRODUCTS_MANAGE, ORDERS_MANAGE, USERS_MANAGE);
            case "ADMIN" -> Set.of(PRODUCTS_READ, PRODUCTS_MANAGE, ORDERS_MANAGE);
            case "CLIENTE" -> Set.of(PRODUCTS_READ);
            default -> Set.of();
        };
    }
}

// En el controller — permisos, no roles directos
@PreAuthorize("hasAuthority('products:manage')")
```

## Reglas de tokens

- **Access token corto**: 15–60 min con refresh token; máximo 2 h sin refresh.
- **Secret** de al menos 256 bits, SIEMPRE desde variable de entorno.
- **Blacklist** (logout/revocación): en BD o Redis con TTL = expiración del
  token — nunca en un `Set` en memoria (se pierde al reiniciar, no se comparte
  entre instancias).
- No meter datos sensibles en los claims (el payload es legible por cualquiera).

## CORS para API consumida por frontend propio

```java
@Bean
public CorsConfigurationSource corsConfigurationSource(
        @Value("${cors.allowed-origins}") List<String> origins) {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(origins);   // NUNCA "*" con credenciales
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE"));
    config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
    config.setAllowCredentials(true);
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/api/**", config);
    return source;
}
```
Orígenes por entorno en `application.properties` — no hardcodeados.

## 401 vs 403 — no confundirlos

| Situación | Código |
|---|---|
| Sin token, token inválido o expirado | **401 Unauthorized** |
| Token válido pero sin el permiso requerido | **403 Forbidden** |

```java
// Respuestas JSON consistentes con el GlobalExceptionHandler
http.exceptionHandling(e -> e
    .authenticationEntryPoint((req, res, ex) -> writeJson(res, 401, "No autenticado"))
    .accessDeniedHandler((req, res, ex) -> writeJson(res, 403, "Sin permisos")));
```
