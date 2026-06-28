# WireMock

Local WireMock server for the repository explorer.

## Run

From this folder:

```sh
docker compose up --build
```

Or from the project root:

```sh
docker build -t westpac-assessment-wiremock WireMock
docker run --rm -p 8080:8080 westpac-assessment-wiremock
```

The app's `WireMock` API source uses:

```text
http://127.0.0.1:8080/repositories
```

The mappings include:

- First and second repository pages.
- A GitHub-style `Link` response header with `rel="next"`.
- Repository detail endpoints.
- Repository language endpoints.

Keep the mock URLs as `127.0.0.1` so the iOS Simulator can reach the WireMock container through the host port mapping.
