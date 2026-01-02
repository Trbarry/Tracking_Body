import pandas as pd
import json
import os

URL_CSV = "https://docs.google.com/spreadsheets/d/1GUeb36Zm42LNgKf3vdFdEkVEz_Bm8ct1dPdOAIyEBaY/export?format=csv"

def clean_data():
    try:
        raw_df = pd.read_csv(URL_CSV, header=None)
        header_row_index = 0
        for i, row in raw_df.iterrows():
            if "Date" in row.values:
                header_row_index = i
                break
        df = pd.read_csv(URL_CSV, header=header_row_index)
        df.columns = df.columns.str.strip()
        df = df.dropna(subset=['Date'])
        for col in ['PDC', 'KCALS', 'PAS', 'DIFFERENCE']:
            if col in df.columns:
                df[col] = df[col].astype(str).str.replace(',', '.').str.strip()
                df[col] = pd.to_numeric(df[col], errors='coerce')
        df = df.dropna(subset=['PDC'])
        os.makedirs('data', exist_ok=True)
        df.to_json('data/summary.json', orient='records', indent=4, force_ascii=False)
        print(f"✅ Sync réussie.")
    except Exception as e:
        print(f"❌ Erreur : {e}")

if __name__ == "__main__":
    clean_data()