//
//  BasicCalculator.h
//  iCalc
//
//  Created by Florian Heller on 10/22/10.
//  Modified by Chat Wacharamanotham on 11.11.13.
//  Copyright 2010 RWTH Aachen University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ResultManager.h"

//This is the set of operations we support
typedef enum BCOperator : NSUInteger {
	BCOperatorNoOperation=0,
	BCOperatorAddition=11,
	BCOperatorSubtraction,
    BCOperatorDivision,
	BCOperatorMultiplication
	
} BCOperator;

typedef enum ApplicationState : NSUInteger
{
    operandOnlyState = 0,
    operandAndOperatorState,
    twoOperandsAndOperatorState,
    expressionState,
    undefinedState
    
} ApplicationState ;

@protocol BasicCalculatorDelegate <NSObject>    // Task 1.2 make ViewController comply with this delegate

- (void)operationDidCompleteWithResult:(NSNumber*)result;
- (void)expressionOperationDidCompleteWithResult:(NSNumber*)result;

@end



@protocol PrimeCalculatorDelegate <NSObject>    // Task 2.1 use these two methods to inform the ViewController of the prime calculation.

@optional
- (void)willPrimeCheckNumber:(NSNumber *)theNumber;

@required
- (void)didPrimeCheckNumber:(NSNumber *)theNumber result:(BOOL)theIsPrime;

@end


// Task 1.1: Implement the model class
@interface BasicCalculator : NSObject 

@property (assign) BOOL rememberLastResult;
@property(assign) BOOL
result1;
@property (strong) id<BasicCalculatorDelegate> delegate;
@property (strong) id<PrimeCalculatorDelegate> primeDelegate; 
@property (strong) NSNumber *lastOperand;
@property (strong) NSNumber *lastResult;        // Task 1.3: Use this property for KVO
@property ApplicationState appState;

- (void)setFirstOperand:(NSNumber*)anOperand;
- (void)performOperation:(BCOperator)operation withOperand:(NSNumber*)operand storeResult:(BOOL)storeRes;
- (void)performExpressionOperation:(NSString*)expression;
- (NSString*)getFormatForDecimalPrecision:(NSInteger)precision;
- (void)reset;


@end
