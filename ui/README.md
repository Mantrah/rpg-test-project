# DAS Belgium Frontend

Interface React pour le système de protection juridique DAS Belgium. Construit avec React 18 + Vite + Tailwind CSS.

## Stack Technique

- **React** 18.2 - UI library
- **Vite** 5.0 - Build tool (ultra-rapide)
- **React Router** 6.20 - Navigation
- **TanStack Query** 5.12 - Data fetching & caching
- **Tailwind CSS** 3.3 - Styling utility-first
- **Recharts** 2.10 - Charts (pie chart dashboard)
- **Axios** 1.6 - HTTP client
- **date-fns** 3.0 - Date formatting

## Installation

### 1. Pré-requis

- Node.js 18+ installé
- Backend API running sur `http://localhost:3000`

### 2. Installation des dépendances

```bash
cd ui
npm install
```

### 3. Configuration

Copier `.env.example` vers `.env` :

```bash
cp .env.example .env
```

Modifier si nécessaire :

```env
VITE_API_BASE_URL=http://localhost:3000/api
```

### 4. Démarrer le serveur de développement

```bash
npm run dev
```

L'application démarre sur `http://localhost:5173`.

## Structure du Projet

```
ui/
├── src/
│   ├── components/
│   │   ├── Layout.jsx           # Layout principal avec header/nav/footer
│   │   ├── Loading.jsx          # Spinner de chargement
│   │   ├── ErrorMessage.jsx     # Affichage erreurs
│   │   └── KPICard.jsx          # Card KPI pour dashboard
│   ├── pages/
│   │   ├── Dashboard.jsx        # Page dashboard (KPIs + pie chart)
│   │   ├── BrokerList.jsx       # Liste courtiers
│   │   ├── ContractList.jsx     # Liste contrats
│   │   ├── CreateContract.jsx   # ⭐ Workflow 1: Wizard 3 étapes
│   │   └── DeclareClaim.jsx     # ⭐ Workflow 2: Validation temps réel
│   ├── services/
│   │   └── api.js               # API client (axios + endpoints)
│   ├── App.jsx                  # Routes principales
│   ├── main.jsx                 # Entry point
│   └── index.css                # Styles Tailwind + custom
├── index.html
├── vite.config.js
├── tailwind.config.js
├── postcss.config.js
├── package.json
└── README.md
```

## Pages de l'Application (5 pages)

### 1. Dashboard (`/`)

**KPIs affichés** :
- Courtiers actifs
- Clients actifs (IND/BUS)
- Contrats actifs
- Sinistres total

**Métriques business** :
- Taux résolution amiable (79% objectif)
- Montants sinistres (réclamé vs approuvé)
- Statuts sinistres détaillés

**Visualisation** :
- Pie chart: Répartition sinistres par statut

### 2. Liste Courtiers (`/brokers`)

- Table tous courtiers avec filtrage par statut (ACT/SUS)
- Colonnes: Code, Société, Localisation, Contact, Statut
- Action: **Créer Contrat** → Lance Workflow 1

### 3. Liste Contrats (`/contracts`)

- Table tous contrats avec filtrage par statut (ACT/SUS/EXP/CLS)
- Colonnes: Référence, Client, Produit, Période, Prime, Statut
- Action: **Déclarer Sinistre** → Lance Workflow 2

### 4. Créer Contrat (`/contracts/create`) ⭐ **WORKFLOW 1**

**Wizard en 3 étapes** :

**Étape 1: Client**
- Sélection client existant OU
- Création nouveau client (IND/BUS)
- Formulaire complet (nom, email, adresse TELEBIB2)

**Étape 2: Produit**
- Sélection produit DAS (Classic/Connect/Comfort)
- Nombre véhicules (+€25 par véhicule)
- Fréquence paiement (Annuel/Trimestriel +2%/Mensuel +5%)
- Auto-renewal toggle
- **Calculateur prime temps réel** :
  ```
  Base: €114
  Véhicules (2 × €25): +€50
  Fréquence Mensuel (×1.05): +5%
  ────────────────────
  TOTAL: €172.20
  ```

**Étape 3: Récapitulatif**
- Affichage toutes infos
- Validation finale
- Création contrat → Génère référence `DAS-2025-00001-000123`

### 5. Déclarer Sinistre (`/contracts/:id/claim`) ⭐ **WORKFLOW 2**

**Formulaire avec validation temps réel** :

**Champs** :
- Garantie (liste dynamique du produit)
- Circonstance (Litige/Accident/Conflit/Autre)
- Dates (déclaration + incident)
- Description
- Montant réclamé

**Validation Temps Réel** (API `/claims/validate`) :
```javascript
// Appel automatique quand garantie + montant + date remplis
POST /api/claims/validate
{
  "contId": 1,
  "guaranteeCode": "VOIS",
  "claimedAmount": 1500,
  "incidentDate": "2025-11-20"
}

// Response
{
  "isValid": true,
  "errors": [],
  "warnings": [],
  "coverage": {
    "isCovered": true,
    "isWaitingPeriodOver": true,
    "guaranteeName": "Troubles de voisinage",
    "waitingMonths": 3,
    "waitingEndDate": "2025-04-01",
    "daysUntilCoverage": 0
  }
}
```

**Affichage dynamique** :
- ✅ Garantie couverte
- ✅ Période d'attente écoulée (ou J jours restants)
- ✅ Montant ≥ €350 (seuil DAS)
- ✅ Sous plafond €200k
- ⚠️ Erreurs bloquantes en rouge
- ⚠️ Avertissements en jaune

**Soumission** :
- Bouton désactivé si validation échoue
- Création sinistre → Génère `SIN-2025-000045` + `DOS-0000000045`

## Workflows Démo Interview (5-7 minutes)

### Workflow 1: Créer Contrat (2 minutes)

```
1. Dashboard → KPIs (15 sec)
2. Courtiers → Sélectionner "Assurances Dupont" (10 sec)
3. Client → Nouveau Particulier "Jean Martin" (30 sec)
4. Produit → DAS Classic + 2 véhicules + Mensuel (30 sec)
5. Calculateur → €172.20 (affichage automatique)
6. Récap → Créer → DAS-2025-00001-000123 (35 sec)
```

### Workflow 2: Déclarer Sinistre (2 minutes)

```
1. Contrats → Sélectionner DAS-2025-00001-000123 (10 sec)
2. Garantie → "Troubles de voisinage" (VOIS) (15 sec)
3. Montant → €1500 (10 sec)
4. Validation temps réel → Affichage (15 sec)
   ✅ Garantie couverte
   ✅ Période d'attente 3 mois écoulée
   ✅ Montant ≥ €350
5. Description → "Litige avec voisin" (30 sec)
6. Soumettre → SIN-2025-000045 créé (20 sec)
```

## Features Techniques Impressionnantes

### 1. Validation Temps Réel

La validation du sinistre se fait **pendant la saisie**, pas à la soumission :

```jsx
// DeclareClaim.jsx
useEffect(() => {
  if (guaranteeCode && claimedAmount && incidentDate) {
    // Appel API automatique
    validateMutation.mutate({
      contId, guaranteeCode, claimedAmount, incidentDate
    })
  }
}, [guaranteeCode, claimedAmount, incidentDate])
```

**Bénéfice** : Feedback immédiat à l'utilisateur (UX moderne)

### 2. Calculateur Prime Automatique

Le calculateur recalcule automatiquement quand :
- Produit change
- Nombre véhicules change
- Fréquence paiement change

```jsx
// CreateContract.jsx
useEffect(() => {
  if (productCode && step === 2) {
    premiumMutation.mutate({
      productCode, vehiclesCount, payFrequency
    })
  }
}, [productCode, vehiclesCount, payFrequency])
```

**Résultat** : L'utilisateur voit la prime en direct sans cliquer "Calculer"

### 3. TanStack Query Caching

```jsx
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // Cache 5 minutes
      refetchOnWindowFocus: false,
    },
  },
})
```

**Bénéfice** : Pas de rechargement inutile, expérience fluide

### 4. Responsive Design Tailwind

```jsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
  {/* KPI Cards s'adaptent automatiquement */}
</div>
```

**Résultat** : Desktop responsive (mobile bonus si temps)

### 5. Error Handling Unifié

```javascript
// api.js
api.interceptors.response.use(
  (response) => response.data,
  (error) => {
    const message = error.response?.data?.error?.message
    const code = error.response?.data?.error?.code
    return Promise.reject({ message, code, status })
  }
)
```

**Affichage** : Toujours code erreur DAS (BUS006, VAL001, etc.)

## Composants Réutilisables

### Loading

```jsx
<Loading message="Chargement des données..." />
```

### ErrorMessage

```jsx
<ErrorMessage message={error.message} code={error.code} />
```

### KPICard

```jsx
<KPICard
  title="Contrats Actifs"
  value={42}
  icon="📄"
  color="purple"
  subtitle="8 auto-renewal"
/>
```

## API Integration

Tous les endpoints API sont disponibles via `src/services/api.js` :

```javascript
import { dashboardApi, brokerApi, customerApi, productApi, contractApi, claimApi } from './services/api'

// Dashboard
const stats = await dashboardApi.getStats()

// Brokers
const brokers = await brokerApi.getAll('ACT')

// Customers
const customer = await customerApi.create({ ... })

// Products
const premium = await productApi.calculatePremium({ ... })

// Contracts
const contract = await contractApi.create({ ... })

// Claims
const validation = await claimApi.validate({ ... })
const claim = await claimApi.create({ ... })
```

## Thème DAS Belgium

Couleurs personnalisées dans `tailwind.config.js` :

```javascript
colors: {
  'das-blue': '#003B7A',        // Bleu primaire DAS
  'das-light-blue': '#0066CC',  // Bleu hover
  'das-gray': '#F5F5F5',        // Background
  'das-dark-gray': '#333333',   // Text
}
```

Classes utilitaires custom dans `index.css` :

```css
.btn-primary   /* Bouton bleu DAS */
.btn-secondary /* Bouton outline */
.btn-success   /* Bouton vert validation */
.card          /* Container blanc avec shadow */
.input-field   /* Input standardisé */
.label         /* Label standardisé */
```

## Scripts NPM

```bash
npm run dev      # Dev server (Vite HMR)
npm run build    # Production build
npm run preview  # Preview production build
npm run lint     # ESLint
```

## Build Production

```bash
npm run build
```

Génère dans `dist/` :
- HTML/CSS/JS minifiés
- Assets optimisés
- Tree-shaking automatique
- Code-splitting par route

## Proxy API (Dev)

Configuration dans `vite.config.js` :

```javascript
server: {
  proxy: {
    '/api': {
      target: 'http://localhost:3000',
      changeOrigin: true
    }
  }
}
```

**Bénéfice** : Pas de CORS en dev, URLs relatives

## Déploiement

### Option 1: Static Hosting (Vercel/Netlify)

```bash
npm run build
# Deploy dist/ folder
```

### Option 2: IBM i IFS

```bash
npm run build
# Copy dist/ to /www/dasbe/public
```

### Option 3: Docker

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
# Serve with nginx
```

## Points Forts pour Interview

1. **Architecture Moderne** : React 18 + Vite (comme Angular chez DAS mais en React)
2. **Validation Temps Réel** : Feedback immédiat sur sinistres
3. **Wizard Multi-étapes** : UX guidée pour créer contrats
4. **Business Rules Visibles** : €350, 79% AMI, waiting periods affichés
5. **Error Handling Professionnel** : Codes erreur DAS (BUS*, VAL*, DB*)
6. **Performance** : Caching TanStack Query, Vite build rapide
7. **Design Cohérent** : Tailwind + thème DAS Belgium

## Améliorations Post-MVP

- [ ] Authentification JWT courtiers
- [ ] Tests unitaires (Vitest + React Testing Library)
- [ ] Tests E2E (Playwright)
- [ ] Internationalization FR/NL/EN
- [ ] Mobile responsive complet
- [ ] PWA (offline support)
- [ ] WebSocket real-time updates
- [ ] Export PDF sinistres
- [ ] Drag & drop documents

---

**Objectif** : Impressionner DAS Belgium en montrant un système moderne, complet et fonctionnel qui respecte leurs règles business et pourrait s'intégrer à leur infrastructure Angular existante.
