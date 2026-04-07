abstract class AuthRepository {
  Future<void> localGuest();
  Future<void> googleSignIn();
  Future<void> signOut();
  Future<String?> currentUser();
}
