## 0.3.2
- use new bwu_utils
- add grinder tasks
- use IPV6 by default if available
- add url getter to Server

## 0.3.1
- lower logging level for server process output, because all output from the
server is sent to stderr.

## 0.3.0+1
- add dependency constraints

## 0.3.0
- Use logging instead of print
- Change shutdown delay to startup delay (the start command returns only after
 a delay to ensure the server is ready to process commands).

## 0.2.3+1
- Fix some mistake with inconsistent version numbers during deployment.

## 0.2.3
- Add minimum delay for remoteShutdown to wait until the server is ready to
process the shutdown request.

## 0.2.2
- move utility function getNextFreeIpPort to the bwu_util_server package.
- change host field form String to InternetAddress.

## 0.2.1
- Some refactoring

## 0.2.0
- Support for Appengine API Server added

## 0.1.5
- The same as 0.2.0 I just tried if I can publish an older version when a newer
already exists.

##0.1.0
- Initial support for Gcloud Datastore Local Development Server
