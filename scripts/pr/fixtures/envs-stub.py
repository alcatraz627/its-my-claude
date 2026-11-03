"""Stands in for versable/envs.py in the ready-to-merge tests: prints the file named by ENVS_JSON."""
import os
import sys

path = os.environ.get("ENVS_JSON", "")
if not path or not os.path.exists(path):
    sys.exit(1)
sys.stdout.write(open(path).read())
