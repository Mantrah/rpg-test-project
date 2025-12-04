# RPG Best Practices

This document outlines best practices for modern RPG development.

**Target System: IBM i V7R5**

## General Principles

### 1. Write Self-Documenting Code
- Use descriptive variable and procedure names
- Keep procedures short and focused
- Use clear logic flow

```rpg
// Good: Clear and self-documenting
dcl-proc CalculateOrderDiscount;
  dcl-pi *n packed(15:2);
    orderTotal packed(15:2) const;
    customerTier varchar(10) const;
  end-pi;

  dcl-s discountRate packed(5:4);

  select;
    when customerTier = 'GOLD';
      discountRate = 0.15;
    when customerTier = 'SILVER';
      discountRate = 0.10;
    other;
      discountRate = 0.05;
  endsl;

  return orderTotal * discountRate;
end-proc;
```

### 2. Follow the Single Responsibility Principle
Each procedure should do one thing and do it well.

```rpg
// Bad: Too many responsibilities
dcl-proc ProcessCustomerOrder;
  ValidateCustomer();
  CheckInventory();
  CalculatePrice();
  UpdateDatabase();
  SendEmail();
  GenerateInvoice();
  UpdateStatistics();
end-proc;

// Good: Delegate to specialized procedures
dcl-proc ProcessCustomerOrder;
  dcl-pi *n ind;
    orderId packed(10:0) const;
  end-pi;

  if not ValidateOrder(orderId);
    return *off;
  endif;

  if not ProcessPayment(orderId);
    return *off;
  endif;

  if not FulfillOrder(orderId);
    return *off;
  endif;

  NotifyCustomer(orderId);
  return *on;
end-proc;
```

## Error Handling

### Always Use MONITOR/ON-ERROR
```rpg
dcl-proc ProcessRecord;

  monitor;
    // Your code here
    UpdateDatabase();
    ProcessBusinessLogic();

  on-error;
    // use error handler
    ERRUTIL_addExecutionError();
  endmon;

  return *on;
end-proc;
```

### Check SQL Return Codes
```rpg
exec sql
  update CUSTOMERS
  set status = 'A'
  where customerId = :customerId;

if sqlcode < 0;
  errorMsg = 'SQL Error: ' + %char(sqlcode) + ' - ' + sqlstate;
  LogError(errorMsg);
  exec sql rollback;
  return *off;
elseif sqlcode = 100;
  // No rows updated - handle accordingly
  return *off;
endif;
```

### Validate Input Early
```rpg
dcl-proc ProcessCustomer;
  dcl-pi *n ind;
    customerId packed(10:0) const;
  end-pi;

  // Validate immediately
  if customerId <= 0;
    LogError('Invalid customer ID');
    return *off;
  endif;

  // Continue with processing
  // ...
end-proc;
```

## Database Operations

### Use SQL for Set Operations
```rpg
// Good: Set-based operation
exec sql
  update INVENTORY
  set quantity = quantity - ol.quantity
  from ORDER_LINES ol
  where INVENTORY.productId = ol.productId
    and ol.orderId = :orderId;

// Less efficient: Row-by-row processing
exec sql declare c1 cursor for
  select productId, quantity
  from ORDER_LINES
  where orderId = :orderId;

exec sql open c1;
dow sqlcode = 0;
  exec sql fetch c1 into :productId, :quantity;
  if sqlcode = 0;
    exec sql
      update INVENTORY
      set quantity = quantity - :quantity
      where productId = :productId;
  endif;
enddo;
exec sql close c1;
```

### Use Transactions Appropriately
```rpg
dcl-proc ProcessOrder;

  // Start transaction
  exec sql
    set transaction isolation level read committed;

  monitor;
    // Multiple related operations
    exec sql
      insert into ORDERS (orderId, customerId, orderDate)
      values (:orderId, :customerId, :orderDate);

    exec sql
      insert into ORDER_LINES (orderId, productId, quantity)
      values (:orderId, :productId, :quantity);

    exec sql
      update INVENTORY
      set quantity = quantity - :quantity
      where productId = :productId;

    // Commit if all successful
    exec sql commit;
    return *on;

  on-error;
    // Rollback on any error
    exec sql rollback;
    LogError('Transaction failed');
    return *off;
  endmon;

end-proc;
```

### Avoid SELECT *
```rpg
// Bad: Selects all columns
exec sql
  select * into :CustomerData
  from CUSTOMERS
  where customerId = :customerId;

// Good: Select only needed columns
exec sql
  select customerId, customerName, email
  into :customerId, :customerName, :email
  from CUSTOMERS
  where customerId = :customerId;
```

## Data Structure Best Practices

### Always Use QUALIFIED
```rpg
// Good: Qualified - no naming conflicts
dcl-ds CustomerData qualified;
  customerId packed(10:0);
  name varchar(50);
  email varchar(100);
end-ds;

dcl-ds OrderData qualified;
  orderId packed(10:0);
  customerId packed(10:0);  // No conflict with CustomerData.customerId
  orderDate date;
end-ds;
```

### Use LIKEDS for Consistency
```rpg
// Define template
dcl-ds CustomerInfo qualified template;
  customerId packed(10:0);
  name varchar(50);
  email varchar(100);
end-ds;

// Use template for consistency
dcl-ds customer1 likeds(CustomerInfo);
dcl-ds customer2 likeds(CustomerInfo);

// Arrays of data structures
dcl-ds customerArray likeds(CustomerInfo) dim(100);
```

### Use Data Structures for Related Data
```rpg
// Good: Related data grouped together
dcl-ds OrderSummary qualified;
  totalOrders int(10);
  totalAmount packed(15:2);
  avgOrderAmount packed(15:2);
  lastOrderDate date;
end-ds;

// Bad: Scattered variables
dcl-s totalOrders int(10);
dcl-s totalAmount packed(15:2);
dcl-s avgOrderAmount packed(15:2);
dcl-s lastOrderDate date;
```

## Procedure Best Practices

### Use CONST for Read-Only Parameters
```rpg
dcl-proc FormatCustomerName;
  dcl-pi *n varchar(100);
    firstName varchar(50) const;  // Won't be modified
    lastName varchar(50) const;   // Won't be modified
  end-pi;

  return %trim(firstName) + ' ' + %trim(lastName);
end-proc;
```

### Return Early to Reduce Nesting
```rpg
// Bad: Deep nesting
dcl-proc ValidateAndProcess;
  if customerValid;
    if inventoryAvailable;
      if creditCheckPassed;
        if shippingAddressValid;
          ProcessOrder();
          return *on;
        endif;
      endif;
    endif;
  endif;
  return *off;
end-proc;

// Good: Early returns
dcl-proc ValidateAndProcess;
  if not customerValid;
    return *off;
  endif;

  if not inventoryAvailable;
    return *off;
  endif;

  if not creditCheckPassed;
    return *off;
  endif;

  if not shippingAddressValid;
    return *off;
  endif;

  ProcessOrder();
  return *on;
end-proc;
```

### Keep Procedures Small
Aim for procedures under 50-75 lines. Break larger procedures into smaller, focused ones.

```rpg
// Instead of one large procedure:
dcl-proc ProcessCompleteOrder;
  // 200 lines of code
end-proc;

// Break into smaller procedures:
dcl-proc ProcessCompleteOrder;
  if not ValidateOrder();
    return *off;
  endif;

  if not ReserveInventory();
    return *off;
  endif;

  if not ProcessPayment();
    return *off;
  endif;

  if not CreateShipment();
    return *off;
  endif;

  NotifyCustomer();
  return *on;
end-proc;
```

## Performance Considerations

### Minimize Database Round Trips
```rpg
// Bad: Multiple queries
exec sql
  select customerName into :customerName
  from CUSTOMERS where customerId = :customerId;

exec sql
  select email into :email
  from CUSTOMERS where customerId = :customerId;

exec sql
  select phone into :phone
  from CUSTOMERS where customerId = :customerId;

// Good: Single query
exec sql
  select customerName, email, phone
  into :customerName, :email, :phone
  from CUSTOMERS
  where customerId = :customerId;
```

### Use Appropriate Data Types
```rpg
// Good: Appropriate sized fields
dcl-s recordCount int(10);          // For counts
dcl-s amount packed(15:2);          // For currency
dcl-s largeNumber packed(30:0);     // For very large numbers

// Bad: Oversized fields waste memory
dcl-s recordCount packed(30:0);     // Overkill for a count
```

### Avoid Unnecessary Conversions
```rpg
// Bad: Multiple conversions
dcl-s numString varchar(10);
dcl-s amount packed(15:2);

numString = %char(amount);
amount = %dec(numString:15:2);

// Good: Use appropriate type from start
dcl-s amount packed(15:2);
```

## Security Best Practices

### Validate All External Input
```rpg
dcl-proc ProcessApiRequest;
  dcl-pi *n;
    requestJson varchar(5000) const;
  end-pi;

  dcl-s customerId packed(10:0);

  // Parse and validate
  customerId = ExtractCustomerId(requestJson);

  // Validate range
  if customerId <= 0 or customerId > 9999999999;
    SendErrorResponse('Invalid customer ID');
    return;
  endif;

  // Validate existence
  if not CustomerExists(customerId);
    SendErrorResponse('Customer not found');
    return;
  endif;

  // Process request
end-proc;
```

### Use Parameterized SQL (Avoid SQL Injection)
```rpg
// Good: Parameterized - safe from SQL injection
exec sql
  select * from CUSTOMERS
  where customerName = :searchName;

// Bad: String concatenation - vulnerable to SQL injection
// NEVER DO THIS:
// sqlStatement = 'select * from CUSTOMERS where customerName = ''' +
//                searchName + '''';
// exec sql prepare stmt from :sqlStatement;
```

### Don't Log Sensitive Data
```rpg
// Bad: Logs sensitive information
LogMessage('Processing payment: Card=' + cardNumber +
           ' CVV=' + cvv);

// Good: Logs safely
LogMessage('Processing payment for customer: ' + %char(customerId));
```

## Code Organization

### Group Related Functionality
```rpg
// Customer-related procedures together
dcl-proc GetCustomer;
dcl-proc CreateCustomer;
dcl-proc UpdateCustomer;
dcl-proc DeleteCustomer;

// Order-related procedures together
dcl-proc GetOrder;
dcl-proc CreateOrder;
dcl-proc UpdateOrder;
dcl-proc CancelOrder;
```

### Use Modules for Shared Code
Create service modules for common functionality:
- `JSONUTIL` - JSON handling
- `ERRORUTIL` - Error handling
- `DATEUTIL` - Date operations
- `STRINGUTIL` - String operations
- `DBACCESS` - Database utilities

### Use Service Programs
Package related modules into service programs for easier maintenance and deployment.

## Testing Best Practices

### Write Testable Code
```rpg
// Good: Easy to test - no dependencies
dcl-proc CalculateDiscount;
  dcl-pi *n packed(15:2);
    amount packed(15:2) const;
    discountRate packed(5:4) const;
  end-pi;

  return amount * discountRate;
end-proc;

// Harder to test - has dependencies
dcl-proc CalculateDiscount;
  dcl-pi *n packed(15:2);
    customerId packed(10:0) const;
  end-pi;

  // Gets data from database
  exec sql
    select discountRate into :rate
    from CUSTOMERS
    where customerId = :customerId;

  exec sql
    select sum(orderTotal) into :total
    from ORDERS
    where customerId = :customerId;

  return total * rate;
end-proc;
```

### Test Error Conditions
Don't just test the happy path - test error conditions too:
- Invalid input
- Missing data
- SQL errors
- Boundary conditions

## Documentation

### Document Public Interfaces
```rpg
// *************************************************************
// GetCustomerOrders - Retrieve all orders for a customer
//
// Parameters:
//   customerId - Customer identifier
//   startDate - Optional start date filter
//   endDate - Optional end date filter
//
// Returns:
//   Number of orders found (0 if none)
//
// Output:
//   orderArray - Populated with order data
//
// Description:
//   Retrieves all orders for the specified customer within
//   the optional date range. Orders are sorted by order date
//   descending (newest first).
//
// Error Handling:
//   Returns 0 on error. Check global error variables for details.
// *************************************************************
dcl-proc GetCustomerOrders export;
  // Implementation
end-proc;
```

### Keep Documentation Current
Update documentation when you change code behavior.

## Maintenance and Debugging

### Use Meaningful Error Messages
```rpg
// Bad: Cryptic
LogError('Error 1');

// Good: Descriptive
LogError('Failed to update inventory for product ' +
         %char(productId) + ': Insufficient stock');
```

### Log Important Operations
```rpg
dcl-proc ProcessPayment;
  LogMessage('Payment processing started for order ' +
             %char(orderId));

  if ProcessCreditCard();
    LogMessage('Payment successful for order ' + %char(orderId));
    return *on;
  else;
    LogError('Payment failed for order ' + %char(orderId) +
             ': ' + paymentErrorMsg);
    return *off;
  endif;
end-proc;
```

### Use Debug-Friendly Code
```rpg
// Good: Easy to debug with breakpoints
isValid = ValidateCustomer(customerId);
if not isValid;
  return *off;
endif;

hasInventory = CheckInventory(productId, quantity);
if not hasInventory;
  return *off;
endif;

// Harder to debug: Everything in one line
if not ValidateCustomer(customerId) or
   not CheckInventory(productId, quantity);
  return *off;
endif;
```

## Modern RPG Features

### Use Modern Built-In Functions
```rpg
// String operations
fullName = %trim(firstName) + ' ' + %trim(lastName);
upperName = %upper(customerName);
position = %scan('@': email);

// Array operations
arraySize = %elem(customerArray);
%subarr(sourceArray: 1: 10: targetArray);

// Date/Time operations
currentDate = %date();
currentTime = %time();
currentTimestamp = %timestamp();
formattedDate = %char(orderDate: *iso);
daysUntil = %diff(dueDate: currentDate: *days);

// Conversion functions
charValue = %char(numericValue);
numValue = %dec(stringValue: 15: 2);
```

### Use Data Structure Arrays
```rpg
dcl-ds OrderLine qualified dim(100);
  lineNumber int(10);
  productId packed(10:0);
  quantity int(10);
  price packed(15:2);
end-ds;

// Access array elements
OrderLine(1).productId = 12345;
OrderLine(1).quantity = 5;

// Loop through array
for index = 1 to %elem(OrderLine);
  if OrderLine(index).productId > 0;
    ProcessOrderLine(OrderLine(index));
  endif;
endfor;
```

## Summary Checklist

- [ ] Use full free-format RPG
- [ ] Follow naming conventions (camelCase, PascalCase, UPPER_SNAKE_CASE)
- [ ] Use QUALIFIED data structures
- [ ] Use CONST for read-only parameters
- [ ] Implement proper error handling (MONITOR/ON-ERROR)
- [ ] Check SQL return codes
- [ ] Use transactions for related operations
- [ ] Write small, focused procedures
- [ ] Return early to reduce nesting
- [ ] Validate input early
- [ ] Use parameterized SQL
- [ ] Document public procedures
- [ ] Write testable code
- [ ] Log important operations
- [ ] Use meaningful variable names
- [ ] Keep code DRY (Don't Repeat Yourself)
- [ ] Comment complex logic, not obvious code
- [ ] Use modern RPG built-in functions
- [ ] Optimize database access
- [ ] Secure sensitive data
