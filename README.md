# DAS Belgium - Legal Protection Insurance System

Système complet de gestion d'assurance protection juridique pour DAS Belgium, construit avec **RPG ILE (IBM i)** + **Node.js** + **React**.

Projet de démonstration pour interview DAS Belgium montrant les 5 modules RPG en action avec 2 workflows business critiques.

## 🎯 Objectif

Impressionner DAS Belgium en démontrant :
- ✅ Compréhension de leur modèle business (distribution 100% courtiers)
- ✅ Implémentation de leurs règles métier (79% AMI, €350 seuil, waiting periods)
- ✅ Conformité TELEBIB2 (standard EDI belge)
- ✅ Architecture moderne (RPG backend + Node.js API + React frontend)
- ✅ Système demo fonctionnel avec 2 workflows complets

## 🏗️ Architecture End-to-End

```
┌──────────────────┐
│  React Frontend  │  ← UI moderne (5 pages, 2 workflows)
│  (Vite + React)  │
└────────┬─────────┘
         │ HTTP/REST
         ↓
┌──────────────────┐
│   Node.js API    │  ← 37 endpoints REST
│  (Express+ODBC)  │
└────────┬─────────┘
         │ ODBC
         ↓
┌──────────────────┐
│   SQL Stored     │  ← 15 SPs wrappers
│   Procedures     │
└────────┬─────────┘
         │ CALL
         ↓
┌──────────────────┐
│   RPG ILE        │  ← 5 Service Programs (business logic)
│  Service Programs│     BROKRSRV, CUSTSRV, PRODSRV, CONTSRV, CLAIMSRV
└────────┬─────────┘
         │
         ↓
┌──────────────────┐
│   DB2 for i      │  ← 7 tables (IBM i V7R5)
│   Database       │
└──────────────────┘
```

## 📦 Structure du Projet

```
rpg-test-project/
├── docs/
│   ├── DAS-BELGIUM-RESEARCH.md    # Recherche DAS (business, tech, interview)
│   ├── implementation-plan.md     # Plan complet du projet
│   ├── sql-sp-review.md          # Review SQL SPs (bug fix SP_IsCovered)
│   └── program/                  # Docs 5 RPG programs
│       ├── BROKRSRV.md
│       ├── CUSTSRV.md
│       ├── PRODSRV.md
│       ├── CONTSRV.md
│       └── CLAIMSRV.md
├── sql/
│   ├── tables.sql                # DDL 7 tables
│   ├── sp/                       # 15 Stored Procedures
│   │   ├── SP_CreateBroker.sql
│   │   ├── SP_CreateCustomer.sql
│   │   ├── SP_CreateContract.sql
│   │   ├── SP_CreateClaim.sql
│   │   ├── SP_IsCovered.sql      # ⭐ Fixed critical bug
│   │   └── ...
│   └── seed-data.sql             # Demo data (5 brokers, 10 clients, 8 contracts, 5 claims)
├── src/qrpglesrc/                # 5 RPG Service Programs
│   ├── BROKRSRV.sqlrpgle         # Broker management
│   ├── CUSTSRV.sqlrpgle          # Customer management (IND/BUS)
│   ├── PRODSRV.sqlrpgle          # Product catalog
│   ├── CONTSRV.sqlrpgle          # Contract lifecycle
│   ├── CLAIMSRV.sqlrpgle         # Claim processing (79% AMI)
│   └── ERRUTIL.rpgleinc          # Error handling
├── api/                          # Node.js REST API
│   ├── src/
│   │   ├── config/
│   │   │   ├── database.js       # ODBC connection pool
│   │   │   └── constants.js      # Business rules
│   │   ├── services/             # 6 services
│   │   ├── controllers/          # 6 controllers
│   │   ├── routes/               # 6 route files
│   │   ├── middleware/
│   │   └── app.js                # Express server
│   ├── package.json
│   ├── .env.example
│   └── README.md
└── ui/                           # React Frontend
    ├── src/
    │   ├── pages/
    │   │   ├── Dashboard.jsx     # KPIs + pie chart
    │   │   ├── BrokerList.jsx
    │   │   ├── ContractList.jsx
    │   │   ├── CreateContract.jsx    # ⭐ Workflow 1 (3-step wizard)
    │   │   └── DeclareClaim.jsx      # ⭐ Workflow 2 (real-time validation)
    │   ├── components/
    │   ├── services/api.js
    │   └── App.jsx
    ├── package.json
    ├── .env.example
    └── README.md
```

## 🚀 Quick Start (3 étapes)

### Pré-requis
- IBM i V7R5 (ou PUB400.com)
- Node.js 18+
- ODBC Driver IBM i Access

### 1. Setup Database (IBM i)

```bash
# 1. Créer les tables
db2 -f sql/tables.sql

# 2. Créer les Stored Procedures
db2 -f sql/sp/SP_CreateBroker.sql
db2 -f sql/sp/SP_CreateCustomer.sql
# ... (15 SPs au total)

# 3. Insérer les données de démo
db2 -f sql/seed-data.sql
```

**Alternative**: Compiler les 5 RPG Service Programs si vous voulez utiliser directement RPG :
```bash
CRTBNDRPG PGM(DASBE/BROKRSRV) SRCFILE(DASBE/QRPGLESRC)
# ... (5 programs)
```

### 2. Démarrer Backend API

```bash
cd api
npm install
cp .env.example .env
# Éditer .env avec vos credentials IBM i
npm start
```

API disponible sur `http://localhost:3000`

### 3. Démarrer Frontend

```bash
cd ui
npm install
cp .env.example .env
npm run dev
```

Frontend disponible sur `http://localhost:5173`

## 🎬 Démo Interview (5-7 minutes)

### Préparation
1. Backend API running (`npm start`)
2. Frontend running (`npm run dev`)
3. Browser sur `http://localhost:5173`
4. Données seed chargées

### Workflow 1: Créer Contrat (2 min)

**Path**: Dashboard → Courtiers → Créer Contrat

```
1. Dashboard → Montrer KPIs (courtiers, clients, contrats, sinistres)
2. Courtiers → Cliquer "Créer Contrat" sur "Assurances Dupont"
3. Step 1: Client → Nouveau client "Jean Martin" (IND)
   - Email: jean.martin@email.be
   - Adresse: Rue de la Loi 50, 1000 Bruxelles
4. Step 2: Produit → DAS Classic
   - 2 véhicules (+ €50)
   - Mensuel (+5%)
   - Calculateur: €114 + €50 + 5% = €172.20 ✨
5. Step 3: Récap → Créer
   - Contrat créé: DAS-2025-00001-000009 🎉
```

**Points à souligner** :
- Calculateur temps réel (pas de bouton "Calculer")
- Référence contrat format TELEBIB2 (DAS-YYYY-BBBBB-NNNNNN)
- Business rule €25/véhicule + surcharge fréquence

### Workflow 2: Déclarer Sinistre (2 min)

**Path**: Contrats → Déclarer Sinistre

```
1. Contrats → Cliquer "Déclarer Sinistre" sur contrat créé
2. Garantie → "Troubles de voisinage" (VOIS)
3. Montant → €1500
4. Validation temps réel apparaît automatiquement ✨:
   ✅ Garantie couverte par DAS Classic
   ✅ Période d'attente 3 mois écoulée
   ✅ Montant ≥ €350 (seuil minimum DAS)
   ✅ Couverture active - 0 jours restants
5. Description → "Litige haie mitoyenne avec voisin"
6. Date incident → 2025-11-20
7. Soumettre
   - Sinistre créé: SIN-2025-000006 🎉
   - Dossier: DOS-0000000006
```

**Points à souligner** :
- Validation **temps réel** (pas à la soumission)
- Affichage règles business (€350, waiting period, couverture)
- Bouton désactivé si validation échoue
- Référence sinistre format TELEBIB2 (SIN-YYYY-NNNNNN)

### Dashboard KPI (1 min)

```
1. Retour Dashboard
2. Montrer KPI "Résolution Amiable"
   - Taux: 79% (objectif atteint ✓)
   - AMI vs TRI
3. Pie Chart: Répartition sinistres par statut
```

**Point à souligner** : Le KPI 79% correspond à leur objectif business réel

## 💡 Features Impressionnantes

### 1. Règles Business Implémentées

| Règle | Valeur | Implémentation |
|-------|--------|----------------|
| Seuil minimum | €350 | BUS006 error code |
| Plafond couverture | €200,000 | BUS003 warning |
| Période d'attente | 3-12 mois | Per guarantee |
| Objectif AMI | 79% | Dashboard KPI |
| Addon véhicule | €25 each | Premium calculation |
| Surcharge mensuel | +5% | Premium calculation |
| Surcharge trimestriel | +2% | Premium calculation |

### 2. Conformité TELEBIB2

**Segment ADR (Address)** :
- STREET (X002) - 30 chars
- HOUSE_NBR (X003) - 5 chars
- BOX_NBR (X004) - 4 chars
- POSTAL_CODE (X006) - 7 chars
- CITY (X007) - 24 chars
- COUNTRY_CODE (X008) - 3 chars

**Références Format Standard** :
- Contrat: `DAS-YYYY-BBBBB-NNNNNN` (BBBBB = broker_id)
- Sinistre: `SIN-YYYY-NNNNNN`
- Dossier: `DOS-NNNNNNNNNN`

### 3. Validation Temps Réel

Le frontend valide **pendant la saisie**, pas à la soumission :

```javascript
// DeclareClaim.jsx - Auto-validation
useEffect(() => {
  if (guaranteeCode && claimedAmount && incidentDate) {
    // API call automatique
    validateMutation.mutate({ contId, guaranteeCode, claimedAmount })
  }
}, [guaranteeCode, claimedAmount, incidentDate])
```

**Résultat** : Feedback immédiat sur couverture, waiting period, seuil

### 4. Architecture 3-Tier Propre

```
Presentation (React)
    ↓
Business Logic (RPG)
    ↓
Data Access (DB2)
```

**Séparation claire** : React = UI, RPG = business rules, SQL = data

## 📊 Stack Technique Complet

### Backend
- **RPG ILE** - Business logic (5 service programs)
- **SQL/DB2** - Data layer (7 tables, 15 SPs)
- **Node.js 18** - REST API layer
- **Express 4** - Web framework
- **ODBC 2** - IBM i connectivity

### Frontend
- **React 18** - UI library
- **Vite 5** - Build tool (ultra-rapide)
- **TanStack Query 5** - Data fetching
- **Tailwind CSS 3** - Styling
- **Recharts 2** - Charts (pie)

### Database (IBM i V7R5 / DB2)
- 7 tables: BROKER, CUSTOMER, PRODUCT, GUARANTEE, CONTRACT, CLAIM
- 15 Stored Procedures (wrappers RPG)
- IDENTITY columns pour IDs auto-increment
- Foreign keys + indexes

## 📚 Documentation Complète

- **[docs/DAS-BELGIUM-RESEARCH.md](docs/DAS-BELGIUM-RESEARCH.md)** - Recherche entreprise + tech + interview prep
- **[docs/implementation-plan.md](docs/implementation-plan.md)** - Plan détaillé du projet
- **[api/README.md](api/README.md)** - Documentation API (37 endpoints)
- **[ui/README.md](ui/README.md)** - Documentation Frontend (5 pages)
- **[docs/program/](docs/program/)** - Documentation 5 RPG programs

## ✅ Checklist Interview

- [ ] Backend API démarré (`npm start` dans `api/`)
- [ ] Frontend démarré (`npm run dev` dans `ui/`)
- [ ] Seed data chargée (5 brokers, 10 customers, 8 contracts, 5 claims)
- [ ] Browser ouvert sur `http://localhost:5173`
- [ ] Doc DAS Belgium imprimée (aide-mémoire)
- [ ] Workflow 1 répété (créer contrat en 2 min)
- [ ] Workflow 2 répété (déclarer sinistre en 2 min)
- [ ] 3 questions préparées pour eux

## 🎓 Points Clés Interview

### À Mentionner
1. **Modèle B2B2C** : "Distribution 100% courtiers - les références DAS-YYYY-BBBBB incluent le broker_id"
2. **KPI 79% Amiable** : "J'ai implémenté le tracking AMI vs TRI - c'est votre objectif stratégique"
3. **TELEBIB2** : "Champs adresse conformes segment ADR (X002-X008)"
4. **Règles Business** : "€350 seuil, €200k plafond, waiting periods - tous validés en temps réel"
5. **Architecture Moderne** : "RPG backend + Node.js API + React frontend - s'intègre avec votre Angular"

### Questions à Leur Poser
1. "Utilisez-vous encore IBM i en production pour le core business ?"
2. "Le KPI 79% amiable est-il mesuré par garantie ou globalement ?"
3. "TELEBIB2 évolue-t-il vers JSON/REST ou reste EDIFACT ?"

## 🚧 Améliorations Post-MVP

- [ ] Authentication JWT courtiers
- [ ] Tests unitaires (Jest + Vitest)
- [ ] Tests E2E (Playwright)
- [ ] CI/CD pipeline
- [ ] Internationalization FR/NL/EN
- [ ] Mobile responsive complet
- [ ] PWA (offline support)
- [ ] Export PDF sinistres
- [ ] WebSocket real-time
- [ ] Monitoring (Prometheus)

## 📄 License

Demo project for DAS Belgium interview - Not for production use.

---

**Objectif** : Démontrer compétence technique RPG + architecture moderne + compréhension business DAS Belgium.

**Message clé** : "J'ai construit un système qui reflète votre réalité business : B2B2C via courtiers, conformité TELEBIB2, règles métier critiques (79% AMI, €350), et prêt à s'intégrer avec votre infrastructure existante."
