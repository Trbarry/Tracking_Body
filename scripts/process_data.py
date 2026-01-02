import pandas as pd
import os

URL_CSV = "https://docs.google.com/spreadsheets/d/1GUeb36Zm42LNgKf3vdFdEkVEz_Bm8ct1dPdOAIyEBaY/export?format=csv"

def clean_data():
    try:
        # 1. On lit le fichier sans headers d'abord pour le scanner
        raw_df = pd.read_csv(URL_CSV, header=None)

        # 2. On cherche quelle ligne contient le mot "Date"
        # On parcourt les premières lignes pour trouver l'index du header
        header_row_index = 0
        for i, row in raw_df.iterrows():
            if "Date" in row.values:
                header_row_index = i
                break
        
        # 3. On relit proprement avec le bon index
        df = pd.read_csv(URL_CSV, header=header_row_index)

        # 4. CRUCIAL : On nettoie les noms de colonnes (enlève les espaces et les sauts de ligne)
        df.columns = df.columns.str.strip()

        print(f"[*] Colonnes détectées : {list(df.columns)}")

        # 5. On ne garde que les lignes où Date est rempli
        if 'Date' in df.columns:
            df = df.dropna(subset=['Date'])
        else:
            print("❌ Erreur : La colonne 'Date' est toujours introuvable.")
            return

        # 6. Nettoyage des PDC (virgule -> point)
        if 'PDC' in df.columns:
            df['PDC'] = df['PDC'].astype(str).str.replace(',', '.').replace('#DIV/0!', None)
            df['PDC'] = pd.to_numeric(df['PDC'], errors='coerce')
        
        # On vire les lignes où PDC est vide (données futures)
        df = df.dropna(subset=['PDC'])

        # 7. Sauvegarde
        os.makedirs('data', exist_ok=True)
        df.to_json('data/summary.json', orient='records', indent=4)
        print("✅ Données synchronisées et nettoyées.")

    except Exception as e:
        print(f"❌ Erreur lors du nettoyage : {e}")

if __name__ == "__main__":
    clean_data()