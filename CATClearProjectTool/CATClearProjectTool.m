//
//  CATClearProjectTool.m
//  CATClearProjectTool
//
//  Created by CatchZeng on 16/1/1.
//  Copyright © 2015年 catch. All rights reserved.
//

#import "CATClearProjectTool.h"
#import <Cocoa/Cocoa.h>

@implementation CATClearProjectTool{
    NSMutableDictionary* _allClasses;
    NSMutableDictionary* _unUsedClasses;
    NSMutableDictionary* _usedClasses;
    NSMutableArray* _fliterClasses;
    NSDictionary* _objects;
    NSString* _projectDir;
    NSString* _pbxprojPath;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        _allClasses = [NSMutableDictionary dictionary];
        _unUsedClasses = [NSMutableDictionary dictionary];
        _usedClasses = [NSMutableDictionary dictionary];
        [self _resetFilter];
    }
    return self;
}

#pragma mark -- dealloc

-(void)dealloc{
    _allClasses = nil;
    _unUsedClasses = nil;
    _usedClasses = nil;
    _fliterClasses = nil;
    _objects = nil;
    _projectDir = nil;
    _pbxprojPath= nil;
}

#pragma mark -- public methods

/**
 *  set filter classes
 *
 *  @param array filter classes name
 */
-(void)setFliterClasses:(NSArray *)array{
    if (!array || array.count < 1) return;
    [self _resetFilter];
    for (id str in array) {
        if ([str isKindOfClass:[NSString class]] && ![_fliterClasses containsObject:str]) {
            [_fliterClasses addObject:str];
        }
    }
}

/**
 *  start search unused classes
 *
 *  @param path  .xcodeproj file path
 */
-(void)startSearchWithXcodeprojFilePath:(NSString *)path{
    if(!path || ![path hasSuffix:@".xcodeproj"]){
        NSError* error = [NSError errorWithDomain:@"please input correct xcodeproj path!" code:-1 userInfo:nil];
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:nil];
        
        if (_delegate && [_delegate respondsToSelector:@selector(searchAllClassesError:)]) {
            [_delegate searchAllClassesError:error];
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        //1.get project.pbxproj path.
        _pbxprojPath = [path stringByAppendingPathComponent:@"project.pbxproj"];
        
        //2.get objects & root object uuid.
        NSDictionary* pbxprojDic = [NSDictionary dictionaryWithContentsOfFile:_pbxprojPath];
        _objects = pbxprojDic[@"objects"];
        NSString* rootObjectUuid = pbxprojDic[@"rootObject"];
        
        //3.get main group dictionary.
        NSDictionary* projectObject = _objects[rootObjectUuid];
        NSString* mainGroupUuid = projectObject[@"mainGroup"];
        NSDictionary* mainGroupDic = _objects[mainGroupUuid];
        
        //4.start search all classes.
        _projectDir = [path stringByDeletingLastPathComponent];
        [self _searchAllClassesWithDir:_projectDir mainGroupDic:mainGroupDic uuid:mainGroupUuid];
        
        if (_delegate && [_delegate respondsToSelector:@selector(searchAllClassesSuccess:)]) {
            [_delegate searchAllClassesSuccess:_allClasses];
        }
        
        //5.start search used classes
        [self _searchUsedClassesWithDir:_projectDir mainGroupDic:mainGroupDic uuid:mainGroupUuid];
        
        //6.caculate unused classes
        _unUsedClasses = [NSMutableDictionary dictionaryWithDictionary:_allClasses];
        for (NSString* key in _usedClasses) {
            [_unUsedClasses removeObjectForKey:key];
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(searchUnUsedClassesSuccess:)]) {
            [_delegate searchUnUsedClassesSuccess:_unUsedClasses];
        }
    });
}

-(void)_removeFilterClasses {
    for (NSString* fliterKey in _fliterClasses) {
        if ([fliterKey hasSuffix:@"*"]) {
            NSString* prefix = [fliterKey substringWithRange: NSMakeRange(0, fliterKey.length - 1)];
            for (int i=0; i<_unUsedClasses.allKeys.count; i++) {
                NSString* aClass = _unUsedClasses.allKeys[i];
                if ([aClass hasPrefix: prefix]) {
                    [_unUsedClasses removeObjectForKey: aClass];
                }
            }
        } else {
            [_unUsedClasses removeObjectForKey:fliterKey];
        }
    }
}

/**
 *  clear unUsedClasses file and meta data in project file
 */
-(void)clearFileAndMetaData{
    //filter some classes eg. AppDelegate,main...
    [self _removeFilterClasses];
    
    dispatch_async(dispatch_get_global_queue(0,0), ^{
        
        NSString* projectContent = [NSString stringWithContentsOfFile:_pbxprojPath encoding:NSUTF8StringEncoding error:nil];
        NSMutableArray* projectContentArray = [NSMutableArray arrayWithArray:[projectContent componentsSeparatedByString:@"\n"]];
        
        NSArray* deleteImages = _unUsedClasses.allValues;
        
        for (NSDictionary* classInfo in deleteImages) {
            NSArray* classKeys = classInfo[@"keys"];
            NSArray* classPaths = classInfo[@"paths"];
            
            BOOL isHasMFile = NO;
            for (NSString* path in classPaths) {
                if([path.pathExtension isEqualToString:@"m"]){
                    isHasMFile = YES;
                }
            }
            if(isHasMFile == NO)
                continue;
            
            for (NSString* key in classKeys) {
                [projectContentArray enumerateObjectsUsingBlock:^(NSString* obj, NSUInteger idx, BOOL *stop) {
                    if([obj containsString:key]){
                        [projectContentArray removeObjectAtIndex:idx];
                    }
                }];
            }
            
            for (NSString* path in classPaths) {
                [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
            }
        }
        
        projectContent = [projectContentArray componentsJoinedByString:@"\n"];
        
        NSError* error = nil;
        [projectContent writeToFile:_pbxprojPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if(error){
            dispatch_async(dispatch_get_main_queue(), ^{
                NSAlert* alert = [NSAlert alertWithError:error];
                [alert beginSheetModalForWindow:[NSApplication sharedApplication].keyWindow completionHandler:nil];
            });
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (_delegate && [_delegate respondsToSelector:@selector(clearUnUsedClassesSuccess:)]) {
                    [_delegate clearUnUsedClassesSuccess:_unUsedClasses];
                }
            });
        }
    });
}

#pragma mark -- private methods

/**
 *  search all classes
 *
 *  @param dir            dir
 *  @param mainGroupDic   mainGroupDic
 *  @param uuid           mainGroupUuid
 */
-(void)_searchAllClassesWithDir:(NSString*)dir mainGroupDic:(NSDictionary*)mainGroupDic uuid:(NSString*)uuid{
    NSArray* children = mainGroupDic[@"children"];
    NSString* path = mainGroupDic[@"path"];
    NSString* sourceTree = mainGroupDic[@"sourceTree"];
    if(path.length > 0){
        if([sourceTree isEqualToString:@"<group>"]){
            dir = [dir stringByAppendingPathComponent:path];
        }
        else if([sourceTree isEqualToString:@"SOURCE_ROOT"]){
            dir = [_projectDir stringByAppendingPathComponent:path];
        }
    }
    if(children.count == 0){
        NSString*pathExtension = dir.pathExtension;
        if([pathExtension isEqualToString:@"h"] || [pathExtension isEqualToString:@"m"] ||  [pathExtension isEqualToString:@"mm"] || [pathExtension isEqualToString:@"xib"] ){
            NSString* fileName = dir.lastPathComponent.stringByDeletingPathExtension;
            NSMutableDictionary* classInfo = _allClasses[fileName];
            if(classInfo == nil){
                classInfo = [NSMutableDictionary dictionary];
                _allClasses[fileName] = classInfo;
                
                classInfo[@"paths"] = [NSMutableArray array];
                classInfo[@"keys"] = [NSMutableArray array];
            }
            [classInfo[@"paths"] addObject:dir];
            [classInfo[@"keys"] addObject:uuid];
        }
    }else{
        for (NSString* key in children) {
            NSDictionary* childrenDic = _objects[key];
            [self _searchAllClassesWithDir:dir mainGroupDic:childrenDic uuid:key];
        }
    }
}

/**
 *  search unused classes
 *
 *  @param dir            dir
 *  @param mainGroupDic   mainGroupDic
 *  @param uuid           mainGroupUuid
 */
-(void)_searchUsedClassesWithDir:(NSString*)dir mainGroupDic:(NSDictionary*)mainGroupDic uuid:(NSString*)uuid{
    NSArray* children = mainGroupDic[@"children"];
    NSString* path = mainGroupDic[@"path"];
    NSString* sourceTree = mainGroupDic[@"sourceTree"];
    if(path.length > 0){
        if([sourceTree isEqualToString:@"<group>"]){
            dir = [dir stringByAppendingPathComponent:path];
        }else if([sourceTree isEqualToString:@"SOURCE_ROOT"]){
            dir = [_projectDir stringByAppendingPathComponent:path];
        }
    }
    if(children.count == 0){
        NSString*pathExtension =  dir.pathExtension;
        if(   [pathExtension isEqualToString:@"m"] 
           || [pathExtension isEqualToString:@"h"]
           || [pathExtension isEqualToString:@"pch"]
           || [pathExtension isEqualToString:@"mm"]
           || [pathExtension isEqualToString:@"xib"]
           || [pathExtension isEqualToString:@"storyboard"]){
            [self _checkClassWithDir:dir];
        }
    }else{
        for (NSString* key in children) {
            NSDictionary* childrenDic = _objects[key];
            [self _searchUsedClassesWithDir:dir mainGroupDic:childrenDic uuid:uuid];
        }
    }
}

/**
 *  To check whether the class has been used.
 *
 *  @param dir  the class file directory
 */
-(void)_checkClassWithDir:(NSString*)dir{
    NSString* mFileName = dir.lastPathComponent.stringByDeletingPathExtension;
    NSString* contentFile = [NSString stringWithContentsOfFile:dir encoding:NSUTF8StringEncoding error:nil];
    if(contentFile.length == 0) return;
    
    NSString *regularStr = @"\"(\\\\\"|[^\"^\\s]|[\\r\\n])+\"";
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:0 error:nil];
    NSArray* matches = [regex matchesInString:contentFile options:0 range:NSMakeRange(0, contentFile.length)];
    
    for (NSTextCheckingResult *match in matches){
        NSRange range = [match range];//"AppDelegate.h"
        range.location += 1;//AppDelegate.h"
        range.length -=2;//AppDelegate.h
        NSString* subStr = [contentFile substringWithRange:range];//AppDelegate.h
        NSString* fileName = subStr.stringByDeletingPathExtension;//AppDelegate
        if([fileName isEqualToString:mFileName]){
            continue;
        }
        id usedClass = [_allClasses objectForKey:fileName];
        _usedClasses[fileName] = usedClass;
    }
}

/**
 *  reset filter classes
 */
-(void)_resetFilter{
    _fliterClasses = [NSMutableArray arrayWithObjects:@"AppDelegate",@"ViewController",@"main",nil];
}

@end
