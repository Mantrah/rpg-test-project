# DAS Belgium - Cheat Sheet Interview (5 min)

## 📊 PARTIE 1: CONTEXTE BUSINESS & ENTREPRISE

### Identité
- **Fondation**: 1927 (presque 100 ans)
- **Groupe**: ERGO (Munich Re) - Solidité financière internationale
- **Effectif**: ~236 employés
- **Position**: **#1 Protection juridique Belgique** (leader marché)
- **Bureaux**: 5 régionaux (Bruxelles, Anvers, Gand, Liège, Nivelles)

### Modèle Business UNIQUE ⭐
**DISTRIBUTION 100% VIA COURTIERS** (pas de vente directe)
- B2B2C: DAS → Courtiers → Clients finaux
- Tous les contrats passent par brokers
- **Impact IT**: Système doit gérer relations broker-client (d'où DAS-YYYY-BBBBB-NNNNNN avec BBBBB = broker_id)

### Produits & Prix
| Produit | Prix/an | Cible |
|---------|---------|-------|
| **DAS Classic** | €114 | Base particuliers |
| **DAS Connect** | €276 | Étendu (Internet, e-commerce) |
| **DAS Comfort** | €396 | Complet (+ famille, fiscal) |
| **Benefisc** | €245-756 | Avec déduction fiscale 40% (Loi Geens 2019) |

### Règles Business Critiques (À MENTIONNER)
- **Seuil minimum**: €350 (évite micro-sinistres)
- **Plafond**: €200,000 max
- **Période attente**: 3-12 mois selon garantie
- **KPI stratégique**: **79% résolution amiable** (AMI vs TRI)
  - Réduit coûts juridiques
  - Améliore satisfaction
  - À tracker dans système

### Garanties Principales
- **VOIS**: Troubles voisinage (3 mois attente)
- **PENAL**: Défense pénale (0 mois)
- **ASSUR**: Litiges assurance (3 mois)
- **MEDIC**: Erreurs médicales (6 mois)
- **FAMIL**: Droit familial (12 mois - Comfort only)
- **FISCAL**: Litiges fiscaux (6 mois - Benefisc only)

---

## 💻 PARTIE 2: INFRASTRUCTURE TECHNIQUE (INFÉRÉE)

### Frontend Constaté
- **Angular-based SPA** (site www.das.be)
- Architecture moderne client-side
- Style récent (probablement Angular 12+)

### Portails Authentifiés
- `claims.das.be` - Déclaration sinistres clients
- `extranet.das.be` - **Extranet23** (portail courtiers)
- `www-data.das.be/strapi/` - CMS/Documents (AWS S3)
- **Pas d'API publique** - Tout authentifié

### Backend Probable
**IBM i (AS/400) très probable** pour:
- Gestion contrats (références TELEBIB2 complexes)
- Calculs actuariels (primes, waiting periods)
- Historique transactions (depuis 1927 = legacy)
- Intégration TELEBIB2 native (standard EDI belge)

**Pourquoi IBM i probable?**
- Assureur historique (1927)
- TELEBIB2 = standard belge très structuré (typique mainframe)
- Calculs complexes (actuariat)
- Référencement contrats sophistiqué
- Pas d'API moderne publique (legacy backend)

### TELEBIB2 (Standard EDI Belge) ⭐

**Qu'est-ce que c'est?**
- **TELEBIB2** = Standard obligatoire belge pour échanges électroniques assurances
- **EDI** (Electronic Data Interchange) = Échange de données structurées entre systèmes
- **Format**: Fichiers plats texte avec délimiteurs (pas XML/JSON)
- **Base**: UN/EDIFACT (norme internationale années 80-90)

**Format technique EDI**:
```
Exemple UN/EDIFACT (fichier plat):
UNH+1+ORDERS:D:96A:UN'
BGM+220+POLICY123+9'
NAD+BY+12345::92++CompanyName+StreetName+12+BoxA++1000+Brussels+BE'
```
- Segments séparés par `'` (apostrophe)
- Éléments séparés par `+` (plus)
- Composants séparés par `:` (deux-points)
- **Pas de XML/JSON** = Fichier texte plat avec structure rigide

**TELEBIB2 = Version belge** adaptée pour assurances (contrats, sinistres, primes, courtiers)

**Segment ADR (adresses)**:
  - X002: Rue (30 chars)
  - X003: Numéro (5 chars)
  - X004: Boîte (4 chars)
  - X006: Code postal (7 chars)
  - X007: Ville (24 chars)
  - X008: Pays (3 chars - "BE")

**Éléments Business**:
- `AgencyCode` (courtier)
- `BrokerPolicyReference` (contrat)
- `ClaimReference` (sinistre)
- `CoverageCode` (garantie)

**Format références DAS**:
- Contrat: `DAS-YYYY-BBBBB-NNNNNN`
- Sinistre: `SIN-YYYY-NNNNNN`
- Dossier: `DOS-NNNNNNNNNN`

---

## 🎯 PHRASES CLÉS À DIRE (VERBATIM)

### Sur le Modèle Business
> "Votre distribution 100% courtiers implique que le système doit gérer les relations broker-client avec traçabilité complète. C'est pourquoi j'ai intégré le broker_id dans les références contrats: DAS-YYYY-**BBBBB**-NNNNNN."

### Sur le KPI 79%
> "Le taux de 79% de résolution amiable est un KPI critique. J'ai implémenté le suivi AMI vs TRI dans le module Claims avec tracking dans le Dashboard."

### Sur TELEBIB2
> "TELEBIB2 est le standard EDI obligatoire pour les assurances belges - un format de fichiers plats structurés basé sur UN/EDIFACT. J'ai respecté le segment ADR (X002 rue, X003 numéro, X004 boîte) et les formats de références standard pour faciliter l'intégration avec vos systèmes courtiers."

### Sur la Loi Geens
> "La déduction fiscale 40% depuis septembre 2019 explique le succès de la gamme Benefisc. Ça démocratise l'accès à la justice, aligné avec votre mission."

### Sur l'Architecture
> "Mon architecture Node.js + ODBC fait le pont entre votre backend traditionnel (probablement IBM i) et un frontend moderne. Ça s'intègre facilement avec votre infrastructure Angular existante."

---

## ❓ QUESTIONS À LEUR POSER

1. **"Utilisez-vous encore IBM i en production pour le core business, ou avez-vous migré vers une autre plateforme?"**
   - Montre compréhension legacy
   - Ouvre discussion architecture

2. **"Le KPI 79% résolution amiable est-il mesuré par garantie spécifique ou globalement sur tous les sinistres?"**
   - Montre attention aux détails business
   - Intérêt pour leurs métriques

3. **"TELEBIB2 évolue-t-il vers des standards plus modernes comme JSON/REST API, ou reste-t-il sur EDIFACT?"**
   - Montre connaissance EDI
   - Intérêt pour modernisation

---

## 🚨 PIÈGES À ÉVITER

### ❌ NE PAS DIRE:
- "Votre site permet aux clients de souscrire directement"
  - FAUX: 100% via courtiers
- "C'est un assureur généraliste"
  - FAUX: Spécialiste pure-player protection juridique
- "Angular est dépassé, React est mieux"
  - Maladroit: ils utilisent Angular

### ✅ À LA PLACE:
- "Votre modèle B2B2C via courtiers est unique"
- "Spécialiste protection juridique vs multi-line insurers"
- "Mon React s'intègre facilement avec votre Angular backend"

---

## 📋 CHECKLIST 5 MIN AVANT INTERVIEW

- [ ] **Chiffres clés**: 1927, 236 employés, #1 marché, 79% AMI
- [ ] **Modèle**: 100% courtiers (B2B2C)
- [ ] **KPI**: 79% résolution amiable
- [ ] **Règles**: €350 seuil, €200k plafond
- [ ] **TELEBIB2**: Segment ADR, références format standard
- [ ] **3 questions** préparées
- [ ] **Demo** répétée (5-7 min max)
- [ ] **Phrases clés** relues

---

## 🎬 STRUCTURE PITCH (30 SEC)

> "J'ai construit un système de protection juridique pour DAS Belgium qui reflète votre réalité business. **Distribution 100% courtiers** donc chaque contrat trace le broker_id. **Conformité TELEBIB2** avec segment ADR et références standard. **Règles métier critiques**: €350 seuil minimum, 79% résolution amiable tracké dans le dashboard. **Architecture moderne**: RPG backend + Node.js API + React frontend, prête à s'intégrer avec votre infrastructure Angular existante. Deux workflows complets: créer contrat avec calculateur temps réel, et déclarer sinistre avec validation instantanée de la couverture et des waiting periods."

---

## 💪 MESSAGE DE CONFIANCE

**Vous avez**:
- ✅ Système fonctionnel end-to-end
- ✅ Compréhension modèle business unique
- ✅ Règles métier implémentées (79% AMI, €350, waiting periods)
- ✅ Conformité TELEBIB2
- ✅ Architecture moderne intégrable

**Vous montrez**:
- 🎯 Compétence technique (RPG + moderne)
- 🎯 Compréhension business (pas juste dev)
- 🎯 Attention aux détails (TELEBIB2, KPIs)
- 🎯 Vision architecturale (intégration)

**Soyez confiant. Vous avez fait le travail.** 💪
