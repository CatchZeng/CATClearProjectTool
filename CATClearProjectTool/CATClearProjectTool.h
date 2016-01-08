//
//  CATClearProjectTool.h
//  CATClearProjectTool
//
//  Created by CatchZeng on 16/1/1.
//  Copyright © 2015年 catch. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CATClearProjectToolDelegate <NSObject>

@required
-(void)searchAllClassesSuccess:(NSMutableDictionary *)dic;
-(void)searchUnUsedClassesSuccess:(NSMutableDictionary *)dic;
-(void)clearUnUsedClassesSuccess:(NSMutableDictionary *)dic;

@optional
-(void)searchAllClassesError:(NSError *)error;
-(void)searchUnUsedClassesError:(NSError *)error;
-(void)clearUnUsedClassesError:(NSError *)error;

@end

@interface CATClearProjectTool : NSObject

@property (nonatomic,weak) id<CATClearProjectToolDelegate> delegate;


/**
 *  set filter classes. 
 *  the fliter classes will not be cleared
 *
 *  @param array filter classes name
 */
-(void)setFliterClasses:(NSArray *)array;

/**
 *  start search unused classes
 *
 *  @param path .xcodeproj file path
 */
-(void)startSearchWithXcodeprojFilePath:(NSString *)path;

/**
 *  clear unUsedClasses file and meta data in project file
 */
-(void)clearFileAndMetaData;

@end