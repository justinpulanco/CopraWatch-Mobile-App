# CopraWatch Deployment and Security Setup

## Technician installation (one time)

Normal operators do not run terminal commands. A technician provisions the Raspberry Pi, enables SPI/I2C, installs the camera/GPIO and Python dependencies, places this backend directory at its permanent location, and creates its `.venv`. The virtual environment must contain Flask, Picamera2, and RPi.GPIO, and the Pi account must have access to camera and GPIO devices.

From the deployed backend directory, the technician runs `sudo ./install_service.sh` once. The installer installs and enables the systemd unit, starts CopraWatch at boot, and restarts it after a failure. The service runs as the invoking Pi account and stores its API credential in `/etc/coprawatch/coprawatch.env` with restricted permissions. Keep the backend directory at the same path after installing the service; rerun the installer if its location or service account changes.

The technician securely retrieves the generated `COPRAWATCH_API_KEY` from that file and enters it in the mobile app under Settings along with the Raspberry Pi address and port. The app stores the key locally and sends it in the `X-API-Key` request header. Do not share the key or commit the environment file to source control. If a key is rotated, update the Pi environment file and app setting together, then restart the service.

## Network requirements

Keep the phone and Raspberry Pi on a private, trusted Wi-Fi network. Do not expose port 5000 to the public internet or forward it through a router. The API key is a shared secret and does not encrypt traffic; use a private network and configure and verify TLS before sending it over an untrusted network.

The backend intentionally has no demo-key fallback. If `COPRAWATCH_API_KEY` is missing, API requests return HTTP 503. A wrong or missing key returns HTTP 401. Remote capture, camera unlock, camera test, and still snapshot routes are disabled. The mobile preview is read-only; use the physical Pi button to capture and classify copra.

## Optional HTTPS

For a technician-managed TLS deployment, provide valid certificate and private-key paths through `COPRAWATCH_TLS_CERT` and `COPRAWATCH_TLS_KEY` in the service environment. The certificate must be trusted by the target phone. Test connection, preview streaming, and credential handling on the deployed phone before use. Do not expose the service publicly as a substitute for local-network security.

## Operations and recovery

The systemd service is named `coprawatch.service`; routine operators should use the app's connection status and contact their technician if the Pi is offline. A technician can inspect service logs/status, network connectivity, sensor wiring, and camera/GPIO permissions. Reboot and service recovery should be handled by the configured service manager; operators are not expected to launch Python manually.

See [ENCLOSURE_SETUP.md](ENCLOSURE_SETUP.md) for physical camera, lighting, and repeatability acceptance checks. Installation and hardware acceptance require a technician and a real Raspberry Pi; they are not verified by local development tests.
