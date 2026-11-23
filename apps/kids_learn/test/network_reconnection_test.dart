import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslearn/device_network_probe.dart';
import 'package:kidslearn/device_access_policy.dart';

void main() {
  test('real TCP/HTTP disconnect, reconnection, and server errors fail closed', () async {
    var server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = server.port;
    final endpoint = Uri.parse('http://127.0.0.1:$port/approval');
    var listener = server.listen((request) {
      request.response.statusCode = HttpStatus.ok;
      request.response.close();
    });
    try {
      // Actual loopback TCP request, not a mocked network state.
      expect(await DeviceNetworkProbe.check(endpoint), isTrue);
      await listener.cancel();
      await server.close(force: true);
      expect(await DeviceNetworkProbe.check(endpoint), isFalse);
      expect(DeviceAccessPolicy.canOpenLessons(DeviceVerification.offline), isFalse);

      // Reopen the same port to exercise a genuine socket reconnection.
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      listener = server.listen((request) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        request.response.close();
      });
      expect(await DeviceNetworkProbe.check(endpoint), isFalse);
      await listener.cancel();
      await server.close(force: true);

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      listener = server.listen((request) {
        request.response.statusCode = HttpStatus.ok;
        request.response.close();
      });
      expect(await DeviceNetworkProbe.check(endpoint), isTrue);
      // Transport availability alone must not authorize a child.
      expect(DeviceAccessPolicy.canOpenLessons(DeviceVerification.pending), isFalse);
      expect(DeviceAccessPolicy.canOpenLessons(
        DeviceAccessPolicy.fromServerResponse(true)), isTrue);
    } finally {
      await listener.cancel();
      await server.close(force: true);
    }
  });
}
