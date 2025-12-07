**free
// ============================================================
// ERRUTIL - Error Handling Utility
// DAS.be Backend - Legal Protection Insurance
// ============================================================
// Provides standardized error handling for all service modules.
// Usage:
//   /copy qrpglesrc/ERRUTIL
//   ERRUTIL_addErrorCode('ERR001');
//   ERRUTIL_addErrorMessage('Custom error message');
//   ERRUTIL_addExecutionError(); // In ON-ERROR blocks
// ============================================================

ctl-opt nomain option(*srcstmt:*nodebugio);

// SQL Options - COMMIT(*NONE) required for PUB400
exec sql SET OPTION COMMIT = *NONE, CLOSQLCSR = *ENDMOD;

// Job info variables
dcl-s gJobName char(10);
dcl-s gJobUser char(10);
dcl-s gJobNumber char(6);

//==============================================================
// Constants
//==============================================================
dcl-c MAX_ERRORS 10;
dcl-c MAX_MSG_LEN 256;

//==============================================================
// Error Data Structure
//==============================================================
dcl-ds ErrorEntry qualified template;
    errorCode   char(10);
    errorMsg    varchar(256);
    errorType   char(1);        // C=Code, M=Message, X=Execution
    timestamp   timestamp;
end-ds;

dcl-ds ErrorStack qualified export;
    count       int(10) inz(0);
    errors      likeds(ErrorEntry) dim(MAX_ERRORS);
end-ds;

//==============================================================
// ERRUTIL_init : Initialize error stack
//
//  Returns: Nothing (clears all errors)
//
//==============================================================
dcl-proc ERRUTIL_init export;
    // Initialization
    ErrorStack.count = 0;
end-proc;

//==============================================================
// ERRUTIL_addErrorCode : Add error by code
//
//  Returns: Nothing
//
//==============================================================
dcl-proc ERRUTIL_addErrorCode export;
    dcl-pi *n;
        pErrorCode char(10) const;
    end-pi;

    // Validation
    if ErrorStack.count >= MAX_ERRORS;
        return;
    endif;

    // Business logic
    ErrorStack.count += 1;
    ErrorStack.errors(ErrorStack.count).errorCode = pErrorCode;
    ErrorStack.errors(ErrorStack.count).errorMsg = getErrorMessage(pErrorCode);
    ErrorStack.errors(ErrorStack.count).errorType = 'C';
    ErrorStack.errors(ErrorStack.count).timestamp = %timestamp();
end-proc;

//==============================================================
// ERRUTIL_addErrorMessage : Add error by message
//
//  Returns: Nothing
//
//==============================================================
dcl-proc ERRUTIL_addErrorMessage export;
    dcl-pi *n;
        pErrorMsg varchar(256) const;
    end-pi;

    // Validation
    if ErrorStack.count >= MAX_ERRORS;
        return;
    endif;

    // Business logic
    ErrorStack.count += 1;
    ErrorStack.errors(ErrorStack.count).errorCode = 'CUSTOM';
    ErrorStack.errors(ErrorStack.count).errorMsg = pErrorMsg;
    ErrorStack.errors(ErrorStack.count).errorType = 'M';
    ErrorStack.errors(ErrorStack.count).timestamp = %timestamp();
end-proc;

//==============================================================
// ERRUTIL_addExecutionError : Add execution error (for ON-ERROR)
//
//  Returns: Nothing
//
//==============================================================
dcl-proc ERRUTIL_addExecutionError export;
    // Validation
    if ErrorStack.count >= MAX_ERRORS;
        return;
    endif;

    // Business logic
    ErrorStack.count += 1;
    ErrorStack.errors(ErrorStack.count).errorCode = 'EXEC_ERR';
    ErrorStack.errors(ErrorStack.count).errorMsg = 'Execution error occurred';
    ErrorStack.errors(ErrorStack.count).errorType = 'X';
    ErrorStack.errors(ErrorStack.count).timestamp = %timestamp();
end-proc;

//==============================================================
// ERRUTIL_hasErrors : Check if errors exist
//
//  Returns: Indicator (true if errors exist)
//
//==============================================================
dcl-proc ERRUTIL_hasErrors export;
    dcl-pi *n ind end-pi;

    return (ErrorStack.count > 0);
end-proc;

//==============================================================
// ERRUTIL_getErrorCount : Get number of errors
//
//  Returns: Error count
//
//==============================================================
dcl-proc ERRUTIL_getErrorCount export;
    dcl-pi *n int(10) end-pi;

    return ErrorStack.count;
end-proc;

//==============================================================
// ERRUTIL_getLastError : Get last error message
//
//  Returns: Last error message (empty if none)
//
//==============================================================
dcl-proc ERRUTIL_getLastError export;
    dcl-pi *n varchar(256) end-pi;

    if ErrorStack.count = 0;
        return '';
    endif;

    return ErrorStack.errors(ErrorStack.count).errorMsg;
end-proc;

//==============================================================
// ERRUTIL_getLastErrorCode : Get last error code
//
//  Returns: Last error code (empty if none)
//
//==============================================================
dcl-proc ERRUTIL_getLastErrorCode export;
    dcl-pi *n char(10) end-pi;

    if ErrorStack.count = 0;
        return '';
    endif;

    return ErrorStack.errors(ErrorStack.count).errorCode;
end-proc;

//==============================================================
// getErrorMessage : Get message for error code (internal)
//
//  Returns: Error message for code
//
//==============================================================
dcl-proc getErrorMessage;
    dcl-pi *n varchar(256);
        pErrorCode char(10) const;
    end-pi;

    // Standard DAS.be error codes
    select;
        // Validation errors
        when pErrorCode = 'VAL001';
            return 'Invalid email format';
        when pErrorCode = 'VAL002';
            return 'Invalid Belgian VAT number';
        when pErrorCode = 'VAL003';
            return 'Invalid Belgian National Register Number';
        when pErrorCode = 'VAL004';
            return 'Invalid postal code';
        when pErrorCode = 'VAL005';
            return 'Invalid FSMA registration number';
        when pErrorCode = 'VAL006';
            return 'Required field missing';
        when pErrorCode = 'VAL007';
            return 'Invalid date range';

        // Business rule errors
        when pErrorCode = 'BUS001';
            return 'Customer type requires individual fields';
        when pErrorCode = 'BUS002';
            return 'Customer type requires business fields';
        when pErrorCode = 'BUS003';
            return 'Contract is not active';
        when pErrorCode = 'BUS004';
            return 'Claim is in waiting period';
        when pErrorCode = 'BUS005';
            return 'Coverage not included in product';
        when pErrorCode = 'BUS006';
            return 'Claim amount below minimum threshold (350 EUR)';
        when pErrorCode = 'BUS007';
            return 'Claim amount exceeds coverage limit';
        when pErrorCode = 'BUS008';
            return 'Contract cannot be renewed';
        when pErrorCode = 'BUS009';
            return 'Broker not active';
        when pErrorCode = 'BUS010';
            return 'Product not available';

        // Database errors
        when pErrorCode = 'DB001';
            return 'Record not found';
        when pErrorCode = 'DB002';
            return 'Duplicate record';
        when pErrorCode = 'DB003';
            return 'Foreign key violation';
        when pErrorCode = 'DB004';
            return 'Database error';

        other;
            return 'Unknown error: ' + %trim(pErrorCode);
    endsl;
end-proc;

//==============================================================
// ERRUTIL_getJobInfo : Get current job identifier
//
//  Returns: Job identifier (number/user/name)
//
//==============================================================
dcl-proc ERRUTIL_getJobInfo export;
    dcl-pi *n varchar(50) end-pi;

    dcl-s jobInfo varchar(50);

    // Get job info via SQL
    exec sql
        SELECT JOB_NAME, JOB_USER, JOB_NUMBER
        INTO :gJobName, :gJobUser, :gJobNumber
        FROM TABLE(QSYS2.GET_JOB_INFO('*')) LIMIT 1;

    if sqlcode = 0;
        jobInfo = %trim(gJobNumber) + '/' +
                  %trim(gJobUser) + '/' +
                  %trim(gJobName);
    else;
        // Fallback: use PSDS if SQL fails
        jobInfo = 'UNKNOWN';
    endif;

    return jobInfo;
end-proc;

//==============================================================
// ERRUTIL_addSqlError : Add SQL error with job info
//
//  Returns: Nothing
//
//==============================================================
dcl-proc ERRUTIL_addSqlError export;
    dcl-pi *n;
        pSqlCode int(10) const;
        pSqlState char(5) const;
        pContext varchar(50) const;
    end-pi;

    dcl-s errMsg varchar(256);
    dcl-s jobInfo varchar(50);

    // Validation
    if ErrorStack.count >= MAX_ERRORS;
        return;
    endif;

    // Get job info
    jobInfo = ERRUTIL_getJobInfo();

    // Build error message with job info
    errMsg = 'SQLCODE=' + %char(pSqlCode) +
             ' SQLSTATE=' + pSqlState +
             ' Context=' + %trim(pContext) +
             ' Job=' + jobInfo;

    // Business logic
    ErrorStack.count += 1;
    ErrorStack.errors(ErrorStack.count).errorCode = 'SQL' + %char(pSqlCode);
    ErrorStack.errors(ErrorStack.count).errorMsg = errMsg;
    ErrorStack.errors(ErrorStack.count).errorType = 'S';
    ErrorStack.errors(ErrorStack.count).timestamp = %timestamp();
end-proc;
