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

@interface BasicCalculator ()
{
    NSMutableArray* dependantQueues;
    NSOperationQueue * _myOpQueue;
}
@end

@implementation BasicCalculator


- (id)init
{
	self = [super init];
	if (self != nil) {
		self.lastOperand = [NSNumber numberWithInt:0];
		self.delegate = nil;
        self.primeDelegate = nil;
		self.rememberLastResult = YES;
        self.appState = undefinedState;
        _myOpQueue = [[NSOperationQueue alloc] init];
        dependantQueues = [[NSMutableArray alloc] init];

	}
	return self;
}

- (void)dealloc
{
	//With synthesized setters, you set the object to nil to release it
	//If delegate would be just a simple ivar, we would call [delegate release];
	self.delegate = nil;
    self.primeDelegate = nil;
	self.lastOperand = nil;
}


#pragma mark Method implementation
//Set our lastOperand cache to be another operand
- (void)setFirstOperand:(NSNumber*)anOperand
{
	self.lastOperand = anOperand;
}

// This method performs an operation with the given operation and the second operand. 
// After the operation is performed, the result is written to lastOperand 
- (void)performOperation:(BCOperator)operation withOperand:(NSNumber*)operand storeResult:(BOOL)storeRes
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
            if(operand.floatValue != 0)
            result = [NSNumber numberWithFloat:([self.lastOperand floatValue] / [operand floatValue])];
            else result = [NSNumber numberWithFloat:NAN];
            break;
        case BCOperatorSubtraction:
            result = [NSNumber numberWithFloat:([self.lastOperand floatValue] - [operand floatValue])];
            break;
        default:
            break;
    }
	
    //this is autoreleased
    self.lastOperand = result; //Since NSNumber is immutable, no side-effects. Memory management is done in the setter
	
    if(storeRes)
        self.lastResult = result;
    
    //Prime call
     // [self checkByGCD:result.integerValue];
	[self checkByOpQueue:result.integerValue];
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
        
         sleep(1);    // uncomment this line to make the execution significantly longer for a more dramatic effect :D
    }
    if (checkValue == theInteger)
    {
        result = YES;
    }
    
    return result;
}



-(NSString*) getFormatForDecimalPrecision:(NSInteger)precision
{
    return [[[NSMutableString stringWithString:@"%."] stringByAppendingString:[NSString stringWithFormat:@"%d",precision]] stringByAppendingString:@"f"];
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

- (void)checkByGCD:(NSInteger) theInteger;
{
    // Task 2.2
    
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        // This block will be executed asynchronously on the main thread.
        //To update the UI.
        //The delegate method with the result call. If the delegate is nil, this will just do nothing.
        if (_primeDelegate != nil) {
            if ([_primeDelegate respondsToSelector:@selector(willPrimeCheckNumber:)])
            {
                [_primeDelegate willPrimeCheckNumber:[NSNumber numberWithInt:theInteger]];
            }
            else {
                NSLog(@"WARNING: the PrimeCalculator delegate does not implement didPrimeCheckNumber:");
            }
        }
        else {
            NSLog(@"WARNING: the PrimeCalculator delegate is nil");
        }
    });
    dispatch_async(aQueue, ^(){
        BOOL *result;
        result = [self checkPrime: theInteger];
        
        
        //To perform the checking
        //The delegate method with the result call. If the delegate is nil, this will just do nothing.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_primeDelegate != nil) {
            if ([_primeDelegate respondsToSelector:@selector(didPrimeCheckNumber:result:)])
            {
                [_primeDelegate didPrimeCheckNumber:[NSNumber numberWithInt:theInteger] result:result];
            }
            else {
                NSLog(@"WARNING: the PrimeCalculator delegate does not implement didPrimeCheckNumber:");
            }
        }
        else {
            NSLog(@"WARNING: the PrimeCalculator delegate is nil");
        }
    });
    });
    
    
}

- (void)checkByOpQueue:(NSInteger) theInteger;
{
    // Task 2.3
    
   
    [_myOpQueue setMaxConcurrentOperationCount:1];
    NSLog(@"Queue Count: %d",_myOpQueue.operationCount);
    [_myOpQueue cancelAllOperations];
    [_myOpQueue waitUntilAllOperationsAreFinished];
    
    
    if (_primeDelegate != nil) {

        if ([_primeDelegate respondsToSelector:@selector(willPrimeCheckNumber:)])
        {
            [_primeDelegate willPrimeCheckNumber:[NSNumber numberWithInt:theInteger]];
        }
        else {
            NSLog(@"WARNING: the PrimeCalculator delegate does not implement didPrimeCheckNumber:");
        }
    }
    else {
        NSLog(@"WARNING: the PrimeCalculator delegate is nil");
    }
    
    NSBlockOperation *blockOp = [[NSBlockOperation alloc] init];
    __weak NSBlockOperation * weakOperation = blockOp;
    [blockOp addExecutionBlock:^()
                                 {
                                     
                                     BOOL *result;
                                     result = [self checkPrimeAllowCancel: theInteger withOperation:weakOperation ];
                                     
                                     if (_primeDelegate != nil) {
                                         if ([_primeDelegate respondsToSelector:@selector(didPrimeCheckNumber:result:)])
                                         {
                                             [_primeDelegate didPrimeCheckNumber:[NSNumber numberWithInt:theInteger] result:result];
                                         }
                                         else {
                                             NSLog(@"WARNING: the PrimeCalculator delegate does not implement didPrimeCheckNumber:");
                                         }
                                     }
                                     else {
                                         NSLog(@"WARNING: the PrimeCalculator delegate is nil");
                                     }
                                     
//                                     [self checkByGCD:theInteger];
                                    
                                 }];
    [_myOpQueue addOperation:blockOp];
    

//  /*  NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self
//                                                                            selector:@selector(checkByGCD:)
//                                                                              object:nil];
//    [_myOpQueue addOperation:operation]; */
//
//
    
}


- (BOOL)checkPrimeAllowCancel:(NSInteger)theInteger withOperation:(NSBlockOperation *)operation;
{
        
        BOOL *result;
        NSInteger checkValue = theInteger;
                        
        for (checkValue = 2 ; checkValue <= theInteger - 1 ; checkValue++)
        {
        if([operation isCancelled]){return NO;}
        if (theInteger % checkValue == 0)
        {
                result = NO;
                break;
        }
            sleep(1);    // uncomment this line to make the execution significantly longer for a more dramatic effect :D
            }
            if (checkValue == theInteger)
            {
                result = YES;
            }
        return result;
}

- (void)checkPerserveOrder:(NSUInteger)theInteger
{
    
    NSOperationQueue* newQueue = [[NSOperationQueue alloc] init];
    
    NSBlockOperation *blockOp = [NSBlockOperation blockOperationWithBlock:^()
                                 {
                                     
                                     BOOL *result;
                                     result = [self checkPrime: theInteger];
                                     if(result)
                                         NSLog(@"%d is Prime",theInteger);
                                     else NSLog(@"%d is NOT Prime",theInteger);
                                     
                                 }];
    
    if([dependantQueues count]>0)
    {
        if([[[dependantQueues objectAtIndex:[dependantQueues count]-1] operations] count]>0)
            
            [blockOp addDependency:(NSOperation*)[[[dependantQueues objectAtIndex:[dependantQueues count]-1] operations] objectAtIndex:0]];
    }
    [newQueue addOperation:blockOp];
    [dependantQueues addObject:newQueue];
    
    
}

@end
