//
//  AppDelegate.m
//  remote-band
//
//  Created by Edoardo Spadoni on 05/07/15.
//  Copyright (c) 2015 Edoardo Spadoni. All rights reserved.
//

#import "AppDelegate.h"
#import "RemoteBandViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    [self.statusItem setImage:[NSImage imageNamed:@"Control"]];
    [self.statusItem setHighlightMode:YES];
    
    [self.statusItem setAction:@selector(togglePopup:)];
    
    self.popover = [[NSPopover alloc] init];
    self.popover.contentViewController = [[RemoteBandViewController alloc] initWithNibName:@"RemoteBandViewController" bundle:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}

- (void)showPopup:(id)sender {
    NSStatusBarButton *buttonBar = [self.statusItem button];
    [self.popover showRelativeToRect:buttonBar.bounds ofView:buttonBar preferredEdge:NSMinYEdge];
}
- (void)closePopup:(id)sender {
    [self.popover performClose:sender];
}
- (void)togglePopup:(id)sender {
    if (self.popoverTransiencyMonitor == nil) {
        self.popoverTransiencyMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:(NSLeftMouseDownMask | NSRightMouseDownMask | NSKeyUpMask) handler:^(NSEvent* event) {
            [NSEvent removeMonitor:self.popoverTransiencyMonitor];
            self.popoverTransiencyMonitor = nil;
            [self.popover close];
        }];
    }
    
    if(self.popover.isShown) {
        [self closePopup:sender];
    } else {
        [self showPopup:sender];
    }
}

@end
