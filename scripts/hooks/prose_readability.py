"""Readability checks for prose a person has to read (dense blocks, spliced
lines, internals-only runs), kept importable under their old name.

The checks now live in the prose engine's module, scripts/style/readability_core.py,
next to prose-lint.py, so every prose gate asks one definition. This file only
re-exports it for older callers (`import prose_readability`). New code asks the
engine: prose-lint.py `lint(text, surface)`.
"""
import importlib.util
import os
import sys

_NAME = "readability_core"
_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "style", "readability_core.py")

_mod = sys.modules.get(_NAME)
if _mod is None:
    _spec = importlib.util.spec_from_file_location(_NAME, _PATH)
    _mod = importlib.util.module_from_spec(_spec)
    sys.modules[_NAME] = _mod
    _spec.loader.exec_module(_mod)

globals().update({k: v for k, v in vars(_mod).items() if not k.startswith("__")})
