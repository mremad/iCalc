//
//  ViewController.m
//  iCalc
//
//  Created by Florian Heller on 10/5/12.
//  Copyright (c) 2012 Florian Heller. All rights reserved.
//

// Define operation identifiers
//#define OP_NOOP     0
#define DOT         10
//#define OP_ADD      11
//#define OP_SUB      12
//#define OP_DIV      13
//#define OP_MUL      14
#define OP_RIGHT    15
#define OP_LEFT     16
#define LEFT_BRACKET    17
#define RIGHT_BRACKET   18


#import "ViewController.h"

@interface ViewController ()
{
	// The following variables do not need to be exposed in the public interface
	// that's why we define them in this class extension in the implementation file.
    
	//float firstOperand;
	BCOperator currentOperation;
    
	BOOL textFieldShouldBeCleared;
    
    NSInteger lastButtonPressed;
    UIButton * lastUIButtonPressed;
    
    NSInteger historyIndex;
    
    enum ApplicationState
    {
        operandOnlyState = 0,
        operandAndOperatorState,
        twoOperandsAndOperatorState,
        expressionState,
        undefinedState
        
    } appState;
    
    BasicCalculator* basicCalculatorModel;
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
    switch (appState) {
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
    
    [self saveToUserDefaultsObject:[NSNumber numberWithInt:appState] forKey:@"CurrentState"];
}

-(void)loadCurrentState
{
    appState = [[NSUserDefaults standardUserDefaults] integerForKey:@"CurrentState"];
    UIButton *operationButton;
    switch (appState)
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

-(NSMutableArray*) loadPlistFile
{
    NSMutableArray* resultArray;
    NSString *errorDesc = nil;
    NSPropertyListFormat format;
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,
                                                              NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"iCalcDataT.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath = [[NSBundle mainBundle] pathForResource:@"iCalcDataT" ofType:@"plist"];
    }
    NSData *plistXML = [[NSFileManager defaultManager] contentsAtPath:plistPath];
    NSDictionary *temp = (NSDictionary *)[NSPropertyListSerialization
                                          propertyListFromData:plistXML
                                          mutabilityOption:NSPropertyListMutableContainersAndLeaves
                                          format:&format
                                          errorDescription:&errorDesc];
    
    resultArray = [temp objectForKey:@"ResultArray"];
    
    return resultArray;
}

-(void) saveToPlistFile:(NSMutableArray*)arrayToSave
{
    
    
    NSString* errorCreatingPlist;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootPath isDirectory:NULL])
    {
        NSError *errorCreatingDir = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:&errorCreatingDir];
    }
    
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"iCalcDataT.plist"];
    NSDictionary *plistDict = [NSDictionary dictionaryWithObject:arrayToSave forKey:@"ResultArray"];
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:&errorCreatingPlist];
    if(plistData)
        [plistData writeToFile:plistPath atomically:YES];


    
   
}

#pragma mark - Object Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	currentOperation = BCOperatorNoOperation;
	textFieldShouldBeCleared = NO;
    appState = operandOnlyState;
    // swipe gesture recognizers
    // NOTE: Observe how target-action is established in the code below. This is equivalent to dragging connections in the Interface Builder.
    UISwipeGestureRecognizer *leftSwipeRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    leftSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipeRecognizer.numberOfTouchesRequired = 1;
    
    UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] init];
    rightSwipeRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    rightSwipeRecognizer.numberOfTouchesRequired = 1;
    [rightSwipeRecognizer addTarget:self action:@selector(handleGesture:)];
    
    [self.view addGestureRecognizer:leftSwipeRecognizer];
    [self.view addGestureRecognizer:rightSwipeRecognizer];
    
    basicCalculatorModel = [[BasicCalculator alloc] init];
    basicCalculatorModel.delegate = self;
    
    _selectedDecimalPrecision = [[NSUserDefaults standardUserDefaults] integerForKey:@"SavedDecimalPrecision"];
    [self.precisionLabel setText:[NSString stringWithFormat:@"%d",_selectedDecimalPrecision]];
    
    NSMutableArray* loadedResult = [self loadPlistFile];
    
    if(loadedResult != nil)
    {
        _lastTenResults = loadedResult;
        [self updateRemainingEntries];
    }
    else
        _lastTenResults = [[NSMutableArray alloc]initWithObjects:nil];
    
    [self loadCurrentState];


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
    if(appState == expressionState)
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
    if(appState != expressionState)
    {
        self.expressionModeLabel.text = @"ON";
        [self clearDisplay:nil];
        self.numberTextField.text = @"";
        appState = expressionState;
    }
    else
    {
        self.expressionModeLabel.text = @"OFF";
        [self clearDisplay:nil];
        appState = operandOnlyState;
    }
}
- (IBAction)operationButtonPressed:(UIButton *)sender {
    
    if([self errorCheck])
        return;
    
    if(lastUIButtonPressed != nil)
        [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];
    [sender setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:0.1]];
    lastUIButtonPressed = sender;
    
    if(appState == expressionState)
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
    
    

    if ((lastButtonPressed >= BCOperatorAddition) && (lastButtonPressed<= BCOperatorMultiplication))
    {
        currentOperation = sender.tag;
        return;
    }
     lastButtonPressed = sender.tag;
    
    switch (appState) {
        case operandOnlyState:
            [basicCalculatorModel setFirstOperand:[NSNumber numberWithFloat:[self.numberTextField.text floatValue]]];
            break;
        case operandAndOperatorState:
            break;
        case twoOperandsAndOperatorState:
            [basicCalculatorModel performOperation:currentOperation withOperand:[NSNumber numberWithFloat:[self.numberTextField.text floatValue]]];
        case undefinedState:
            break;
        default:
            break;
    }
    

    
    currentOperation = sender.tag;
	textFieldShouldBeCleared = YES;
    appState = operandAndOperatorState;
}

- (IBAction)resultButtonPressed:(id)sender {
    
    if([self errorCheck])
        return;

    if(appState == expressionState)
    {
        [basicCalculatorModel performExpressionOperation:self.numberTextField.text];
                
        return;
    }
    lastButtonPressed = 0;
    if(lastUIButtonPressed != nil)
        [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];

    
    if(appState == twoOperandsAndOperatorState)
    {
        [basicCalculatorModel performOperation:currentOperation withOperand:[NSNumber numberWithFloat:[self.numberTextField.text floatValue]]];
    }
    
    //if(!isnan(result))
    //    [_lastTenResults addObject:[NSNumber numberWithFloat:result]];
    
    if([_lastTenResults count] == 11)
        [_lastTenResults removeObjectAtIndex:0];
    
    [self updateRemainingEntries];
    [self saveToPlistFile:_lastTenResults];
    
    
	currentOperation = BCOperatorNoOperation;
    textFieldShouldBeCleared = YES;
    appState = operandOnlyState;

}



- (IBAction)numberEntered:(UIButton *)sender {
    
    if([self errorCheck])
        return;
    
    if(appState == expressionState)
    {
        if(sender.tag == DOT)
            self.numberTextField.text = [self.numberTextField.text stringByAppendingString:@"."];
        else
            self.numberTextField.text = [self.numberTextField.text stringByAppendingString:[NSString stringWithFormat:@"%d",sender.tag]];

        return;
    }
    
    lastButtonPressed = sender.tag;
    
    if(lastUIButtonPressed != nil)
    [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];
    
	// If the textField is to be cleared, just replace it with the pressed number
	if (textFieldShouldBeCleared)
	{
		self.numberTextField.text = [NSString stringWithFormat:@"%i",sender.tag];
		textFieldShouldBeCleared = NO;
        
        if(currentOperation != BCOperatorNoOperation)
            appState = twoOperandsAndOperatorState;
        else
            appState = operandOnlyState;
	}
	// otherwise, append the pressed number to what is already in the textField
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
    if(appState == expressionState)
    {
        return;
    }
    if(sender.tag == OP_RIGHT)
    {
        historyIndex++;
        if(historyIndex>([_lastTenResults count]-1))
            historyIndex = [_lastTenResults count]-1;
        
    }
    else
    {
        historyIndex--;
        if(historyIndex < 0)
            historyIndex = 0;
    }
    
    self.numberTextField.text = [NSString stringWithFormat:[basicCalculatorModel getFormatForDecimalPrecision:_selectedDecimalPrecision],[[_lastTenResults objectAtIndex:historyIndex] floatValue]];
    
    
    textFieldShouldBeCleared = YES;
    [self updateRemainingEntries];
}


- (IBAction)clearDisplay:(id)sender {
	[basicCalculatorModel reset];
	
    historyIndex = 0;
    currentOperation = BCOperatorNoOperation;
    [self updateRemainingEntries];
    [lastUIButtonPressed setBackgroundColor:[UIColor whiteColor]];
	self.numberTextField.text = @"0";
    
    if(appState == expressionState)
        self.numberTextField.text = @"";
}

-(void) updateRemainingEntries
{
    NSString* leftBracket = @"(";
    NSString* remainingIndex = [NSString stringWithFormat:@"%d",(historyIndex)];
    NSString* rightBracket = @")";
    NSString* remainingLabel = [leftBracket stringByAppendingString:[remainingIndex stringByAppendingString:rightBracket] ];
    
    [self.leftRemainingEntries setText:remainingLabel];
    
    remainingIndex = [NSString stringWithFormat:@"%d",([self.lastTenResults count] - 1 -historyIndex)];
    remainingLabel = [leftBracket stringByAppendingString:[remainingIndex stringByAppendingString:rightBracket] ];
    
    [self.rightRemainingEntries setText:remainingLabel];
    
    [self visualizedArray].selectedSegmentIndex = historyIndex;
    
}

-(IBAction)segmentChanged:(id)sender
{
    
    if( ([_lastTenResults count] == 0) || (((UISegmentedControl*)sender).selectedSegmentIndex > ([_lastTenResults count] - 1)))
    {
        ((UISegmentedControl*)sender).selectedSegmentIndex = historyIndex;
        return;
    }
    historyIndex = ((UISegmentedControl*)sender).selectedSegmentIndex;
    
    self.numberTextField.text = [NSString stringWithFormat:[basicCalculatorModel getFormatForDecimalPrecision:_selectedDecimalPrecision],[[_lastTenResults objectAtIndex:historyIndex] floatValue]];
    
    
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
@end
