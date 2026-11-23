import 'dart:async';
import 'dart:io';

/// A live HTTP probe used only by integration tests and diagnostics.
/// Real network errors, server failures and timeouts never grant access.
class DeviceNetworkProbe {
  static Future<bool> check(Uri endpoint, {Duration timeout = const Duration(seconds: 2)}) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(endpoint).timeout(timeout);
      final response = await request.close().timeout(timeout);
      await response.drain<void>().timeout(timeout);
      return response.statusCode == HttpStatus.ok;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } on HttpException {
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }
}
