# DAS Belgium Backend API

REST API pour le système d'assurance protection juridique DAS Belgium. Construit avec Node.js + Express + ODBC pour IBM i V7R5.

## Architecture

```
RPG Service Programs (IBM i)
         ↓
SQL Stored Procedures (DB2)
         ↓
Node.js REST API (ODBC)
         ↓
React Frontend
```

## Technologies

- **Node.js** 18+
- **Express** 4.x - Framework web
- **ODBC** 2.x - Connexion IBM i
- **Helmet** - Sécurité HTTP headers
- **Morgan** - Logging HTTP
- **CORS** - Cross-Origin Resource Sharing
- **dotenv** - Configuration environnement

## Installation

### 1. Pré-requis

- Node.js 18+ installé
- Accès à IBM i (PUB400 ou serveur local)
- Driver ODBC IBM i Access installé

### 2. Installation des dépendances

```bash
cd api
npm install
```

### 3. Configuration

Copier `.env.example` vers `.env` et configurer :

```env
# Database (IBM i / PUB400)
DB_HOST=pub400.com
DB_PORT=50000
DB_DATABASE=DASBE
DB_USER=YOUR_USERNAME
DB_PASSWORD=YOUR_PASSWORD
DB_DRIVER=IBM i Access ODBC Driver

# Server
PORT=3000
API_PREFIX=/api
CORS_ORIGIN=*

# Environment
NODE_ENV=development
```

### 4. Démarrer le serveur

```bash
# Mode développement (avec auto-reload)
npm run dev

# Mode production
npm start
```

Le serveur démarre sur `http://localhost:3000`.

## API Endpoints (20 endpoints)

### 🏢 Dashboard (`/api/dashboard`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/stats` | Tous les KPIs (brokers, customers, contracts, claims, revenue) |
| GET | `/brokers` | Statistiques courtiers |
| GET | `/customers` | Statistiques clients |
| GET | `/contracts` | Statistiques contrats |
| GET | `/claims` | Statistiques sinistres |
| GET | `/revenue` | Statistiques revenus |
| GET | `/claims-by-status` | Sinistres par statut (pie chart) |
| GET | `/recent-claims?limit=5` | Sinistres récents |
| GET | `/top-products` | Produits les plus vendus |

### 🏛️ Brokers (`/api/brokers`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/` | Créer courtier |
| GET | `/` | Liste courtiers (filtrage `?status=ACT`) |
| GET | `/:id` | Détail courtier |
| GET | `/code/:code` | Courtier par code |

### 👥 Customers (`/api/customers`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/` | Créer client (IND/BUS) |
| GET | `/` | Liste clients (filtrage `?status=ACT`) |
| GET | `/:id` | Détail client |
| GET | `/email/:email` | Client par email |
| GET | `/:id/contracts` | Contrats du client |

### 📦 Products (`/api/products`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| GET | `/` | Liste produits actifs |
| GET | `/:id` | Détail produit |
| GET | `/code/:code` | Produit par code |
| GET | `/:id/guarantees` | Garanties du produit |
| POST | `/calculate` | Calculer prime |

**Body `/calculate`** :
```json
{
  "productCode": "DASCLAS",
  "vehiclesCount": 2,
  "payFrequency": "M"
}
```

### 📄 Contracts (`/api/contracts`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/` | Créer contrat |
| GET | `/` | Liste contrats (filtrage `?status=ACT`) |
| GET | `/:id` | Détail contrat |
| GET | `/reference/:reference` | Contrat par référence |
| GET | `/broker/:brokerId` | Contrats du courtier |
| GET | `/:id/claims` | Sinistres du contrat |
| POST | `/calculate` | Calculer prime |

**Body `POST /`** :
```json
{
  "brokerId": 1,
  "custId": 5,
  "productCode": "DASCLAS",
  "startDate": "2025-01-01",
  "endDate": "2026-01-01",
  "vehiclesCount": 2,
  "totalPremium": 172.20,
  "payFrequency": "M",
  "autoRenewal": "Y",
  "notes": "Contract notes"
}
```

### ⚖️ Claims (`/api/claims`)

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| POST | `/` | Créer sinistre |
| GET | `/` | Liste sinistres (filtrage `?status=NEW`) |
| GET | `/:id` | Détail sinistre |
| GET | `/reference/:reference` | Sinistre par référence |
| GET | `/stats` | Statistiques sinistres |
| POST | `/check-coverage` | Vérifier couverture |
| POST | `/validate` | Valider avant création |

**Body `POST /`** :
```json
{
  "contId": 1,
  "guaranteeCode": "VOIS",
  "circumstanceCode": "LITIGE",
  "declarationDate": "2025-12-05",
  "incidentDate": "2025-11-20",
  "description": "Neighborhood dispute",
  "claimedAmount": 1500.00
}
```

**Body `/validate`** (validation temps réel UI) :
```json
{
  "contId": 1,
  "guaranteeCode": "VOIS",
  "claimedAmount": 1500.00,
  "incidentDate": "2025-11-20"
}
```

**Response `/validate`** :
```json
{
  "success": true,
  "data": {
    "isValid": true,
    "errors": [],
    "warnings": [],
    "coverage": {
      "isCovered": true,
      "isWaitingPeriodOver": true,
      "contractReference": "DAS-2025-00001-000123",
      "guaranteeName": "Troubles de voisinage",
      "waitingMonths": 3,
      "waitingEndDate": "2025-04-01",
      "daysUntilCoverage": 0
    }
  }
}
```

## Business Rules Validées

L'API implémente automatiquement les règles métier DAS :

| Code | Règle | Endpoint |
|------|-------|----------|
| BUS001 | Garantie non couverte par produit | `/claims/validate` |
| BUS002 | Période d'attente non écoulée | `/claims/validate` |
| BUS003 | Montant > limite couverture (€200k) | `/claims/validate` |
| BUS006 | Montant < seuil minimum (€350) | `/claims/validate`, `POST /claims` |
| VAL001 | Format invalide | Tous |
| VAL002 | Champ requis manquant | Tous |
| VAL003 | Valeur hors limites | Tous |

## Format de Réponse

### Succès
```json
{
  "success": true,
  "data": { ... }
}
```

### Erreur
```json
{
  "success": false,
  "error": {
    "code": "BUS006",
    "message": "Claim amount must be at least €350"
  }
}
```

## Codes Status HTTP

- `200 OK` - Succès
- `201 Created` - Ressource créée
- `400 Bad Request` - Erreur validation (VAL*)
- `404 Not Found` - Ressource non trouvée (DB001)
- `409 Conflict` - Duplicate (DB002)
- `422 Unprocessable Entity` - Règle métier violée (BUS*)
- `500 Internal Server Error` - Erreur serveur

## Health Check

```bash
curl http://localhost:3000/health
```

Response:
```json
{
  "status": "OK",
  "timestamp": "2025-12-05T10:30:00.000Z",
  "service": "DAS Backend API",
  "version": "1.0.0"
}
```

## Scripts NPM

```bash
npm start          # Production
npm run dev        # Développement (nodemon)
npm test           # Tests (TODO)
npm run lint       # Linting (TODO)
```

## Structure du Projet

```
api/
├── src/
│   ├── config/
│   │   ├── database.js          # Connection ODBC + pool
│   │   └── constants.js         # Business rules + constantes
│   ├── controllers/
│   │   ├── brokerController.js
│   │   ├── customerController.js
│   │   ├── productController.js
│   │   ├── contractController.js
│   │   ├── claimController.js
│   │   └── dashboardController.js
│   ├── services/
│   │   ├── brokerService.js
│   │   ├── customerService.js
│   │   ├── productService.js
│   │   ├── contractService.js
│   │   ├── claimService.js
│   │   └── dashboardService.js
│   ├── routes/
│   │   ├── brokers.js
│   │   ├── customers.js
│   │   ├── products.js
│   │   ├── contracts.js
│   │   ├── claims.js
│   │   └── dashboard.js
│   ├── middleware/
│   │   └── errorHandler.js
│   ├── utils/
│   │   └── responseFormatter.js
│   └── app.js                   # Express server
├── .env.example                 # Template config
├── package.json
└── README.md
```

## Workflow Démo Interview

### 1. Créer Contrat (Workflow 1)

```bash
# 1. Lister courtiers
curl http://localhost:3000/api/brokers

# 2. Créer client
curl -X POST http://localhost:3000/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "custType": "IND",
    "firstName": "Jean",
    "lastName": "Dupont",
    "street": "Rue de la Loi",
    "houseNbr": "42",
    "postalCode": "1000",
    "city": "Bruxelles",
    "countryCode": "BE",
    "email": "jean.dupont@example.be",
    "language": "FR"
  }'

# 3. Calculer prime
curl -X POST http://localhost:3000/api/products/calculate \
  -H "Content-Type: application/json" \
  -d '{
    "productCode": "DASCLAS",
    "vehiclesCount": 2,
    "payFrequency": "M"
  }'
# → €172.20 (€114 base + €50 véhicules + 5% mensuel)

# 4. Créer contrat
curl -X POST http://localhost:3000/api/contracts \
  -H "Content-Type: application/json" \
  -d '{
    "brokerId": 1,
    "custId": 1,
    "productCode": "DASCLAS",
    "startDate": "2025-01-01",
    "endDate": "2026-01-01",
    "vehiclesCount": 2,
    "totalPremium": 172.20,
    "payFrequency": "M",
    "autoRenewal": "Y"
  }'
# → DAS-2025-00001-000123
```

### 2. Déclarer Sinistre (Workflow 2)

```bash
# 1. Lister contrats
curl http://localhost:3000/api/contracts?status=ACT

# 2. Valider couverture (temps réel)
curl -X POST http://localhost:3000/api/claims/validate \
  -H "Content-Type: application/json" \
  -d '{
    "contId": 1,
    "guaranteeCode": "VOIS",
    "claimedAmount": 1500.00,
    "incidentDate": "2025-11-20"
  }'
# → Validations: Couvert, Période OK, Montant OK

# 3. Créer sinistre
curl -X POST http://localhost:3000/api/claims \
  -H "Content-Type: application/json" \
  -d '{
    "contId": 1,
    "guaranteeCode": "VOIS",
    "circumstanceCode": "LITIGE",
    "declarationDate": "2025-12-05",
    "incidentDate": "2025-11-20",
    "description": "Neighborhood dispute",
    "claimedAmount": 1500.00
  }'
# → SIN-2025-000045 + DOS-0000000045
```

## Prochaines Étapes

- [ ] Sprint 2: React Frontend (5 pages)
- [ ] Sprint 3: Seed data + Polish
- [ ] Tests unitaires (Jest)
- [ ] Documentation Swagger/OpenAPI
- [ ] Rate limiting
- [ ] Authentication JWT

## Support

Documentation complète: `/docs/program/*.md`
SQL Stored Procedures: `/sql/sp/*.sql`
RPG Service Programs: `/src/qrpglesrc/*SRV.sqlrpgle`

---

**Objectif**: Impressionner DAS Belgium lors de l'interview en montrant un système complet et fonctionnel avec les 5 modules RPG en action à travers 2 workflows business critiques.
