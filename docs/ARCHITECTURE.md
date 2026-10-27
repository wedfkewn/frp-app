# LocalBridge architecture

## Modes

1. IKEv2 system VPN: NEVPNManager controls an OS-managed tunnel with an existing external IKEv2 gateway. Once a VPN route exists, Safari can access remote private IP addresses, even while the UI app is suspended.
2. Foreground local TCP relay: NWListener binds 127.0.0.1:localPort, and NWConnection forwards TCP streams to the configured remote endpoint. This listener cannot be relied on when iOS suspends the app.

The MVP intentionally does not include a PacketTunnelProvider or WireGuard implementation. Those are distinct network architectures. Despite the repository name frp-app, this MVP is not an frp client.

## Build

Run xcodegen generate from the repository root, then use Xcode to build LocalBridge. CI uses macos-15 with Xcode and XcodeGen; output is an unsigned Simulator app ZIP rather than a device-installable IPA.

## Requirements for a working VPN

A reachable IKEv2 gateway, properly issued and trusted server certificate, compatible EAP credentials, route to a remote service, and Personal VPN signing capability. No credentials are committed to this repository.

## Security design

Password stored in Keychain, metadata in UserDefaults. Never turn off VPN certificate validation. Loopback binds explicitly to 127.0.0.1. A remote service must still authenticate users and authorize access.

## Future work

WireGuard PacketTunnel extension, gateway provisioning, certificate lifecycle, per-service auth, error reporting, advanced stream handling, and device-signed release pipeline.
