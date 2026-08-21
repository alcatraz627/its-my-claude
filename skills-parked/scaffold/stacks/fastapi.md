# FastAPI + Pydantic + SQLAlchemy + Alembic

## Meta
- Runtime: python
- Default port: 5010
- Install command: python3 -m venv .venv && source .venv/bin/activate && pip install -e ".[dev]"
- Run command: source .venv/bin/activate && uvicorn app.main:app --reload --port {{port}}
- Test command: source .venv/bin/activate && pytest

## Dependencies
fastapi: >=0.115
uvicorn[standard]: >=0.34
pydantic: >=2.10
pydantic-settings: >=2.7
sqlalchemy: >=2.0
alembic: >=1.14
httpx: >=0.28

## Dev Dependencies
pytest: >=8.3
pytest-asyncio: >=0.25
ruff: >=0.9

## Files

### pyproject.toml
```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "{{name}}"
version = "0.1.0"
description = ""
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115",
    "uvicorn[standard]>=0.34",
    "pydantic>=2.10",
    "pydantic-settings>=2.7",
    "sqlalchemy>=2.0",
    "alembic>=1.14",
    "httpx>=0.28",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.3",
    "pytest-asyncio>=0.25",
    "ruff>=0.9",
]

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

### app/__init__.py
```python
```

### app/main.py
```python
from fastapi import FastAPI
from app.api import router as api_router
from app.config import settings

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
)

app.include_router(api_router, prefix="/api")


@app.get("/health")
async def health_check():
    return {"status": "ok", "app": settings.app_name}
```

### app/config.py
```python
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "{{name}}"
    debug: bool = False
    database_url: str = "sqlite:///./{{name}}.db"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8"}


settings = Settings()
```

### app/api/__init__.py
```python
from fastapi import APIRouter

router = APIRouter()

# Import route modules here as the API grows:
# from app.api import users, items
```

### app/db/__init__.py
```python
```

### app/db/session.py
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.config import settings

engine = create_engine(settings.database_url, echo=settings.debug)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### app/models/__init__.py
```python
```

### app/schemas/__init__.py
```python
```

### alembic.ini
```ini
[alembic]
script_location = alembic
sqlalchemy.url = sqlite:///./{{name}}.db

[loggers]
keys = root,sqlalchemy,alembic

[handlers]
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

### alembic/env.py
```python
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.db.session import Base

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

### alembic/versions/.gitkeep
```
```

### alembic/script.py.mako
```mako
"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision | comma,n}
Create Date: ${create_date}
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
${imports if imports else ""}

revision: str = ${repr(up_revision)}
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}


def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
```

### tests/__init__.py
```python
```

### tests/test_health.py
```python
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_health_check():
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
```

### .env.example
```bash
# App
APP_NAME={{name}}
DEBUG=false

# Database
DATABASE_URL=sqlite:///./{{name}}.db
# DATABASE_URL=postgresql://user:pass@localhost:5432/{{name}}
```

### .gitignore
```
__pycache__/
*.py[cod]
*$py.class
*.so
.venv/
venv/
.env
*.db
dist/
*.egg-info/
.ruff_cache/
.pytest_cache/
.coverage
htmlcov/
```

### .editorconfig
```ini
root = true

[*]
indent_style = space
indent_size = 4
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.{json,yaml,yml,toml}]
indent_size = 2
```

### Makefile
```makefile
.PHONY: dev test lint format migrate

dev:
	uvicorn app.main:app --reload --port {{port}}

test:
	pytest -v

lint:
	ruff check .

format:
	ruff format .

migrate:
	alembic upgrade head

revision:
	alembic revision --autogenerate -m "$(msg)"
```
