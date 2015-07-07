//
//  RemoteBandViewController.h
//  remote-band
//
//  Created by Edoardo Spadoni on 05/07/15.
//  Copyright (c) 2015 Edoardo Spadoni. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIKMIDIDeviceManager;
@class MIKMIDIDevice;
@class MIKMIDISourceEndpoint;

@interface RemoteBandViewController : NSViewController

- (IBAction)quit:(NSButton *)sender;

@property (nonatomic, strong, readonly) NSArray *availableDevices;
@property (nonatomic, strong) MIKMIDIDevice *device;
@property (nonatomic, strong) MIKMIDISourceEndpoint *source;

@end
