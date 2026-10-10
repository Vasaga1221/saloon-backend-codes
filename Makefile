.PHONY: install db up migrate seed run test test-unit test-integration lint

install:            ## create venv and install with dev tools
	python -m venv .venv && . .venv/bin/activate && pip install -e ".[dev]"

db:                 ## start PostgreSQL only
	docker compose up -d db

up:                 ## full stack (API + DB) in Docker
	docker compose up --build

migrate:
	alembic upgrade head

seed:               ## demo data from the frontends' mock data
	python -m scripts.seed

run:                ## dev server with reload
	uvicorn app.main:app --reload --port 8000

test-unit:          ## no database needed
	pytest tests/unit

test-integration:   ## needs PostgreSQL (see tests/integration/conftest.py); DROPS the test database schema
	TEST_DATABASE_URL=postgresql+psycopg://aura:aura@localhost:5432/aura_test pytest tests/integration

test: test-unit test-integration

lint:
	ruff check app tests scripts
