//
//  AppDelegate.h
//  remote-band
//
//  Created by Edoardo Spadoni on 05/07/15.
//  Copyright (c) 2015 Edoardo Spadoni. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

- (void)showPopup:(id)sender;
- (void)closePopup:(id)sender;
- (void)togglePopup:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSPopover  *popover;

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) NSStatusItem *statusItem;

@property (strong, nonatomic) NSEvent *popoverTransiencyMonitor;

@end

