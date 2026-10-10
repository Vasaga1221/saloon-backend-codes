# Aura Salon Backend

FastAPI + PostgreSQL backend for two existing frontends (kept untouched, in their own repos):
**Aura Salon** (customer app) and **Aura Partner OS** (owner / stylist app).

## Status: read this first

| Area | Status |
|---|---|
| Domain logic (pricing, scheduling, status rules, formatting, tokens, QR, ICS) | 61 unit tests, passing |
| API, ORM models, Alembic baseline, seed | Written and statically checked (compile, undefined-name scan, import review). **Not executed** by the author: no PostgreSQL/pip in the authoring sandbox |
| Integration tests (`tests/integration`) | Written, **never run**. Expect to fix small things on first run |
| Payments | Mock gateway only. Refused in production unless `ALLOW_MOCK_PAYMENTS=true` |
| OTP delivery | Console logger only. Plug an SMS/email provider into `app/infra/otp_sender.py` |
| Google / Apple sign-in | `501` until a verifier is implemented in `app/infra/social.py` |
| Alembic baseline | Uses `create_all` + raw SQL; freeze it before relying on migrations (docs/DATABASE.md) |

## Quick start

```bash
cp .env.example .env
docker compose up -d db                      # PostgreSQL 16
python -m venv .venv && . .venv/bin/activate
pip install -e ".[dev]"
alembic upgrade head                         # extensions, 24 tables, no-overlap constraints
python -m scripts.seed                       # demo data from the frontends' mock data
uvicorn app.main:app --reload                # http://localhost:8000/docs
```
Or everything in Docker: `docker compose up --build`.

Demo logins (password `Passw0rd123`): customer `+919876543210`, owner `+919820184920`; admin `admin@aura.test` / `Admin#12345`.
With `OTP_DEV_ECHO=true` the OTP is returned in the response (`devCode`), so OTP login works locally.

## Tests
```bash
pytest tests/unit                                            # no database
TEST_DATABASE_URL=postgresql+psycopg://aura:aura@localhost:5432/aura_test pytest tests/integration
```
The integration run **drops and recreates schema `public`** of that database, then applies the Alembic migration.

## Layout
```
app/domain/    pure rules: pricing, scheduling, status machine, formatting (stdlib only)
app/services/  use-cases; own the transaction (commit on success)
app/api/       FastAPI routers + dependencies (auth, per-salon roles)
app/db/        SQLAlchemy 2.0 models (24 tables)
app/infra/     ports + adapters: payments, OTP, social login
app/schemas/   Pydantic models (camelCase JSON = the frontends' TypeScript shapes)
alembic/       migrations      scripts/  seed + doc generators      docs/  documentation
```
Docs: `docs/FRONTEND_ANALYSIS.md`, `ARCHITECTURE.md`, `DATABASE.md`, `API.md`, plus generated `API_ENDPOINTS.md` and `DATABASE_TABLES.md`
(regenerate with `python -m scripts.gen_api_docs` / `gen_db_docs`).

## Configuration
All via environment variables; see `.env.example`. Production start-up **fails fast** if secrets are defaults, `OTP_DEV_ECHO` is on, the console OTP sender or mock payments are used without opt-in, or `DEBUG` is true.
Images in seed data are served from `/media/seed` (resized copies of the frontends' assets); use object storage + CDN in production.
