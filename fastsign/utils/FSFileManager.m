//
//  FSFileManager.m
//  fastsign
//
//  Created by zhudezhen on 2019/11/13.
//  Copyright © 2019 zhudezhen. All rights reserved.
//

#import "FSFileManager.h"

@implementation FSFileManager

+ (NSString *)rootPath
{
    NSString *temp = NSTemporaryDirectory();
    NSString *dir = @"fsTemp";
    temp = [temp stringByAppendingPathComponent:dir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:temp] == NO )
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:temp withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return temp;
}

+ (NSString *)rootPath:(NSString *)dir
{
    NSString *rootPath = [FSFileManager rootPath];
    rootPath = [rootPath stringByAppendingPathComponent:dir];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath] == NO )
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return rootPath;
}

+ (void)createExsitDirectory:(NSString *)path
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO )
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

@end
