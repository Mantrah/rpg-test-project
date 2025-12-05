-- ============================================================
-- DAS Belgium Demo Seed Data
-- IBM i V7R5 / DB2 for i
-- ============================================================

-- Clean existing data (optional - comment out if you want to keep data)
-- DELETE FROM CLAIM;
-- DELETE FROM CONTRACT;
-- DELETE FROM GUARANTEE;
-- DELETE FROM PRODUCT;
-- DELETE FROM CUSTOMER;
-- DELETE FROM BROKER;

-- ============================================================
-- 1. BROKERS (5 courtiers)
-- ============================================================

INSERT INTO BROKER (
  BROKER_CODE, COMPANY_NAME, VAT_NUMBER, FSMA_NUMBER,
  STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY, COUNTRY_CODE,
  PHONE, EMAIL, CONTACT_NAME, STATUS
) VALUES
-- Broker 1
('BRK00001', 'Assurances Dupont SA', 'BE0123456789', 'FSMA001234',
 'Rue de la Loi', '42', NULL, '1000', 'Bruxelles', 'BE',
 '+32 2 123 45 67', 'contact@dupont.be', 'Pierre Dupont', 'ACT'),

-- Broker 2
('BRK00002', 'Martin & Associés', 'BE0234567890', 'FSMA002345',
 'Avenue Louise', '125', 'B', '1050', 'Ixelles', 'BE',
 '+32 2 234 56 78', 'info@martin.be', 'Sophie Martin', 'ACT'),

-- Broker 3
('BRK00003', 'Verzekeringen Janssens NV', 'BE0345678901', 'FSMA003456',
 'Meir', '88', NULL, '2000', 'Antwerpen', 'BE',
 '+32 3 345 67 89', 'contact@janssens.be', 'Jan Janssens', 'ACT'),

-- Broker 4
('BRK00004', 'Lambert Insurance Group', 'BE0456789012', 'FSMA004567',
 'Rue des Guillemins', '15', NULL, '4000', 'Liège', 'BE',
 '+32 4 456 78 90', 'info@lambert.be', 'Marc Lambert', 'ACT'),

-- Broker 5
('BRK00005', 'Courtage Leroy SPRL', 'BE0567890123', 'FSMA005678',
 'Chaussée de Waterloo', '250', 'A3', '6000', 'Charleroi', 'BE',
 '+32 71 567 89 01', 'contact@leroy.be', 'Christine Leroy', 'SUS');

-- ============================================================
-- 2. CUSTOMERS (10 clients: 6 IND + 4 BUS)
-- ============================================================

-- Individual Customers (6)
INSERT INTO CUSTOMER (
  CUST_TYPE, FIRST_NAME, LAST_NAME, VAT_NUMBER, NRN_NUMBER, BIRTH_DATE,
  STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY, COUNTRY_CODE,
  PHONE, MOBILE, EMAIL, LANGUAGE, STATUS
) VALUES
-- Customer 1
('IND', 'Jean', 'Dubois', NULL, '85031212345', '1985-03-12',
 'Rue du Commerce', '23', NULL, '1000', 'Bruxelles', 'BE',
 '+32 2 111 22 33', '+32 475 11 22 33', 'jean.dubois@email.be', 'FR', 'ACT'),

-- Customer 2
('IND', 'Marie', 'Vandenbergh', NULL, '90071523456', '1990-07-15',
 'Laan van Vlaanderen', '45', 'B12', '1000', 'Brussel', 'BE',
 NULL, '+32 476 22 33 44', 'marie.v@email.be', 'NL', 'ACT'),

-- Customer 3
('IND', 'Ahmed', 'Ben Ali', NULL, '88091834567', '1988-09-18',
 'Avenue des Arts', '78', NULL, '1040', 'Etterbeek', 'BE',
 '+32 2 222 33 44', '+32 477 33 44 55', 'ahmed.benali@email.be', 'FR', 'ACT'),

-- Customer 4
('IND', 'Sophie', 'Lemaire', NULL, '92041045678', '1992-04-10',
 'Rue de la Paix', '12', NULL, '5000', 'Namur', 'BE',
 '+32 81 333 44 55', '+32 478 44 55 66', 'sophie.lemaire@email.be', 'FR', 'ACT'),

-- Customer 5
('IND', 'Pieter', 'De Vries', NULL, '87122156789', '1987-12-21',
 'Grote Markt', '5', NULL, '9000', 'Gent', 'BE',
 '+32 9 444 55 66', '+32 479 55 66 77', 'pieter.devries@email.be', 'NL', 'ACT'),

-- Customer 6
('IND', 'Laura', 'Rossi', NULL, '95062367890', '1995-06-23',
 'Rue Saint-Georges', '89', 'A', '7000', 'Mons', 'BE',
 NULL, '+32 470 66 77 88', 'laura.rossi@email.be', 'FR', 'ACT');

-- Business Customers (4)
INSERT INTO CUSTOMER (
  CUST_TYPE, FIRST_NAME, LAST_NAME, COMPANY_NAME, VAT_NUMBER, NRN_NUMBER, BIRTH_DATE,
  STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY, COUNTRY_CODE,
  PHONE, MOBILE, EMAIL, LANGUAGE, STATUS
) VALUES
-- Customer 7
('BUS', NULL, NULL, 'TechStart SPRL', 'BE0678901234', NULL, NULL,
 'Rue de l Innovation', '100', 'B5', '1070', 'Anderlecht', 'BE',
 '+32 2 555 66 77', NULL, 'contact@techstart.be', 'FR', 'ACT'),

-- Customer 8
('BUS', NULL, NULL, 'Bouwbedrijf Vandamme NV', 'BE0789012345', NULL, NULL,
 'Industrielaan', '250', NULL, '8500', 'Kortrijk', 'BE',
 '+32 56 666 77 88', NULL, 'info@vandamme.be', 'NL', 'ACT'),

-- Customer 9
('BUS', NULL, NULL, 'Restaurant Le Gourmet SA', 'BE0890123456', NULL, NULL,
 'Place du Grand Sablon', '18', NULL, '1000', 'Bruxelles', 'BE',
 '+32 2 666 77 88', NULL, 'reservation@legourmet.be', 'FR', 'ACT'),

-- Customer 10
('BUS', NULL, NULL, 'Pharmacie Centrale SPRL', 'BE0901234567', NULL, NULL,
 'Grand-Place', '32', NULL, '6000', 'Charleroi', 'BE',
 '+32 71 777 88 99', NULL, 'info@pharmacentrale.be', 'FR', 'ACT');

-- ============================================================
-- 3. PRODUCTS (3 produits DAS)
-- ============================================================

INSERT INTO PRODUCT (
  PRODUCT_CODE, PRODUCT_NAME, CATEGORY,
  BASE_PREMIUM, COVERAGE_LIMIT, WAITING_MONTHS,
  DESCRIPTION, STATUS
) VALUES
-- Product 1: DAS Classic
('DASCLAS', 'DAS Classic', 'INDIVIDUAL',
 114.00, 200000.00, 3,
 'Protection juridique de base pour particuliers', 'ACT'),

-- Product 2: DAS Connect
('DASCONN', 'DAS Connect', 'INDIVIDUAL',
 276.00, 200000.00, 3,
 'Protection juridique étendue avec couverture Internet et e-commerce', 'ACT'),

-- Product 3: DAS Comfort
('DASCOMF', 'DAS Comfort', 'INDIVIDUAL',
 396.00, 200000.00, 6,
 'Protection juridique complète incluant droit familial', 'ACT');

-- ============================================================
-- 4. GUARANTEES (Garanties par produit)
-- ============================================================

-- Guarantees for DAS Classic (4 garanties de base)
INSERT INTO GUARANTEE (
  PRODUCT_ID, GUARANTEE_CODE, GUARANTEE_NAME,
  WAITING_MONTHS, DESCRIPTION, STATUS
) VALUES
(1, 'VOIS', 'Troubles de voisinage', 3, 'Litiges avec voisins et copropriétaires', 'ACT'),
(1, 'PENAL', 'Défense pénale', 0, 'Défense en cas de poursuites pénales', 'ACT'),
(1, 'ASSUR', 'Litiges assurance', 3, 'Contestations avec compagnies assurance', 'ACT'),
(1, 'MEDIC', 'Erreurs médicales', 6, 'Litiges erreurs médicales et hospitalières', 'ACT');

-- Additional guarantees for DAS Connect (+ 2 garanties)
INSERT INTO GUARANTEE (
  PRODUCT_ID, GUARANTEE_CODE, GUARANTEE_NAME,
  WAITING_MONTHS, DESCRIPTION, STATUS
) VALUES
(2, 'VOIS', 'Troubles de voisinage', 3, 'Litiges avec voisins et copropriétaires', 'ACT'),
(2, 'PENAL', 'Défense pénale', 0, 'Défense en cas de poursuites pénales', 'ACT'),
(2, 'ASSUR', 'Litiges assurance', 3, 'Contestations avec compagnies assurance', 'ACT'),
(2, 'MEDIC', 'Erreurs médicales', 6, 'Litiges erreurs médicales et hospitalières', 'ACT'),
(2, 'INTER', 'Internet et e-commerce', 3, 'Litiges achats en ligne et réseaux sociaux', 'ACT'),
(2, 'CONSOM', 'Litiges consommation', 3, 'Conflits avec fournisseurs et commerçants', 'ACT');

-- All guarantees for DAS Comfort (+ 3 garanties supplémentaires)
INSERT INTO GUARANTEE (
  PRODUCT_ID, GUARANTEE_CODE, GUARANTEE_NAME,
  WAITING_MONTHS, DESCRIPTION, STATUS
) VALUES
(3, 'VOIS', 'Troubles de voisinage', 3, 'Litiges avec voisins et copropriétaires', 'ACT'),
(3, 'PENAL', 'Défense pénale', 0, 'Défense en cas de poursuites pénales', 'ACT'),
(3, 'ASSUR', 'Litiges assurance', 3, 'Contestations avec compagnies assurance', 'ACT'),
(3, 'MEDIC', 'Erreurs médicales', 6, 'Litiges erreurs médicales et hospitalières', 'ACT'),
(3, 'INTER', 'Internet et e-commerce', 3, 'Litiges achats en ligne et réseaux sociaux', 'ACT'),
(3, 'CONSOM', 'Litiges consommation', 3, 'Conflits avec fournisseurs et commerçants', 'ACT'),
(3, 'FAMIL', 'Droit familial', 12, 'Divorces, séparations, garde d enfants', 'ACT'),
(3, 'TRAV', 'Droit du travail', 6, 'Conflits avec employeurs', 'ACT'),
(3, 'FISCAL', 'Litiges fiscaux', 6, 'Contestations avec administration fiscale', 'ACT');

-- ============================================================
-- 5. CONTRACTS (8 contrats)
-- ============================================================

-- Contract 1: Jean Dubois - DAS Classic - Broker Dupont
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00001-000001', 1, 1, 1,
 '2025-01-01', '2026-01-01', 2,
 172.20, 'M', 'Y',
 'Demo contract - 2 vehicles, monthly payment', 'ACT');

-- Contract 2: Marie Vandenbergh - DAS Connect - Broker Dupont
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00001-000002', 1, 2, 2,
 '2024-06-15', '2025-06-15', 0,
 276.00, 'A', 'Y',
 'Demo contract - annual payment', 'ACT');

-- Contract 3: Ahmed Ben Ali - DAS Classic - Broker Martin
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00002-000003', 2, 3, 1,
 '2024-09-01', '2025-09-01', 1,
 144.15, 'Q', 'Y',
 'Demo contract - 1 vehicle, quarterly payment', 'ACT');

-- Contract 4: Sophie Lemaire - DAS Comfort - Broker Martin
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00002-000004', 2, 4, 3,
 '2024-03-10', '2025-03-10', 0,
 396.00, 'A', 'N',
 'Demo contract - no auto-renewal', 'ACT');

-- Contract 5: Pieter De Vries - DAS Classic - Broker Janssens
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00003-000005', 3, 5, 1,
 '2024-11-20', '2025-11-20', 3,
 194.25, 'M', 'Y',
 'Demo contract - 3 vehicles, monthly', 'ACT');

-- Contract 6: TechStart SPRL - DAS Connect - Broker Lambert
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00004-000006', 4, 7, 2,
 '2024-01-15', '2025-01-15', 5,
 401.00, 'A', 'Y',
 'Demo contract - business customer, 5 vehicles', 'ACT');

-- Contract 7: Restaurant Le Gourmet - DAS Comfort - Broker Lambert
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2025-00004-000007', 4, 9, 3,
 '2024-07-01', '2025-07-01', 0,
 396.00, 'A', 'Y',
 'Demo contract - restaurant business', 'ACT');

-- Contract 8: Laura Rossi - DAS Classic - Expired
INSERT INTO CONTRACT (
  CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
  START_DATE, END_DATE, VEHICLES_COUNT,
  TOTAL_PREMIUM, PAY_FREQUENCY, AUTO_RENEWAL,
  NOTES, STATUS
) VALUES
('DAS-2024-00001-000008', 1, 6, 1,
 '2023-12-01', '2024-12-01', 0,
 114.00, 'A', 'N',
 'Demo contract - expired', 'EXP');

-- ============================================================
-- 6. CLAIMS (5 sinistres avec statuts variés)
-- ============================================================

-- Claim 1: NEW - Litige voisinage Jean Dubois
INSERT INTO CLAIM (
  CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
  GUARANTEE_CODE, CIRCUMSTANCE_CODE,
  DECLARATION_DATE, INCIDENT_DATE,
  DESCRIPTION, CLAIMED_AMOUNT,
  APPROVED_AMOUNT, RESOLUTION_TYPE,
  LAWYER_NAME, STATUS
) VALUES
('SIN-2025-000001', 'DOS-0000000001', 1,
 'VOIS', 'LITIGE',
 '2025-11-15', '2025-10-28',
 'Litige avec voisin concernant une haie mitoyenne dépassant la limite de propriété',
 1500.00,
 NULL, NULL,
 NULL, 'NEW');

-- Claim 2: UNDER REVIEW - Défense pénale Marie
INSERT INTO CLAIM (
  CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
  GUARANTEE_CODE, CIRCUMSTANCE_CODE,
  DECLARATION_DATE, INCIDENT_DATE,
  DESCRIPTION, CLAIMED_AMOUNT,
  APPROVED_AMOUNT, RESOLUTION_TYPE,
  LAWYER_NAME, STATUS
) VALUES
('SIN-2025-000002', 'DOS-0000000002', 2,
 'PENAL', 'ACCIDENT',
 '2025-10-20', '2025-09-15',
 'Accusation injustifiée suite accident de la route - besoin défense pénale',
 2500.00,
 NULL, NULL,
 'Me. Dubois', 'REV');

-- Claim 3: APPROVED - Erreur médicale Sophie
INSERT INTO CLAIM (
  CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
  GUARANTEE_CODE, CIRCUMSTANCE_CODE,
  DECLARATION_DATE, INCIDENT_DATE,
  DESCRIPTION, CLAIMED_AMOUNT,
  APPROVED_AMOUNT, RESOLUTION_TYPE,
  LAWYER_NAME, STATUS
) VALUES
('SIN-2025-000003', 'DOS-0000000003', 4,
 'MEDIC', 'AUTRE',
 '2025-09-05', '2025-07-12',
 'Erreur de diagnostic ayant entraîné complications médicales',
 5000.00,
 4200.00, 'AMI',
 'Me. Lemaire', 'APP');

-- Claim 4: CLOSED - Litige assurance Ahmed (résolu amiable)
INSERT INTO CLAIM (
  CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
  GUARANTEE_CODE, CIRCUMSTANCE_CODE,
  DECLARATION_DATE, INCIDENT_DATE,
  DESCRIPTION, CLAIMED_AMOUNT,
  APPROVED_AMOUNT, RESOLUTION_TYPE,
  LAWYER_NAME, STATUS
) VALUES
('SIN-2024-000004', 'DOS-0000000004', 3,
 'ASSUR', 'LITIGE',
 '2024-11-10', '2024-10-05',
 'Refus prise en charge sinistre auto par assureur - contestation',
 1800.00,
 1800.00, 'AMI',
 'Me. Martin', 'CLS');

-- Claim 5: REJECTED - Montant trop faible (< €350)
INSERT INTO CLAIM (
  CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
  GUARANTEE_CODE, CIRCUMSTANCE_CODE,
  DECLARATION_DATE, INCIDENT_DATE,
  DESCRIPTION, CLAIMED_AMOUNT,
  APPROVED_AMOUNT, RESOLUTION_TYPE,
  LAWYER_NAME, STATUS
) VALUES
('SIN-2024-000005', 'DOS-0000000005', 1,
 'VOIS', 'LITIGE',
 '2024-08-20', '2024-08-01',
 'Petit litige voisinage - montant en dessous du seuil minimum',
 200.00,
 NULL, NULL,
 NULL, 'REJ');

-- ============================================================
-- Verification Queries
-- ============================================================

-- SELECT 'BROKERS', COUNT(*) FROM BROKER;
-- SELECT 'CUSTOMERS', COUNT(*) FROM CUSTOMER;
-- SELECT 'PRODUCTS', COUNT(*) FROM PRODUCT;
-- SELECT 'GUARANTEES', COUNT(*) FROM GUARANTEE;
-- SELECT 'CONTRACTS', COUNT(*) FROM CONTRACT;
-- SELECT 'CLAIMS', COUNT(*) FROM CLAIM;

COMMIT;
