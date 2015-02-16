part of bwu_datastore_launcher;

String getHost(address) {
  if (address is InternetAddress) {
    switch (address) {
      case InternetAddress.loopbackIpV4:
        return io.InternetAddress.LOOPBACK_IP_V4.address;
      case InternetAddress.loopbackIpV6:
        return io.InternetAddress.LOOPBACK_IP_V6.address;
      case InternetAddress.anyIpV4:
        return io.InternetAddress.ANY_IP_V4.address;
      case InternetAddress.anyIpV6:
        return io.InternetAddress.ANY_IP_V6.address;
    }
  }
  return address;
}

Future<int> getNextFreeIpPort(
    {host: InternetAddress.loopbackIpV4}) async {
  return io.ServerSocket.bind(getHost(host), 0).then((socket) {
    final port = socket.port;
    socket.close();
    return port;
  });
}

enum InternetAddress { loopbackIpV4, loopbackIpV6, anyIpV4, anyIpV6, }

