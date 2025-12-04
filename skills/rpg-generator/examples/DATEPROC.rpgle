**free
// *************************************************************
// Program: DATEPROC
// Description: Calculate future date (+15 days), convert to
//              CYYMMDD format, and insert into FUTUREDATES table
// *************************************************************
ctl-opt dftactgrp(*no) actgrp(*new);
ctl-opt option(*srcstmt:*nodebugio);

/copy qrpglesrc/ERRUTIL

// Constants
dcl-c DAYS_TO_ADD 15;

// Data structures
dcl-ds FutureDateRecord qualified;
  recordId                          int(10);
  futureDate                        packed(7:0);
  createdDate                       date;
  createdTime                       time;
end-ds;

// Main procedure
dcl-proc Main;
  dcl-s success                     ind;

  monitor;

    // Process the date calculation and insertion
    success = ProcessFutureDate();

    if success;
      *inlr = *on;
      return;
    else;
      *inlr = *on;
      return;
    endif;

  on-error;
    ERRUTIL_addExecutionError();
    *inlr = *on;
  endmon;

end-proc;
//==============================================================
// ProcessFutureDate : Calculate and insert future date
//
//  Returns: *on if successful, *off if failed
//
//==============================================================
dcl-proc ProcessFutureDate;
  dcl-pi *n ind end-pi;

  dcl-s calculatedDate              packed(7:0);
  dcl-s insertSuccess               ind;

  monitor;

    // Initialization
    clear calculatedDate;
    insertSuccess = *off;

    // Business logic - Step 1: Calculate future date
    calculatedDate = CalculateFutureDateCYYMMDD(DAYS_TO_ADD);

    if calculatedDate = 0;
      ERRUTIL_addErrorMessage('Failed to calculate future date');
      return *off;
    endif;

    // Business logic - Step 2: Insert into database
    insertSuccess = InsertFutureDateRecord(calculatedDate);

    if not insertSuccess;
      ERRUTIL_addErrorMessage('Failed to insert future date record');
      return *off;
    endif;

  on-error;
    ERRUTIL_addExecutionError();
    return *off;
  endmon;

  return *on;

end-proc;
//==============================================================
// CalculateFutureDateCYYMMDD : Calculate date + days and
//                              convert to CYYMMDD format
//
//  Returns: Date in CYYMMDD format (packed 7,0)
//           Returns 0 if error occurs
//
//==============================================================
dcl-proc CalculateFutureDateCYYMMDD;
  dcl-pi *n packed(7:0);
    daysToAdd                       int(10) const;
  end-pi;

  dcl-s currentDate                 date;
  dcl-s futureDate                  date;
  dcl-s cyymmddDate                 packed(7:0);
  dcl-s dateString                  char(10);
  dcl-s century                     int(3);
  dcl-s year                        int(3);
  dcl-s month                       int(3);
  dcl-s day                         int(3);

  monitor;

    // Initialization
    clear cyymmddDate;

    // Validation
    if daysToAdd < 0;
      ERRUTIL_addErrorCode('DATE001');
      return 0;
    endif;

    // Business logic - Step 1: Get current date
    currentDate = %date();

    // Business logic - Step 2: Add days
    futureDate = currentDate + %days(daysToAdd);

    // Business logic - Step 3: Convert to CYYMMDD format
    // CYYMMDD: C = 0 for 19xx, 1 for 20xx, YY = year, MM = month, DD = day
    dateString = %char(futureDate : *iso);  // YYYY-MM-DD format

    year = %int(%subst(dateString:1:4));
    month = %int(%subst(dateString:6:2));
    day = %int(%subst(dateString:9:2));

    // Calculate century digit (0 for 1900s, 1 for 2000s)
    if year >= 2000;
      century = 1;
      year = year - 2000;
    else;
      century = 0;
      year = year - 1900;
    endif;

    // Build CYYMMDD: C(1) + YY(2) + MM(2) + DD(2) = 7 digits
    cyymmddDate = (century * 1000000) + (year * 10000) +
                  (month * 100) + day;

  on-error;
    ERRUTIL_addExecutionError();
    return 0;
  endmon;

  return cyymmddDate;

end-proc;
//==============================================================
// InsertFutureDateRecord : Insert future date into FUTUREDATES
//
//  Returns: *on if successful, *off if failed
//
//==============================================================
dcl-proc InsertFutureDateRecord;
  dcl-pi *n ind;
    futureDate                      packed(7:0) const;
  end-pi;

  dcl-s recordId                    int(10);
  dcl-s currentDate                 date;
  dcl-s currentTime                 time;

  monitor;

    // Initialization
    currentDate = %date();
    currentTime = %time();

    // Validation
    if futureDate = 0;
      ERRUTIL_addErrorCode('DATE002');
      return *off;
    endif;

    // Business logic - Step 1: Get next record ID
    exec sql
      select coalesce(max(RECORD_ID), 0) + 1
      into :recordId
      from FUTUREDATES;

    if sqlcode <> 0;
      ERRUTIL_addErrorMessage('Failed to get next record ID');
      return *off;
    endif;

    // Business logic - Step 2: Insert the record
    exec sql
      insert into FUTUREDATES
        (RECORD_ID, FUTURE_DATE, CREATED_DATE, CREATED_TIME)
      values
        (:recordId, :futureDate, :currentDate, :currentTime);

    if sqlcode <> 0;
      ERRUTIL_addErrorMessage('Failed to insert future date record');
      exec sql rollback;
      return *off;
    endif;

    // Business logic - Step 3: Commit the transaction
    exec sql commit;

  on-error;
    ERRUTIL_addExecutionError();
    exec sql rollback;
    return *off;
  endmon;

  return *on;

end-proc;

