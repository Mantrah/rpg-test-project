-- ============================================================
-- CUSTOMER - Policyholders (Individuals and Businesses)
-- DAS.be Backend - Legal Protection Insurance
-- ============================================================
-- Customers can be individuals (IND) or businesses (BUS).
-- Individuals require NRN (National Register Number).
-- Businesses require VAT number and NACE code.
-- TELEBIB2 alignment: CivilStatusCode, BusinessCodeNace, Address
-- ============================================================

CREATE OR REPLACE TABLE CUSTOMER (
    -- Primary Key
    CUST_ID             DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Customer Type
    CUST_TYPE           CHAR(3)         NOT NULL,       -- IND/BUS

    -- Individual Fields
    FIRST_NAME          VARCHAR(50),
    LAST_NAME           VARCHAR(50),
    NATIONAL_ID         CHAR(15),                       -- Belgian NRN: 00.00.00-000.00
    CIVIL_STATUS        CHAR(3),                        -- CivilStatusCode (TELEBIB2)
    BIRTH_DATE          DATE,

    -- Business Fields
    COMPANY_NAME        VARCHAR(100),
    VAT_NUMBER          CHAR(12),                       -- Belgian VAT: BE0123456789
    NACE_CODE           CHAR(5),                        -- BusinessCodeNace (TELEBIB2)

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
    LANGUAGE            CHAR(2)         DEFAULT 'FR',   -- FR/NL/DE

    -- Status & Audit
    STATUS              CHAR(3)         DEFAULT 'ACT',  -- ACT/INA/SUS
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT CUSTOMER_PK PRIMARY KEY (CUST_ID),
    CONSTRAINT CUSTOMER_TYPE_CK CHECK (CUST_TYPE IN ('IND', 'BUS')),
    CONSTRAINT CUSTOMER_STATUS_CK CHECK (STATUS IN ('ACT', 'INA', 'SUS')),
    CONSTRAINT CUSTOMER_LANG_CK CHECK (LANGUAGE IN ('FR', 'NL', 'DE')),
    CONSTRAINT CUSTOMER_CIVIL_CK CHECK (
        CIVIL_STATUS IS NULL OR CIVIL_STATUS IN ('SGL', 'MAR', 'COH', 'DIV', 'WID')
    )
);

-- Indexes
CREATE INDEX CUSTOMER_TYPE_IX ON CUSTOMER (CUST_TYPE);
CREATE INDEX CUSTOMER_NRN_IX ON CUSTOMER (NATIONAL_ID);
CREATE INDEX CUSTOMER_VAT_IX ON CUSTOMER (VAT_NUMBER);
CREATE INDEX CUSTOMER_STATUS_IX ON CUSTOMER (STATUS);
CREATE INDEX CUSTOMER_NAME_IX ON CUSTOMER (LAST_NAME, FIRST_NAME);
CREATE INDEX CUSTOMER_COMPANY_IX ON CUSTOMER (COMPANY_NAME);

-- Labels
LABEL ON TABLE CUSTOMER IS 'Policyholders - DAS.be';
LABEL ON COLUMN CUSTOMER (
    CUST_ID         IS 'Customer ID',
    CUST_TYPE       IS 'Type (IND/BUS)',
    FIRST_NAME      IS 'First Name',
    LAST_NAME       IS 'Last Name',
    NATIONAL_ID     IS 'National Register Number',
    CIVIL_STATUS    IS 'Civil Status (CivilStatusCode)',
    BIRTH_DATE      IS 'Date of Birth',
    COMPANY_NAME    IS 'Company Name',
    VAT_NUMBER      IS 'Belgian VAT Number',
    NACE_CODE       IS 'NACE Business Code',
    STREET          IS 'Street (X002)',
    HOUSE_NBR       IS 'House Number (X003)',
    BOX_NBR         IS 'Box Number (X004)',
    POSTAL_CODE     IS 'Postal Code (X006)',
    CITY            IS 'City (X007)',
    COUNTRY_CODE    IS 'Country Code (X008)',
    PHONE           IS 'Phone Number',
    EMAIL           IS 'Email Address',
    LANGUAGE        IS 'Preferred Language',
    STATUS          IS 'Status (ACT/INA/SUS)',
    CREATED_AT      IS 'Created Timestamp',
    UPDATED_AT      IS 'Updated Timestamp'
);
