# RPG Code Structure Standards

This document defines the structural standards for RPG development.

## File Format

**Always use full free-format RPG** (`**free`)

### Standard File Header:
```rpg
**free
// *************************************************************
// Program: PROGRAMNAME
// Description: [Brief description of the program]
// Author: [Your Team/Company]
// Created: [Date]
//
// Purpose:
//   [Detailed description of what this program does]
//
// Parameters:
//   [List parameters if applicable]
//
// Modification History:
// Date       User        Description
// ---------- ----------- ------------------------------------
// 2024-01-15 JDoe        Initial creation
//
// *************************************************************
```

## Control Options

### Standard Control Options for Programs:
```rpg
ctl-opt dftactgrp(*no) actgrp(*new);
ctl-opt option(*srcstmt:*nodebugio);
ctl-opt main(Main);  // For main programs
```

### Standard Control Options for Modules:
```rpg
ctl-opt nomain;
ctl-opt option(*srcstmt:*nodebugio);
```

## Declaration Order

Follow this order for declarations:

1. File declarations
2. Global constants
3. Global variables
4. Data structures
5. Procedure interfaces/prototypes
6. Main program logic
7. Procedure implementations

### Example:
```rpg
**free
// Control options
ctl-opt dftactgrp(*no) actgrp(*new);
ctl-opt option(*srcstmt:*nodebugio);
ctl-opt main(Main);

// 1. File declarations
dcl-f CUSTOMERS disk(*ext) usage(*input) keyed;

// 2. Constants
dcl-c MAX_RECORDS                       1000;
dcl-c PROGRAM_NAME                      'CUSTPROG';

// 3. Global variables
dcl-s recordCount                       int(10);
dcl-s errorMessage                      varchar(256);

// 4. Data structures
dcl-ds CustomerData                     qualified;
  customerId                            packed(10:0);
  name                                  varchar(50);
end-ds;

// 5. Procedure prototypes (if needed)
dcl-pr ProcessCustomer                  ind;
  custId                                packed(10:0) const;
end-pr;

// 6. Main program
dcl-proc Main;
  // Main logic
end-proc;

// 7. Procedure implementations
dcl-proc ProcessCustomer;
  // Implementation
end-proc;
```

## Variable Declaration Alignment

**Align data types at column 40** for consistent, readable declarations.

### Rule:
The data type keyword (`char`, `varchar`, `int`, `packed`, `ind`, etc.) should start at position 40.

### Example:
```rpg
// Good: Types aligned at column 40
dcl-s myChar                            char(10);
dcl-s customerName                      varchar(50);
dcl-s recordCount                       int(10);
dcl-s totalAmount                       packed(15:2);
dcl-s isValid                           ind;
dcl-s longVariableNameHere              varchar(100);

// Constants follow the same rule
dcl-c MAX_RECORDS                       1000;
dcl-c PROGRAM_NAME                      'CUSTPROG';
```

### Benefits:
- Improves readability by creating clear visual columns
- Makes it easy to scan variable types at a glance
- Follows traditional RPG column-based formatting conventions

### Note:
If a variable name exceeds 36 characters (reaching column 40), place the type on the same line with a single space separator.

## Indentation

Use **2 spaces** per indentation level.

### Example:
```rpg
dcl-proc ProcessOrder;
  dcl-pi *n                             ind;
    orderId                             packed(10:0) const;
  end-pi;

  dcl-s isValid                         ind;

  if orderId <= 0;
    return *off;
  endif;

  monitor;
    if ValidateOrder(orderId);
      isValid = UpdateInventory(orderId);
      if isValid;
        exec sql commit;
        return *on;
      else;
        exec sql rollback;
        return *off;
      endif;
    endif;
  on-error;
    exec sql rollback;
    return *off;
  endmon;

  return *off;
end-proc;
```

## Line Length

- Keep lines under **100 characters** when possible
- Break long lines logically

### Example of Line Breaking:
```rpg
// Good: Break at logical points
errorMessage = 'Customer ID ' + %char(customerId) +
               ' not found in database';

// Good: Break SQL statements
exec sql
  select customerId, customerName, email, phone
  into :CustomerData
  from CUSTOMERS
  where customerId = :customerId
    and status = 'A';

// Good: Break procedure calls
result = ProcessCustomerOrder(
  orderId:
  customerId:
  orderDate:
  totalAmount
);
```

## Comments

### File/Program Comments:
Use the structured header shown above.

### Procedure Comments:
Document all exported procedures:

```rpg
// *************************************************************
// ProcessOrder - Process customer order and update inventory
//
// Parameters:
//   orderId - Unique order identifier
//   customerId - Customer placing the order
//
// Returns:
//   *on if successful, *off if error occurred
//
// Description:
//   Validates the order, checks inventory availability,
//   updates inventory levels, and creates shipping record.
//   All operations are performed within a transaction.
//
// Error Handling:
//   Returns *off and rolls back transaction on any error.
//   Logs errors to ERROR_LOG table.
// *************************************************************
dcl-proc ProcessOrder export;
  dcl-pi *n                             ind;
    orderId                             packed(10:0) const;
    customerId                          packed(10:0) const;
  end-pi;

  // Implementation

end-proc;
```

### Inline Comments:
Use for complex logic or non-obvious code:

```rpg
// Calculate discount based on customer tier
select;
  when customerTier = 'GOLD';
    discount = 0.15;                    // 15% for gold tier
  when customerTier = 'SILVER';
    discount = 0.10;                    // 10% for silver tier
  other;
    discount = 0.05;                    // 5% default discount
endsl;

// Important: Must check inventory before processing
if not CheckInventory(productId: quantity);
  return *off;
endif;
```

### Avoid Obvious Comments:
```rpg
// Bad: Comment states the obvious
customerId = 1234;                      // Set customer ID to 1234

// Good: Comment explains why
customerId = 1234;                      // Using test customer for validation
```

## Blank Lines

Use blank lines to separate logical sections:

```rpg
dcl-proc ProcessBatch;

  dcl-s recordCount                     int(10);
  dcl-s errorCount                      int(10);

  // Initialize counters
  recordCount = 0;
  errorCount = 0;

  // Open files
  open INPUTFILE;
  open OUTPUTFILE;

  // Main processing loop
  read INPUTFILE;
  dow not %eof(INPUTFILE);
    recordCount += 1;
    ProcessRecord();
    read INPUTFILE;
  enddo;

  // Cleanup
  close INPUTFILE;
  close OUTPUTFILE;

  // Report results
  PrintSummary(recordCount: errorCount);

end-proc;
```

## Procedure Structure

### Standard Procedure Layout:
```rpg
dcl-proc ProcedureName export;          // or 'export' as needed
  dcl-pi *n                             returnType;
    param1                              type const;
    param2                              type;
  end-pi;

  // Local variable declarations
  dcl-s localVar                        type;
  dcl-ds LocalData                      qualified;
    // fields
  end-ds;

  // Procedure logic
  // ...

  return returnValue;

end-proc;
```

### Procedure Interface Guidelines:
```rpg
// Named return value (preferred for clarity)
dcl-proc GetCustomerName;
  dcl-pi *n                             varchar(50);
    customerId                          packed(10:0) const;
  end-pi;

// Use CONST for input-only parameters
dcl-proc ValidateOrder;
  dcl-pi *n                             ind;
    orderId                             packed(10:0) const;
    customerId                          packed(10:0) const;
  end-pi;

// Optional parameters
dcl-proc FormatDate;
  dcl-pi *n                             varchar(10);
    inputDate                           date const;
    formatString                        varchar(20) const options(*nopass);
  end-pi;
```

## Control Structures

### IF Statements:
```rpg
// Simple if
if condition;
  // code
endif;

// If-else
if condition;
  // code
else;
  // code
endif;

// If-elseif-else
if condition1;
  // code
elseif condition2;
  // code
else;
  // code
endif;

// Avoid deep nesting - use early returns instead
// Bad:
if valid;
  if hasPermission;
    if dataExists;
      // process
    endif;
  endif;
endif;

// Good:
if not valid;
  return *off;
endif;

if not hasPermission;
  return *off;
endif;

if not dataExists;
  return *off;
endif;

// process
```

### SELECT Statements:
```rpg
select;
  when condition1;
    // code
  when condition2;
    // code
  other;
    // default code
endsl;
```

### Loops:
```rpg
// DOW (Do While)
dow condition;
  // code
enddo;

// DOU (Do Until)
dou condition;
  // code
enddo;

// FOR loop
for index = 1 to maxValue;
  // code
endfor;

// FOR loop with BY
for index = 1 to maxValue by 2;
  // code
endfor;
```

## Error Handling

### Always Use MONITOR/ON-ERROR:
```rpg
monitor;
  // Risky operation
  ExecuteDatabaseOperation();
  ProcessBusinessLogic();

on-error;
  errorMsg = 'Error occurred: ' + %char(%error());
  LogError(errorMsg);
  exec sql rollback;
  return *off;
endmon;
```

### Multiple Error Handlers:
```rpg
monitor;
  // Code

on-error 1211;  // Specific error code
  // Handle specific error

on-error 1200:1299;  // Range of errors
  // Handle range

on-error *file;  // File errors
  // Handle file errors

on-error;  // Catch all
  // Handle any other error
endmon;
```

## SQL Integration

### Embedded SQL:
```rpg
// Simple query
exec sql
  select customerName
  into :customerName
  from CUSTOMERS
  where customerId = :customerId;

// Multi-line with formatting
exec sql
  select c.customerId,
         c.customerName,
         c.email,
         count(o.orderId) as orderCount
  into :CustomerData.id,
       :CustomerData.name,
       :CustomerData.email,
       :CustomerData.orderCount
  from CUSTOMERS c
  left join ORDERS o on o.customerId = c.customerId
  where c.status = 'A'
  group by c.customerId, c.customerName, c.email;

// Check SQL result
if sqlcode < 0;
  // Error
  LogSqlError();
elseif sqlcode = 100;
  // Not found
  return *off;
endif;
```

### Cursor Processing:
```rpg
exec sql declare c1 cursor for
  select customerId, customerName
  from CUSTOMERS
  where status = 'A'
  order by customerName;

exec sql open c1;

dow sqlcode = 0;
  exec sql fetch c1 into :customerId, :customerName;

  if sqlcode = 0;
    ProcessCustomer(customerId);
  endif;
enddo;

exec sql close c1;
```

## Data Structure Usage

### Always Use QUALIFIED:
```rpg
// Good: Qualified data structure
dcl-ds CustomerData                     qualified;
  customerId                            packed(10:0);
  name                                  varchar(50);
  email                                 varchar(100);
end-ds;

// Access with qualification
customerName = CustomerData.name;
```

### Nested Data Structures:
```rpg
dcl-ds OrderData                        qualified;
  orderId                               packed(10:0);
  orderDate                             date;
  customer                              likeds(CustomerInfo);
  items                                 likeds(OrderItem) dim(100);
end-ds;

dcl-ds CustomerInfo                     qualified template;
  customerId                            packed(10:0);
  name                                  varchar(50);
end-ds;

dcl-ds OrderItem                        qualified template;
  productId                             packed(10:0);
  quantity                              int(10);
  price                                 packed(15:2);
end-ds;
```

## Best Practices Summary

1. **One Procedure, One Purpose**: Keep procedures focused
2. **Use Meaningful Names**: Code should be self-documenting
3. **Handle Errors**: Always use MONITOR for risky operations
4. **Use CONST**: Mark read-only parameters with CONST
5. **Qualify Data Structures**: Always use QUALIFIED
6. **Early Returns**: Reduce nesting with early validation returns
7. **Consistent Formatting**: Follow indentation and spacing rules
8. **Comment Complex Logic**: Explain the "why", not the "what"
9. **Transaction Control**: Use COMMIT/ROLLBACK appropriately
10. **Test Thoroughly**: Include error conditions in testing
