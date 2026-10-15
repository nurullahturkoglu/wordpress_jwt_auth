class AppStrings {
  // App Title
  static const String appTitle = 'WordPress JWT Auth';

  // Login Page
  static const String signInTitle = 'Sign in to WordPress';
  static const String welcomeBack = 'Welcome back!';
  static const String username = 'Username';
  static const String password = 'Password';
  static const String signIn = 'Sign in';
  static const String dontHaveAccount = 'Don\'t have an account?';
  static const String createAccount = 'Create account';

  // Register Page
  static const String createAccountTitle = 'Create an Account';
  static const String joinUsToday = 'Join us today';
  static const String email = 'Email';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String login = 'Login';
  static const String createAccountButton = 'Create Account';
  static const String accountCreated = 'Account created, you can sign in now';

  // Home Page
  static const String home = 'Home';
  static const String welcomeLoggedIn = 'Welcome! You are logged in.';
  static const String homeSubtitle =
      'Your token was validated by the site before this page opened.';
  static const String booksSubtitle = 'A protected page with a search field';
  static const String profileSubtitle = 'Loaded live from /wp/v2/users/me';
  static const String logout = 'Logout';

  // Books Page
  static const String books = 'Books';
  static const String searchBooks = 'Search Books';
  static const String noBooksFound = 'No books found';

  // Profile Page
  static const String profile = 'Profile';
  static const String userId = 'User ID';
  static const String displayName = 'Display name';
  static const String roles = 'Roles';
  static const String couldNotLoadProfile = 'Could not load profile';

  // Messages
  static const String loginSuccessful = 'Login successful';
  static const String usernameOrPasswordIncorrect =
      'Username or password is incorrect';
  static const String sessionExpired =
      'Your session has expired, sign in again';
  static const String serverNotConfigured =
      'The site is not set up for JWT authentication';
  static const String networkError = 'Could not reach the site';
  static const String unexpectedResponse = 'Unexpected response from the site';
  static const String retry = 'Retry';

  // Validation Messages
  static const String pleaseEnterUsername = 'Please enter your username';
  static const String pleaseEnterEmail = 'Please enter your email';
  static const String pleaseEnterPassword = 'Please enter your password';
}
