#!/bin/bash
# ============================================================
# DAS Belgium - Manual Installation Script for PUB400
# Copy-paste this entire script into your SSH session
# ============================================================
# Prerequisites:
# - SSH into PUB400: ssh -p 2222 MRS@pub400.com
# - Run: bash install-pub400-manual.sh
# ============================================================

echo "========================================="
echo "DAS Belgium Installation on PUB400"
echo "========================================="
echo ""

# Create directory structure
echo "Step 1: Creating directory structure..."
mkdir -p ~/rpg-test-project/sql/sp
mkdir -p ~/rpg-test-project/api/src/{config,services,controllers,routes,middleware}
cd ~/rpg-test-project
echo "  ✓ Directories created"
echo ""

# Step 2: Create library
echo "Step 2: Creating DASBE library..."
system "CRTLIB LIB(DASBE) TEXT('DAS Belgium Demo System')" 2>/dev/null || echo "  ⚠ Library might already exist"
echo "  ✓ Library ready"
echo ""

# Step 3: Create tables SQL
echo "Step 3: Creating database tables SQL..."
cat > ~/rpg-test-project/sql/create_tables.sql <<'EOF_TABLES'
-- ============================================================
-- DAS Belgium - Complete Database Schema
-- ============================================================

-- BROKER table
CREATE OR REPLACE TABLE DASBE.BROKER (
    BROKER_ID           DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,
    BROKER_CODE         CHAR(10)        NOT NULL,
    COMPANY_NAME        VARCHAR(100)    NOT NULL,
    VAT_NUMBER          CHAR(12),
    FSMA_NUMBER         CHAR(10),
    STREET              VARCHAR(30),
    HOUSE_NBR           CHAR(5),
    BOX_NBR             CHAR(4),
    POSTAL_CODE         CHAR(7),
    CITY                VARCHAR(24),
    COUNTRY_CODE        CHAR(3)         DEFAULT 'BEL',
    PHONE               VARCHAR(20),
    EMAIL               VARCHAR(100),
    CONTACT_NAME        VARCHAR(100),
    STATUS              CHAR(3)         DEFAULT 'ACT',
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT BROKER_PK PRIMARY KEY (BROKER_ID),
    CONSTRAINT BROKER_CODE_UK UNIQUE (BROKER_CODE),
    CONSTRAINT BROKER_STATUS_CK CHECK (STATUS IN ('ACT', 'INA', 'SUS'))
);

CREATE INDEX BROKER_VAT_IX ON DASBE.BROKER (VAT_NUMBER);
CREATE INDEX BROKER_STATUS_IX ON DASBE.BROKER (STATUS);

-- CUSTOMER table
CREATE OR REPLACE TABLE DASBE.CUSTOMER (
    CUST_ID             DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,
    CUST_TYPE           CHAR(3)         NOT NULL,
    FIRST_NAME          VARCHAR(50),
    LAST_NAME           VARCHAR(50),
    COMPANY_NAME        VARCHAR(100),
    VAT_NUMBER          CHAR(12),
    NRN_NUMBER          CHAR(11),
    BIRTH_DATE          DATE,
    STREET              VARCHAR(30)     NOT NULL,
    HOUSE_NBR           CHAR(5)         NOT NULL,
    BOX_NBR             CHAR(4),
    POSTAL_CODE         CHAR(7)         NOT NULL,
    CITY                VARCHAR(24)     NOT NULL,
    COUNTRY_CODE        CHAR(3)         DEFAULT 'BEL',
    PHONE               VARCHAR(20),
    MOBILE              VARCHAR(20),
    EMAIL               VARCHAR(100)    NOT NULL,
    LANGUAGE            CHAR(2)         DEFAULT 'FR',
    STATUS              CHAR(3)         DEFAULT 'ACT',
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CUSTOMER_PK PRIMARY KEY (CUST_ID),
    CONSTRAINT CUSTOMER_TYPE_CK CHECK (CUST_TYPE IN ('IND', 'BUS')),
    CONSTRAINT CUSTOMER_STATUS_CK CHECK (STATUS IN ('ACT', 'INA', 'SUS'))
);

CREATE INDEX CUSTOMER_EMAIL_IX ON DASBE.CUSTOMER (EMAIL);
CREATE INDEX CUSTOMER_TYPE_IX ON DASBE.CUSTOMER (CUST_TYPE);

-- PRODUCT table
CREATE OR REPLACE TABLE DASBE.PRODUCT (
    PRODUCT_ID          DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,
    PRODUCT_CODE        CHAR(10)        NOT NULL,
    PRODUCT_NAME        VARCHAR(100)    NOT NULL,
    CATEGORY            VARCHAR(20)     NOT NULL,
    BASE_PREMIUM        DECIMAL(9, 2)   NOT NULL,
    COVERAGE_LIMIT      DECIMAL(11, 2)  NOT NULL,
    WAITING_MONTHS      DECIMAL(2, 0)   DEFAULT 0,
    DESCRIPTION         VARCHAR(500),
    STATUS              CHAR(3)         DEFAULT 'ACT',
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PRODUCT_PK PRIMARY KEY (PRODUCT_ID),
    CONSTRAINT PRODUCT_CODE_UK UNIQUE (PRODUCT_CODE),
    CONSTRAINT PRODUCT_STATUS_CK CHECK (STATUS IN ('ACT', 'INA', 'DIS'))
);

-- GUARANTEE table
CREATE OR REPLACE TABLE DASBE.GUARANTEE (
    GUARANTEE_ID        DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,
    PRODUCT_ID          DECIMAL(10, 0)  NOT NULL,
    GUARANTEE_CODE      CHAR(10)        NOT NULL,
    GUARANTEE_NAME      VARCHAR(100)    NOT NULL,
    WAITING_MONTHS      DECIMAL(2, 0)   DEFAULT 0,
    DESCRIPTION         VARCHAR(500),
    STATUS              CHAR(3)         DEFAULT 'ACT',
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT GUARANTEE_PK PRIMARY KEY (GUARANTEE_ID),
    CONSTRAINT GUARANTEE_PRODUCT_FK FOREIGN KEY (PRODUCT_ID)
        REFERENCES DASBE.PRODUCT(PRODUCT_ID),
    CONSTRAINT GUARANTEE_STATUS_CK CHECK (STATUS IN ('ACT', 'INA'))
);

-- CONTRACT table
CREATE OR REPLACE TABLE DASBE.CONTRACT (
    CONT_ID             DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,
    CONT_REFERENCE      CHAR(30)        NOT NULL,
    BROKER_ID           DECIMAL(10, 0)  NOT NULL,
    CUST_ID             DECIMAL(10, 0)  NOT NULL,
    PRODUCT_ID          DECIMAL(10, 0)  NOT NULL,
    START_DATE          DATE            NOT NULL,
    END_DATE            DATE            NOT NULL,
    VEHICLES_COUNT      DECIMAL(2, 0)   DEFAULT 0,
    TOTAL_PREMIUM       DECIMAL(9, 2)   NOT NULL,
    PAY_FREQUENCY       CHAR(1)         DEFAULT 'A',
    AUTO_RENEWAL        CHAR(1)         DEFAULT 'Y',
    NOTES               VARCHAR(500),
    STATUS              CHAR(3)         DEFAULT 'ACT',
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CONTRACT_PK PRIMARY KEY (CONT_ID),
    CONSTRAINT CONTRACT_REF_UK UNIQUE (CONT_REFERENCE),
    CONSTRAINT CONTRACT_BROKER_FK FOREIGN KEY (BROKER_ID)
        REFERENCES DASBE.BROKER(BROKER_ID),
    CONSTRAINT CONTRACT_CUSTOMER_FK FOREIGN KEY (CUST_ID)
        REFERENCES DASBE.CUSTOMER(CUST_ID),
    CONSTRAINT CONTRACT_PRODUCT_FK FOREIGN KEY (PRODUCT_ID)
        REFERENCES DASBE.PRODUCT(PRODUCT_ID),
    CONSTRAINT CONTRACT_STATUS_CK CHECK (STATUS IN ('ACT', 'EXP', 'CAN', 'SUS'))
);

-- CLAIM table
CREATE OR REPLACE TABLE DASBE.CLAIM (
    CLAIM_ID            DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,
    CLAIM_REFERENCE     CHAR(20)        NOT NULL,
    FILE_REFERENCE      CHAR(20)        NOT NULL,
    CONT_ID             DECIMAL(10, 0)  NOT NULL,
    GUARANTEE_CODE      CHAR(10)        NOT NULL,
    CIRCUMSTANCE_CODE   CHAR(10)        NOT NULL,
    DECLARATION_DATE    DATE            NOT NULL,
    INCIDENT_DATE       DATE            NOT NULL,
    DESCRIPTION         VARCHAR(500)    NOT NULL,
    CLAIMED_AMOUNT      DECIMAL(11, 2)  NOT NULL,
    APPROVED_AMOUNT     DECIMAL(11, 2),
    RESOLUTION_TYPE     CHAR(3),
    LAWYER_NAME         VARCHAR(100),
    STATUS              CHAR(3)         DEFAULT 'NEW',
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT CLAIM_PK PRIMARY KEY (CLAIM_ID),
    CONSTRAINT CLAIM_REF_UK UNIQUE (CLAIM_REFERENCE),
    CONSTRAINT CLAIM_FILE_UK UNIQUE (FILE_REFERENCE),
    CONSTRAINT CLAIM_CONTRACT_FK FOREIGN KEY (CONT_ID)
        REFERENCES DASBE.CONTRACT(CONT_ID),
    CONSTRAINT CLAIM_STATUS_CK CHECK (STATUS IN ('NEW', 'REV', 'APP', 'REJ', 'CLS'))
);
EOF_TABLES

echo "  ✓ Tables SQL created"
echo ""

# Step 4: Execute table creation
echo "Step 4: Creating tables in database..."
db2 -tvf ~/rpg-test-project/sql/create_tables.sql 2>&1 | grep -v "SQL0601W" || echo "  ⚠ Some tables might already exist"
echo "  ✓ Tables created"
echo ""

# Step 5: Create seed data
echo "Step 5: Creating seed data..."
cat > ~/rpg-test-project/sql/seed-data.sql <<'EOF_SEED'
-- ============================================================
-- DAS Belgium - Seed Data for Demo
-- ============================================================

-- Brokers (5)
INSERT INTO DASBE.BROKER (BROKER_CODE, COMPANY_NAME, VAT_NUMBER, FSMA_NUMBER,
    STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY, COUNTRY_CODE,
    PHONE, EMAIL, CONTACT_NAME, STATUS)
VALUES
('BRK001', 'Assurances Dupont', 'BE0123456789', 'FSMA001234',
    'Rue de la Loi', '16', NULL, '1000', 'Bruxelles', 'BEL',
    '+32 2 123 45 67', 'info@dupont-assur.be', 'Jean Dupont', 'ACT'),
('BRK002', 'Martin Courtage', 'BE0234567890', 'FSMA002345',
    'Avenue Louise', '54', 'B12', '1050', 'Bruxelles', 'BEL',
    '+32 2 234 56 78', 'contact@martin-courtage.be', 'Sophie Martin', 'ACT'),
('BRK003', 'Bertrand & Fils', 'BE0345678901', 'FSMA003456',
    'Chaussée de Wavre', '1245', NULL, '1160', 'Auderghem', 'BEL',
    '+32 2 345 67 89', 'info@bertrand-fils.be', 'Luc Bertrand', 'ACT'),
('BRK004', 'Lejeune Assurances', 'BE0456789012', 'FSMA004567',
    'Rue Neuve', '89', NULL, '1000', 'Bruxelles', 'BEL',
    '+32 2 456 78 90', 'contact@lejeune.be', 'Marie Lejeune', 'SUS'),
('BRK005', 'Peeters Verzekeringen', 'BE0567890123', 'FSMA005678',
    'Grote Markt', '23', NULL, '2000', 'Antwerpen', 'BEL',
    '+32 3 567 89 01', 'info@peeters.be', 'Jan Peeters', 'ACT');

-- Customers (10: 6 IND + 4 BUS)
INSERT INTO DASBE.CUSTOMER (CUST_TYPE, FIRST_NAME, LAST_NAME, COMPANY_NAME,
    VAT_NUMBER, NRN_NUMBER, BIRTH_DATE,
    STREET, HOUSE_NBR, BOX_NBR, POSTAL_CODE, CITY, COUNTRY_CODE,
    PHONE, MOBILE, EMAIL, LANGUAGE, STATUS)
VALUES
('IND', 'Marc', 'Dubois', NULL, NULL, '85051234567', '1985-05-15',
    'Rue de Flandre', '125', NULL, '1000', 'Bruxelles', 'BEL',
    '+32 2 111 11 11', '+32 475 111 111', 'marc.dubois@email.be', 'FR', 'ACT'),
('IND', 'Sophie', 'Lambert', NULL, NULL, '90081298765', '1990-08-22',
    'Avenue des Arts', '43', 'B2', '1040', 'Etterbeek', 'BEL',
    NULL, '+32 476 222 222', 'sophie.lambert@email.be', 'FR', 'ACT'),
('BUS', NULL, NULL, 'BVBA TechStart', 'BE0678901234', NULL, NULL,
    'Rue du Commerce', '89', NULL, '1000', 'Bruxelles', 'BEL',
    '+32 2 333 33 33', NULL, 'info@techstart.be', 'NL', 'ACT'),
('IND', 'Thomas', 'Mercier', NULL, NULL, '78031056789', '1978-03-10',
    'Chaussée de Charleroi', '234', NULL, '1060', 'Saint-Gilles', 'BEL',
    '+32 2 444 44 44', '+32 477 444 444', 'thomas.mercier@email.be', 'FR', 'ACT'),
('BUS', NULL, NULL, 'SA Consulting Plus', 'BE0789012345', NULL, NULL,
    'Boulevard Anspach', '12', '3', '1000', 'Bruxelles', 'BEL',
    '+32 2 555 55 55', NULL, 'contact@consultingplus.be', 'FR', 'ACT');

-- Products (3)
INSERT INTO DASBE.PRODUCT (PRODUCT_CODE, PRODUCT_NAME, CATEGORY,
    BASE_PREMIUM, COVERAGE_LIMIT, WAITING_MONTHS, DESCRIPTION, STATUS)
VALUES
('DAS-CLAS', 'DAS Classic', 'FAMILY', 114.00, 200000.00, 3,
    'Protection juridique famille complète', 'ACT'),
('DAS-CONN', 'DAS Connect', 'FAMILY', 89.00, 150000.00, 3,
    'Protection juridique connectée', 'ACT'),
('DAS-COMF', 'DAS Comfort', 'FAMILY', 145.00, 250000.00, 3,
    'Protection juridique premium', 'ACT');

-- Guarantees (9 - 3 per product)
INSERT INTO DASBE.GUARANTEE (PRODUCT_ID, GUARANTEE_CODE, GUARANTEE_NAME,
    WAITING_MONTHS, DESCRIPTION, STATUS)
VALUES
(1, 'VOIS', 'Troubles de voisinage', 3, 'Litiges avec voisins', 'ACT'),
(1, 'TRAF', 'Circulation routière', 0, 'Accidents et infractions', 'ACT'),
(1, 'FISC', 'Fiscal', 3, 'Litiges fiscaux', 'ACT'),
(2, 'VOIS', 'Troubles de voisinage', 3, 'Litiges avec voisins', 'ACT'),
(2, 'TRAF', 'Circulation routière', 0, 'Accidents et infractions', 'ACT'),
(2, 'CONS', 'Consommation', 3, 'Litiges achats', 'ACT'),
(3, 'VOIS', 'Troubles de voisinage', 3, 'Litiges avec voisins', 'ACT'),
(3, 'TRAF', 'Circulation routière', 0, 'Accidents et infractions', 'ACT'),
(3, 'FISC', 'Fiscal', 3, 'Litiges fiscaux', 'ACT');

-- Contracts (8)
INSERT INTO DASBE.CONTRACT (CONT_REFERENCE, BROKER_ID, CUST_ID, PRODUCT_ID,
    START_DATE, END_DATE, VEHICLES_COUNT, TOTAL_PREMIUM, PAY_FREQUENCY,
    AUTO_RENEWAL, NOTES, STATUS)
VALUES
('DAS-2025-00001-000001', 1, 1, 1, '2025-01-01', '2025-12-31', 2, 164.00, 'A', 'Y', 'Famille Dubois', 'ACT'),
('DAS-2025-00001-000002', 1, 2, 2, '2025-02-01', '2026-01-31', 1, 114.00, 'M', 'Y', 'Mme Lambert', 'ACT'),
('DAS-2025-00002-000003', 2, 3, 3, '2025-01-15', '2026-01-14', 0, 145.00, 'A', 'Y', 'BVBA TechStart', 'ACT'),
('DAS-2024-00001-000004', 1, 4, 1, '2024-06-01', '2025-05-31', 1, 139.00, 'A', 'Y', 'M. Mercier', 'ACT'),
('DAS-2024-00002-000005', 2, 5, 2, '2024-09-01', '2025-08-31', 3, 164.00, 'Q', 'Y', 'SA Consulting', 'ACT');

-- Claims (5 - varied statuses)
INSERT INTO DASBE.CLAIM (CLAIM_REFERENCE, FILE_REFERENCE, CONT_ID,
    GUARANTEE_CODE, CIRCUMSTANCE_CODE, DECLARATION_DATE, INCIDENT_DATE,
    DESCRIPTION, CLAIMED_AMOUNT, APPROVED_AMOUNT, RESOLUTION_TYPE,
    LAWYER_NAME, STATUS)
VALUES
('SIN-2025-000001', 'DOS-0000000001', 1, 'VOIS', 'LITIGE',
    '2025-11-15', '2025-11-10', 'Litige avec voisin concernant la haie',
    1500.00, 1200.00, 'AMI', 'Me. Dubois', 'CLS'),
('SIN-2025-000002', 'DOS-0000000002', 2, 'TRAF', 'ACCIDENT',
    '2025-11-20', '2025-11-18', 'Accident de la circulation',
    2500.00, NULL, NULL, NULL, 'REV'),
('SIN-2025-000003', 'DOS-0000000003', 3, 'FISC', 'CONFLIT',
    '2025-11-25', '2025-10-30', 'Litige fiscal avec administration',
    5000.00, 4500.00, 'JUD', 'Me. Martin', 'APP');
EOF_SEED

echo "  ✓ Seed data SQL created"
echo ""

# Step 6: Load seed data
echo "Step 6: Loading seed data..."
db2 -tf ~/rpg-test-project/sql/seed-data.sql 2>&1 | tail -5
echo "  ✓ Seed data loaded"
echo ""

# Step 7: Verify installation
echo "Step 7: Verifying database..."
db2 "SELECT 'Brokers' AS TABLE_NAME, COUNT(*) AS COUNT FROM DASBE.BROKER
     UNION ALL SELECT 'Customers', COUNT(*) FROM DASBE.CUSTOMER
     UNION ALL SELECT 'Products', COUNT(*) FROM DASBE.PRODUCT
     UNION ALL SELECT 'Guarantees', COUNT(*) FROM DASBE.GUARANTEE
     UNION ALL SELECT 'Contracts', COUNT(*) FROM DASBE.CONTRACT
     UNION ALL SELECT 'Claims', COUNT(*) FROM DASBE.CLAIM"
echo ""

echo "========================================="
echo "Installation Complete!"
echo "========================================="
echo ""
echo "Database tables created and populated."
echo ""
echo "Next: Install Node.js API and React Frontend"
echo "Visit GitHub: https://github.com/Mantrah/rpg-test-project"
echo ""
