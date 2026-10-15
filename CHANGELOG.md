## 1.0.0

First release as a package. The repository previously held only the example app.

- `WordPressJwtAuth` client for `POST /jwt-auth/v1/token` and `POST /jwt-auth/v1/token/validate`.
- `currentUser()` reads the token owner from `GET /wp/v2/users/me?context=edit`, no plugin patch needed.
- Optional `register()` against the endpoint shipped in `wordpress/jwt-auth-register.php`.
- Sealed `JwtAuthException` hierarchy with HTML stripped messages: `InvalidCredentialsException`, `InvalidTokenException`, `ServerConfigurationException`, `RegistrationException`, `NetworkException`, `UnexpectedResponseException`.
- `JwtClaims` decodes `exp` and the user ID from the token without a network call.
- `TokenStorage` interface with `InMemoryTokenStorage`; the example app implements it with `flutter_secure_storage`.
- `JwtAuthInterceptor` adds the bearer header to any Dio instance.
