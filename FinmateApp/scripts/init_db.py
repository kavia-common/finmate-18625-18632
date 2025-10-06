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
