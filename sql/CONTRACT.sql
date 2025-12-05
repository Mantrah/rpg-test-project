-- ============================================================
-- CONTRACT - Insurance Policies
-- DAS.be Backend - Legal Protection Insurance
-- ============================================================
-- Contracts link Broker, Customer, and Product.
-- Key business rules:
-- - 1 year duration, auto-renewal
-- - Cancellation: 2 months before expiration
-- - Premium varies by vehicle count
-- TELEBIB2 alignment: BrokerPolicyReference
-- ============================================================

CREATE OR REPLACE TABLE CONTRACT (
    -- Primary Key
    CONT_ID             DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Policy Reference
    CONT_REFERENCE      CHAR(20)        NOT NULL,       -- BrokerPolicyReference (TELEBIB2)

    -- Foreign Keys
    BROKER_ID           DECIMAL(10, 0)  NOT NULL,       -- AgencyCode
    CUST_ID             DECIMAL(10, 0)  NOT NULL,
    PRODUCT_ID          DECIMAL(10, 0)  NOT NULL,

    -- Coverage Period
    START_DATE          DATE            NOT NULL,
    END_DATE            DATE            NOT NULL,

    -- Pricing
    PREMIUM_AMT         DECIMAL(9, 2)   NOT NULL,       -- Annual premium
    PAY_FREQUENCY       CHAR(1)         DEFAULT 'A',    -- M/Q/A

    -- Options
    VEHICLES_COUNT      DECIMAL(2, 0)   DEFAULT 0,      -- Affects premium
    AUTO_RENEW          CHAR(1)         DEFAULT 'Y',    -- Y/N

    -- Status & Audit
    STATUS              CHAR(3)         DEFAULT 'PEN',  -- PEN/ACT/EXP/CAN/REN
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT CONTRACT_PK PRIMARY KEY (CONT_ID),
    CONSTRAINT CONTRACT_REF_UK UNIQUE (CONT_REFERENCE),
    CONSTRAINT CONTRACT_BROKER_FK FOREIGN KEY (BROKER_ID) REFERENCES BROKER (BROKER_ID),
    CONSTRAINT CONTRACT_CUST_FK FOREIGN KEY (CUST_ID) REFERENCES CUSTOMER (CUST_ID),
    CONSTRAINT CONTRACT_PROD_FK FOREIGN KEY (PRODUCT_ID) REFERENCES PRODUCT (PRODUCT_ID),
    CONSTRAINT CONTRACT_FREQ_CK CHECK (PAY_FREQUENCY IN ('M', 'Q', 'A')),
    CONSTRAINT CONTRACT_RENEW_CK CHECK (AUTO_RENEW IN ('Y', 'N')),
    CONSTRAINT CONTRACT_STATUS_CK CHECK (STATUS IN ('PEN', 'ACT', 'EXP', 'CAN', 'REN')),
    CONSTRAINT CONTRACT_DATES_CK CHECK (END_DATE > START_DATE)
);

-- Indexes
CREATE INDEX CONTRACT_BROKER_IX ON CONTRACT (BROKER_ID);
CREATE INDEX CONTRACT_CUST_IX ON CONTRACT (CUST_ID);
CREATE INDEX CONTRACT_PROD_IX ON CONTRACT (PRODUCT_ID);
CREATE INDEX CONTRACT_STATUS_IX ON CONTRACT (STATUS);
CREATE INDEX CONTRACT_DATES_IX ON CONTRACT (START_DATE, END_DATE);

-- Labels
LABEL ON TABLE CONTRACT IS 'Insurance Policies - DAS.be';
LABEL ON COLUMN CONTRACT (
    CONT_ID         IS 'Contract ID',
    CONT_REFERENCE  IS 'Policy Reference (BrokerPolicyReference)',
    BROKER_ID       IS 'Broker ID (FK)',
    CUST_ID         IS 'Customer ID (FK)',
    PRODUCT_ID      IS 'Product ID (FK)',
    START_DATE      IS 'Coverage Start Date',
    END_DATE        IS 'Coverage End Date',
    PREMIUM_AMT     IS 'Annual Premium',
    PAY_FREQUENCY   IS 'Payment Frequency (M/Q/A)',
    VEHICLES_COUNT  IS 'Number of Vehicles',
    AUTO_RENEW      IS 'Auto-Renewal (Y/N)',
    STATUS          IS 'Status (PEN/ACT/EXP/CAN/REN)',
    CREATED_AT      IS 'Created Timestamp',
    UPDATED_AT      IS 'Updated Timestamp'
);
