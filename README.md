# PERFORMANCE_MIRROR_V2.2

Dashboard de monitoring biométrique et prédictif automatisé. Ce projet permet de visualiser l'évolution de la composition corporelle et de l'activité physique à partir de données extraites dynamiquement d'un tableur distant.

## 🚀 Vue d'ensemble du Système

Le projet repose sur une architecture **Data-Driven** où le frontend est totalement découplé de la saisie des données. L'objectif est de transformer des données brutes de suivi (Log) en indicateurs de performance exploitables (KPIs).

### Architecture du Flux de Données (Data Pipeline)

1. **Source (Saisie)** : Les données sont saisies manuellement dans un Google Sheets (Excel-like).
2. **Extraction (Extraction)** : Un script Python récupère les données via une URL d'export CSV.
3. **Traitement (Cleaning)** : Le script utilise la bibliothèque **Pandas** pour nettoyer les données (conversion des virgules françaises en points, typage numérique, suppression des entrées vides).
4. **Stockage (Artifact)** : Un fichier `data/summary.json` est généré, servant de base de données statique pour le frontend.
5. **Automatisation (CI/CD)** : Une **GitHub Action** exécute ce script périodiquement ou à chaque push, assurant la synchronisation automatique.
6. **Visualisation (Frontend)** : Le dashboard (Vanilla JS / Chart.js) parse le JSON et affiche les KPIs et graphiques interactifs.

---

## 🛠 Stack Technique

* **Langage** : Python 3.x (Backend), JavaScript ES6 (Frontend).
* **Data Analysis** : Pandas (Python).
* **Visualisation** : Chart.js (Graphiques dynamiques).
* **Style** : CSS3 Premium (Glassmorphism, Cyber-Neon theme).
* **Automation** : GitHub Actions.

---

## 📂 Structure du Projet

```text
├── .github/workflows/
│   └── sync.yml           # Workflow d'automatisation de la synchronisation
├── data/
│   └── summary.json       # Données traitées prêtes pour le frontend
├── scripts/
│   └── process_data.py    # Script d'extraction et de nettoyage (Pandas)
├── index.html             # Interface utilisateur
├── app.js                 # Logique frontend et calculs de maintenance
└── style.css              # Design Cyber-Premium

```

---

## 📈 Fonctionnalités Prédictives

Le dashboard n'affiche pas seulement des données passées, il intègre une couche d'analyse métabolique :

* **Maintenance Théorique (TDEE)** : Calculée dynamiquement en corrélant la variation de poids réelle et l'apport calorique moyen sur la période de suivi.
* **Extrapolation de l'Activité** : Projection annuelle du nombre de pas basée sur la moyenne glissante hebdomadaire.
* **Predictive System Logs** : Simulation d'un terminal SOC affichant l'état de l'analyse des données en temps réel.

---

## 🛠 Installation et Usage

1. **Prérequis** : Python 3.x installé.
2. **Installation des dépendances** :
```bash
pip install pandas

```


3. **Lancement manuel de la synchronisation** :
```bash
python scripts/process_data.py

```


4. **Visualisation** : Ouvrir `index.html` dans un navigateur ou via un serveur local (Live Server).

---

> **Note du développeur** : Ce projet est une démonstration de maîtrise du cycle de vie de la donnée, de son extraction brute à sa mise en valeur graphique, en respectant les standards de l'automatisation logicielle.

