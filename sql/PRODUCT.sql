-- ============================================================
-- PRODUCT - Insurance Product Catalog
-- DAS.be Backend - Legal Protection Insurance
-- ============================================================
-- Products match DAS.be offerings:
-- - Classic, Connect, Comfort (individuals)
-- - Vie Privée, Consommateur, Conflits (alternative naming)
-- - Benefisc variants (40% tax benefit)
-- - Sur Mesure, FiscAssist (businesses)
-- ============================================================

CREATE OR REPLACE TABLE PRODUCT (
    -- Primary Key
    PRODUCT_ID          DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Product Identification
    PRODUCT_CODE        CHAR(10)        NOT NULL,
    PRODUCT_NAME        VARCHAR(50)     NOT NULL,
    PRODUCT_TYPE        CHAR(3)         NOT NULL,       -- IND/FAM/BUS

    -- Pricing & Coverage
    BASE_PREMIUM        DECIMAL(9, 2)   NOT NULL,       -- Annual base premium
    COVERAGE_LIMIT      DECIMAL(11, 2)  DEFAULT 200000, -- Max €200,000
    MIN_THRESHOLD       DECIMAL(7, 2)   DEFAULT 350,    -- Min €350 intervention

    -- Features
    TAX_BENEFIT         CHAR(1)         DEFAULT 'N',    -- Y/N (Benefisc)
    WAITING_MONTHS      DECIMAL(2, 0)   DEFAULT 3,      -- Default waiting period

    -- Status & Audit
    STATUS              CHAR(3)         DEFAULT 'ACT',  -- ACT/INA
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT PRODUCT_PK PRIMARY KEY (PRODUCT_ID),
    CONSTRAINT PRODUCT_CODE_UK UNIQUE (PRODUCT_CODE),
    CONSTRAINT PRODUCT_TYPE_CK CHECK (PRODUCT_TYPE IN ('IND', 'FAM', 'BUS')),
    CONSTRAINT PRODUCT_TAX_CK CHECK (TAX_BENEFIT IN ('Y', 'N')),
    CONSTRAINT PRODUCT_STATUS_CK CHECK (STATUS IN ('ACT', 'INA'))
);

-- Indexes
CREATE INDEX PRODUCT_TYPE_IX ON PRODUCT (PRODUCT_TYPE);
CREATE INDEX PRODUCT_STATUS_IX ON PRODUCT (STATUS);

-- Labels
LABEL ON TABLE PRODUCT IS 'Product Catalog - DAS.be';
LABEL ON COLUMN PRODUCT (
    PRODUCT_ID      IS 'Product ID',
    PRODUCT_CODE    IS 'Product Code',
    PRODUCT_NAME    IS 'Product Name',
    PRODUCT_TYPE    IS 'Type (IND/FAM/BUS)',
    BASE_PREMIUM    IS 'Annual Base Premium',
    COVERAGE_LIMIT  IS 'Maximum Coverage',
    MIN_THRESHOLD   IS 'Minimum Intervention',
    TAX_BENEFIT     IS 'Benefisc Tax Benefit',
    WAITING_MONTHS  IS 'Default Waiting Period',
    STATUS          IS 'Status (ACT/INA)',
    CREATED_AT      IS 'Created Timestamp',
    UPDATED_AT      IS 'Updated Timestamp'
);

-- ============================================================
-- Initial Product Data (matching DAS.be offerings)
-- ============================================================

INSERT INTO PRODUCT (PRODUCT_CODE, PRODUCT_NAME, PRODUCT_TYPE, BASE_PREMIUM, TAX_BENEFIT, WAITING_MONTHS) VALUES
    ('CLASSIC',    'DAS Classic',             'IND', 114.00, 'N', 3),
    ('CONNECT',    'DAS Connect',             'IND', 276.00, 'N', 3),
    ('COMFORT',    'DAS Comfort',             'IND', 396.00, 'N', 3),
    ('VIE_PRIV',   'Vie Privée',              'IND', 139.00, 'N', 3),
    ('CONSOM',     'Consommateur',            'IND', 154.00, 'N', 3),
    ('CONSOM_BF',  'Consommateur Benefisc',   'IND', 245.00, 'Y', 3),
    ('CONFLIT_BF', 'Conflits Benefisc',       'IND', 539.00, 'Y', 3),
    ('SUR_MES',    'Sur Mesure',              'BUS', 500.00, 'N', 3),
    ('FISCASST',   'FiscAssist',              'BUS', 350.00, 'N', 3);
