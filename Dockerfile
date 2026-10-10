FROM python:3.12-slim AS base
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PIP_NO_CACHE_DIR=1
WORKDIR /srv

COPY pyproject.toml ./
COPY app ./app
# Resolves dependencies from pyproject.toml (generate and use a lockfile for reproducible releases)
RUN pip install .

COPY alembic ./alembic
COPY alembic.ini ./
COPY scripts ./scripts
COPY media ./media

RUN useradd --create-home --uid 10001 aura && chown -R aura /srv
USER aura
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8000/health').status==200 else 1)"
# Apply migrations, then serve. For multiple replicas run `alembic upgrade head` as a separate release step.
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000 --proxy-headers"]
