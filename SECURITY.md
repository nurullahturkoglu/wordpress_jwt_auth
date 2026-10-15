# Security Policy

## Supported versions

Only the latest release on pub.dev receives fixes.

## Reporting a vulnerability

Please do not open a public issue for security problems. Use the private
"Report a vulnerability" form under the Security tab of this repository, or
email info@solorota.com. You will get a reply within a week.

Problems in the WordPress plugin itself (token signing, validation, CORS)
should go to the plugin authors at https://github.com/Tmeister/wp-api-jwt-auth.

## Scope notes

The package decodes JWT claims locally without verifying the signature. That
is by design: the client has no access to the server secret, and the server
validates every token on `token/validate` and on each protected request.
Treat `JwtClaims` as a hint for the UI, not as proof of identity.

The optional `register` endpoint shipped in `wordpress/jwt-auth-register.php`
is unauthenticated. Keep `users_can_register` off unless you add rate limiting
or a captcha in front of it.
