-- ============================================================
-- BROKER - Insurance Brokers
-- DAS.be Backend - Legal Protection Insurance
-- ============================================================
-- Brokers are the exclusive sales channel for DAS.
-- All policies are sold through registered insurance brokers.
-- TELEBIB2 alignment: AgencyCode, Address segments (X002-X008)
-- ============================================================

CREATE OR REPLACE TABLE BROKER (
    -- Primary Key
    BROKER_ID           DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Broker Identification
    BROKER_CODE         CHAR(10)        NOT NULL,       -- AgencyCode (TELEBIB2)
    COMPANY_NAME        VARCHAR(100)    NOT NULL,
    VAT_NUMBER          CHAR(12),                       -- Belgian VAT: BE0123456789
    FSMA_NUMBER         CHAR(10),                       -- FSMA registration

    -- Address (TELEBIB2 ADR segment)
    STREET              VARCHAR(30),                    -- X002
    HOUSE_NBR           CHAR(5),                        -- X003
    BOX_NBR             CHAR(4),                        -- X004
    POSTAL_CODE         CHAR(7),                        -- X006
    CITY                VARCHAR(24),                    -- X007
    COUNTRY_CODE        CHAR(3)         DEFAULT 'BEL',  -- X008

    -- Contact
    PHONE               VARCHAR(20),
    EMAIL               VARCHAR(100),
    CONTACT_NAME        VARCHAR(100),

    -- Status & Audit
    STATUS              CHAR(3)         DEFAULT 'ACT',  -- ACT/INA/SUS
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT BROKER_PK PRIMARY KEY (BROKER_ID),
    CONSTRAINT BROKER_CODE_UK UNIQUE (BROKER_CODE),
    CONSTRAINT BROKER_STATUS_CK CHECK (STATUS IN ('ACT', 'INA', 'SUS'))
);

-- Indexes
CREATE INDEX BROKER_VAT_IX ON BROKER (VAT_NUMBER);
CREATE INDEX BROKER_STATUS_IX ON BROKER (STATUS);

-- Labels
LABEL ON TABLE BROKER IS 'Insurance Brokers - DAS.be';
LABEL ON COLUMN BROKER (
    BROKER_ID       IS 'Broker ID',
    BROKER_CODE     IS 'Broker Code (AgencyCode)',
    COMPANY_NAME    IS 'Company Name',
    VAT_NUMBER      IS 'Belgian VAT Number',
    FSMA_NUMBER     IS 'FSMA Registration',
    STREET          IS 'Street (X002)',
    HOUSE_NBR       IS 'House Number (X003)',
    BOX_NBR         IS 'Box Number (X004)',
    POSTAL_CODE     IS 'Postal Code (X006)',
    CITY            IS 'City (X007)',
    COUNTRY_CODE    IS 'Country Code (X008)',
    PHONE           IS 'Phone Number',
    EMAIL           IS 'Email Address',
    CONTACT_NAME    IS 'Primary Contact',
    STATUS          IS 'Status (ACT/INA/SUS)',
    CREATED_AT      IS 'Created Timestamp',
    UPDATED_AT      IS 'Updated Timestamp'
);
