import pandas as pd
import json
import os

URL_CSV = "https://docs.google.com/spreadsheets/d/1GUeb36Zm42LNgKf3vdFdEkVEz_Bm8ct1dPdOAIyEBaY/export?format=csv"

def to_float(val):
    """Nettoie et convertit une valeur en float (gère les virgules et erreurs Excel)."""
    try:
        if pd.isna(val) or str(val).startswith('#'):
            return None
        # Remplace la virgule par un point et nettoie les caractères non numériques
        clean_val = str(val).replace(',', '.').strip()
        return float(clean_val)
    except (ValueError, TypeError):
        return None

def clean_data():
    try:
        # 1. Lecture brute pour trouver le header
        raw_df = pd.read_csv(URL_CSV, header=None)
        header_row_index = 0
        for i, row in raw_df.iterrows():
            if "Date" in row.values:
                header_row_index = i
                break
        
        # 2. Re-lecture avec le bon header
        df = pd.read_csv(URL_CSV, header=header_row_index)
        df.columns = df.columns.str.strip()

        # 3. Filtrage : on supprime les lignes sans date
        df = df.dropna(subset=['Date'])

        # 4. Conversion des colonnes critiques
        numeric_cols = ['PDC', 'KCALS', 'PAS', 'DIFFERENCE']
        for col in numeric_cols:
            if col in df.columns:
                df[col] = df[col].apply(to_float)

        # 5. On ne garde que les données passées (où le PDC est saisi)
        df = df.dropna(subset=['PDC'])
        
        # 6. Tri par date (sécurité)
        # Note: On garde le format string pour l'affichage simple en JS
        
        # 7. Export JSON propre
        os.makedirs('data', exist_ok=True)
        df.to_json('data/summary.json', orient='records', indent=4, force_ascii=False)
        
        print(f"✅ Sync réussie : {len(df)} entrées traitées.")

    except Exception as e:
        print(f"❌ Erreur critique : {e}")

if __name__ == "__main__":
    clean_data()