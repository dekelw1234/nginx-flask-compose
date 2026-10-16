# nginx-flask-compose

A small two-container stack I built while learning DevOps from scratch:
an nginx reverse proxy in front of a Flask API, run with Docker Compose,
tested by a Bash script, and built, tested and published by GitHub Actions.

## Architecture

```
 browser --> localhost:8080 --> [ web: nginx ] --/api/--> [ backend: Flask ]
                                  port 80                   port 5000
                                  static html               counter in a
                                  /health                   named volume
```

- **web** serves the static site and `/health`, and forwards `/api/` to `backend:5000`
  (the Compose service name, resolved by Docker's internal DNS).
- **backend** answers `/api/hello` and `/api/health`, and keeps a call counter
  in the `counter-data` volume so it survives restarts.
- `web` starts only after `backend` is **healthy** (`depends_on` + `condition: service_healthy`),
  not just started.

## Run it

```bash
docker compose up -d --build --wait
curl localhost:8080/api/hello
docker compose down        # add -v to also delete the counter volume
```

## Test it

```bash
./scripts/run-tests.sh
```

Builds the stack, waits until it is healthy, runs smoke tests
(health, nginx config, home page, 404, API through the proxy),
prints logs on failure, and always tears down. Exit code 0 means every test passed.

## CI/CD

`.github/workflows/ci.yml`:

- **test** runs on every push and pull request to `main`: build, start, smoke tests, logs on failure, teardown.
- **publish** runs only after `test` passes on a push to `main`: it pushes the exact images that were tested
  to GHCR, tagged with the commit SHA (for traceability and rollback) and `main`.

## What I practiced

Each of these was a real bug I diagnosed with logs, `exec`, `inspect` and `git diff`:

| Symptom | Root cause |
| --- | --- |
| nginx container exits with code 1 | Missing `;` in `default.conf` (`[emerg]` in the logs) |
| 404 while every check is green | `root` pointed to `/usr/share/nginx/htm` |
| Container `unhealthy` while the site works | Healthcheck used `localhost` -> `::1`, nginx listened on IPv4 only |
| 502 from `/api/` in CI | `proxy_pass` port 5001, Flask listens on 5000 |
| `--wait` fails, backend unhealthy | `PORT=8000` env var, healthcheck still checks 5000 |
| `Permission denied` on a fresh clone | Executable bit not committed to git (100644 vs 100755) |
| `/usr/bin/env: 'bash\r'` | CRLF line endings, fixed for good with `.gitattributes` |

`scripts/hello.sh` is left in on purpose: it was the demo file for the last two rows.
