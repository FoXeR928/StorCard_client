class AuthResult {
  AuthResult.success() : error = null, isSuccess = true;
  AuthResult.failure(this.error) : isSuccess = false;

  final bool isSuccess;
  final String? error;
}
