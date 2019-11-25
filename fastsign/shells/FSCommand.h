//
//  FSCommand.h
//  fastsign
//
//  Created by zhudezhen on 2019/11/8.
//  Copyright © 2019 zhudezhen. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FSCommand : NSObject

/// 单例
+ (instancetype)sharedInstance;

/// 检查当前计算机环境是否支持
- (BOOL)envCheckAllowed;

/// 执行 shell 指令
/// @param commandToRun shell命令
- (NSString *)runCommand:(NSString *)commandToRun args:(NSArray * _Nullable )args;

- (id)InvokingShellScriptAtPath:(NSString *)shellScriptPath executeDir:(NSString *)dir;

@end

NS_ASSUME_NONNULL_END
