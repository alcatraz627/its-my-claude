# Pure Python Package

## Meta
- Runtime: python
- Default port: none
- Install command: python3 -m venv .venv && source .venv/bin/activate && pip install -e ".[dev]"
- Run command: source .venv/bin/activate && python -m {{name}}
- Test command: source .venv/bin/activate && pytest

## Dependencies
(none by default — add as needed)

## Dev Dependencies
pytest: >=8.3
ruff: >=0.9
mypy: >=1.14

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
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=8.3",
    "ruff>=0.9",
    "mypy>=1.14",
]

[tool.ruff]
target-version = "py312"
line-length = 100

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.mypy]
python_version = "3.12"
strict = true
```

### src/{{name}}/__init__.py
```python
"""{{name}} — a Python package."""

__version__ = "0.1.0"
```

### src/{{name}}/__main__.py
```python
"""Entry point for `python -m {{name}}`."""


def main() -> None:
    print("{{name}} v0.1.0")


if __name__ == "__main__":
    main()
```

### tests/__init__.py
```python
```

### tests/test_version.py
```python
from {{name}} import __version__


def test_version():
    assert __version__ == "0.1.0"
```

### .gitignore
```
__pycache__/
*.py[cod]
*$py.class
.venv/
venv/
.env
dist/
*.egg-info/
.ruff_cache/
.mypy_cache/
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
.PHONY: test lint format typecheck

test:
	pytest -v

lint:
	ruff check .

format:
	ruff format .

typecheck:
	mypy src/
```
