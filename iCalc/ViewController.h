//
//  ViewController.h
//  iCalc
//
//  Created by Florian Heller on 10/5/12.
//  Copyright (c) 2012 Florian Heller. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BasicCalculator.h"



@interface ViewController : UIViewController<BasicCalculatorDelegate, PrimeCalculatorDelegate>

@property (strong, nonatomic) IBOutlet UILabel *precisionLabel;
@property (strong, nonatomic) IBOutlet UISegmentedControl *threadingType;
@property (strong, nonatomic) IBOutlet UILabel *leftRemainingEntries;

@property (strong, nonatomic) IBOutlet UILabel *rightRemainingEntries;


@property (weak, nonatomic) IBOutlet UITextField *numberTextField;

@property (strong, nonatomic) IBOutlet UILabel *expressionModeLabel;
@property NSInteger selectedDecimalPrecision;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *primeActivityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *primeLabel;
@property (weak, nonatomic) IBOutlet UISwitch *primeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *primeModeLabel;


- (IBAction)operationButtonPressed:(UIButton *)sender;
- (IBAction)resultButtonPressed:(UIButton *)sender;
- (IBAction)numberEntered:(UIButton *)sender;
- (IBAction)clearDisplay:(id)sender;
- (IBAction) arrowsPressed:(UIButton*)sender;
- (IBAction) toggleEnabledTextForSwitch: (id) sender;
- (void)saveCurrentState;


@end
