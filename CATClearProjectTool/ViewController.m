//
//  ViewController.m
//  CATClearProjectTool
//
//  Created by CatchZeng on 15/12/29.
//  Copyright © 2015年 catch. All rights reserved.
//

#import "ViewController.h"
#import "CATClearProjectTool.h"

@interface ViewController()<CATClearProjectToolDelegate>

@property (weak) IBOutlet NSTextField *txtPath;
@property (unsafe_unretained) IBOutlet NSTextView *txtResult;
@property (unsafe_unretained) IBOutlet NSTextView *txtFilter;

@property (nonatomic,strong) CATClearProjectTool* clearProjectTool;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.clearProjectTool.delegate = self;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark -- UIResponder

- (IBAction)searchButtonClicked:(id)sender {
    if (_txtPath.stringValue.length < 1) {
        return;
    }
    
    _txtResult.string = @"Searching all classes...";
    [self.clearProjectTool startSearchWithXcodeprojFilePath:_txtPath.stringValue];
}

- (IBAction)clearButtonClicked:(id)sender {
    [self _addFilter];
    [self.clearProjectTool clearFileAndMetaData];
}

#pragma mark -- CATClearProjectToolDelegate

-(void)searchAllClassesSuccess:(NSMutableDictionary *)dic{
    NSString* msg = @"Successfully searched all classes:\n";
    dispatch_async(dispatch_get_main_queue(), ^{
        _txtResult.string = [msg stringByAppendingString:[self _getClassNamesFromDic:dic]];
    });
}

-(void)searchUnUsedClassesSuccess:(NSMutableDictionary *)dic{
    NSString* msg = @"Successfully searched unused classes:\n";
    dispatch_async(dispatch_get_main_queue(), ^{
        _txtResult.string = [msg stringByAppendingString:[self _getClassNamesFromDic:dic]];
    });
}

-(void)clearUnUsedClassesSuccess:(NSMutableDictionary *)dic{
    NSString* msg = @"Successfully clear unused classes:\n";
    dispatch_async(dispatch_get_main_queue(), ^{
        _txtResult.string = [msg stringByAppendingString:[self _getClassNamesFromDic:dic]];
    });
}

#pragma mark -- helper

-(NSString *)_getClassNamesFromDic:(NSMutableDictionary *)dic{
    NSArray* keys = [dic allKeys];
    NSString* classNames = @"";
    for (NSString* className in keys) {
        classNames = [classNames stringByAppendingString:[NSString stringWithFormat:@"\n%@",className]];
    }
    return classNames;
}

-(void)_addFilter{
    NSString* strFilter = [NSString stringWithString:_txtFilter.string];
    if (strFilter && strFilter.length > 0) {
        if ([strFilter containsString:@","]) {
            NSArray* array = [strFilter componentsSeparatedByString:@","];
            [_clearProjectTool setFliterClasses:array];
        }else{
            [_clearProjectTool setFliterClasses:[NSArray arrayWithObject:strFilter]];
        }
    }
}

#pragma mark -- properties

/**
 *  get clearProjectTool
 *
 *  @return clearProjectTool
 */
-(CATClearProjectTool *)clearProjectTool{
    if (!_clearProjectTool) {
        _clearProjectTool = [[CATClearProjectTool alloc]init];
    }
    return _clearProjectTool;
}


#pragma mark -- dealloc

-(void)dealloc{
    _clearProjectTool = nil;
}

@end
