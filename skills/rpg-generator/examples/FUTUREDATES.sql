-- *************************************************************
-- Table: FUTUREDATES
-- Description: Stores calculated future dates in CYYMMDD format
-- *************************************************************

CREATE TABLE FUTUREDATES (
    RECORD_ID     INTEGER       NOT NULL,
    FUTURE_DATE   DECIMAL(7,0)  NOT NULL,
    CREATED_DATE  DATE          NOT NULL,
    CREATED_TIME  TIME          NOT NULL,

    CONSTRAINT FUTUREDATES_PK PRIMARY KEY (RECORD_ID)
);

LABEL ON TABLE FUTUREDATES IS 'Future Dates Records';

LABEL ON COLUMN FUTUREDATES.RECORD_ID     IS 'Record ID';
LABEL ON COLUMN FUTUREDATES.FUTURE_DATE   IS 'Future Date (CYYMMDD)';
LABEL ON COLUMN FUTUREDATES.CREATED_DATE  IS 'Created Date';
LABEL ON COLUMN FUTUREDATES.CREATED_TIME  IS 'Created Time';

-- Comments
COMMENT ON TABLE FUTUREDATES IS 'Stores future dates calculated by DATEPROC program';
COMMENT ON COLUMN FUTUREDATES.RECORD_ID IS 'Unique identifier for each record';
COMMENT ON COLUMN FUTUREDATES.FUTURE_DATE IS 'Future date in CYYMMDD format (C=century: 0=1900s, 1=2000s)';
COMMENT ON COLUMN FUTUREDATES.CREATED_DATE IS 'Date when the record was created';
COMMENT ON COLUMN FUTUREDATES.CREATED_TIME IS 'Time when the record was created';
