# Follow the project's config pattern for env vars

Every project centralizes environment variable access in its own way: a
config module, a validated schema (zod, pydantic), or a typed wrapper. Before
adding a raw read, search for how existing variables are read.

```bash
rg -n 'process\.env\.|os\.getenv|os\.environ' src/
```

If a central config module exists, add the variable there and read it through
the module. Raw reads scattered across files drift apart and skip validation.

## An illustration

Say a project validates its settings in `config.py` with pydantic. A new feature
adds `timeout = int(os.getenv("UPLOAD_TIMEOUT"))` deep in a handler. It works
locally, where the variable is set. In staging it is unset, `int(None)` raises
at request time instead of at boot, and the default the config module would
have supplied never applies. The same line in `Settings` would have failed at
startup with a clear message, or used the default.

## What is universal and what is local

The specific config module is per project. The universal part is to find the
project's pattern and follow it, and not to introduce a second way of reading
config. If the project documents its config module in its own rules, that
local rule wins.

## Diagnostic

You are typing `process.env.`, `os.getenv` or `os.environ` outside the
project's config module and have not checked whether one exists.
