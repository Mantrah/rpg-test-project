**free
// *************************************************************
// Program: MATHCALC
// Description: Mathematical calculation program that receives a number,
//              performs exponential multiplication, then calculates
//              triangle area using the result as base (height=10)
// *************************************************************
ctl-opt dftactgrp(*no) actgrp(*new);
ctl-opt option(*srcstmt:*nodebugio);
ctl-opt main(Main);

/copy qrpglesrc/ERRUTIL

// Constants
dcl-c TRIANGLE_HEIGHT 10;

// Data structures
dcl-ds CalculationResult qualified;
  inputNumber           packed(15:0);
  exponentialResult     packed(31:0);
  triangleArea          packed(31:2);
  success               ind;
end-ds;

//==============================================================
// Main: Program entry point
//==============================================================
dcl-proc Main;
  dcl-pi *n;
    inputNumber         packed(15:0);
  end-pi;

  dcl-s result          likeds(CalculationResult);

  // Perform calculations
  result = ProcessMathematicalCalculation(inputNumber);

  // Display results
  if result.success;
    dsply ('Input Number: ' + %char(result.inputNumber));
    dsply ('Exponential Result: ' + %char(result.exponentialResult));
    dsply ('Triangle Area (height=10): ' + %char(result.triangleArea));
  else;
    dsply 'Calculation failed. Check error log.';
  endif;

  *inlr = *on;
  return;

end-proc;
//==============================================================
// ProcessMathematicalCalculation : Execute all calculations
//
//  Returns: CalculationResult data structure with all values
//
//==============================================================
dcl-proc ProcessMathematicalCalculation;
  dcl-pi *n likeds(CalculationResult);
    inputNumber         packed(15:0) const;
  end-pi;

  dcl-s expResult       packed(31:0);
  dcl-s area            packed(31:2);
  dcl-ds result         likeds(CalculationResult);

  monitor;

    // Initialization
    clear result;
    result.inputNumber = inputNumber;

    // Validation
    if inputNumber <= 0;
      ERRUTIL_addErrorCode('MATH001');
      ERRUTIL_addErrorMessage('Input number must be greater than zero');
      return result;
    endif;

    // Business logic - Step 1: Calculate exponential
    expResult = CalculateExponential(inputNumber);
    if expResult = 0;
      return result;
    endif;
    result.exponentialResult = expResult;

    // Business logic - Step 2: Calculate triangle area
    area = CalculateTriangleArea(expResult, TRIANGLE_HEIGHT);
    if area = 0;
      return result;
    endif;
    result.triangleArea = area;

    result.success = *on;

  on-error;
    ERRUTIL_addExecutionError();
    result.success = *off;
  endmon;

  return result;

end-proc;

//==============================================================
// CalculateExponential : Multiply number by itself n times
//
//  Returns: Result of base^exponent (or 0 on error)
//
//==============================================================
dcl-proc CalculateExponential;
  dcl-pi *n packed(31:0);
    baseNumber          packed(15:0) const;
  end-pi;

  dcl-s result          packed(31:0);
  dcl-s counter         packed(15:0);

  monitor;

    // Initialization
    result = baseNumber;

    // Validation
    if baseNumber <= 0;
      ERRUTIL_addErrorCode('MATH002');
      ERRUTIL_addErrorMessage('Base number must be positive');
      return 0;
    endif;

    if baseNumber = 1;
      return 1;
    endif;

    // Business logic
    // Multiply by itself (baseNumber - 1) more times
    // Example: if baseNumber = 3, we do 3 * 3 * 3 = 3^3
    for counter = 2 to baseNumber;
      result = result * baseNumber;

      if result < 0;
        ERRUTIL_addErrorCode('MATH003');
        ERRUTIL_addErrorMessage('Exponential calculation overflow');
        return 0;
      endif;
    endfor;

  on-error;
    ERRUTIL_addExecutionError();
    return 0;
  endmon;

  return result;

end-proc;
//==============================================================
// CalculateTriangleArea : Calculate area of triangle
//
//  Returns: Triangle area (base * height / 2)
//
//==============================================================
dcl-proc CalculateTriangleArea;
  dcl-pi *n packed(31:2);
    base                packed(31:0) const;
    height              packed(15:0) const;
  end-pi;

  dcl-s area            packed(31:2);

  monitor;

    // Initialization
    area = 0;

    // Validation
    if base <= 0 or height <= 0;
      ERRUTIL_addErrorCode('MATH004');
      ERRUTIL_addErrorMessage('Base and height must be greater than zero');
      return 0;
    endif;

    // Business logic
    area = (base * height) / 2;

    if area <= 0;
      ERRUTIL_addErrorCode('MATH005');
      ERRUTIL_addErrorMessage('Invalid triangle area calculation result');
      return 0;
    endif;

  on-error;
    ERRUTIL_addExecutionError();
    return 0;
  endmon;

  return area;

end-proc;