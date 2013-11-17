//
//  ResultManager.m
//  iCalc
//
//  Created by Mohamed Emad on 11/16/13.
//  Copyright (c) 2013 Florian Heller. All rights reserved.
//

#import "ResultManager.h"

@implementation ResultManager

-(id)init
{
    self = [super init];
    if(self)
    {
        if(![self loadPlistFile])
            _lastTenResults = [[NSMutableArray alloc]initWithObjects:nil];
    }
    return self;
}

-(int)savedResultsCount
{
    return [_lastTenResults count];
}

-(float)getCurrentResult
{
    return [[_lastTenResults objectAtIndex:_historyIndex] floatValue];
}

-(void)shiftSliderLeft
{
    _historyIndex--;
    if(_historyIndex < 0)
        _historyIndex = 0;
}

-(void)shiftSliderRight
{
    _historyIndex++;
    if(_historyIndex>([_lastTenResults count]-1))
        _historyIndex = [_lastTenResults count]-1;
}

-(int)leftElementsCount
{
    return _historyIndex;
}

-(int)rightElementsCount
{
    if([_lastTenResults count] == 0)
        return 0;
    else return [_lastTenResults count] - 1 - _historyIndex;
}

-(BOOL) loadPlistFile
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
    

    _lastTenResults = resultArray;
    
    if(resultArray)
        return YES;
    else return NO;
}

-(void)saveToPlistFile
{
    
    
    NSString* errorCreatingPlist;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:rootPath isDirectory:NULL])
    {
        NSError *errorCreatingDir = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:&errorCreatingDir];
    }
    
    NSString *plistPath = [rootPath stringByAppendingPathComponent:@"iCalcDataT.plist"];
    NSDictionary *plistDict = [NSDictionary dictionaryWithObject:_lastTenResults forKey:@"ResultArray"];
    NSData *plistData = [NSPropertyListSerialization dataFromPropertyList:plistDict
                                                                   format:NSPropertyListXMLFormat_v1_0
                                                         errorDescription:&errorCreatingPlist];
    if(plistData)
        [plistData writeToFile:plistPath atomically:YES];
    
    
    
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"lastResult"])
    {
        NSNumber* newValue = (NSNumber*)[object valueForKeyPath:keyPath];
        if(!isnan(newValue.floatValue))
            [_lastTenResults addObject:[NSNumber numberWithFloat:newValue.floatValue]];
        
        if([_lastTenResults count] == 11)
            [_lastTenResults removeObjectAtIndex:0];
        
        [self saveToPlistFile];
    }

}


@end
