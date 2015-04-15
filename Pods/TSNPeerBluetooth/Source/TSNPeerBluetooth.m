//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Brian Lambert.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  TSNPeerBluetooth
//  TSNPeerBluetooth.m
//

#import <pthread.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "TSNPeerBluetooth.h"

// WHPErrorCode enumeration.
typedef NS_ENUM(NSUInteger, TSNPeerDescriptorState)
{
    TSNPeerDescriptorStateDisconnected  = 1,
    TSNPeerDescriptorStateConnecting    = 2,
    TSNPeerDescriptorStateInitializing  = 3,
    TSNPeerDescriptorStateConnected     = 4
};

// TSNPeerDescriptor interface.
@interface TSNPeerDescriptor : NSObject

// Properties.
@property (nonatomic) NSUUID * peerID;
@property (nonatomic) NSString * peerName;
@property (nonatomic) CLLocation * peerLocation;
@property (nonatomic) TSNPeerDescriptorState state;

// Class initializer.
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                      initialState:(TSNPeerDescriptorState)initialState;

@end

// TSNPeerDescriptor implementation.
@implementation TSNPeerDescriptor
{
@private
    // The peripheral.
    CBPeripheral * _peripheral;
}

// Class initializer.
- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral
                      initialState:(TSNPeerDescriptorState)initialState
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _peripheral = peripheral;
    _state = initialState;

    // Done.
    return self;
}

@end

// TSNPeerBluetooth (CBPeripheralManagerDelegate) interface.
@interface TSNPeerBluetooth (CBPeripheralManagerDelegate) <CBPeripheralManagerDelegate>
@end

// TSNPeerBluetooth (CBCentralManagerDelegate) interface.
@interface TSNPeerBluetooth (CBCentralManagerDelegate) <CBCentralManagerDelegate>
@end

// TSNPeerBluetooth (CBPeripheralDelegate) interface.
@interface TSNPeerBluetooth (CBPeripheralDelegate) <CBPeripheralDelegate>
@end

// TSNPeerBluetooth (Internal) interface.
@interface TSNPeerBluetooth (Internal)

// Starts advertising.
- (void)startAdvertising;

// Stops advertising.
- (void)stopAdvertising;

// Starts scanning.
- (void)startScanning;

// Stops scanning.
- (void)stopScanning;

// Updates the peer name characteristic.
- (void)updatePeerNameCharacteristic;

// Updates the peer location characteristic.
- (void)updatePeerLocationCharacteristic;

// Updates the peer status characteristic.
- (void)updatePeerStatusCharacteristic:(NSString *)peerMessage;

// Gets the peer location data.
- (NSData *)peerLocationData;

@end

// TSNPeerBluetooth implementation.
@implementation TSNPeerBluetooth
{
@private
    // The peer identifier.
    NSUUID * _peerIdentifier;
    
    // The peer name.
    NSString * _peerName;
    
    // The canonical peer name.
    NSData * _canonicalPeerName;
    
    // The enabled flag.
    BOOL _enabled;
    
    // The scanning flag.
    BOOL _scanning;

    // The service type.
    CBUUID * _serviceType;
    
    // The peer ID type.
    CBUUID * _peerIDType;

    // The peer name type.
    CBUUID * _peerNameType;
    
    // The peer location type.
    CBUUID * _peerLocationType;

    // The peer status type.
    CBUUID * _peerStatusType;
    
    // The service.
    CBMutableService * _service;
    
    // The peer ID characteristic.
    CBMutableCharacteristic * _characteristicPeerID;

    // The peer name characteristic.
    CBMutableCharacteristic * _characteristicPeerName;
    
    // The peer locaton characteristic.
    CBMutableCharacteristic * _characteristicPeerLocation;

    // The peer status characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus;

    // The advertising data.
    NSDictionary * _advertisingData;
    
    // The peripheral manager.
    CBPeripheralManager * _peripheralManager;
    
    // The central manager.
    CBCentralManager * _centralManager;
    
    // Mutex used to synchronize accesss to peers.
    pthread_mutex_t _mutex;
    
    // The last location coordinate.
    CLLocationCoordinate2D _lastLocationCoordinate;

    // The peers dictionary.
    NSMutableDictionary * _peers;
}

// Class initializer.
- (instancetype)initWithServiceType:(NSUUID *)serviceType
                     peerIdentifier:(NSUUID *)peerIdentifier
                           peerName:(NSString *)peerName
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _serviceType = [CBUUID UUIDWithNSUUID:serviceType];
    _peerIdentifier = peerIdentifier;
    _peerName = peerName;
    _canonicalPeerName = [_peerName dataUsingEncoding:NSUTF8StringEncoding];
    
    UInt8 uuid[16];
    [_peerIdentifier getUUIDBytes:uuid];
    NSData * peerIdentifierValue = [NSData dataWithBytes:uuid
                                                  length:sizeof(uuid)];
    
    // Allocate and initialize the peer ID type.
    _peerIDType = [CBUUID UUIDWithString:@"E669893C-F4C2-4604-800A-5252CED237F9"];
    
    // Allocate and initialize the peer name type.
    _peerNameType = [CBUUID UUIDWithString:@"2EFDAD55-5B85-4C78-9DE8-07884DC051FA"];
    
    // Allocate and initialize the peer location type.
    _peerLocationType = [CBUUID UUIDWithString:@"1EA08229-38D7-4927-98EC-113723C30C1B"];

    // Allocate and initialize the peer status type.
    _peerStatusType = [CBUUID UUIDWithString:@"3211022A-EEF4-4522-A5CE-47E60342FFB5"];
    
    // Allocate and initialize the service.
    _service = [[CBMutableService alloc] initWithType:_serviceType
                                              primary:YES];
    
    // Allocate and initialize the peer ID characteristic.
    _characteristicPeerID = [[CBMutableCharacteristic alloc] initWithType:_peerIDType
                                                               properties:CBCharacteristicPropertyRead
                                                                    value:peerIdentifierValue
                                                              permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the peer name characteristic.
    _characteristicPeerName = [[CBMutableCharacteristic alloc] initWithType:_peerNameType
                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
                                                                      value:nil
                                                                permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the peer location characteristic.
    _characteristicPeerLocation = [[CBMutableCharacteristic alloc] initWithType:_peerLocationType
                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
                                                                      value:nil
                                                                permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the peer status characteristic.
    _characteristicPeerStatus = [[CBMutableCharacteristic alloc] initWithType:_peerStatusType
                                                                   properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
                                                                        value:nil
                                                                  permissions:CBAttributePermissionsReadable];

    // Set the service characteristics.
    [_service setCharacteristics:@[_characteristicPeerID,
                                   _characteristicPeerName,
                                   _characteristicPeerLocation,
                                   _characteristicPeerStatus]];
    
    // Allocate and initialize the advertising data.
    _advertisingData = @{CBAdvertisementDataServiceUUIDsKey:    @[_serviceType],
                         CBAdvertisementDataLocalNameKey:       _peerName};
    
    // The background queue.
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    
    // Allocate and initialize the peripheral manager.
    _peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:(id<CBPeripheralManagerDelegate>)self
                                                                 queue:backgroundQueue];
    
    // Allocate and initialize the central manager.
    _centralManager = [[CBCentralManager alloc] initWithDelegate:(id<CBCentralManagerDelegate>)self
                                                           queue:backgroundQueue];
    

    // Initialize
    pthread_mutex_init(&_mutex, NULL);
   
    // Allocate and initialize the peers dictionary. It contains a TSNPeerDescriptor for
    // every peer we are either connecting or connected to.
    _peers = [[NSMutableDictionary alloc] init];
    
    // Done.
    return self;
}

// Gets the peer name.
- (NSString *)peerName
{
    return _peerName;
}

// Sets the peer name.
- (void)setPeerName:(NSString *)peerName
{
    if (![_peerName isEqualToString:_peerName])
    {
        _peerName = peerName;
        _canonicalPeerName = [_peerName dataUsingEncoding:NSUTF8StringEncoding];
        if (_enabled)
        {
            [self updatePeerNameCharacteristic];
        }
    }
}

// Starts peer Bluetooth.
- (void)start
{
    if (!_enabled)
    {
        _enabled = YES;
        [self startAdvertising];
        [self startScanning];
    }
}

// Stops peer Bluetooth.
- (void)stop
{
    if (_enabled)
    {
        _enabled = NO;
        [self stopAdvertising];
        [self stopScanning];
    }
}

// Updates the location.
- (void)updateLocation:(CLLocation *)location
{
    _lastLocationCoordinate = [location coordinate];
    [self updatePeerLocationCharacteristic];
}

// Updates the status.
- (void)updateStatus:(NSString *)status
{
    [self updatePeerStatusCharacteristic:status];
}

@end

// TSNPeerBluetooth (CBPeripheralManagerDelegate) implementation.
@implementation TSNPeerBluetooth (CBPeripheralManagerDelegate)

// Invoked whenever the peripheral manager's state has been updated.
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManager
{
    if ([_peripheralManager state] == CBPeripheralManagerStatePoweredOn)
    {
        [self startAdvertising];
    }
    else
    {
        [self stopAdvertising];
    }
}

// Invoked with the result of a startAdvertising call.
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheralManager
                                       error:(NSError *)error
{
}

// Invoked with the result of a addService call.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
            didAddService:(CBService *)service
                    error:(NSError *)error
{
}

// Invoked when peripheral manager receives a read request.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
    didReceiveReadRequest:(CBATTRequest *)request
{
    // Process the characteristic being read.
    if ([[[request characteristic] UUID] isEqual:_peerNameType])
    {
        [request setValue:_canonicalPeerName];
        [peripheralManager respondToRequest:request
                                 withResult:CBATTErrorSuccess];
    }
    else if ([[[request characteristic] UUID] isEqual:_peerLocationType])
    {
        [request setValue:[self peerLocationData]];
        [peripheralManager respondToRequest:request
                                 withResult:CBATTErrorSuccess];
    }
}

// Invoked after characteristic is subscribed to.
- (void)peripheralManager:(CBPeripheralManager *)peripheralManager
                  central:(CBCentral *)central
didSubscribeToCharacteristic:(CBCharacteristic *)characteristic
{
    // Request low latency for the central.
    [_peripheralManager setDesiredConnectionLatency:CBPeripheralManagerConnectionLatencyLow
                                         forCentral:central];
}

// Invoked after a failed call to update a characteristic.
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheralManager
{
}

@end

// TSNPeerBluetooth (CBCentralManagerDelegate) implementation.
@implementation TSNPeerBluetooth (CBCentralManagerDelegate)

// Invoked whenever the central manager's state has been updated.
- (void)centralManagerDidUpdateState:(CBCentralManager *)centralManager
{
    // If the central manager is powered on, make sure we're scanning. If it's in any other state,
    // make sure we're not scanning.
    if ([_centralManager state] == CBCentralManagerStatePoweredOn)
    {
        [self startScanning];
    }
    else
    {
        [self stopScanning];
    }
}

// Invoked when a peripheral is discovered.
- (void)centralManager:(CBCentralManager *)centralManager
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    // Obtain the peripheral identifier string.
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    // If we're not connected or connecting to this peripheral, connect to it.
    if (!_peers[peripheralIdentifierString])
    {
        // Add a TSNPeerDescriptor to the peers dictionary.
        _peers[peripheralIdentifierString] = [[TSNPeerDescriptor alloc] initWithPeripheral:peripheral
                                                                              initialState:TSNPeerDescriptorStateConnecting];

        // Connect to the peripheral.
        [_centralManager connectPeripheral:peripheral
                                   options:nil];
    }
}

// Invoked when a peripheral is connected.
- (void)centralManager:(CBCentralManager *)centralManager
  didConnectPeripheral:(CBPeripheral *)peripheral
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];
    
    // Find the peer descriptor in the peers dictionary. It should be there.
    TSNPeerDescriptor * peerDescriptor = _peers[peripheralIdentifierString];
    if (peerDescriptor)
    {
        // Update the peer descriptor state.
        [peerDescriptor setState:TSNPeerDescriptorStateInitializing];
    }
    else
    {
        // Allocate a new peer descriptor and add it to the peers dictionary.
        peerDescriptor = [[TSNPeerDescriptor alloc] initWithPeripheral:peripheral
                                                          initialState:TSNPeerDescriptorStateInitializing];
        _peers[peripheralIdentifierString] = peerDescriptor;
    }
    
    // Set our delegate on the peripheral and discover its services.
    [peripheral setDelegate:(id<CBPeripheralDelegate>)self];
    [peripheral discoverServices:@[_serviceType]];
}

// Invoked when a peripheral connection fails.
- (void)centralManager:(CBCentralManager *)centralManager
didFailToConnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    // Immediately reconnect. This is long-lived meaning that we will connect to this peer whenever it is
    // encountered again.
    [_centralManager connectPeripheral:peripheral
                               options:nil];
}

// Invoked when a peripheral is disconnected.
- (void)centralManager:(CBCentralManager *)centralManager
didDisconnectPeripheral:(CBPeripheral *)peripheral
                 error:(NSError *)error
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];

    // Find the peer descriptor.
    TSNPeerDescriptor * peerDescriptor = [_peers objectForKey:peripheralIdentifierString];
    if (peerDescriptor)
    {
        // Notify the delegate.
        if ([peerDescriptor peerName])
        {
            if ([[self delegate] respondsToSelector:@selector(peerBluetooth:didDisconnectPeerIdentifier:)])
            {
                [[self delegate] peerBluetooth:self
                   didDisconnectPeerIdentifier:[peerDescriptor peerID]];
            }
        }
        
        // Immediately reconnect. This is long-lived meaning that we will connect to this peer whenever it is
        // encountered again.
        [peerDescriptor setState:TSNPeerDescriptorStateConnecting];
        [_centralManager connectPeripheral:peripheral
                                   options:nil];
    }
}

@end

// TSNPeerBluetooth (CBPeripheralDelegate) implementation.
@implementation TSNPeerBluetooth (CBPeripheralDelegate)

// Invoked when services are discovered.
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverServices:(NSError *)error
{
    // Process the services.
    for (CBService * service in [peripheral services])
    {
        // If this is our service, discover its characteristics.
        if ([[service UUID] isEqual:_serviceType])
        {
            [peripheral discoverCharacteristics:@[_peerIDType,
                                                  _peerNameType,
                                                  _peerLocationType,
                                                  _peerStatusType]
                                     forService:service];
        }
    }
}

// Invoked when service characteristics are discovered.
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    // If this is our service, process its discovered characteristics.
    if ([[service UUID] isEqual:_serviceType])
    {
        for (CBCharacteristic * characteristic in [service characteristics])
        {
            if ([[characteristic UUID] isEqual:_peerIDType])
            {
                [peripheral readValueForCharacteristic:characteristic];
            }
            else if ([[characteristic UUID] isEqual:_peerNameType])
            {
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
            else if ([[characteristic UUID] isEqual:_peerLocationType])
            {
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
            else if ([[characteristic UUID] isEqual:_peerStatusType])
            {
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
        }
    }
}

// Invoked when the value of a characteristic is updated.
- (void)peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    // Get the peripheral identifier string.
    NSString * peripheralIdentifierString = [[peripheral identifier] UUIDString];

    // Obtain the peer descriptor.
    TSNPeerDescriptor * peerDescriptor = _peers[peripheralIdentifierString];
    if (!peerDescriptor)
    {
        return;
    }

    // Process the characteristic.
    if ([[characteristic UUID] isEqual:_peerIDType])
    {
        [peerDescriptor setPeerID:[[NSUUID alloc] initWithUUIDBytes:[[characteristic value] bytes]]];
    }
    else if ([[characteristic UUID] isEqual:_peerNameType])
    {
        [peerDescriptor setPeerName:[[NSString alloc] initWithData:[characteristic value]
                                                          encoding:NSUTF8StringEncoding]];
    }
    else if ([[characteristic UUID] isEqual:_peerLocationType])
    {
        if ([[characteristic value] length] == sizeof(CLLocationDegrees) * 2)
        {
            CLLocationDegrees * latitude = (CLLocationDegrees *)[[characteristic value] bytes];
            CLLocationDegrees * longitude = latitude + 1;
            [peerDescriptor setPeerLocation:[[CLLocation alloc] initWithLatitude:*latitude
                                                                       longitude:*longitude]];
            
            if ([peerDescriptor state] == TSNPeerDescriptorStateConnected && [[self delegate] respondsToSelector:@selector(peerBluetooth:didReceivePeerLocation:fromPeerIdentifier:)])
            {
                [[self delegate] peerBluetooth:self
                        didReceivePeerLocation:[peerDescriptor peerLocation]
                            fromPeerIdentifier:[peerDescriptor peerID]];
            }
        }
    }
    else if ([[characteristic UUID] isEqual:_peerStatusType])
    {
        if ([[characteristic value] length])
        {
            if ([peerDescriptor state] == TSNPeerDescriptorStateConnected && [[self delegate] respondsToSelector:@selector(peerBluetooth:didReceivePeerStatus:fromPeerIdentifier:)])
            {
                [[self delegate] peerBluetooth:self
                          didReceivePeerStatus:[[NSString alloc] initWithData:[characteristic value]
                                                                     encoding:NSUTF8StringEncoding]
                            fromPeerIdentifier:[peerDescriptor peerID]];
            }
        }
    }

    // Detect when the peer is fully initialized and move to the connected state.
    if ([peerDescriptor state] == TSNPeerDescriptorStateInitializing && [peerDescriptor peerID] && [peerDescriptor peerName] && [peerDescriptor peerLocation])
    {
        // Move the peer to the connected state.
        [peerDescriptor setState:TSNPeerDescriptorStateConnected];

        // Notify the delegate that the peer is connected.
        if ([[self delegate] respondsToSelector:@selector(peerBluetooth:didConnectPeerIdentifier:peerName:peerLocation:)])
        {
            [[self delegate] peerBluetooth:self
                  didConnectPeerIdentifier:[peerDescriptor peerID]
                                  peerName:[peerDescriptor peerName]
                              peerLocation:[peerDescriptor peerLocation]];
        }
    }
}

@end

// TSNPeerBluetooth (Internal) implementation.
@implementation TSNPeerBluetooth (Internal)

// Starts advertising.
- (void)startAdvertising
{
    if ([_peripheralManager state] == CBPeripheralManagerStatePoweredOn && _enabled && ![_peripheralManager isAdvertising])
    {
        [_peripheralManager addService:_service];
        [_peripheralManager startAdvertising:_advertisingData];
    }
}

// Stops advertising.
- (void)stopAdvertising
{
    if ([_peripheralManager isAdvertising])
    {
        [_peripheralManager removeAllServices];
        [_peripheralManager stopAdvertising];
    }
}

// Starts scanning.
- (void)startScanning
{
    if ([_centralManager state] == CBCentralManagerStatePoweredOn && _enabled && !_scanning)
    {
        _scanning = YES;
        [_centralManager scanForPeripheralsWithServices:@[_serviceType]
                                                options:@{CBCentralManagerScanOptionAllowDuplicatesKey: @(NO)}];
    }
}

// Stops scanning.
- (void)stopScanning
{
    if (_scanning)
    {
        _scanning = NO;
        [_centralManager stopScan];
    }
}

// Updates the peer name characteristic.
- (void)updatePeerNameCharacteristic
{
    if (_enabled)
    {
        [_peripheralManager updateValue:_canonicalPeerName
                      forCharacteristic:_characteristicPeerName
                   onSubscribedCentrals:nil];
    }
}

// Updates the peer location characteristic.
- (void)updatePeerLocationCharacteristic
{
    if (_enabled)
    {
        [_peripheralManager updateValue:[self peerLocationData]
                      forCharacteristic:_characteristicPeerLocation
                   onSubscribedCentrals:nil];
    }
}

// Updates the peer status characteristic.
- (void)updatePeerStatusCharacteristic:(NSString *)peerMessage
{
    if (_enabled)
    {
        [_peripheralManager updateValue:[peerMessage dataUsingEncoding:NSUTF8StringEncoding]
                      forCharacteristic:_characteristicPeerStatus
                   onSubscribedCentrals:nil];
    }
}

// Gets the peer location data.
- (NSData *)peerLocationData
{
    // Obtain the last location coordinate.
    pthread_mutex_lock(&_mutex);
    CLLocationCoordinate2D lastLocationCoordinate = _lastLocationCoordinate;
    pthread_mutex_unlock(&_mutex);
    
    // Construct and return an NSData with the location.
    NSMutableData * data = [[NSMutableData alloc] initWithCapacity:sizeof(CLLocationDegrees) * 2];
    [data appendBytes:&lastLocationCoordinate.latitude
               length:sizeof(lastLocationCoordinate.latitude)];
    [data appendBytes:&lastLocationCoordinate.longitude
               length:sizeof(lastLocationCoordinate.longitude)];
    return data;
}

@end
