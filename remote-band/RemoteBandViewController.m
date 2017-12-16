//
//  RemoteBandViewController.m
//  remote-band
//
//  Created by Edoardo Spadoni on 05/07/15.
//  Copyright (c) 2015 Edoardo Spadoni. All rights reserved.
//

#import "RemoteBandViewController.h"
#import <MIKMIDI/MIKMIDI.h>
#import <Carbon/Carbon.h>

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
    
    self.midiDeviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
    [self.midiDeviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
    [self.midiDeviceManager addObserver:self forKeyPath:@"virtualSources" options:NSKeyValueObservingOptionInitial context:NULL];
    [self.midiDeviceManager addObserver:self forKeyPath:@"virtualDestinations" options:NSKeyValueObservingOptionInitial context:NULL];
    
    
    [self setDevice:self.availableDevices[[self.availableDevices count]-1]];
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
    NSString *commandHash = command.data.description;
    
    // write to console the hash of your MIDI button
    NSLog(@"Command Hash: %@", commandHash);
    
    if (![activeAppName isEqual:@"GarageBand"] || commandHash == nil) {
        return;
    }

    // map the command hash to relative GarageBand actions
    NSDictionary *mapMIDI = @{
        @"<b00f0e45>": @(kVK_ANSI_R), //record
        @"<b00f0e44>": @(kVK_Space), //play
        @"<b00f0e43>": @(kVK_Return), //stop
        @"<b00f0d43>": @(kVK_RightArrow),
        @"<b00f0d41>": @(kVK_LeftArrow),
        @"<b00f0d44>": @(kVK_UpArrow),
        @"<b00f0d40>": @(kVK_DownArrow),
        @"<b00f0d42>": @(kVK_DownArrow),
    };
    
    NSNumber *keycode = mapMIDI[commandHash];
    if (keycode == nil) {
        return;
    }
    
    CGEventRef e = CGEventCreateKeyboardEvent (NULL, (CGKeyCode)keycode.integerValue, true);
    CGEventPost(kCGSessionEventTap, e);
    CFRelease(e);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    // NSLog(@"%@'s %@ changed to: %@", object, keyPath, [object valueForKeyPath:keyPath]);
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
