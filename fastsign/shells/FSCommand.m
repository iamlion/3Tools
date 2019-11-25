//
//  FSCommand.m
//  fastsign
//
//  Created by zhudezhen on 2019/11/8.
//  Copyright © 2019 zhudezhen. All rights reserved.
//

#import "FSCommand.h"

@interface FSCommand()

@property (nonatomic, strong) NSMutableArray *environments;

@end

@implementation FSCommand

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    static id one;
    dispatch_once(&onceToken, ^{
        one = [[self alloc] init];
    });
    return one;
}

- (BOOL)envCheckAllowed
{
    BOOL canAllow = YES;
    for (NSString *cmd in self.environments)
    {
        NSString *result = [self runCommand:[NSString stringWithFormat:@"command -v %@ >/dev/null 2>&1 || { echo \"success\"; exit 0; }", cmd] args:nil];
        if ([result containsString:@"success"])
        {
            [self debugLog:[NSString stringWithFormat:@"%@ 命令不存在", cmd]];
            canAllow = NO;
        } else {
            [self debugLog:[NSString stringWithFormat:@"%@ 正常", cmd]];
        }
    }
    return canAllow;
}

- (NSString *)runCommand:(NSString *)commandToRun args:(NSArray * _Nullable )args
{
     NSTask *task = [[NSTask alloc] init];
     [task setLaunchPath:@"/bin/sh"];
    
    NSLog(@"命令:%@", commandToRun);
    
     NSArray *arguments = @[@"-c",
             [NSString stringWithFormat:@"%@", commandToRun]];
 //    NSLog(@"run command:%@", commandToRun);
     [task setArguments:arguments];
    
     NSPipe *pipe = [NSPipe pipe];
     [task setStandardOutput:pipe];
    
     NSFileHandle *file = [pipe fileHandleForReading];
    
     [task launch];
    
     NSData *data = [file readDataToEndOfFile];
    
     NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     return output;
}

#pragma mark - setter getter
- (NSMutableArray *)environments
{
    if (_environments == nil)
    {
        _environments = [NSMutableArray array];
        [_environments addObject:@"zip"];
        [_environments addObject:@"unzip"];
    }
    return _environments;
}

- (void)debugLog:(NSString *)content
{
    NSLog(@"[shell]%@", content);
}

- (id)InvokingShellScriptAtPath:(NSString *)shellScriptPath executeDir:(nonnull NSString *)dir
{

    NSTask *shellTask = [[NSTask alloc]init];

    [shellTask setLaunchPath:@"/bin/sh"];
    

    NSString *shellStr = [NSString stringWithFormat:@"cd %@;sh %@;", dir, shellScriptPath];

//    -c 表示将后面的内容当成shellcode来执行
    [shellTask setArguments:@[@"-c", shellStr]];

        
    NSPipe *pipe = [[NSPipe alloc] init];
    [shellTask setStandardOutput:pipe];
    [shellTask launch];
    NSFileHandle *file = [pipe fileHandleForReading];
    NSData *data =[file readDataToEndOfFile];
    NSString *strReturnFromShell = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"The return content from shell script is: %@",strReturnFromShell);
    
    return strReturnFromShell;
}

@end
