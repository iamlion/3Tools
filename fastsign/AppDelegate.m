//
//  AppDelegate.m
//  fastsign
//
//  Created by zhudezhen on 2019/11/8.
//  Copyright © 2019 zhudezhen. All rights reserved.
//

#import "AppDelegate.h"
#import "FSWindowController.h"

@interface AppDelegate ()

@property (nonatomic, strong) FSWindowController *mainViewController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    self.mainViewController = [[FSWindowController alloc] initWithWindowNibName:@"FSWindowController"];
    [self.mainViewController showWindow:self];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
