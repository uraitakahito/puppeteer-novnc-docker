## Setup

**Detailed environment setup instructions are described at the beginning of the `Dockerfile`.**

## Chromium Auto-Start

When the container starts, Chromium automatically launches and is viewable via noVNC.

- **noVNC URL:** http://localhost:6080
- **Remote Debugging Port:** 9222 (forwarded from 9223)

### Process Management

Chromium and socat are managed by supervisord. To check status:

```bash
supervisorctl -c /etc/supervisor/conf.d/app.conf status
```

To restart Chromium:

```bash
supervisorctl -c /etc/supervisor/conf.d/app.conf restart chromium
```

### Logs

- Chromium: `/tmp/chromium-stdout.log`, `/tmp/chromium-stderr.log`
- Socat: `/tmp/socat-stdout.log`, `/tmp/socat-stderr.log`
- Supervisord: `/tmp/supervisord.log`

## Example Usage(Not implemented)

### Running from the terminal

Set the `DISPLAY` environment variable to use the VNC server:

```sh
DISPLAY=:1 node example.mjs
```

You can watch the browser in action via noVNC at http://localhost:6080/

### Using xvfb

Use `xvfb-run` to run headful mode without a display (useful for CI/CD):

```sh
xvfb-run --auto-servernum npx node example.mjs
```
