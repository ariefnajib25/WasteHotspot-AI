class UserStore {
  static String currentUserEmail = '';
  static String currentUserName = 'User';

  static void login({
    required String email,
    String name = 'User',
  }) {
    currentUserEmail = email.trim().toLowerCase();
    currentUserName = name;
  }

  static void logout() {
    currentUserEmail = '';
    currentUserName = 'User';
  }
}