#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/finmate-18625-18632/FinmateApp"
cd "$WORKSPACE"
VENV="$WORKSPACE/.venv"
LOG="$WORKSPACE/venv-pip.log"
PY="$VENV/bin/python"
PIP="$VENV/bin/pip"
# create venv if missing
if [ ! -d "$VENV" ]; then python3 -m venv "$VENV"; fi
# ensure pip/setuptools/wheel
$PY -m pip install --upgrade pip setuptools wheel --prefer-binary >"$LOG" 2>&1 || (tail -n 200 "$LOG" >&2; exit 3)
if [ ! -f requirements.txt ]; then echo "requirements.txt missing" >&2; exit 2; fi
# record pre-install freeze if venv existed
if [ -f "$VENV/bin/activate" ] && [ -s "$VENV/pyvenv.cfg" ]; then
  $PY -m pip freeze > "$WORKSPACE/.venv-before-freeze.txt" || true
fi
# install requirements with logs and prefer-binary
$PIP install --upgrade -r requirements.txt --prefer-binary >"$LOG" 2>&1 || (tail -n 200 "$LOG" >&2; exit 4)
# install pytest and capture
$PIP install --upgrade pytest==7.* --prefer-binary >>"$LOG" 2>&1 || (tail -n 200 "$LOG" >&2; exit 5)
# run init_db to create sqlite file (safe Python script)
if [ -x "$WORKSPACE/scripts/init_db.py" ] || [ -f "$WORKSPACE/scripts/init_db.py" ]; then
  $PY "$WORKSPACE/scripts/init_db.py" >>"$LOG" 2>&1 || true
fi
# output versions for verification
$PY - <<PY
import sys, importlib
for pkg in ('streamlit','pandas','numpy'):
    try:
        m=importlib.import_module(pkg); print(pkg, getattr(m,'__version__','unknown'))
    except Exception as e:
        print('missing', pkg, e, file=sys.stderr)
print('python', sys.version.split()[0])
PY
