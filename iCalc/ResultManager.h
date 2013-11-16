//
//  ResultManager.h
//  iCalc
//
//  Created by Mohamed Emad on 11/16/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ResultManager : NSObject

@property NSMutableArray *lastTenResults;
@property NSInteger historyIndex;

-(int)savedResultsCount;
-(float)getCurrentResult;
-(void)shiftSliderLeft;
-(void)shiftSliderRight;
-(int)leftElementsCount;
-(int)rightElementsCount;
-(BOOL)loadPlistFile;
-(void)saveToPlistFile;
@end
