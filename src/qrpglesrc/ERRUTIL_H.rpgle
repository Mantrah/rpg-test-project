**free
// ============================================================
// ERRUTIL_H - Error Handling Utility Prototypes
// DAS.be Backend - Legal Protection Insurance
// ============================================================

dcl-pr ERRUTIL_init;
end-pr;

dcl-pr ERRUTIL_addErrorCode;
    pErrorCode char(10) const;
end-pr;

dcl-pr ERRUTIL_addErrorMessage;
    pErrorMsg varchar(256) const;
end-pr;

dcl-pr ERRUTIL_addExecutionError;
end-pr;

dcl-pr ERRUTIL_hasErrors ind;
end-pr;

dcl-pr ERRUTIL_getErrorCount int(10);
end-pr;

dcl-pr ERRUTIL_getLastError varchar(256);
end-pr;

dcl-pr ERRUTIL_getLastErrorCode char(10);
end-pr;

dcl-pr ERRUTIL_getJobInfo varchar(50);
end-pr;

dcl-pr ERRUTIL_addSqlError;
    pSqlCode int(10) const;
    pSqlState char(5) const;
    pContext varchar(50) const;
end-pr;
