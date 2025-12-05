-- ============================================================
-- CLAIM - Legal Protection Claims (Sinistres)
-- DAS.be Backend - Legal Protection Insurance
-- ============================================================
-- Claims represent requests for legal protection.
-- Key business rules:
-- - 79% resolved via amicable settlement (no court)
-- - Must check waiting period and coverage
-- - Customer can freely choose lawyer
-- TELEBIB2 alignment: ClaimReference, ClaimFileReference,
--                     ClaimAmount, ClaimCircumstancesCode, CoverageCode
-- ============================================================

CREATE OR REPLACE TABLE CLAIM (
    -- Primary Key
    CLAIM_ID            DECIMAL(10, 0)  NOT NULL GENERATED ALWAYS AS IDENTITY,

    -- Claim References (TELEBIB2)
    CLAIM_REFERENCE     CHAR(20)        NOT NULL,       -- ClaimReference
    FILE_REFERENCE      CHAR(20),                       -- ClaimFileReference (dossier)

    -- Foreign Key
    CONT_ID             DECIMAL(10, 0)  NOT NULL,

    -- Claim Classification (TELEBIB2)
    GUARANTEE_CODE      CHAR(10)        NOT NULL,       -- CoverageCode
    CIRCUMSTANCE_CODE   CHAR(10)        NOT NULL,       -- ClaimCircumstancesCode

    -- Dates
    DECLARATION_DATE    DATE            NOT NULL,
    INCIDENT_DATE       DATE,

    -- Claim Details
    DESCRIPTION         VARCHAR(500),

    -- Amounts (TELEBIB2: ClaimAmount)
    CLAIMED_AMOUNT      DECIMAL(11, 2),
    APPROVED_AMOUNT     DECIMAL(11, 2),

    -- Resolution
    RESOLUTION_TYPE     CHAR(3),                        -- AMI/LIT/REJ (79% AMI)
    LAWYER_NAME         VARCHAR(100),                   -- Customer can choose freely

    -- Status & Audit
    STATUS              CHAR(3)         DEFAULT 'NEW',  -- NEW/PRO/RES/CLO/REJ
    CREATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,
    UPDATED_AT          TIMESTAMP       DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT CLAIM_PK PRIMARY KEY (CLAIM_ID),
    CONSTRAINT CLAIM_REF_UK UNIQUE (CLAIM_REFERENCE),
    CONSTRAINT CLAIM_CONTRACT_FK FOREIGN KEY (CONT_ID) REFERENCES CONTRACT (CONT_ID),
    CONSTRAINT CLAIM_RESOL_CK CHECK (
        RESOLUTION_TYPE IS NULL OR RESOLUTION_TYPE IN ('AMI', 'LIT', 'REJ')
    ),
    CONSTRAINT CLAIM_STATUS_CK CHECK (STATUS IN ('NEW', 'PRO', 'RES', 'CLO', 'REJ')),
    CONSTRAINT CLAIM_CIRCUM_CK CHECK (
        CIRCUMSTANCE_CODE IN (
            'CONTR_DISP',   -- Contract dispute
            'EMPL_DISP',    -- Employment dispute
            'NEIGH_DISP',   -- Neighborhood dispute
            'TAX_DISP',     -- Tax dispute
            'MED_MALPR',    -- Medical malpractice
            'CRIM_DEF',     -- Criminal defense
            'FAM_DISP',     -- Family dispute
            'ADMIN_DISP'    -- Administrative dispute
        )
    )
);

-- Indexes
CREATE INDEX CLAIM_CONTRACT_IX ON CLAIM (CONT_ID);
CREATE INDEX CLAIM_STATUS_IX ON CLAIM (STATUS);
CREATE INDEX CLAIM_GUARANTEE_IX ON CLAIM (GUARANTEE_CODE);
CREATE INDEX CLAIM_CIRCUM_IX ON CLAIM (CIRCUMSTANCE_CODE);
CREATE INDEX CLAIM_DATES_IX ON CLAIM (DECLARATION_DATE);

-- Labels
LABEL ON TABLE CLAIM IS 'Legal Protection Claims - DAS.be';
LABEL ON COLUMN CLAIM (
    CLAIM_ID            IS 'Claim ID',
    CLAIM_REFERENCE     IS 'Claim Reference (ClaimReference)',
    FILE_REFERENCE      IS 'Dossier Reference (ClaimFileReference)',
    CONT_ID             IS 'Contract ID (FK)',
    GUARANTEE_CODE      IS 'Coverage Type (CoverageCode)',
    CIRCUMSTANCE_CODE   IS 'Claim Type (ClaimCircumstancesCode)',
    DECLARATION_DATE    IS 'Declaration Date',
    INCIDENT_DATE       IS 'Incident Date',
    DESCRIPTION         IS 'Claim Description',
    CLAIMED_AMOUNT      IS 'Amount Claimed (ClaimAmount)',
    APPROVED_AMOUNT     IS 'Amount Approved',
    RESOLUTION_TYPE     IS 'Resolution (AMI/LIT/REJ)',
    LAWYER_NAME         IS 'Assigned Lawyer',
    STATUS              IS 'Status (NEW/PRO/RES/CLO/REJ)',
    CREATED_AT          IS 'Created Timestamp',
    UPDATED_AT          IS 'Updated Timestamp'
);
