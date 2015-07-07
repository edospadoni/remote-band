//
//  RemoteBandViewController.m
//  remote-band
//
//  Created by Edoardo Spadoni on 05/07/15.
//  Copyright (c) 2015 Edoardo Spadoni. All rights reserved.
//

#import "RemoteBandViewController.h"
#import <MIKMIDI/MIKMIDI.h>

@interface RemoteBandViewController ()

@property (nonatomic, strong) MIKMIDIDeviceManager *midiDeviceManager;
@property (nonatomic, strong) NSMapTable *connectionTokensForSources;

@end

@implementation RemoteBandViewController

- (id)init
{
    self = [super init];
    if (self) {
        self.connectionTokensForSources = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    self.midiDeviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
    [self.midiDeviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
    [self.midiDeviceManager addObserver:self forKeyPath:@"virtualSources" options:NSKeyValueObservingOptionInitial context:NULL];
    [self.midiDeviceManager addObserver:self forKeyPath:@"virtualDestinations" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (IBAction)quit:(NSButton *)sender {
    [self.midiDeviceManager removeObserver:self forKeyPath:@"availableDevices"];
    [self.midiDeviceManager removeObserver:self forKeyPath:@"virtualSources"];
    [self.midiDeviceManager removeObserver:self forKeyPath:@"virtualDestinations"];
    [[NSApplication sharedApplication] terminate:sender];
}

- (void)connectToSource:(MIKMIDISourceEndpoint *)source
{
    NSError *error = nil;
    id connectionToken = [self.midiDeviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
        for (MIKMIDIChannelVoiceCommand *command in commands) { [self handleMIDICommand:command]; }
    }];
    if (!connectionToken) {
        NSLog(@"Unable to connect to input: %@", error);
        return;
    }
    [self.connectionTokensForSources setObject:connectionToken forKey:source];
}

- (void)disconnectFromSource:(MIKMIDISourceEndpoint *)source
{
    if (!source) return;
    id token = [self.connectionTokensForSources objectForKey:source];
    if (!token) return;
    [self.midiDeviceManager disconnectInput:source forConnectionToken:token];
}

- (void)connectToDevice:(MIKMIDIDevice *)device
{
    if (!device) return;
    NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
    if (![sources count]) return;
    for (MIKMIDISourceEndpoint *source in sources) {
        [self connectToSource:source];
    }
}

- (void)disconnectFromDevice:(MIKMIDIDevice *)device
{
    if (!device) return;
    NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
    for (MIKMIDISourceEndpoint *source in sources) {
        [self disconnectFromSource:source];
    }
}

- (void)handleMIDICommand:(MIKMIDICommand *)command
{
    NSDictionary *activeApp = [[NSWorkspace sharedWorkspace] activeApplication];
    NSString *activeAppName = [activeApp objectForKey:@"NSApplicationName"];
    
    if([activeAppName isEqualToString:@"GarageBand"]) {
    
        NSString *commandView;
        if([command.data.description isEqualToString:@"<b00f0e45>"]) {
            commandView = @"Record";
            
            // R
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)15, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        if([command.data.description isEqualToString:@"<b00f0e44>"]) {
            commandView = @"Play";
            
            // spacebar
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)49, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        if([command.data.description isEqualToString:@"<b00f0e43>"]) {
            commandView = @"Stop";
            
            // return
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)36, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        
        if([command.data.description isEqualToString:@"<b00f0d43>"]) {
            commandView = @"Right";
            
            // right
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)124, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        if([command.data.description isEqualToString:@"<b00f0d41>"]) {
            commandView = @"Left";
            
            // left
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)123, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        
        if([command.data.description isEqualToString:@"<b00f0d44>"]) {
            commandView = @"Up";
            
            // up
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)126, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        if([command.data.description isEqualToString:@"<b00f0d40>"]) {
            commandView = @"Down";
            
            // down
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)125, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
        
        if([command.data.description isEqualToString:@"<b00f0d42>"]) {
            commandView = @"Center";
            
            // down
            CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)125, true);
            CGEventPost(kCGSessionEventTap, e);
            CFRelease(e);
        }
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"%@'s %@ changed to: %@", object, keyPath, [object valueForKeyPath:keyPath]);
}

#pragma mark - Devices

+ (NSSet *)keyPathsForValuesAffectingAvailableDevices
{
    return [NSSet setWithObject:@"midiDeviceManager.availableDevices"];
}

- (NSArray *)availableDevices
{
    NSArray *regularDevices = [self.midiDeviceManager availableDevices];
    NSMutableArray *result = [regularDevices mutableCopy];
    
    NSMutableSet *endpointsInDevices = [NSMutableSet set];
    for (MIKMIDIDevice *device in regularDevices) {
        NSSet *sources = [NSSet setWithArray:[device.entities valueForKeyPath:@"@distinctUnionOfArrays.sources"]];
        NSSet *destinations = [NSSet setWithArray:[device.entities valueForKeyPath:@"@distinctUnionOfArrays.destinations"]];
        [endpointsInDevices unionSet:sources];
        [endpointsInDevices unionSet:destinations];
    }
    
    NSMutableSet *devicelessSources = [NSMutableSet setWithArray:self.midiDeviceManager.virtualSources];
    NSMutableSet *devicelessDestinations = [NSMutableSet setWithArray:self.midiDeviceManager.virtualDestinations];
    [devicelessSources minusSet:endpointsInDevices];
    [devicelessDestinations minusSet:endpointsInDevices];
    
    // Now we need to try to associate each source with its corresponding destination on the same device
    NSMapTable *destinationToSourceMap = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
    NSMapTable *deviceNamesBySource = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    for (MIKMIDIEndpoint *source in devicelessSources) {
        NSMutableArray *sourceNameComponents = [[source.name componentsSeparatedByCharactersInSet:whitespace] mutableCopy];
        [sourceNameComponents removeLastObject];
        for (MIKMIDIEndpoint *destination in devicelessDestinations) {
            NSMutableArray *destinationNameComponents = [[destination.name componentsSeparatedByCharactersInSet:whitespace] mutableCopy];
            [destinationNameComponents removeLastObject];
            
            if ([sourceNameComponents isEqualToArray:destinationNameComponents]) {
                // Source and destination match
                [destinationToSourceMap setObject:destination forKey:source];
                
                NSString *deviceName = [sourceNameComponents componentsJoinedByString:@" "];
                [deviceNamesBySource setObject:deviceName forKey:source];
                break;
            }
        }
    }
    
    for (MIKMIDIEndpoint *source in destinationToSourceMap) {
        MIKMIDIEndpoint *destination = [destinationToSourceMap objectForKey:source];
        [devicelessSources removeObject:source];
        [devicelessDestinations removeObject:destination];
        
        MIKMIDIDevice *device = [MIKMIDIDevice deviceWithVirtualEndpoints:@[source, destination]];
        device.name = [deviceNamesBySource objectForKey:source];
        if (device) [result addObject:device];
    }
    for (MIKMIDIEndpoint *endpoint in devicelessSources) {
        MIKMIDIDevice *device = [MIKMIDIDevice deviceWithVirtualEndpoints:@[endpoint]];
        if (device) [result addObject:device];
    }
    for (MIKMIDIEndpoint *endpoint in devicelessSources) {
        MIKMIDIDevice *device = [MIKMIDIDevice deviceWithVirtualEndpoints:@[endpoint]];
        if (device) [result addObject:device];
    }
    
    return result;
}

- (void)setDevice:(MIKMIDIDevice *)device
{
    if (device != _device) {
        [self disconnectFromDevice:_device];
        _device = device;
        [self connectToDevice:_device];
    }
}

- (void)setSource:(MIKMIDISourceEndpoint *)source
{
    if (source != _source) {
        [self disconnectFromSource:_source];
        _source = source;
        [self connectToSource:_source];
    }
}

@end
