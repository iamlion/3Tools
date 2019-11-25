//
//  FSFileManager.h
//  fastsign
//
//  Created by zhudezhen on 2019/11/13.
//  Copyright © 2019 zhudezhen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSFileManager : NSObject

+ (NSString *)rootPath;

+ (NSString *)rootPath:(NSString *)dir;

+ (void)createExsitDirectory:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
