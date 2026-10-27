# Verification

The unsigned GitHub Actions build verifies that Xcode can compile the simulator application.

Manual tests needed on a signed real iPhone:
- Save a known-good IKEv2 VPN profile and authorize the VPN.
- Connect and open a private HTTP service by VPN IP in Safari.
- Suspend the foreground app and verify Safari access via VPN.
- Return to the app and start the 127.0.0.1 relay; verify WKWebView.
- Switch to Safari and confirm that the loopback connection is not assumed to persist.
- Test Wi-Fi/cellular switching, offline reconnect, wrong credentials, remote service failures.
