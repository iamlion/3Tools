//
//  FSWindowController.m
//  fastsign
//
//  Created by zhudezhen on 2019/11/8.
//  Copyright © 2019 zhudezhen. All rights reserved.
//

#import "FSWindowController.h"
#import "FSCommand.h"
#import "FSFileManager.h"
//#import "FSSignListWindowController.h"
 #import <CommonCrypto/CommonDigest.h>

@interface FSWindowController () <NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate, NSComboBoxDataSource, NSComboBoxDelegate>

#pragma mark - 不可修改
// 不可修改的bundleId显示标签
@property (weak) IBOutlet NSTextField *bundleIdLabel;

#pragma mark - 可以修改
// 应用名称
@property (weak) IBOutlet NSTextField *appNameLabel;
// 应用版本
@property (weak) IBOutlet NSTextField *appVersionLabel;
// 应用图标
@property (weak) IBOutlet NSImageView *appIcon;
// 应用描述文件名称
@property (weak) IBOutlet NSTextField *mobileProvisionLabel;
// 应用拓展分类描述文件信息
@property (weak) IBOutlet NSTableView *appexMobileProvisionList;
// 主面板
@property (weak) IBOutlet NSView *mainContentView;
// 应用描述文件图标
@property (weak) IBOutlet NSImageView *appmbIcon;

// loading提示
@property (weak) NSView *loadingView;

@property (weak) IBOutlet NSToolbarItem *exportBtn;
#pragma mark - 按钮
// 更改应用描述文件
@property (weak) IBOutlet NSButton *updateMobileProvisionBtn;
// 重签名按钮
@property (weak) IBOutlet NSButtonCell *reSignBtn;

@property (weak) IBOutlet NSComboBox *signKeyListCombbox;
@property (weak) IBOutlet NSTextField *signKeyIndeitfyLabel;
#pragma mark - 数据源
@property (nonatomic, strong) NSMutableArray *appexDataList;

#pragma mark - 业务核心
@property (nonatomic, strong) FSCommand *commond;
@property (nonatomic, strong) NSString *targetPath;
@property (nonatomic, strong) NSMutableDictionary *cache;
@property (nonatomic, strong) NSString *trashTempPath;
@property (nonatomic, strong) NSString *outputFilePath;
@property (nonatomic, strong) NSString *applicaitonName;
@property (nonatomic, strong) NSString *applicationMd5Path;
@property (nonatomic, strong) NSMutableArray *signTeamDataList;

// 新应用描述文件
@property (nonatomic, strong) NSString *nearestAppMbPath;
@property (nonatomic, strong) NSMutableDictionary *nearestAppexMbPath;
@property (nonatomic, strong) NSString *ipaPath;

//@property (nonatomic, strong) FSSignListWindowController *signListWindow;

@end

@implementation FSWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    
    // 设置TableView代理
    self.appexMobileProvisionList.delegate = self;
    self.appexMobileProvisionList.dataSource = self;
    self.appexMobileProvisionList.selectionHighlightStyle = NSTableViewSelectionHighlightStyleNone;
    
    [self.updateMobileProvisionBtn setTarget:self];
    [self.updateMobileProvisionBtn setAction:@selector(updateAppMobileprovisionFile:)];
    
    [self.reSignBtn setTarget:self];
    [self.reSignBtn setAction:@selector(reSignAction)];
    
    self.outputFilePath = [[FSFileManager rootPath] stringByAppendingPathComponent:@"ipa-output-list"];
    [FSFileManager createExsitDirectory:self.outputFilePath];
    
    self.appmbIcon.wantsLayer = YES;

    self.window.delegate = self;
    
    // 初始化钥匙列表
    [self initialCodeSigningList];
}

#pragma mark - 常用方法
- (void)showProgress
{
    if (self.loadingView == nil)
    {
        NSView *shadowView = [NSView new];
        shadowView.frame = CGRectMake(0, 0, self.mainContentView.frame.size.width, self.mainContentView.frame.size.height);
        shadowView.wantsLayer = true;///设置背景颜色
        shadowView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.6].CGColor;
        [self.mainContentView addSubview:shadowView];
        
        CGFloat size = 100;
        NSProgressIndicator *p = [NSProgressIndicator new];
        p.frame = CGRectMake((shadowView.frame.size.width - size)/2, (shadowView.frame.size.height - size)/2, size, size);
        [p startAnimation:nil];
        [shadowView addSubview:p];
        self.loadingView = shadowView;
    }
}

- (void)hideProgress
{
     [self.loadingView removeFromSuperview];
}

- (void)toast:(NSString *)message
{
    NSView *shadowView = [NSView new];
    shadowView.frame = CGRectMake(0, 0, self.mainContentView.frame.size.width, self.mainContentView.frame.size.height);
    shadowView.wantsLayer = true;///设置背景颜色
    shadowView.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0].CGColor;
    shadowView.layer.zPosition = 9999;
    [self.mainContentView addSubview:shadowView];
    
    NSView *canShaDowView = [NSView new];
    canShaDowView.wantsLayer = true;///设置背景颜色
    canShaDowView.layer.backgroundColor = [NSColor colorWithWhite:0 alpha:0.2].CGColor;
    canShaDowView.layer.cornerRadius = 5;
    [shadowView addSubview:canShaDowView];
        
    NSTextField *textFiled = [NSTextField new];
    textFiled.font = [NSFont systemFontOfSize:12];
    textFiled.frame = CGRectMake(0, 0, 120, 0);
    textFiled.stringValue = message;
    textFiled.bordered = NO;
    textFiled.editable = NO;
    textFiled.alignment = NSTextAlignmentCenter;
    textFiled.backgroundColor = [NSColor clearColor];
    [textFiled sizeToFit];
    [canShaDowView addSubview:textFiled];
    
    CGFloat w = textFiled.frame.size.width + 10;
    CGFloat h = textFiled.frame.size.height + 10;
    
    canShaDowView.frame = CGRectMake((shadowView.frame.size.width - w)/2,
                                     (shadowView.frame.size.height - h)/2,
                                     w, h);
    textFiled.frame = CGRectMake(5, 5,
                                 textFiled.frame.size.width, textFiled.frame.size.height);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [shadowView removeFromSuperview];
    });
}

- (NSString *)stringToMD5:(NSString *)str {
    // 1.首先将字符串转换成UTF-8编码, 因为MD5加密是基于C语言的,所以要先把字符串转化成C语言的字符串
    const char *fooData = [str UTF8String];
    // 2.然后创建一个字符串数组,接收MD5的值
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    // 3.计算MD5的值, 这是官方封装好的加密方法:把我们输入的字符串转换成16进制的32位数,然后存储到result中
    CC_MD5(fooData, (CC_LONG)strlen(fooData), result);
    /*
     第一个参数:要加密的字符串
     第二个参数: 获取要加密字符串的长度
     第三个参数: 接收结果的数组
    */
    // 4.创建一个字符串保存加密结果
    NSMutableString *saveResult = [NSMutableString string];
    // 5.从result 数组中获取加密结果并放到 saveResult中
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [saveResult appendFormat:@"%02x", result[i]];
    }

    // x表示十六进制，%02X  意思是不足两位将用0补齐，如果多余两位则不影响
    return saveResult;
}

- (void)initialCodeSigningList
{
    NSString *rlt = [self.commond runCommand:@"security find-identity -v -p codesigning" args:nil];
    NSArray *names = [rlt componentsSeparatedByString:@"\n"];
    for (NSString *codesigning in names)
    {
        NSArray *keyNames = [codesigning componentsSeparatedByString:@"\""];
        if (keyNames.count > 2)
        {
            NSString *keyName = [keyNames objectAtIndex:1];
            NSString *identify = [keyNames objectAtIndex:0];
            NSArray *identifys = [identify componentsSeparatedByString:@" "];
            identify = [identifys objectAtIndex:3];
            [self.signTeamDataList addObject:@{
                @"label":keyName,
                @"value":identify,
            }];
        }
    }
    self.signKeyListCombbox.dataSource = self;
    self.signKeyListCombbox.delegate = self;
    self.signKeyListCombbox.stringValue = [[self.signTeamDataList firstObject] objectForKey:@"label"];
    self.signKeyIndeitfyLabel.stringValue = [[self.signTeamDataList firstObject] objectForKey:@"value"];
}

#pragma mark - NSTableViewDelegate, NSTableViewDataSource
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return  self.appexDataList.count;
}



- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return  30;
}

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
//    return @"111";
//}
//
- (CGFloat)tableView:(NSTableView *)tableView sizeToFitWidthOfColumn:(NSInteger)column
{
    return 300;
}

- (NSView* )tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSInteger column = [tableView.tableColumns indexOfObject:tableColumn];
    NSDictionary *info = [self.appexDataList objectAtIndex:row];
    NSString *name = [info objectForKey:@"name"];
    NSTableCellView *cell = nil;
    if (column == 0)
    {
        // 第1列
        cell = [NSTableCellView new];
        
        NSTextField *textField = [NSTextField new];
        textField.stringValue = name ? :@"未知";
        [textField sizeToFit];
        CGSize size = textField.frame.size;
        textField.frame = CGRectMake(0, 2.5, size.width + 20, 25);
        textField.editable = NO;
        textField.bordered = NO;
        textField.backgroundColor = [NSColor clearColor];
//        textField.alignment = NSTextAlignmentCenter;
        [cell addSubview:textField];
    }
    else if (column == 1)
    {
       cell = [NSTableCellView new];
        
        NSString *key = [NSString stringWithFormat:@"row_key_%@", @(row)];
        NSButton *btn = [self.cache objectForKey:key];
        if (btn == nil)
        {
            // 第2列
            btn = [[NSButton alloc] initWithFrame:CGRectMake(10, 5, 60, 25)];
            [btn setBezelStyle:NSThickSquareBezelStyle];
            [btn setButtonType:NSMomentaryLightButton];
            [btn setAlignment:NSTextAlignmentCenter];
            [btn setFont:[NSFont systemFontOfSize:10]];
            [btn setSound:[NSSound soundNamed:@"Pop"]];
            [cell addSubview:btn];
            
            [btn setTag:row];
            [btn setTarget:self];
            [btn setAction:@selector(onTapRowItem:)];
        }
        
        NSString *nearestPath = [self.nearestAppexMbPath objectForKey:name];
        if (nearestPath.length > 0)
        {
            btn.title = @"已更新";
        } else {
            btn.title = @"更新";
        }

    }
    
    return cell;
}


//- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
//{
//    NSCell
//    NSCell *cell = [[NSCell alloc] init];
//    
//    return cell;
//}

#pragma mark - setter getter
- (NSMutableArray *)appexDataList
{
    if (_appexDataList == nil)
    {
        _appexDataList = [NSMutableArray array];
    }
    return _appexDataList;
}

- (FSCommand *)commond
{
    if (_commond == nil)
    {
        _commond = [FSCommand sharedInstance];
    }
    return _commond;
}

- (NSMutableDictionary *)nearestAppexMbPath
{
    if (_nearestAppexMbPath == nil)
    {
        _nearestAppexMbPath = [NSMutableDictionary dictionary];
    }
    return _nearestAppexMbPath;
}

- (NSMutableDictionary *)cache
{
    if (_cache == nil)
    {
        _cache = [NSMutableDictionary dictionary];
    }
    return _cache;
}

- (NSMutableArray *)signTeamDataList
{
    if (_signTeamDataList == nil)
    {
        _signTeamDataList = [NSMutableArray array];
    }
    return _signTeamDataList;
}

#pragma mark - 点击事件

- (IBAction)onTapImportIPA:(id)sender {
    
    
    NSOpenPanel *p = [NSOpenPanel new];
    NSModalResponse response = [p runModal];
    if (response == NSModalResponseOK)
    {
       
        
        // 重置状态
        self.targetPath = nil;
        self.cache = nil;
        self.trashTempPath = nil;
        self.applicaitonName = nil;
        self.applicationMd5Path = nil;
        self.nearestAppMbPath = nil;
        self.nearestAppexMbPath = nil;
        self.ipaPath = nil;
        self.signKeyListCombbox.stringValue = [[self.signTeamDataList firstObject] objectForKey:@"label"];
        self.signKeyIndeitfyLabel.stringValue = [[self.signTeamDataList firstObject] objectForKey:@"value"];
        self.updateMobileProvisionBtn.title = @"更新";
        self.appmbIcon.layer.backgroundColor = [NSColor clearColor].CGColor;
       
        __block NSString *path = p.URL.absoluteString;
        NSString *lastFileExtension = [[path componentsSeparatedByString:@"/"] lastObject];
        lastFileExtension = [[lastFileExtension componentsSeparatedByString:@"."] lastObject];
        if ([lastFileExtension isEqualToString:@"ipa"] == NO)
        {
            [self toast:@"请上传合法的IPA文件！"];
            return ;
        }
        
        [self showProgress];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            
            NSString *rootPath = [FSFileManager rootPath];
            
            path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            path = [path stringByRemovingPercentEncoding];
            
            // 将路径查看是否已经存在
            NSString *md5 = [self stringToMD5:path];
            NSString *target = [rootPath stringByAppendingPathComponent:md5];
            self.applicationMd5Path = target;
            
            // 如果存在同样的地址就删除
            if ([[NSFileManager defaultManager] fileExistsAtPath:target] == YES)
            {
                // 移除垃圾文件
                [[NSFileManager defaultManager] removeItemAtPath:self.applicationMd5Path error:nil];
            }
            
            // 设置临时目录
            self.trashTempPath = [target stringByAppendingPathComponent:@"temps"];
            target = [target stringByAppendingPathComponent:@"ipas"];
            
            // 创建目录
            [FSFileManager createExsitDirectory:target];
            
            [self.commond runCommand:[NSString stringWithFormat:@"rm -rf %@", target] args:nil];
            [self.commond runCommand:[NSString stringWithFormat:@"unzip -d %@ %@", target, path]  args:nil];
            [self.commond runCommand:@"exit 1;" args:nil];
            
            // **/*/ipas/Payload
            target = [target stringByAppendingPathComponent:@"Payload"];
            
            NSArray<NSString *> *subNames = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:target error:nil];
            for (NSString *subfileName in subNames)
            {
                if ([subfileName containsString:@".app"])
                {
                    target = [target stringByAppendingPathComponent:subfileName];
                    break;
                }
            }
            
            
            self.targetPath = target;
            
            // **/*/temps/
            // 1. 提取旧版描述文件中的 info.plist 文件信息
//            NSString *trashPath = [rootPath stringByAppendingPathComponent:@"temps"];
            [FSFileManager createExsitDirectory:self.trashTempPath];
            
            // 2.1 获取 info.plist 信息
            NSString *originInfoPlist = [target stringByAppendingPathComponent:@"Info.plist"];
            
            // 获取应用信息
            NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:originInfoPlist];
            NSString *CFBundleDisplayName = [data objectForKey:@"CFBundleDisplayName"];
            NSString *CFBundleIdentifier = [data objectForKey:@"CFBundleIdentifier"];
            NSString *CFBundleShortVersionString = [data objectForKey:@"CFBundleShortVersionString"];
            // 获取图标
            NSDictionary *CFBundleIcons = [data objectForKey:@"CFBundleIcons"];
            NSDictionary *CFBundlePrimaryIcon = [CFBundleIcons objectForKey:@"CFBundlePrimaryIcon"];
            NSArray *CFBundleIconFiles = [CFBundlePrimaryIcon objectForKey:@"CFBundleIconFiles"];
            NSString *appIcon = [CFBundleIconFiles lastObject];
            // 获取应用描述文件地址
            __block NSString *mppath = [target stringByAppendingPathComponent:@"embedded.mobileprovision"];
            // 获取应用拓展分类信息
            __weak __typeof(self) weakSelf = self;
            weakSelf.appexDataList = nil;
            [self recursivePath:target plugins:^(NSDictionary *info) {
                NSMutableDictionary *itemDic = info.mutableCopy;
                NSString *p = [itemDic objectForKey:@"path"];
                [itemDic setValue:[p stringByAppendingPathComponent:@"embedded.mobileprovision"] forKey:@"mb"];
                [weakSelf.appexDataList addObject:itemDic];
            }];
            
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.appNameLabel.stringValue = CFBundleDisplayName;
                self.bundleIdLabel.stringValue = CFBundleIdentifier;
                self.appVersionLabel.stringValue = CFBundleShortVersionString;
                self.appmbIcon.image = [NSImage imageNamed:@"mbicon"];
                self.appmbIcon.layer.backgroundColor = [NSColor colorWithRed:252.0/255.0 green:252.0/255.0 blue:252.0/255.0 alpha:1.0].CGColor;
                
                self.appIcon.image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfFile:[target stringByAppendingPathComponent:[appIcon stringByAppendingString:@"@2x.png"]]]];
                
                if ([[NSFileManager defaultManager] fileExistsAtPath:mppath])
                {
                    mppath = [mppath stringByReplacingOccurrencesOfString:[FSFileManager rootPath] withString:@""];
                    self.mobileProvisionLabel.stringValue = mppath;
                }
                
                [self.appexMobileProvisionList reloadData];
                
                
                [self hideProgress];
            });
        });
        
    }
    
}

- (void)updateAppMobileprovisionFile:(NSButton *)sender
{
    
    if (self.targetPath.length <= 0)
    {
        [self toast:@"请上传iPA应用包"];
        return ;
    }

    NSOpenPanel *p = [NSOpenPanel new];
    NSModalResponse response = [p runModal];
    if (response == NSModalResponseOK)
    {
        __block NSString *path = p.URL.absoluteString;
        path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        path = [path stringByRemovingPercentEncoding];
        self.nearestAppMbPath = path;
        self.updateMobileProvisionBtn.title = @"已更新";
        
        // 解析签名证书
        NSString *plistPath = [self.trashTempPath stringByAppendingString:@"temp-update-info.plist"];
        [self.commond runCommand:[NSString stringWithFormat:@"security cms -D -i \"%@\" > \"%@\"", path, plistPath] args:nil];
        
//        NSDictionary *info = [[NSDictionary alloc] initWithContentsOfFile:plistPath];
//        NSString *TeamName = [info objectForKey:@"TeamName"];
//        if (TeamName.length > 0)
//        {
//            for (NSDictionary *dic in self.signTeamDataList)
//            {
//                NSString *key = [dic objectForKey:@"label"];
//                if ([key containsString:TeamName])
//                {
//                    self.signKeyListCombbox.stringValue = key;
//                    self.signKeyIndeitfyLabel.stringValue = [dic objectForKey:@"value"];
//                    return ;
//                }
//            }
//        }
    }
}

- (void)onTapRowItem:(NSButton *)sender
{
    if (self.targetPath.length <= 0)
    {
        [self toast:@"请上传iPA应用包"];
        return ;
    }
    
    NSOpenPanel *p = [NSOpenPanel new];
    NSModalResponse response = [p runModal];
    if (response == NSModalResponseOK)
    {
        NSDictionary *info = [self.appexDataList objectAtIndex:sender.tag];
        NSString *name = [info objectForKey:@"name"];
        name = [[name componentsSeparatedByString:@"."] firstObject];
        __block NSString *path = p.URL.absoluteString;
        if (path.length > 0)
        {
            path = [path stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            path = [path stringByRemovingPercentEncoding];
            
            NSString *trashPath = self.trashTempPath;
            NSString *newPath = [trashPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mobileprovision", name]];
            [self.commond runCommand:[NSString stringWithFormat:@"cp %@ %@", path, newPath] args:nil];
            
            [self.nearestAppexMbPath setObject:newPath forKey:name];
            sender.title = @"已更新";
        }
    }
}

- (void)reSignAction
{
    
    if (self.nearestAppMbPath.length <= 0)
    {
        [self toast:@"请上传应用新描述文件"];
        return ;
    }
    
//    if ((self.appexDataList.count > 0) && (self.nearestAppexMbPath.count < self.appexDataList.count))
//    {
//        [self toast:@"请上传拓展应用新描述文件"];
//        return ;
//    }
    

    [self showProgress];
    // 递归遍历目录
    __weak __typeof(self) weakSelf = self;
    __block NSString *appName = self.appNameLabel.stringValue;
    __block NSString *appVersion = self.appVersionLabel.stringValue;
    // 获取当前选择的签名证书
    __block NSString *teamName = self.signKeyIndeitfyLabel.stringValue;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // 修改名字和版本号
        NSString *iPlistPath = [self.targetPath stringByAppendingPathComponent:@"Info.plist"];
        // 备份该文件
        NSString *iPlistBakPath = [self.trashTempPath stringByAppendingPathComponent:@"Info-bak.plist"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:iPlistBakPath] == YES)
        {
            [[NSFileManager defaultManager] removeItemAtPath:iPlistBakPath error:nil];
        }
        [[NSFileManager defaultManager] copyItemAtPath:iPlistPath toPath:iPlistBakPath error:nil];
        NSMutableDictionary *iPlistInfo = [[NSDictionary alloc] initWithContentsOfFile:iPlistPath].mutableCopy;
        if (appName.length > 0)
        {
            [iPlistInfo setObject:appName forKey:@"CFBundleDisplayName"];
        }
        if (appVersion.length > 0)
        {
            [iPlistInfo setObject:appVersion forKey:@"CFBundleShortVersionString"];
        }
        NSString *xml = [self infoPlitDic2XML:iPlistInfo];
        [[xml dataUsingEncoding:NSUTF8StringEncoding] writeToFile:iPlistPath atomically:YES];
        
        
        // 对 appex 进行签名
        [self recursivePath:self.targetPath plugins:^(NSDictionary *dic) {
            NSString *fileName = [dic objectForKey:@"name"];
            NSString *name = [[fileName componentsSeparatedByString:@"."] firstObject];
            NSString *newAppexMbPath =  [weakSelf.nearestAppexMbPath objectForKey:name];;
            NSString *targetPath = [dic objectForKey:@"path"];
            if (newAppexMbPath.length > 0)
            {
                [weakSelf reSignFullAction:targetPath newMpPath:newAppexMbPath name:name teamName:teamName];
            }
        }];
        
        NSString *fileName = [[self.targetPath componentsSeparatedByString:@"/"] lastObject];
        fileName = [[fileName componentsSeparatedByString:@"."] firstObject];
        
        // 替换新的描述文件
        [self reSignFullAction:self.targetPath newMpPath:self.nearestAppMbPath name:fileName teamName:teamName];
        
        // 获取当前时间
        NSDate *now = [NSDate new];
        NSTimeInterval timestamp = now.timeIntervalSince1970*1000;
        NSString *newIpaName = [NSString stringWithFormat:@"%@-%@.ipa", fileName, @(floor(timestamp))];
        NSString *newIpaPath = [self.outputFilePath stringByAppendingPathComponent:newIpaName];
        // 签名完成打包 Payload
        [self.commond runCommand:[NSString stringWithFormat:@"cd %@;cd ../../;zip -r \"./New.ipa\" \"./Payload\";mv ./New.ipa %@", self.targetPath, newIpaPath] args:nil];
        
        // 移除垃圾文件
//        [[NSFileManager defaultManager] removeItemAtPath:self.applicationMd5Path error:nil];

//        NSLog(@"%@", self.outputFilePath);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf hideProgress];
            // 导出iPA
            NSSavePanel *saveDlg = [[NSSavePanel alloc]init];
            saveDlg.title = [NSString stringWithFormat:@"%@, 签名成功", fileName];
            saveDlg.message = @"将新的iPA文件导出至指定目录？";
            saveDlg.allowedFileTypes = @[@"ipa"];
            saveDlg.nameFieldStringValue = newIpaName;
            [saveDlg beginWithCompletionHandler: ^(NSInteger result){
                if(result == NSFileHandlingPanelOKButton){
                    NSURL *url =[saveDlg URL];
                    [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:newIpaPath] toURL:url error:nil];
                    // 打开指定目录
                    NSString *targetPath = url.absoluteString;
                    targetPath = [targetPath stringByReplacingOccurrencesOfString:@"file://" withString:@""];
                    NSString *lastName = [[targetPath componentsSeparatedByString:@"/"] lastObject];
                    targetPath = [targetPath stringByReplacingOccurrencesOfString:lastName withString:@""];
                    [weakSelf.commond runCommand:[NSString stringWithFormat:@"open %@", [targetPath stringByRemovingPercentEncoding]] args:nil];
                }
            }];
        });
    });
}

- (void)recursivePath:(NSString *)path plugins:(void(^)(NSDictionary *))handler
{
    NSString *fileName = [[path componentsSeparatedByString:@"/"] lastObject];
    
    if ([fileName containsString:@".appex"])
    {
        if (handler) handler(@{@"path":path, @"name":fileName});
        return ;
    }
    
    NSError *error;
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if (array.count > 0)
    {
        for (NSString *itemPath in array)
        {
            NSString *subPath = [path stringByAppendingPathComponent:itemPath];
            [self recursivePath:subPath plugins:handler];
        }
    }
}


- (void)reSignFullAction:(NSString *)signPath newMpPath:(NSString *)newMpPath name:(NSString *)name teamName:(NSString *)teamName
{
    // 替换新的描述文件
    NSString *originMobileProvisionPath = [signPath stringByAppendingPathComponent:@"embedded.mobileprovision"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:originMobileProvisionPath error:nil];
    [fileManager copyItemAtPath:newMpPath toPath:originMobileProvisionPath error:nil];

    // 转换 info.plist 文件
    NSString *tempEnttilePlistFilePath = [self.trashTempPath stringByAppendingPathComponent:@"entitleTemp.plist"];
    [self.commond runCommand:[NSString stringWithFormat:@"security cms -D -i \"%@\" > \"%@\"", originMobileProvisionPath, tempEnttilePlistFilePath] args:nil];

    // 提取 Entitlements 字段，并且写入本地文件
    NSDictionary *tempEnttilePlist = [[NSDictionary alloc] initWithContentsOfFile:tempEnttilePlistFilePath];
    NSDictionary *EntitlementsDic = [tempEnttilePlist objectForKey:@"Entitlements"];
    NSString *xmlString = [self infoPlitDic2XML:EntitlementsDic];
    NSData *xmlDs = [xmlString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *tempEntitlementsPath = [self.trashTempPath stringByAppendingPathComponent:[NSString stringWithFormat:@"entitlements-%@-temp.plist", name]];
    [xmlDs writeToFile:tempEntitlementsPath atomically:YES];

    // 提取 TeamName 名称
    if (teamName.length <= 0)
    {
        [self toast:@"请选择签名证书"];
        return;
    }
//    if (teamName.length <= 0)
//        TeamName = [tempEnttilePlist objectForKey:@"TeamName"];

    // 对目录进行重签名
    //  codesign -f -s "${PARAM_DEVELOPTEAM}" --entitlements "${_plistPath}" "${_path}"
    [self.commond runCommand:[NSString stringWithFormat:@"codesign -f -s \"%@\" --entitlements \"%@\" \"%@\" ", teamName, tempEntitlementsPath, signPath] args:nil];
}

- (NSString *)infoPlitDic2XML:(NSDictionary *)dictionary
{
    NSMutableString *xml = [NSMutableString string];
    [xml appendString:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"];
    [xml appendString:@"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"];
    [xml appendString:@"<plist version=\"1.0\">\n"];
    [xml appendString:@"<dict>\n"];
    [xml appendString:[self dictionary2XML:dictionary prefix:@"\t"]];
    [xml appendString:@"</dict>\n"];
    [xml appendString:@"</plist>\n"];
    return  xml;
}

- (NSString *)dictionary2XML:(NSDictionary *)dictionary prefix:(NSString *)prefix
{
    NSMutableString *xml = [NSMutableString string];
    if (prefix.length <= 0)
    {
        prefix = @"\t";
    }
    for (NSString *key in dictionary.allKeys)
    {
        id obj = [dictionary objectForKey:key];
        [xml appendFormat:@"%@<key>%@</key>\n", prefix, key];
        if ([obj isKindOfClass:[NSString class]])
        {
            NSString *value = (NSString *)obj;
            [xml appendFormat:@"%@<string>%@</string>\n", prefix, value];
        }
        else if ([obj isKindOfClass:NSClassFromString(@"__NSCFBoolean")])
        {
            BOOL value = [obj boolValue];
            [xml appendFormat:@"%@<%@/>\n", prefix, value?@"true":@"false"];
        }
        else if ([obj isKindOfClass:[NSNumber class]])
        {
            NSInteger value = [obj integerValue];
            [xml appendFormat:@"%@<integer>%@</integer>\n", prefix, @(value)];
        }
        else if ([obj isKindOfClass:[NSDate class]])
        {
            NSDate *value = (NSDate *)obj;
            NSDateFormatter *dateFormat = [NSDateFormatter new];
            // 2019-11-24T02:51:02Z
            dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssXXX";
            dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            [xml appendFormat:@"%@<date>%@</date>\n", prefix, [dateFormat stringFromDate:value]];
        }
        else if ([obj isKindOfClass:[NSData class]])
        {
            NSData *value = (NSData *)obj;
            NSData *base64Data = [value base64EncodedDataWithOptions:(NSDataBase64Encoding64CharacterLineLength)];
            NSString *base64Str = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
            [xml appendFormat:@"%@<data>%@</data>\n", prefix, base64Str];
        }
        else if ([obj isKindOfClass:[NSArray class]])
        {
            NSArray *value = (NSArray *)obj;
            if (value.count > 0)
            {
                [xml appendFormat:@"%@<array>\n", prefix];
                for (id item in value)
                {
                    NSString *subXml = [self obj2XML:key input:item prefix:@"\t\t\t"];
                    [xml appendString:subXml];
                }
                [xml appendFormat:@"%@</array>\n", prefix];
            }
            else
            {
                 [xml appendFormat:@"%@<array/>\n", prefix];
            }
        }
        else if ([obj isKindOfClass:[NSDictionary class]])
        {
            NSDictionary *value = (NSDictionary *)obj;
            if (value.allValues.count > 0)
            {
                [xml appendFormat:@"%@<dict>\n", prefix];
                [xml appendString:[self dictionary2XML:value prefix:[prefix stringByAppendingString:@"\t\t"]]];
                [xml appendFormat:@"%@</dict>\n", prefix];
            }
            else
            {
                [xml appendFormat:@"%@<dict/>\n", prefix];
            }
        }
    }
    return xml;
}

- (NSString *)obj2XML:(NSString *)key input:(id)obj prefix:(NSString *)prefix
{
    NSMutableString *xml = [NSMutableString string];
    if ([obj isKindOfClass:[NSString class]])
    {
        NSString *value = (NSString *)obj;
        [xml appendFormat:@"%@<string>%@</string>\n", prefix, value];
    }
    else if ([obj isKindOfClass:NSClassFromString(@"__NSCFBoolean")])
    {
        BOOL value = [obj boolValue];
        [xml appendFormat:@"%@<%@/>\n", prefix, value?@"true":@"false"];
    }
    else if ([obj isKindOfClass:[NSNumber class]])
    {
        NSInteger value = [obj integerValue];
        [xml appendFormat:@"%@<integer>%@</integer>\n", prefix, @(value)];
    }
    else if ([obj isKindOfClass:[NSDate class]])
    {
        NSDate *value = (NSDate *)obj;
        NSDateFormatter *dateFormat = [NSDateFormatter new];
        // 2019-11-24T02:51:02Z
        dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssXXX";
        dateFormat.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [xml appendFormat:@"%@<date>%@</date>\n", prefix, [dateFormat stringFromDate:value]];
    }
    else if ([obj isKindOfClass:[NSData class]])
    {
        NSData *value = (NSData *)obj;
        NSData *base64Data = [value base64EncodedDataWithOptions:(NSDataBase64Encoding64CharacterLineLength)];
        NSString *base64Str = [[NSString alloc] initWithData:base64Data encoding:NSUTF8StringEncoding];
        [xml appendFormat:@"%@<data>%@</data>\n", prefix, base64Str];
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        NSArray *value = (NSArray *)obj;
        if (value.count > 0)
        {
            [xml appendFormat:@"%@<array>\n", prefix];
            for (id item in value)
            {
                NSString *subXml = [self obj2XML:key input:item prefix:[prefix stringByAppendingString:@"\t\t"]];
                [xml appendString:subXml];
            }
            [xml appendFormat:@"%@</array>\n", prefix];
        }
        else
        {
             [xml appendFormat:@"%@<array/>\n", prefix];
        }
    }
    else if ([obj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *value = (NSDictionary *)obj;
        if (value.allValues.count > 0)
        {
            [xml appendFormat:@"%@<dict>\n", prefix];
            [xml appendString:[self dictionary2XML:value prefix:[prefix stringByAppendingString:@"\t\t"]]];
            [xml appendFormat:@"%@</dict>\n", prefix];
        }
        else
        {
            [xml appendFormat:@"%@<dict/>\n", prefix];
        }
    }
    
    return xml;
}

- (IBAction)openSingListView:(id)sender {
    // 打开签名列表
    [self.commond runCommand:[NSString stringWithFormat:@"open %@", self.outputFilePath] args:nil];
//    if (self.signListWindow == nil)
//    {
//        FSSignListWindowController *fsSignListView = [[FSSignListWindowController alloc] initWithWindowNibName:@"FSSignListWindowController"];
//        [self.window beginSheet:fsSignListView.window completionHandler:^(NSModalResponse returnCode) {
//
//            self.signListWindow = nil;
//        }];
//        self.signListWindow = fsSignListView;
//    }
}



#pragma mark - NSWindowDelegate
- (BOOL)windowShouldClose:(NSWindow *)sender
{
    // 退出软件
    exit(0);
    return NO;
}


#pragma mark - NSComboBoxDataSource, NSComboBoxDelegate
- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)comboBox
{
    return self.signTeamDataList.count;
}

- (id)comboBox:(NSComboBox *)comboBox objectValueForItemAtIndex:(NSInteger)index
{
    NSDictionary *dic = [self.signTeamDataList objectAtIndex:index];
    
    return [dic objectForKey:@"label"];
}

- (void)comboBoxSelectionDidChange:(NSNotification *)notification
{
    NSDictionary *item = [self.signTeamDataList objectAtIndex:self.signKeyListCombbox.indexOfSelectedItem];
    self.signKeyListCombbox.stringValue = [item objectForKey:@"label"];
    self.signKeyIndeitfyLabel.stringValue = [item objectForKey:@"value"];
}





@end
