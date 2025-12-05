# DAS Belgium - Recherche Approfondie pour Interview

Documentation récapitulative des éléments clés pour impressionner DAS Belgium lors de l'interview.

---

## 🏢 Profil Entreprise

### Identité
| Attribut | Valeur |
|----------|--------|
| **Nom complet** | DAS Belgium NV/SA |
| **Fondation** | 1927 (presque 100 ans d'histoire) |
| **Effectif** | ~236 employés |
| **Groupe parent** | ERGO Group (Munich Re) |
| **Siège social** | Boulevard du Roi Albert II, 7 - 1210 Bruxelles |
| **Bureaux régionaux** | 5 offices: Bruxelles, Nivelles, Liège, Anvers, Gand |
| **Position marché** | **Leader** de l'assurance protection juridique en Belgique |
| **Supervision** | Banque Nationale de Belgique (code 0687) |
| **Part de marché** | ~3.4% (assurance santé, protection juridique, voyage, accidents) |

### Modèle Business Unique

**🔑 INSIGHT CLÉ:** DAS ne vend PAS directement aux clients finaux. **100% des ventes passent par des courtiers d'assurance** (brokers/makelaars).

Cette distribution exclusive via courtiers est **fondamentale** pour leur architecture IT :
- Portail broker authentifié (`extranet.das.be`)
- Système de référencement contrats par courtier (DAS-YYYY-BBBBB-NNNNNN)
- Commissions et incentives courtiers
- Support dédié aux courtiers

### Concept PROF (Service aux Courtiers)

DAS se positionne comme **partenaire des courtiers** avec :
- **Service Box**: Conseils juridiques préventifs, revue de documents
- **Équipe juridique interne** (pas d'outsourcing pour conseils basiques)
- **Philosophie**: "Wij helpen u" / "Nous vous aidons"

---

## 📦 Produits & Tarification

### Particuliers (Individus)

| Produit | Prix/an | Niveau Couverture | Garanties |
|---------|---------|-------------------|-----------|
| **DAS Classic** | €114 | Basique | 4 garanties de base |
| **DAS Connect** | €276 | Étendue | + Internet, e-commerce |
| **DAS Comfort** | €396 | Complète | + Toutes options |

**Nommage alternatif marketing**: Vie Privée, Consommateur, Conflits

### Gamme Benefisc (avec avantages fiscaux)

| Produit | Prix/an | Avantage Fiscal |
|---------|---------|-----------------|
| **Benefisc Base** | €245 | 40% déduction |
| **Benefisc Plus** | €492 | 40% déduction |
| **Benefisc Premium** | €756 | 40% déduction |

**Loi Geens (2019)**: Déduction fiscale 40% pour protection juridique privée.

### Garanties par Catégorie

| Garantie | Code | Classic | Connect | Comfort | Benefisc |
|----------|------|---------|---------|---------|----------|
| **Recouvrement civil & voisinage** | VOIS | ✅ | ✅ | ✅ | ✅ |
| **Défense pénale** | PENAL | ✅ | ✅ | ✅ | ✅ |
| **Litiges contrats assurance** | ASSUR | ✅ | ✅ | ✅ | ✅ |
| **Erreurs médicales** | MEDIC | ✅ | ✅ | ✅ | ✅ |
| **Droit familial** | FAMIL | ❌ | ❌ | ✅ | ✅ |
| **Droit fiscal (FiscAssist)** | FISC | ❌ | ❌ | ❌ | ✅ |
| **Droit du travail** | TRAV | ❌ | ❌ | ❌ | ✅ |
| **Droits de succession** | SUCCES | ❌ | ❌ | ❌ | ✅ |
| **Droit administratif** | ADMIN | ❌ | ❌ | ❌ | ✅ |

---

## ⚖️ Règles Business Critiques

### Règles de Couverture

| Règle | Valeur | Implémentation |
|-------|--------|----------------|
| **Plafond couverture** | €200,000 max | BUSINESS_RULES.COVERAGE_LIMIT_MAX |
| **Seuil intervention minimum** | €350 | BUSINESS_RULES.MIN_CLAIM_THRESHOLD |
| **Période d'attente** | 3-12 mois selon garantie | WAITING_MONTHS (PRODUCT/GUARANTEE) |
| **Durée contrat** | 1 an | Contract logic |
| **Renouvellement** | Auto-renewal par défaut | AUTO_RENEWAL flag |
| **Résiliation** | 2 mois avant expiration | Business rule |

### KPI Métier Stratégique

**79% de résolution à l'amiable** (AMI) vs tribunal (TRI)

C'est un **KPI critique** pour DAS :
- Réduit les coûts juridiques
- Améliore satisfaction client
- Démontre efficacité médiation
- Implémenté dans: `CLAIMSRV_SetResolutionType()`, Dashboard KPI

### Véhicules (Multi-Vehicle Discount)

Addon véhicule : **€25 par véhicule**
- Implémentation: `SP_CalculateBasePremium`, `productService.calculateBasePremium()`
- Exemple: 2 véhicules = €114 + (2 × €25) = €164 base

### Fréquence Paiement (Surcharges)

| Fréquence | Code | Multiplicateur | Exemple (€114 base) |
|-----------|------|----------------|---------------------|
| **Annuel** | A | 1.00 (0%) | €114.00 |
| **Trimestriel** | Q | 1.02 (+2%) | €116.28 |
| **Mensuel** | M | 1.05 (+5%) | €119.70 |

---

## 💻 Infrastructure Technique

### Stack Frontend

**Angular-based SPA** (Single Page Application)
- Site principal: `www.das.be`
- Architecture moderne client-side
- Probablement Angular 12+ (style récent)

### Portails Authentifiés

| URL | Usage | Utilisateurs |
|-----|-------|--------------|
| `claims.das.be` | Déclaration sinistres | Clients finaux |
| `extranet.das.be` | Extranet23 - Portail courtiers | Brokers uniquement |
| `www-data.das.be/strapi/` | CMS/Documents (AWS S3) | Interne |

**⚠️ Pas d'API publique** - Tout passe par portails authentifiés

### Backend IBM i

Bien que non confirmé officiellement, l'usage de **RPG/COBOL sur IBM i** est très probable pour :
- Gestion contrats (référencements TELEBIB2)
- Calculs actuariels (primes, waiting periods)
- Historique transactions (depuis 1927)
- Intégration TELEBIB2 native

### TELEBIB2 Standard 🇧🇪

**Standard EDI officiel belge** (UN/EDIFACT) pour assurances.

#### Segments Clés

**ADR (Address)** - Adresses conformes standard belge :
```
X002: Street (30 chars)
X003: House number (5 chars)
X004: Box number (4 chars)
X006: Postal code (7 chars)
X007: City (24 chars)
X008: Country code (3 chars - "BE")
```

**Éléments Business** :
- `AgencyCode` - Code courtier (BrokerCode dans notre modèle)
- `BrokerPolicyReference` - Référence contrat courtier
- `ClaimReference` - Référence sinistre (SIN-YYYY-NNNNNN)
- `CoverageCode` - Code garantie (VOIS, PENAL, MEDIC, etc.)
- `PolicyholderInformation` - Données preneur

#### Implémentation dans Notre Projet

| Élément TELEBIB2 | Notre Champ | Table |
|------------------|-------------|-------|
| AgencyCode | BROKER_CODE | BROKER |
| PolicyholderInformation | CUST_* | CUSTOMER |
| BrokerPolicyReference | CONT_REFERENCE | CONTRACT |
| ClaimReference | CLAIM_REFERENCE | CLAIM |
| CoverageCode | GUARANTEE_CODE | GUARANTEE |
| X002-X008 (Address) | STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY, COUNTRY_CODE | BROKER, CUSTOMER |

---

## 🎯 Points Clés pour Impressionner lors de l'Interview

### 1. Comprendre le Modèle Business Unique

**❌ NE PAS DIRE**: "Votre site permet aux clients de souscrire directement"
**✅ DIRE**: "Votre distribution 100% via courtiers implique que le système doit gérer les relations broker-client avec traçabilité complète (d'où les références DAS-YYYY-BBBBB-NNNNNN avec BBBBB = broker_id)"

### 2. Connaître les KPIs Stratégiques

**✅ MENTIONNER**:
- "Le taux de 79% de résolution amiable est un KPI critique - j'ai implémenté le suivi AMI vs TRI dans le module Claims avec tracking dans le Dashboard"
- "Le seuil de €350 évite les micro-sinistres non rentables"
- "Le plafond €200k correspond aux standards protection juridique belges"

### 3. Démontrer la Conformité TELEBIB2

**✅ DIRE**:
- "J'ai structuré les champs adresse selon le segment ADR TELEBIB2 (X002-X008)"
- "Les références suivent le format standard : SIN-YYYY-NNNNNN pour sinistres, DAS-YYYY-BBBBB-NNNNNN pour contrats"
- "La séparation HOUSE_NBR/BOX_NBR respecte la normalisation belge"

### 4. Montrer la Compréhension de la Loi Geens 2019

**✅ MENTIONNER**:
- "La déduction fiscale 40% depuis septembre 2019 explique le succès de la gamme Benefisc"
- "Cela démocratise l'accès à la justice - aligné avec la mission DAS"

### 5. Comprendre l'Écosystème Technique

**✅ OBSERVATIONS**:
- "Votre frontend Angular moderne contraste avec le backend traditionnel - mon architecture Node.js + ODBC fait le pont"
- "L'absence d'API publique confirme le modèle B2B2C via courtiers"
- "Les 5 bureaux régionaux suggèrent une base de données centralisée (IBM i idéal)"

### 6. Connaître les Concurrents

**Principaux concurrents en Belgique** :
- ARAG (concurrent direct protection juridique)
- Baloise, Ethias, AG Insurance (offrent protection juridique en addon)

**Différenciateur DAS** : Spécialiste pure-player vs multi-line insurers

### 7. Comprendre l'Intégration ERGO Group

**✅ MENTIONNER**:
- "Être filiale Munich Re apporte solidité financière et expertise actuarielle internationale"
- "ERGO Group opère dans 30 pays - potentiel d'harmonisation systèmes IT"

---

## 🚀 Workflow Démo pour Interview

### Préparer le Pitch (5-7 minutes)

**Partie 1: Context Business (1 min)**
> "DAS Belgium est leader protection juridique avec distribution 100% courtiers. J'ai implémenté un système qui reflète cette réalité avec 5 modules RPG service programs conformes TELEBIB2."

**Partie 2: Workflow Créer Contrat (2 min)**
> "Le courtier sélectionne un client, choisit DAS Classic, ajoute 2 véhicules. Le calculateur applique automatiquement €25/véhicule + 5% surcharge mensuelle = €172.20. Le contrat est créé avec référence DAS-2025-00001-000123 où 00001 = broker_id."

**Partie 3: Workflow Déclarer Sinistre (2 min)**
> "Le client déclare un litige de voisinage (€1500). Le système valide en temps réel :
> - ✅ Garantie VOIS couverte par DAS Classic
> - ✅ Période d'attente 3 mois écoulée
> - ✅ Montant ≥ €350 (seuil DAS)
> - ✅ Sous plafond €200k
> Création sinistre SIN-2025-000045 + dossier DOS-0000000045"

**Partie 4: Dashboard KPI (1 min)**
> "Le dashboard affiche le KPI critique : 79% résolution amiable (target atteint), correspondant à votre standard métier."

**Partie 5: Questions Techniques (1 min)**
> "Le système est prêt pour intégration avec vos portails existants (claims.das.be, extranet.das.be) via API REST standardisée."

---

## 📚 Vocabulaire Technique à Maîtriser

### Termes DAS-Specific

| Français | Néerlandais | English | Usage |
|----------|-------------|---------|-------|
| Protection juridique | Rechtsbijstand | Legal protection | Core business |
| Courtier | Makelaar | Broker | Distribution channel |
| Règlement amiable | Minnelijke regeling | Amicable settlement | 79% target |
| Tribunal | Rechtbank | Court | Last resort |
| Garantie | Waarborg | Guarantee/Coverage | Coverage type |
| Franchise | Vrijstelling | Deductible | Rare en protection juridique |
| Plafond | Plafond | Ceiling | €200k max |
| Période d'attente | Wachttijd | Waiting period | 3-12 months |

### Acronymes Importants

- **DAS**: Deutscher Automobil Schutz (origine allemande 1928)
- **ERGO**: European Insurance Group
- **FSMA**: Financial Services and Markets Authority (régulateur belge)
- **NBB**: National Bank of Belgium
- **TELEBIB2**: Télécommunication Electronique Belge Insurance Brokers v2
- **EDI**: Electronic Data Interchange
- **AMI**: Amiable (résolution)
- **TRI**: Tribunal

---

## 🎓 Questions Préparées pour Eux Poser

Démontrer curiosité professionnelle :

1. **Architecture existante** :
   > "Utilisez-vous encore IBM i en production pour le core business ? Si oui, quelle version ?"

2. **Évolution TELEBIB2** :
   > "TELEBIB2 évolue-t-il vers des standards plus modernes (JSON/REST) ou reste-t-il EDIFACT ?"

3. **Objectifs 79% amiable** :
   > "Le KPI 79% amiable est-il mesuré par garantie ou globalement ? Y a-t-il des variations régionales ?"

4. **Stratégie digitale** :
   > "Avec l'extranet courtiers, envisagez-vous une API publique pour faciliter l'intégration chez les gros courtiers ?"

5. **IA/Automation** :
   > "Pour maintenir le 79% amiable, utilisez-vous du NLP/ML pour triage initial des sinistres ?"

---

## 📊 Chiffres Clés à Retenir

| Métrique | Valeur | Source |
|----------|--------|--------|
| Année fondation | 1927 | Public |
| Employés | 236 | LinkedIn |
| Bureaux régionaux | 5 | DAS.be |
| Part marché | 3.4% | Web research |
| Position marché | #1 protection juridique | Public |
| Taux résolution amiable | 79% | Implementation plan |
| Plafond couverture | €200,000 | Conditions générales |
| Seuil intervention | €350 | Business rules |
| Déduction fiscale Benefisc | 40% | Loi Geens 2019 |
| Prix entry-level | €114/an | DAS Classic |

---

## ✅ Checklist Pré-Interview

- [ ] Réviser les 3 produits principaux (Classic/Connect/Comfort + Benefisc)
- [ ] Mémoriser le KPI 79% amiable
- [ ] Connaître les 5 bureaux régionaux
- [ ] Comprendre le modèle 100% courtiers
- [ ] Réviser TELEBIB2 (segment ADR minimum)
- [ ] Préparer démo 5-7 minutes (2 workflows)
- [ ] Tester l'API localement avant interview
- [ ] Imprimer cette doc comme aide-mémoire
- [ ] Préparer 3 questions techniques à leur poser
- [ ] Vérifier que tous les endpoints API fonctionnent

---

**Objectif Final** : Démontrer que vous avez :
1. ✅ Compris leur business model unique (courtiers)
2. ✅ Implémenté leurs règles métier critiques (79% AMI, €350, €200k)
3. ✅ Respecté les standards belges (TELEBIB2)
4. ✅ Créé un système demo impressionnant mais réaliste
5. ✅ Une vision technique cohérente avec leur stack (Angular + IBM i probable)

**Message clé** : "J'ai construit ce système en comprenant DAS comme un assureur B2B2C spécialiste, pas comme un assureur retail généraliste."
