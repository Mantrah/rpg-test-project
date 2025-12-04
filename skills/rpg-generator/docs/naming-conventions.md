# RPG Naming Conventions

This document defines the naming standards for RPG development.

## Variables

Use **camelCase** with type prefix where appropriate.

### Examples:
```rpg
dcl-s orderNumber packed(10:0);
dcl-s customerName varchar(50);
dcl-s isActive ind;
dcl-s totalAmount packed(15:2);
dcl-s currentDate date;
dcl-s itemCount int(10);
```

### Type Prefixes (Optional but Recommended):
- No strict prefix required, but descriptive names are essential
- Boolean indicators: prefix with `is`, `has`, `should` (e.g., `isValid`, `hasError`)
- Counters: suffix with `Count` (e.g., `recordCount`, `errorCount`)

## Data Structures

Use **PascalCase** for all data structure names.

### Examples:
```rpg
dcl-ds CustomerData qualified;
  customerId packed(10:0);
  name varchar(50);
  email varchar(100);
end-ds;

dcl-ds OrderHeader qualified;
  orderId packed(10:0);
  orderDate date;
  customerId packed(10:0);
end-ds;

dcl-ds ResponseData qualified;
  success ind;
  message varchar(256);
  statusCode int(10);
end-ds;
```

### Data Structure Fields:
- Use camelCase for fields within data structures
- Always use `qualified` to avoid naming conflicts

## Procedures

Use **PascalCase** with descriptive verb-noun combinations.

### Examples:
```rpg
dcl-proc ProcessOrder;
dcl-proc ValidateCustomer;
dcl-proc BuildJsonResponse;
dcl-proc GetCustomerById;
dcl-proc UpdateInventory;
dcl-proc CalculateTotal;
dcl-proc SendNotification;
```

### Procedure Naming Guidelines:
- Start with action verbs: `Get`, `Set`, `Create`, `Update`, `Delete`, `Process`, `Validate`, `Calculate`, `Build`, `Send`
- Be specific and descriptive
- Avoid abbreviations unless universally understood
- Use complete words

## Constants

Use **UPPER_SNAKE_CASE** for all constants.

### Examples:
```rpg
dcl-c MAX_RECORDS 1000;
dcl-c API_VERSION 'v1';
dcl-c SUCCESS_CODE 200;
dcl-c ERROR_NOT_FOUND 404;
dcl-c DEFAULT_TIMEOUT 30;
dcl-c DB_CONNECTION_STRING 'localhost';
```

## Files

### Logical File Names (in RPG):
Use **PascalCase** for file variables.

```rpg
dcl-f CustomerMaster disk(*ext) usage(*input) keyed;
dcl-f OrderDetails disk(*ext) usage(*update:*delete:*output) keyed;
```

### Physical File Names (on system):
Use **UPPERCASE** for actual file objects on IBMi.

```
CUSTOMERS
ORDERS
ORDERDETL
INVENTORY
```

## Parameters

Use **camelCase** for procedure parameters, consistent with variable naming.

### Examples:
```rpg
dcl-proc GetCustomer;
  dcl-pi *n likeds(CustomerData);
    customerId packed(10:0) const;
    includeOrders ind const;
  end-pi;

  // Implementation

end-proc;
```

## SQL Table and Column Names

### Tables:
- Use **UPPERCASE** for table names
- Use singular or plural based on your organization's standard

```sql
select * from CUSTOMERS;
select * from ORDER_DETAILS;
```

### Columns:
- Use **camelCase** or **snake_case** consistently
- Match your data structure field names when possible

```sql
select customerId, customerName, email
from CUSTOMERS
where customerId = :customerId;
```

## Program Names

- Use **UPPERCASE** for program names (IBMi convention)
- Keep to 10 characters or less (system limitation)
- Use meaningful abbreviations

```
CUSTMAINT  - Customer Maintenance
ORDPROC    - Order Processing
INVUPD     - Inventory Update
APICUST    - Customer API
```

## Module Names

- Use **UPPERCASE** for module names
- Suffix with purpose or type

```
JSONUTIL   - JSON utilities
ERRORUTIL  - Error handling utilities
DATEUTIL   - Date utilities
STRINGUTIL - String utilities
```

## Service Program Names

- Use **UPPERCASE**
- Descriptive of functionality

```
UTILITIES  - General utilities
APIBASE    - API base functions
DBACCESS   - Database access layer
```

## General Naming Rules

1. **Be Descriptive**: Names should clearly indicate purpose
   - Good: `customerEmailAddress`
   - Bad: `cea`, `x`, `temp`

2. **Avoid Abbreviations**: Unless widely understood
   - Good: `quantity`, `description`
   - Acceptable: `id`, `num`, `max`, `min`
   - Avoid: `qty`, `desc`, `amt`

3. **Use Consistent Terminology**:
   - Pick one term and stick with it
   - `customer` vs `client` - choose one
   - `order` vs `purchase` - choose one

4. **Length Considerations**:
   - Be descriptive but concise
   - Avoid overly long names (keep under 30 characters when possible)
   - Balance clarity with readability

5. **Special Prefixes**:
   - Global variables: consider `g` prefix (e.g., `gConnectionString`)
   - Local variables: no prefix needed
   - Parameters: consider `p` prefix if it aids clarity (e.g., `pCustomerId`)

## Examples of Good vs Bad Names

### Good:
```rpg
dcl-s customerCount int(10);
dcl-s orderTotal packed(15:2);
dcl-s isProcessingComplete ind;
dcl-ds InvoiceHeader qualified;
dcl-proc CalculateOrderTotal;
dcl-c MAX_RETRY_ATTEMPTS 3;
```

### Bad:
```rpg
dcl-s cnt int(10);              // Too abbreviated
dcl-s tot packed(15:2);         // Unclear
dcl-s flag ind;                 // Not descriptive
dcl-ds ih qualified;            // Cryptic
dcl-proc calc;                  // What does it calculate?
dcl-c X 3;                      // Meaningless
```

## Case Sensitivity Notes

While RPG is not case-sensitive, maintain consistent casing for:
- Code readability
- Integration with case-sensitive systems (like JSON APIs)
- Professional appearance
- Team collaboration

Always write code as if it were case-sensitive to maintain these standards.
