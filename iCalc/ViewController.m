//
//  ViewController.m
//  iCalc
//
//  Created by Florian Heller on 10/5/12.
//  Copyright (c) 2012 Florian Heller. All rights reserved.
//

// Define operation identifiers

#define DOT         10
#define OP_RIGHT    15
#define OP_LEFT     16
#define LEFT_BRACKET    17
#define RIGHT_BRACKET   18


#import "ViewController.h"

@interface ViewController ()
{

	BCOperator currentOperation;
    
	BOOL textFieldShouldBeCleared;
    
    NSInteger lastButtonPressed;
    UIButton * lastUIButtonPressed;
    
    
    BasicCalculator* basicCalculatorModel;
    ResultManager* resultManager;
}

-(void) updateRemainingEntries;

@end

@implementation ViewController


#pragma mark - File system handlers

-(void)saveToUserDefaultsObject:(NSObject*)object forKey:(NSString*)key
{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:object forKey:key];
    [defaults synchronize];
}

-(void)saveCurrentState
{
    switch (basicCalculatorModel.appState) {
        case operandOnlyState:
            [self saveToUserDefaultsObject:self.numberTextField.text forKey:@"FirstOperand"];
            break;
        case twoOperandsAndOperatorState:
            [self saveToUserDefaultsObject:basicCalculatorModel.lastOperand forKey:@"FirstOperand"];
            [self saveToUserDefaultsObject:self.numberTextField.text forKey:@"SecondOperand"];
            [self saveToUserDefaultsObject:[NSNumber numberWithChar:currentOperation] forKey:@"CurrentOperation"];
            break;
        case operandAndOperatorState:
            [self saveToUserDefaultsObject:basicCalculatorModel.lastOperand forKey:@"FirstOperand"];
            [self saveToUserDefaultsObject:[NSNumber numberWithChar:currentOperation] forKey:@"CurrentOperation"];
            break;
        case expressionState:
            [self saveToUserDefaultsObject:self.numberTextField.text forKey:@"Expression"];
        default:
            break;
    }
    
    [self saveToUserDefaultsObject:[NSNumber numberWithInt:basicCalculatorModel.appState] forKey:@"CurrentState"];
}

-(void)loadCurrentState
{
    basicCalculatorModel.appState = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentState"];
    UIButton *operationButton;
    switch (basicCalculatorModel.appState)
    {
        case operandOnlyState:
            self.numberTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"FirstOperand"];
            break;
        case twoOperandsAndOperatorState:
            
            basicCalculatorModel.lastOperand = [[NSUserDefaults standardUserDefaults] objectForKey:@"FirstOperand"];
            currentOperation = [[[NSUserDefaults standardUserDefaults] stringForKey:@"CurrentOperation"] intValue];
            self.numberTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"SecondOperand"];
            
            break;
        case operandAndOperatorState:
            basicCalculatorModel.lastOperand = [[NSUserDefaults standardUserDefaults] objectForKey:@"FirstOperand"] ;
            self.numberTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"FirstOperand"];
            currentOperation = [[[NSUserDefaults standardUserDefaults] stringForKey:@"CurrentOperation"] intValue];
            operationButton = (UIButton *)[self.view viewWithTag:currentOperation];
            [operationButton setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.1]];
            textFieldShouldBeCleared = YES;
            lastUIButtonPressed = operationButton;
            lastButtonPressed = operationButton.tag;
            break;
        case expressionState:
            self.numberTextField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"Expression"];
            [self toggleExpressionMode:nil];
        default:
            break;
    }
}



#pragma mark - Object Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

	currentOperation = BCOperatorNoOperation;
	textFieldShouldBeCleared = NO;
    basicCalculatorModel.appState = operandOnlyState;

    UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipeRecognizer.numberOfTouchesRequired = 1;
    
    UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] init];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipeRecognizer.numberOfTouchesRequired = 1;
    [rightSwipeRecognizer addTarget:self action:@selector(handleGesture:)];
    
    [self.view addGestureRecognizer:leftSwipeRecognizer];
    [self.view addGestureRecognizer:rightSwipeRecognizer];
    
    resultManager = [[ResultManager alloc] init];
    
    basicCalculatorModel = [[BasicCalculator alloc] init];
    basicCalculatorModel.delegate = self;
    basicCalculatorModel.primeDelegate = self;
    [basicCalculatorModel addObserver:resultManager forKeyPath:@"lastResult" options:0 context:nil];
    
    
    
    _selectedDecimalPrecision = [[NSUserDefaults standardUserDefaults] integerForKey:@"SavedDecimalPrecision"];
    [self.precisionLabel setText:[NSString stringWithFormat:@"%d",_selectedDecimalPrecision]];
    
    
    [self loadCurrentState];
    [self updateRemainingEntries];


}


#pragma mark - handle gestures
- (void)handleGesture:(UIGestureRecognizer *)gestureRecognizer;
{
    // ignore other gesture recognizer
    if (![gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]])
    {
        return;
    }
    
    UISwipeGestureRecognizer *swipeRecognizer = (UISwipeGestureRecognizer *)gestureRecognizer;
    
    switch (swipeRecognizer.direction)
    {
        case UISwipeGestureRecognizerDirectionLeft:
        {
            if( _selectedDecimalPrecision > 0)
                _selectedDecimalPrecision --;
            break;
        }
        case UISwipeGestureRecognizerDirectionRight:
        {
            if( _selectedDecimalPrecision < 9)
                _selectedDecimalPrecision ++;
            break;
        }
        default:
            break;
    }
    [self saveToUserDefaultsObject:[NSNumber numberWithInt:_selectedDecimalPrecision] forKey:@"SavedDecimalPrecision"];
    [self.precisionLabel setText:[NSString stringWithFormat:@"%d",_selectedDecimalPrecision]];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UI response operations
/*	This method get's called whenever an operation button is pressed
 *	The sender object is a pointer to the calling button in this case. 
 *	This way, you can easily change the buttons color or other properties
 */

-(IBAction)bracketPressed:(UIButton*)sender
{
    if(basicCalculatorModel.appState == expressionState)
    {
        switch (sender.tag) {
            case LEFT_BRACKET:
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"("];
                break;
            case RIGHT_BRACKET:
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@")"];
                break;
            default:
                break;
        }
    }
}

-(IBAction)toggleExpressionMode:(id)sender
{
    if(basicCalculatorModel.appState != expressionState)
    {
        self.expressionModeLabel.text = @"ON";
        basicCalculatorModel.appState = expressionState;
    }
    else
    {
        self.expressionModeLabel.text = @"OFF";
        basicCalculatorModel.appState = operandOnlyState;
    }
    
    [self clearDisplay:nil];
    [basicCalculatorModel reset];
}
- (IBAction)operationButtonPressed:(UIButton *)sender {
    
    if([self errorCheck])
        return;
    
    if(lastUIButtonPressed != nil)
        [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];

    
    if(basicCalculatorModel.appState == expressionState)
    {
        switch (sender.tag) {
            case BCOperatorMultiplication:
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"*"];
                break;
            case BCOperatorAddition:
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"+"];
                break;
            case BCOperatorDivision:
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"/"];
                break;
            case BCOperatorSubtraction:
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"-"];
                break;
                
            default:
                break;
        }
        
        return;
    }
    
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.1]];
    lastUIButtonPressed = sender;

    if ((lastButtonPressed >= BCOperatorAddition) && (lastButtonPressed<= BCOperatorMultiplication))
    {
        currentOperation = sender.tag;
        return;
    }
     lastButtonPressed = sender.tag;
    
    switch (basicCalculatorModel.appState) {
        case operandOnlyState:
            [basicCalculatorModel setFirstOperand:[NSNumber numberWithFloat:[self.numberTextField.text floatValue]]];
            break;
        case operandAndOperatorState:
            break;
        case twoOperandsAndOperatorState:
            [basicCalculatorModel performOperation:currentOperation withOperand:[NSNumber numberWithFloat:[self.numberTextField.text floatValue]] storeResult:NO];
        case undefinedState:
            break;
        default:
            break;
    }
    

    
    currentOperation = sender.tag;
	textFieldShouldBeCleared = YES;
    basicCalculatorModel.appState = operandAndOperatorState;
}

- (IBAction)resultButtonPressed:(id)sender {
    
    if([self errorCheck])
        return;

    lastButtonPressed = 0;
    if(lastUIButtonPressed != nil)
        [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];
    
    if(basicCalculatorModel.appState == expressionState)
    {
        [basicCalculatorModel performExpressionOperation:self.numberTextField.text];
                
        return;
    }
    
    if(basicCalculatorModel.appState == twoOperandsAndOperatorState)
    {
        [basicCalculatorModel performOperation:currentOperation withOperand:[NSNumber numberWithFloat:[self.numberTextField.text floatValue]] storeResult:YES];
    }
    

    
    [self updateRemainingEntries];
    
    
	currentOperation = BCOperatorNoOperation;
    textFieldShouldBeCleared = YES;
    basicCalculatorModel.appState = operandOnlyState;

}



- (IBAction)numberEntered:(UIButton *)sender {
    
    if([self errorCheck])
        return;
    
    lastButtonPressed = sender.tag;
    
    if(lastUIButtonPressed != nil)
        [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];
    
    if(basicCalculatorModel.appState == expressionState)
    {
        if(sender.tag == DOT)
            self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"."];
        else
            self.numberTextField.text = [self.numberTextField.text stringByAppendingString:[NSString stringWithFormat:@"%d",sender.tag]];

        return;
    }
    


	if (textFieldShouldBeCleared)
	{
		self.numberTextField.text = [NSString stringWithFormat:@"%i",sender.tag];
		textFieldShouldBeCleared = NO;
        
        if(currentOperation != BCOperatorNoOperation)
            basicCalculatorModel.appState = twoOperandsAndOperatorState;
        else
            basicCalculatorModel.appState = operandOnlyState;
	}
	else
    {
        if (sender.tag == DOT) {
            
            NSCharacterSet *cset = [NSCharacterSet characterSetWithCharactersInString:@"."];
            NSRange range = [self.numberTextField.text rangeOfCharacterFromSet:cset];
            
            if (range.location == NSNotFound)
                self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"."];

        }
        else
        {
            if ([self.numberTextField.text isEqualToString: @"0"])
                self.numberTextField.text = [NSString stringWithFormat:@"%i",sender.tag];
            else
                self.numberTextField.text = [self.numberTextField.text stringByAppendingFormat:@"%i", sender.tag];
            
        }
		
	}
}


-(IBAction) arrowsPressed:(UIButton*)sender
{
    if(basicCalculatorModel.appState == expressionState)
        return;
    
    if(sender.tag == OP_RIGHT)
        [resultManager shiftSliderRight];
    else
        [resultManager shiftSliderLeft];
    
    self.numberTextField.text = [NSString stringWithFormat:[basicCalculatorModel getFormatForDecimalPrecision:_selectedDecimalPrecision],[resultManager getCurrentResult]];
    
    
    textFieldShouldBeCleared = YES;
    [self updateRemainingEntries];
}


- (IBAction)clearDisplay:(id)sender {
	[basicCalculatorModel reset];
	
    currentOperation = BCOperatorNoOperation;
    [self updateRemainingEntries];
    [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];
	self.numberTextField.text = @"0";
    
    if(basicCalculatorModel.appState == expressionState)
        self.numberTextField.text = @"";
}

-(void) updateRemainingEntries
{
    NSString* leftBracket = @"(";
    NSString* remainingIndex = [NSString stringWithFormat:@"%d",[resultManager leftElementsCount]];
    NSString* rightBracket = @")";
    NSString* remainingLabel = [leftBracket stringByAppendingString:[remainingIndex stringByAppendingString:rightBracket] ];
    
    [self.leftRemainingEntries setText:remainingLabel];
    
    remainingIndex = [NSString stringWithFormat:@"%d",[resultManager rightElementsCount]];
    remainingLabel = [leftBracket stringByAppendingString:[remainingIndex stringByAppendingString:rightBracket] ];
    
    [self.rightRemainingEntries setText:remainingLabel];
    
    [self visualizedArray].selectedSegmentIndex = [resultManager leftElementsCount];
    
}

-(IBAction)segmentChanged:(id)sender
{
    
    if( ([resultManager savedResultsCount] == 0) || (((UISegmentedControl*)sender).selectedSegmentIndex > ([resultManager savedResultsCount] - 1)))
    {
        ((UISegmentedControl*)sender).selectedSegmentIndex = resultManager.historyIndex;
        return;
    }
    resultManager.historyIndex = ((UISegmentedControl*)sender).selectedSegmentIndex;
    
    self.numberTextField.text = [NSString stringWithFormat:[basicCalculatorModel getFormatForDecimalPrecision:_selectedDecimalPrecision],[resultManager getCurrentResult]];
    
    
    textFieldShouldBeCleared = YES;
    
    [self updateRemainingEntries];
}


#pragma mark - General Methods

-(BOOL)errorCheck
{
    if([self.numberTextField.text isEqualToString:@"Error"])
    {
        [self clearDisplay:nil];
        return YES;
    }
    else return NO;
}



- (BOOL)prefersStatusBarHidden;
{
    return YES;
}

#pragma -mark Delegate methods
-(void)operationDidCompleteWithResult:(NSNumber *)result
{
    if(isnan(result.floatValue))
        self.numberTextField.text = @"Error";
    else
        self.numberTextField.text = [NSString stringWithFormat:[basicCalculatorModel getFormatForDecimalPrecision:_selectedDecimalPrecision],result.floatValue];
}
-(void)expressionOperationDidCompleteWithResult:(NSNumber *)result
{
    if(isnan(result.floatValue))
        self.numberTextField.text = @"Error";
    else
        self.numberTextField.text = [NSString stringWithFormat:[basicCalculatorModel getFormatForDecimalPrecision:_selectedDecimalPrecision],result.floatValue];
}
-(void)didPrimeCheckNumber:(NSNumber *)theNumber result:(BOOL)theIsPrime{
    
    [self.primeActivityIndicator stopAnimating];
    
    NSString *baseString = [theNumber stringValue];
    
    if (theIsPrime) {
        self.primeLabel.text = [baseString stringByAppendingString:@" is a prime number"];
    } else {
        self.primeLabel.text = [baseString stringByAppendingString:@" is not a prime number"];
    }
}

-(void)willPrimeCheckNumber:(NSNumber *) theNumber
{
    [self.primeActivityIndicator startAnimating];
    self.primeLabel.text = [[@"Checking if " stringByAppendingString:theNumber.stringValue]stringByAppendingString:@" is a prime number"];
    
}
@end
