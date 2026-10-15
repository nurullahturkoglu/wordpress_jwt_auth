<?php
/**
 * Plugin Name: JWT Auth Register Endpoint
 * Plugin URI:  https://github.com/nurullahturkoglu/wordpress_jwt_auth
 * Description: Adds POST /wp-json/jwt-auth/v1/register next to the endpoints of "JWT Authentication for WP REST API". Honours the "Anyone can register" setting.
 * Version:     1.0.0
 * Requires PHP: 7.4
 * License:     MIT
 */

if ( ! defined( 'WPINC' ) ) {
	die;
}

add_action( 'rest_api_init', function () {
	register_rest_route( 'jwt-auth/v1', 'register', [
		'methods'             => 'POST',
		'callback'            => 'jwt_auth_register_endpoint',
		'permission_callback' => '__return_true',
		'args'                => [
			'username' => [ 'required' => true, 'type' => 'string' ],
			'email'    => [ 'required' => true, 'type' => 'string' ],
			'password' => [ 'required' => true, 'type' => 'string' ],
		],
	] );
} );

/**
 * Creates a user with the site's default role.
 *
 * Errors use the same shape as the JWT plugin: { code, message, data: { status } }.
 *
 * @param WP_REST_Request $request
 * @return WP_REST_Response|WP_Error
 */
function jwt_auth_register_endpoint( WP_REST_Request $request ) {
	if ( ! get_option( 'users_can_register' ) ) {
		return new WP_Error(
			'jwt_auth_registration_disabled',
			__( 'User registration is currently not allowed.' ),
			[ 'status' => 403 ]
		);
	}

	$username = sanitize_user( (string) $request->get_param( 'username' ), true );
	$email    = sanitize_email( (string) $request->get_param( 'email' ) );
	$password = (string) $request->get_param( 'password' );

	if ( ! is_email( $email ) ) {
		return new WP_Error(
			'jwt_auth_invalid_email',
			__( 'The email address isn&#8217;t correct.' ),
			[ 'status' => 400 ]
		);
	}

	if ( '' === $password ) {
		return new WP_Error(
			'jwt_auth_empty_password',
			__( 'The password cannot be empty.' ),
			[ 'status' => 400 ]
		);
	}

	$user_id = wp_create_user( $username, $password, $email );

	if ( is_wp_error( $user_id ) ) {
		$user_id->add_data( [ 'status' => 400 ] );
		return $user_id;
	}

	return new WP_REST_Response(
		[
			'id'       => $user_id,
			'username' => $username,
			'email'    => $email,
		],
		201
	);
}
