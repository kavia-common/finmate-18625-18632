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
