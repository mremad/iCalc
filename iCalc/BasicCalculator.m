//
//  BasicCalculator.m
//  iCalc
//
//  Created by Florian Heller on 10/22/10.
//  Modified by Chat Wacharamanotham on 11.11.13.
//  Copyright 2010 RWTH Aachen University. All rights reserved.
//

#import "BasicCalculator.h"


#pragma mark Object Lifecycle
@implementation BasicCalculator


- (id)init
{
	self = [super init];
	if (self != nil) {
		self.lastOperand = [NSNumber numberWithInt:0];
		self.delegate = nil;
		self.rememberLastResult = YES;
	}
	return self;
}

- (void)dealloc
{
	//With synthesized setters, you set the object to nil to release it
	//If delegate would be just a simple ivar, we would call [delegate release];
	self.delegate = nil;
	self.lastOperand = nil;
}


#pragma mark Method implementation
//Set our lastOperand cache to be another operand
- (void)setFirstOperand:(NSNumber*)anOperand;
{
	self.lastOperand = anOperand;
}

// This method performs an operation with the given operation and the second operand. 
// After the operation is performed, the result is written to lastOperand 
- (void)performOperation:(BCOperator)operation withOperand:(NSNumber*)operand;
{
	NSNumber *result;
    
	switch (operation) {
        case BCOperatorAddition:
            result = [NSNumber numberWithFloat:([self.lastOperand floatValue] + [operand floatValue])];
            break;
        case BCOperatorMultiplication:
            result = [NSNumber numberWithFloat:([self.lastOperand floatValue] * [operand floatValue])];
            break;
        case BCOperatorDivision:
            result = [NSNumber numberWithFloat:([self.lastOperand floatValue] / [operand floatValue])];
            break;
        case BCOperatorSubtraction:
            result = [NSNumber numberWithFloat:([self.lastOperand floatValue] - [operand floatValue])];
            break;
        default:
            break;
    }
	
		 //this is autoreleased
		self.lastOperand = result; //Since NSNumber is immutable, no side-effects. Memory management is done in the setter
	
	
	// Now call the delegate method with the result. If the delegate is nil, this will just do nothing.
	if (_delegate != nil) {
		if ([_delegate respondsToSelector:@selector(operationDidCompleteWithResult:)])
		{
			[_delegate operationDidCompleteWithResult:result];
		}
		else {
			NSLog(@"WARNING: the BasicCalculator delegate does not implement operationDidCompleteWithResult:");
		}
	}
	else {
		NSLog(@"WARNING: the BasicCalculator delegate is nil");
	}
	

}

-(void)performExpressionOperation:(NSString*)expression
{
    NSNumber* result = [NSNumber numberWithFloat:[self calculateExpression:expression]];
    
    if (_delegate != nil) {
		if ([_delegate respondsToSelector:@selector(operationDidCompleteWithResult:)])
		{
			[_delegate expressionOperationDidCompleteWithResult:result];
		}
		else {
			NSLog(@"WARNING: the BasicCalculator delegate does not implement operationDidCompleteWithResult:");
		}
	}
	else {
		NSLog(@"WARNING: the BasicCalculator delegate is nil");
	}
}

// This method clears everything (for the moment 
- (void)reset;
{
	self.lastOperand = [NSNumber numberWithInt:0];
}

// The following method is shamelessly modified from http://www.programmingsimplified.com/c/source-code/c-program-for-prime-number
- (BOOL)checkPrime:(NSInteger)theInteger;
{
    NSInteger checkValue;
    BOOL result;
        
    for (checkValue = 2 ; checkValue <= theInteger - 1 ; checkValue++)
    {
        if (theInteger % checkValue == 0)
        {
            result = NO;
            break;
        }
        
        // sleep(1);    // uncomment this line to make the execution significantly longer for a more dramatic effect :D
    }
    if (checkValue == theInteger)
    {
        result = YES;
    }
    
    return result;
}


-(BOOL)errorCheck
{
    if(NO/*[self.numberTextField.text isEqualToString:@"Error"]*/)
    {
        
        return YES;
    }
    else return NO;
}

-(NSString*) removeTrailingZeros:(float)number

{
    
    NSMutableString* returnString = [NSMutableString stringWithFormat:@"%f",number];
    
    
    
    int i = [returnString length]-1;
    
    
    
    while(i>=0)
        
    {
        
        if([returnString characterAtIndex:i] == '0')
            
        {
            
            returnString = (NSMutableString*)[returnString substringToIndex:(i)];
            
        }
        
        else if([returnString characterAtIndex:i] == '.')
            
        {
            
            returnString = (NSMutableString*)[returnString substringToIndex:(i)];
            
            break;
            
        }
        
        else
            
        {
            
            break;
            
        }
        
        
        
        i = [returnString length] - 1;
        
    }
    
    return returnString;
    
}

-(NSString*) getFormatForDecimalPrecision:(NSInteger)precision
{
    return [[[NSMutableString stringWithString:@"%."] stringByAppendingString:[NSString stringWithFormat:@"%d",precision]] stringByAppendingString:@"f"];
}

// This method returns the result of the specified operation
// It is placed here since it is needed in two other methods
- (float)executeOperation:(BCOperator)operation withArgument:(float)firstArgument andSecondArgument:(float)secondArgument;
{
	switch (operation) {
		case BCOperatorAddition:
			return firstArgument + secondArgument;
			break;
		case BCOperatorSubtraction:
			return firstArgument - secondArgument;
        case BCOperatorDivision:
            if (secondArgument != 0)
                return firstArgument / secondArgument;
            else
                return NAN;
        case BCOperatorMultiplication:
			return firstArgument * secondArgument;
            
		default:
			return NAN;
			break;
	}
}

-(BOOL)isValidNumber:(NSString*)number
{
    int dotNum = 0;
    for(int i = 0;i<[number length];i++)
    {
        if([number characterAtIndex:i] == '.')
        {
            dotNum++;
            if(dotNum>1)
                return NO;
        }
    }
    
    return YES;
}

-(float)calculateExpression:(NSString*)expression
{
    NSMutableArray* subExprArray = [[NSMutableArray alloc] initWithObjects:nil];
    NSMutableArray* operationsArray = [[NSMutableArray alloc] initWithObjects:nil];
    NSMutableArray* bracketStack = [[NSMutableArray alloc] initWithObjects:nil];
    NSMutableString* numberString = [NSMutableString stringWithString:@""];
    
    BOOL expressionFound = NO;
    BOOL insideExpression = NO;
    BOOL complex = NO;
    int subExprStartIndex = 0;
    int subExprEndIndex = 0;
    for(int i = 0;i<expression.length;i++)
    {
        switch ([expression characterAtIndex:i])
        {
            case '(':
                complex = YES;
                if([bracketStack count] == 0)
                    subExprStartIndex = i+1;
                [bracketStack addObject:@"("];
                insideExpression = YES;
                break;
            case ')':
                complex = YES;
                if([bracketStack count]>0)
                    [bracketStack removeLastObject];
                else return NAN;
                if([bracketStack count] == 0)
                {
                    subExprEndIndex = i;
                    expressionFound = YES;
                    insideExpression = NO;
                    [subExprArray addObject:[expression substringWithRange:NSMakeRange(subExprStartIndex, subExprEndIndex - subExprStartIndex)]];
                    
                }
                
                break;
            case '+':
            case '-':
            case '*':
            case '/':
                complex = YES;
                if(![numberString isEqual:@""])
                {
                    NSString* number = [NSString stringWithString:numberString];
                    if(![self isValidNumber:number])
                        return NAN;
                    [subExprArray addObject:number];
                    [numberString setString:@""];
                }
                if(!insideExpression)
                    [operationsArray addObject:[NSString stringWithFormat:@"%c",[expression characterAtIndex:i]]];
                break;
                
            default:
                if(!insideExpression)
                    [numberString appendString:[NSString stringWithFormat:@"%c",[expression characterAtIndex:i]]];
                break;
        }
    }
    
    if(![numberString isEqual:@""])
    {
        if(!complex)
            return [numberString floatValue];
        
        NSString* number = [NSString stringWithString:numberString];
        if(![self isValidNumber:number])
            return NAN;
        [subExprArray addObject:number];
        [numberString setString:@""];
    }
    if([operationsArray count] != ([subExprArray count] - 1))
        return NAN;
    
    if([subExprArray count] == 1)
        return [self calculateExpression:[subExprArray objectAtIndex:0]];
    
    BOOL arrayChanged = YES;
    
    while(arrayChanged)
    {
        arrayChanged = NO;
        
        for(NSString* operator in operationsArray)
        {
            int currIndex = [operationsArray indexOfObject:operator];
            if([operator isEqualToString:@"*"])
            {
                arrayChanged = YES;
                float result = [self calculateExpression:[subExprArray objectAtIndex:currIndex]]*[self calculateExpression:[subExprArray objectAtIndex:currIndex+1]];
                NSString* resultString = [NSString stringWithFormat:@"%f",result];
                [subExprArray replaceObjectAtIndex:currIndex withObject:resultString];
                [subExprArray removeObjectAtIndex:currIndex+1];
                [operationsArray removeObjectAtIndex:currIndex];
                break;
            }
        }
    }
    
    arrayChanged = YES;
    
    while(arrayChanged)
    {
        arrayChanged = NO;
        
        for(NSString* operator in operationsArray)
        {
            int currIndex = [operationsArray indexOfObject:operator];
            if([operator isEqualToString:@"/"])
            {
                arrayChanged = YES;
                
                if([self calculateExpression:[subExprArray objectAtIndex:currIndex+1]] == 0)
                    return NAN;
                
                float result = [self calculateExpression:[subExprArray objectAtIndex:currIndex]]/[self calculateExpression:[subExprArray objectAtIndex:currIndex+1]];
                NSString* resultString = [NSString stringWithFormat:@"%f",result];
                [subExprArray replaceObjectAtIndex:currIndex withObject:resultString];
                [subExprArray removeObjectAtIndex:currIndex+1];
                [operationsArray removeObjectAtIndex:currIndex];
                break;
            }
        }
    }
    
    arrayChanged = YES;
    
    while(arrayChanged)
    {
        arrayChanged = NO;
        
        for(NSString* operator in operationsArray)
        {
            int currIndex = [operationsArray indexOfObject:operator];
            if([operator isEqualToString:@"+"])
            {
                arrayChanged = YES;
                float result = [self calculateExpression:[subExprArray objectAtIndex:currIndex]]+[self calculateExpression:[subExprArray objectAtIndex:currIndex+1]];
                NSString* resultString = [NSString stringWithFormat:@"%f",result];
                [subExprArray replaceObjectAtIndex:currIndex withObject:resultString];
                [subExprArray removeObjectAtIndex:currIndex+1];
                [operationsArray removeObjectAtIndex:currIndex];
                break;
            }
            
            else if([operator isEqualToString:@"-"])
            {
                arrayChanged = YES;
                float result = [self calculateExpression:[subExprArray objectAtIndex:currIndex]]-[self calculateExpression:[subExprArray objectAtIndex:currIndex+1]];
                NSString* resultString = [NSString stringWithFormat:@"%f",result];
                [subExprArray replaceObjectAtIndex:currIndex withObject:resultString];
                [subExprArray removeObjectAtIndex:currIndex+1];
                [operationsArray removeObjectAtIndex:currIndex];
                break;
            }
        }
    }
    
    
    
    
    
    for(int i = 0;i<[subExprArray count];i++)
        NSLog(@"%@",subExprArray[i]);
    return [[subExprArray objectAtIndex:0] floatValue];
}


// -----------------------------------------------------------------------------------------------------------------
#pragma mark -
#pragma mark part 2
 // NOTE: you may change the signature of the following methods. Just keep the given name as a substring.
// -----------------------------------------------------------------------------------------------------------------

- (void)checkByGCD;
{
    // Task 2.2
}

- (void)checkByOpQueue;
{
    // Task 2.3
}

- (BOOL)checkPrimeAllowCancel:(NSInteger)theInteger;
{
    // Task 2.4 (extra credit)
}

- (void)checkPerserveOrder;
{
    // Task 2.5 (extra credit)
}

@end
