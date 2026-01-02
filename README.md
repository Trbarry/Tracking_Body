# 📊 Performance Mirror - Fitness Tracker

> **Dashboard statique de suivi de performance, synchronisé en temps réel avec Google Sheets.**

Ce projet permet de transformer un tableur complexe (données de training, diète et mensurations) en une interface web épurée, visuelle et en **lecture seule**. Il repose sur une architecture **Serverless** utilisant des outils de **Data Engineering** simples.

## 🏗️ Architecture Technique

Le projet utilise une pipeline **CI/CD** automatisée :

1. **Source** : Google Sheets (Saisie mobile/PC).
2. **ETL (Extract, Transform, Load)** : Un script **Python** utilisant **Pandas** s'exécute via **GitHub Actions**.
3. **Storage** : Les données nettoyées sont stockées sous forme de fichier `summary.json` dans le dépôt.
4. **Frontend** : Une Single Page Application (SPA) en **HTML/JS** utilise **Chart.js** pour la visualisation.
5. **Hosting** : Déploiement automatique sur **GitHub Pages**.

## 📂 Structure du Projet

```text
.
├── .github/workflows/
│   └── sync.yml            # Automatisation de la synchronisation (Cron)
├── data/
│   └── summary.json        # Données nettoyées (généré par le script)
├── scripts/
│   └── process_data.py      # Script de parsing et nettoyage (Python/Pandas)
├── index.html              # Structure du Dashboard
├── style.css               # Design (Thème sombre & violet)
├── app.js                  # Logique de visualisation (Chart.js)
├── requirements.txt        # Dépendances Python
└── README.md               # Documentation

```

## 🚀 Setup & Déploiement

### Prérequis

* Un environnement **GitHub Codespaces** ou une machine sous **Arch Linux**.
* Python 3.10+ installé.

### Installation

1. Cloner le repository.
2. Installer les dépendances :
```bash
pip install -r requirements.txt

```


3. Lancer une synchronisation manuelle :
```bash
python scripts/process_data.py

```



### Configuration GitHub Actions

Pour que la synchronisation automatique fonctionne, assurez-vous d'activer les droits d'écriture pour le workflow :

* `Settings` > `Actions` > `General` > `Workflow permissions` > **Read and write permissions**.

## 🎨 Visualisations Actuelles

* **Weight Evolution** : Suivi du Poids de Corps (PDC) avec lissage de courbe.
* **Phase Detection** : Coloration dynamique du graphique selon la période (Déficit, Maintenance, Reverse).
* **Last Update Status** : Indicateur de fraîcheur des données.

---

**Développé par [Tristan Barry**](https://www.google.com/search?q=https://trtnxbook.com) *Objectif : Allier passion pour le bodybuilding et expertise en automatisation IT.*

---

### Le conseil du "Prof"

Tristan, ce README est propre, mais n'oublie pas de mettre à jour ton lien `trtnxbook.com` à l'intérieur une fois que tout est lié. Un dépôt sans README est une boîte noire ; ici, tu montres que tu maîtrises ta **Stack technique**.

**Souhaites-tu que je t'aide à rédiger une section "Cybersecurity Note" pour expliquer comment tu as sécurisé l'accès à tes données sans exposer d'API Key ?**
