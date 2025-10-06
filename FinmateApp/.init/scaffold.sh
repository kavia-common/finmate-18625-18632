#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/finmate-18625-18632/FinmateApp"
mkdir -p "$WORKSPACE"/data "$WORKSPACE"/tests "$WORKSPACE"/scripts
# conservative scaffold: skip if app exists unless WORKSPACE_FORCE=1
if [ -f "$WORKSPACE"/app.py ] && [ "${WORKSPACE_FORCE:-0}" != "1" ]; then
  echo "app.py exists; skipping scaffold (set WORKSPACE_FORCE=1 to overwrite)" >&2
else
  cat > "$WORKSPACE"/requirements.txt <<'REQ'
streamlit>=1.20,<3.0
pandas
numpy
reportlab
REQ
  cat > "$WORKSPACE"/app.py <<'PY'
import streamlit as st
import pandas as pd
import numpy as np
from pathlib import Path
DATA_DIR = Path(__file__).parent / 'data'
DATA_DIR.mkdir(exist_ok=True)
st.title('FinMate - Dev Environment')
df = pd.DataFrame({'a': np.arange(5), 'b': np.random.randn(5)})
st.dataframe(df)
st.write('Data dir:', str(DATA_DIR))
PY
  chmod 0644 "$WORKSPACE"/requirements.txt "$WORKSPACE"/app.py || true
fi
# small init_db script that computes DB path relative to script location
cat > "$WORKSPACE"/scripts/init_db.py <<'PY'
from pathlib import Path
import sqlite3
base = Path(__file__).parent.parent
db = base / 'data' / 'finmate.db'
(db.parent).mkdir(parents=True, exist_ok=True)
if not db.exists():
    conn = sqlite3.connect(str(db))
    conn.execute('CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, text TEXT)')
    conn.commit(); conn.close()
print('sqlite-created-at', str(db))
PY
chmod 0755 "$WORKSPACE"/scripts/init_db.py || true
# placeholder and basic test
touch "$WORKSPACE"/data/.placeholder
cat > "$WORKSPACE"/tests/test_basic.py <<'TEST'
def test_smoke():
    assert 2 == 1 + 1
TEST
chmod 0644 "$WORKSPACE"/tests/test_basic.py || true
