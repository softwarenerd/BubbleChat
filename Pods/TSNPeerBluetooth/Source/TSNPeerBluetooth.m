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

// The maximum status length is 140 characters * 4 bytes (the maximum UTF-8 bytes per character).
const NSUInteger kMaxStatusDataLength = 140 * 4;
const NSUInteger kMaxPeerNameLength = 100;

// Returns a new NSData fro the specified location coordinate.
static inline NSData * dataForLocationCoordinate(CLLocationCoordinate2D locationCoordinate)
{
    // Construct and return an NSData with the location.
    NSMutableData * data = [[NSMutableData alloc] initWithCapacity:sizeof(CLLocationDegrees) * 2];
    [data appendBytes:&locationCoordinate.latitude
               length:sizeof(locationCoordinate.latitude)];
    [data appendBytes:&locationCoordinate.longitude
               length:sizeof(locationCoordinate.longitude)];
    return data;
}

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
@property (nonatomic) CBCharacteristic * characteristicPeerStatus1;
@property (nonatomic) CBCharacteristic * characteristicPeerStatus2;
@property (nonatomic) CBCharacteristic * characteristicPeerStatus3;
@property (nonatomic) CBCharacteristic * characteristicPeerStatus4;
@property (nonatomic) CBCharacteristic * characteristicPeerStatus5;

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

// TSNCharacteristicUpdateDescriptor interface.
@interface TSNCharacteristicUpdateDescriptor : NSObject

// Properties.
@property (nonatomic, readonly) NSData * value;
@property (nonatomic, readonly) CBMutableCharacteristic * characteristic;

// Class initializer.
- (instancetype)initWithValue:(NSData *)value
               characteristic:(CBMutableCharacteristic *)characteristic;

@end

// TSNCharacteristicUpdateDescriptor implementation.
@implementation TSNCharacteristicUpdateDescriptor

// Class initializer.
- (instancetype)initWithValue:(NSData *)value
               characteristic:(CBMutableCharacteristic *)characteristic
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _value = value;
    _characteristic = characteristic;
    
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

// Updates the peer location characteristic.
- (void)updatePeerLocationCharacteristic:(CLLocation *)peerLocation;

// Updates the peer status characteristic.
- (BOOL)updatePeerStatusCharacteristic:(NSString *)peerStatus;

// Updates the value of a characteristic. Automatically handles the case when the transmit queue
// is full by enqueuing a characteristic update for later transmission.
- (void)updateValue:(NSData *)value
  forCharacteristic:(CBMutableCharacteristic *)characteristic;

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
    
    // The service type.
    CBUUID * _serviceType;
    
    // The peer ID type.
    CBUUID * _peerIDType;

    // The peer name type.
    CBUUID * _peerNameType;
    
    // The peer location type.
    CBUUID * _peerLocationType;

    // The peer status 1 updated at type.
    CBUUID * _peerStatus1UpdatedAtType;
    
    // The peer status 2 updated at type.
    CBUUID * _peerStatus2UpdatedAtType;
    
    // The peer status 3 updated at type.
    CBUUID * _peerStatus3UpdatedAtType;
    
    // The peer status 4 updated at type.
    CBUUID * _peerStatus4UpdatedAtType;
    
    // The peer status 5 updated at type.
    CBUUID * _peerStatus5UpdatedAtType;

    // The peer status 1 type.
    CBUUID * _peerStatus1Type;

    // The peer status 2 type.
    CBUUID * _peerStatus2Type;

    // The peer status 3 type.
    CBUUID * _peerStatus3Type;

    // The peer status 4 type.
    CBUUID * _peerStatus4Type;

    // The peer status 5 type.
    CBUUID * _peerStatus5Type;

    // The service.
    CBMutableService * _service;
    
    // The peer ID characteristic.
    CBMutableCharacteristic * _characteristicPeerID;

    // The peer name characteristic.
    CBMutableCharacteristic * _characteristicPeerName;
    
    // The peer locaton characteristic.
    CBMutableCharacteristic * _characteristicPeerLocation;

    // The peer status 1 updated at characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus1UpdatedAt;
    
    // The peer status 2 updated at characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus2UpdatedAt;
    
    // The peer status 3 updated at characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus3UpdatedAt;
    
    // The peer status 4 updated at characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus4UpdatedAt;
    
    // The peer status 5 updated at characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus5UpdatedAt;
    
    // The peer status 1 characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus1;

    // The peer status 2 characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus2;

    // The peer status 3 characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus3;

    // The peer status 4 characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus4;

    // The peer status 5 characteristic.
    CBMutableCharacteristic * _characteristicPeerStatus5;
    
    // The advertising data.
    NSDictionary * _advertisingData;
    
    // The peripheral manager.
    CBPeripheralManager * _peripheralManager;
    
    // The central manager.
    CBCentralManager * _centralManager;
    
    // Mutex used to synchronize accesss to the things below.
    pthread_mutex_t _mutex;
    
    // The enabled flag.
    BOOL _enabled;
    
    // The scanning flag.
    BOOL _scanning;

    // The location coordinate.
    CLLocationCoordinate2D _peerLocationCoordinate;
    
    // The peer status index. This is the index (0-4) of the current peer status.
    NSUInteger _peerStatusIndex;

    // The peer status 1 data.
    NSData * _peerStatus1Data;

    // The peer status 2 data.
    NSData * _peerStatus2Data;

    // The peer status 3 data.
    NSData * _peerStatus3Data;

    // The peer status 4 data.
    NSData * _peerStatus4Data;

    // The peer status 5 data.
    NSData * _peerStatus5Data;

    // The peers dictionary.
    NSMutableDictionary * _peers;
    
    // The pending characteristic updates array.
    NSMutableArray * _pendingCharacteristicUpdates;
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
    
    // If the peer name is too long, truncate it.
    if ([peerName length] > 100)
    {
        [peerName substringWithRange:NSMakeRange(0, 100)];
    }

    // Initialize.
    _serviceType = [CBUUID UUIDWithNSUUID:serviceType];
    _peerIdentifier = peerIdentifier;
    _peerName = peerName;
    _canonicalPeerName = [_peerName dataUsingEncoding:NSUTF8StringEncoding];
    
    // Initialize the peer identifier value.
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

    // Allocate and initialize the peer status 1 updated at type.
    _peerStatus1UpdatedAtType = [CBUUID UUIDWithString:@"1D4D00AA-49EC-4368-9FFA-5682D1A6D4B2"];
    
    // Allocate and initialize the peer status 2 updated at type.
    _peerStatus2UpdatedAtType = [CBUUID UUIDWithString:@"A81EB929-1082-4CD5-820B-141D64119786"];
    
    // Allocate and initialize the peer status 3 updated at type.
    _peerStatus3UpdatedAtType = [CBUUID UUIDWithString:@"6BDB663C-E464-4116-90E0-3ED8E2019D49"];
    
    // Allocate and initialize the peer status 4 updated at type.
    _peerStatus4UpdatedAtType = [CBUUID UUIDWithString:@"8F122301-1994-4891-8842-9E76D78629B2"];
    
    // Allocate and initialize the peer status 5 updated at type.
    _peerStatus5UpdatedAtType = [CBUUID UUIDWithString:@"C84354E3-710C-47B7-B082-3E2FC861287A"];

    // Allocate and initialize the peer status 1 type.
    _peerStatus1Type = [CBUUID UUIDWithString:@"3211022A-EEF4-4522-A5CE-47E60342FFB5"];
    
    // Allocate and initialize the peer status 2 type.
    _peerStatus2Type = [CBUUID UUIDWithString:@"B674CE1E-580A-49C5-A12D-59DD58FEF4CF"];

    // Allocate and initialize the peer status 3 type.
    _peerStatus3Type = [CBUUID UUIDWithString:@"DE085020-4BE2-4866-8133-9E1BEE9E7E66"];

    // Allocate and initialize the peer status 4 type.
    _peerStatus4Type = [CBUUID UUIDWithString:@"6F603273-7B82-4BB8-8786-117D7FE1D7F8"];

    // Allocate and initialize the peer status 5 type.
    _peerStatus5Type = [CBUUID UUIDWithString:@"9F52394C-0289-4628-92ED-735FA35CE0D4"];
    
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
                                                                 properties:CBCharacteristicPropertyRead
                                                                      value:_canonicalPeerName
                                                                permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the peer location characteristic.
    _characteristicPeerLocation = [[CBMutableCharacteristic alloc] initWithType:_peerLocationType
                                                                 properties:CBCharacteristicPropertyRead | CBCharacteristicPropertyNotify
                                                                      value:nil
                                                                permissions:CBAttributePermissionsReadable];

    // Allocate and initialize the peer status 1 updated at characteristic.
    _characteristicPeerStatus1UpdatedAt = [[CBMutableCharacteristic alloc] initWithType:_peerStatus1UpdatedAtType
                                                                    properties:CBCharacteristicPropertyNotify
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 2 updated at characteristic.
    _characteristicPeerStatus2UpdatedAt = [[CBMutableCharacteristic alloc] initWithType:_peerStatus2UpdatedAtType
                                                                    properties:CBCharacteristicPropertyNotify
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 3 updated at characteristic.
    _characteristicPeerStatus3UpdatedAt = [[CBMutableCharacteristic alloc] initWithType:_peerStatus3UpdatedAtType
                                                                    properties:CBCharacteristicPropertyNotify
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 4 updated at characteristic.
    _characteristicPeerStatus4UpdatedAt = [[CBMutableCharacteristic alloc] initWithType:_peerStatus4UpdatedAtType
                                                                    properties:CBCharacteristicPropertyNotify
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 5 updated at characteristic.
    _characteristicPeerStatus5UpdatedAt = [[CBMutableCharacteristic alloc] initWithType:_peerStatus5UpdatedAtType
                                                                    properties:CBCharacteristicPropertyNotify
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 1 characteristic.
    _characteristicPeerStatus1 = [[CBMutableCharacteristic alloc] initWithType:_peerStatus1Type
                                                                    properties:CBCharacteristicPropertyRead
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 2 characteristic.
    _characteristicPeerStatus2 = [[CBMutableCharacteristic alloc] initWithType:_peerStatus2Type
                                                                    properties:CBCharacteristicPropertyRead
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 3 characteristic.
    _characteristicPeerStatus3 = [[CBMutableCharacteristic alloc] initWithType:_peerStatus3Type
                                                                    properties:CBCharacteristicPropertyRead
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 4 characteristic.
    _characteristicPeerStatus4 = [[CBMutableCharacteristic alloc] initWithType:_peerStatus4Type
                                                                    properties:CBCharacteristicPropertyRead
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Allocate and initialize the peer status 5 characteristic.
    _characteristicPeerStatus5 = [[CBMutableCharacteristic alloc] initWithType:_peerStatus5Type
                                                                    properties:CBCharacteristicPropertyRead
                                                                         value:nil
                                                                   permissions:CBAttributePermissionsReadable];
    
    // Set the service characteristics.
    [_service setCharacteristics:@[_characteristicPeerID,
                                   _characteristicPeerName,
                                   _characteristicPeerLocation,
                                   _characteristicPeerStatus1UpdatedAt,
                                   _characteristicPeerStatus2UpdatedAt,
                                   _characteristicPeerStatus3UpdatedAt,
                                   _characteristicPeerStatus4UpdatedAt,
                                   _characteristicPeerStatus5UpdatedAt,
                                   _characteristicPeerStatus1,
                                   _characteristicPeerStatus2,
                                   _characteristicPeerStatus3,
                                   _characteristicPeerStatus4,
                                   _characteristicPeerStatus5]];
    
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
    
    // Allocate and initialize the pending updates array. It contains a TSNCharacteristicUpdateDescriptor
    // for each characteristic update that is pending after a failed call to CBPeripheralManager
    // updateValue:forCharacteristic:onSubscribedCentrals.
    _pendingCharacteristicUpdates = [[NSMutableArray alloc] init];
    
    // Done.
    return self;
}

// Starts peer Bluetooth.
- (void)start
{
    // Lock.
    pthread_mutex_lock(&_mutex);
    
    // Start, if we should.
    if (!_enabled)
    {
        _enabled = YES;
        [self startAdvertising];
        [self startScanning];
    }

    // Unlock.
    pthread_mutex_unlock(&_mutex);
}

// Stops peer Bluetooth.
- (void)stop
{
    // Lock.
    pthread_mutex_lock(&_mutex);

    // Stop, if we should.
    if (_enabled)
    {
        _enabled = NO;
        [self stopAdvertising];
        [self stopScanning];
    }

    // Unlock.
    pthread_mutex_unlock(&_mutex);
}

// Updates the location.
- (void)updateLocation:(CLLocation *)location
{
    [self updatePeerLocationCharacteristic:location];
}

// Updates the status. Returns YES if successful; otherwise, NO. A return value of NO
// indicates that the status string was too long.
- (BOOL)updateStatus:(NSString *)status
{
    return [self updatePeerStatusCharacteristic:status];
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
    // Peer location characteristic.
    if ([[[request characteristic] UUID] isEqual:_peerLocationType])
    {
        if ([request offset] > 0)
        {
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorInvalidOffset];
        }
        else
        {
            pthread_mutex_lock(&_mutex);
            CLLocationCoordinate2D locationCoordinate = _peerLocationCoordinate;
            pthread_mutex_unlock(&_mutex);
            [request setValue:dataForLocationCoordinate(locationCoordinate)];
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorSuccess];
        }
    }
    // Peer status 1 characteristic.
    else if ([[[request characteristic] UUID] isEqual:_peerStatus1Type])
    {
        if ([request offset] >= [_peerStatus1Data length])
        {
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorInvalidOffset];
        }
        else
        {
            [request setValue:[_peerStatus1Data subdataWithRange:NSMakeRange([request offset], [_peerStatus1Data length] - [request offset])]];
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorSuccess];
        }
    }
    // Peer status 2 characteristic.
    else if ([[[request characteristic] UUID] isEqual:_peerStatus2Type])
    {
        if ([request offset] >= [_peerStatus2Data length])
        {
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorInvalidOffset];
        }
        else
        {
            [request setValue:[_peerStatus2Data subdataWithRange:NSMakeRange([request offset], [_peerStatus2Data length] - [request offset])]];
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorSuccess];
        }
    }
    // Peer status 3 characteristic.
    else if ([[[request characteristic] UUID] isEqual:_peerStatus3Type])
    {
        if ([request offset] >= [_peerStatus3Data length])
        {
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorInvalidOffset];
        }
        else
        {
            [request setValue:[_peerStatus3Data subdataWithRange:NSMakeRange([request offset], [_peerStatus3Data length] - [request offset])]];
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorSuccess];
        }
    }
    // Peer status 4 characteristic.
    else if ([[[request characteristic] UUID] isEqual:_peerStatus4Type])
    {
        if ([request offset] >= [_peerStatus4Data length])
        {
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorInvalidOffset];
        }
        else
        {
            [request setValue:[_peerStatus4Data subdataWithRange:NSMakeRange([request offset], [_peerStatus4Data length] - [request offset])]];
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorSuccess];
        }
    }
    // Peer status 5 characteristic.
    else if ([[[request characteristic] UUID] isEqual:_peerStatus5Type])
    {
        if ([request offset] >= [_peerStatus5Data length])
        {
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorInvalidOffset];
        }
        else
        {
            [request setValue:[_peerStatus5Data subdataWithRange:NSMakeRange([request offset], [_peerStatus5Data length] - [request offset])]];
            [peripheralManager respondToRequest:request
                                     withResult:CBATTErrorSuccess];
        }
    }
}

// Invoked after a failed call to update a characteristic.
- (void)peripheralManagerIsReadyToUpdateSubscribers:(CBPeripheralManager *)peripheralManager
{
    // Lock.
    pthread_mutex_lock(&_mutex);

    // Process as many pending characteristic updates as we can.
    while ([_pendingCharacteristicUpdates count])
    {
        // Process the next pending characteristic update. If the trasnmission queue is full, stop processing.
        TSNCharacteristicUpdateDescriptor * characteristicUpdateDescriptor = _pendingCharacteristicUpdates[0];
        if (![_peripheralManager updateValue:[characteristicUpdateDescriptor value]
                           forCharacteristic:[characteristicUpdateDescriptor characteristic]
                        onSubscribedCentrals:nil])
        {
            break;
        }
        
        // Remove the pending characteristic update we processed.
        [_pendingCharacteristicUpdates removeObjectAtIndex:0];
    }

    // Unlock.
    pthread_mutex_unlock(&_mutex);
}

@end

// TSNPeerBluetooth (CBCentralManagerDelegate) implementation.
@implementation TSNPeerBluetooth (CBCentralManagerDelegate)

// Invoked whenever the central manager's state has been updated.
- (void)centralManagerDidUpdateState:(CBCentralManager *)centralManager
{
    // Lock.
    pthread_mutex_lock(&_mutex);

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

    // Unlock.
    pthread_mutex_unlock(&_mutex);
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
        // Clear the peer status characteristics.
        [peerDescriptor setCharacteristicPeerStatus1:nil];
        [peerDescriptor setCharacteristicPeerStatus2:nil];
        [peerDescriptor setCharacteristicPeerStatus3:nil];
        [peerDescriptor setCharacteristicPeerStatus4:nil];
        [peerDescriptor setCharacteristicPeerStatus5:nil];

        // Notify the delegate.
        if ([peerDescriptor peerName])
        {
            if ([[self delegate] respondsToSelector:@selector(peerBluetooth:didDisconnectPeerIdentifier:)])
            {
                [[self delegate] peerBluetooth:self
                   didDisconnectPeerIdentifier:[peerDescriptor peerID]];
            }
        }
        
        // Immediately reconnect. This is long-lived. Central manager will connect to this peer whenever it is
        // discovered again.
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
                                                  _peerStatus1UpdatedAtType,
                                                  _peerStatus2UpdatedAtType,
                                                  _peerStatus3UpdatedAtType,
                                                  _peerStatus4UpdatedAtType,
                                                  _peerStatus5UpdatedAtType,
                                                  _peerStatus1Type,
                                                  _peerStatus2Type,
                                                  _peerStatus3Type,
                                                  _peerStatus4Type,
                                                  _peerStatus5Type]
                                     forService:service];
        }
    }
}

// Invoked when service characteristics are discovered.
- (void)peripheral:(CBPeripheral *)peripheral
didDiscoverCharacteristicsForService:(CBService *)service
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
    
    // If this is our service, process its discovered characteristics.
    if ([[service UUID] isEqual:_serviceType])
    {
        // Process each of the discovered characteristics.
        for (CBCharacteristic * characteristic in [service characteristics])
        {
            // Peer ID characteristic.
            if ([[characteristic UUID] isEqual:_peerIDType])
            {
                // Read it.
                [peripheral readValueForCharacteristic:characteristic];
            }
            // Peer name characteristic.
            else if ([[characteristic UUID] isEqual:_peerNameType])
            {
                // Read it.
                [peripheral readValueForCharacteristic:characteristic];
            }
            // Peer location characteristic.
            else if ([[characteristic UUID] isEqual:_peerLocationType])
            {
                // Read it and subscribe to it.
                [peripheral readValueForCharacteristic:characteristic];
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
            // Peer status 1-5 updated at characteristics.
            else if ([[characteristic UUID] isEqual:_peerStatus1UpdatedAtType] ||
                     [[characteristic UUID] isEqual:_peerStatus2UpdatedAtType] ||
                     [[characteristic UUID] isEqual:_peerStatus3UpdatedAtType] ||
                     [[characteristic UUID] isEqual:_peerStatus4UpdatedAtType] ||
                     [[characteristic UUID] isEqual:_peerStatus5UpdatedAtType])
            {
                // Subscribe to it.
                [peripheral setNotifyValue:YES
                         forCharacteristic:characteristic];
            }
            // Peer status 1 characteristics.
            else if ([[characteristic UUID] isEqual:_peerStatus1Type])
            {
                // Remember it so we can read it.
                [peerDescriptor setCharacteristicPeerStatus1:characteristic];
            }
            // Peer status 2 characteristics.
            else if ([[characteristic UUID] isEqual:_peerStatus2Type])
            {
                // Remember it so we can read it.
                [peerDescriptor setCharacteristicPeerStatus2:characteristic];
            }
            // Peer status 3 characteristics.
            else if ([[characteristic UUID] isEqual:_peerStatus3Type])
            {
                // Remember it so we can read it.
                [peerDescriptor setCharacteristicPeerStatus3:characteristic];
            }
            // Peer status 4 characteristics.
            else if ([[characteristic UUID] isEqual:_peerStatus4Type])
            {
                // Remember it so we can read it.
                [peerDescriptor setCharacteristicPeerStatus4:characteristic];
            }
            // Peer status 5 characteristics.
            else if ([[characteristic UUID] isEqual:_peerStatus5Type])
            {
                // Remember it so we can read it.
                [peerDescriptor setCharacteristicPeerStatus5:characteristic];
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

    // Peer ID characteristic.
    if ([[characteristic UUID] isEqual:_peerIDType])
    {
        // When the peer ID is updated, set the peer ID in the peer descriptor.
        [peerDescriptor setPeerID:[[NSUUID alloc] initWithUUIDBytes:[[characteristic value] bytes]]];
    }
    // Peer name characteristic.
    else if ([[characteristic UUID] isEqual:_peerNameType])
    {
        // When the peer name is updated, set the peer name in the peer descriptor.
        [peerDescriptor setPeerName:[[NSString alloc] initWithData:[characteristic value]
                                                          encoding:NSUTF8StringEncoding]];
    }
    // Peer location characteristic.
    else if ([[characteristic UUID] isEqual:_peerLocationType])
    {
        // When the peer location is updated, set the peer location in the peer descriptor.
        if ([[characteristic value] length] == sizeof(CLLocationDegrees) * 2)
        {
            CLLocationDegrees * latitude = (CLLocationDegrees *)[[characteristic value] bytes];
            CLLocationDegrees * longitude = latitude + 1;
            [peerDescriptor setPeerLocation:[[CLLocation alloc] initWithLatitude:*latitude
                                                                       longitude:*longitude]];
            
            // If the peer is fully initialized (it's in the connected state), notify the delegate.
            if ([peerDescriptor state] == TSNPeerDescriptorStateConnected)
            {
                // Notify the delegate.
                if ([[self delegate] respondsToSelector:@selector(peerBluetooth:didReceivePeerLocation:fromPeerIdentifier:)])
                {
                    [[self delegate] peerBluetooth:self
                            didReceivePeerLocation:[peerDescriptor peerLocation]
                                fromPeerIdentifier:[peerDescriptor peerID]];
                }
            }
        }
    }
    // Peer status 1 updated at characteristic.
    else if ([[characteristic UUID] isEqual:_peerStatus1UpdatedAtType])
    {
        // Read the peer status 1 characteristic.
        [peripheral readValueForCharacteristic:[peerDescriptor characteristicPeerStatus1]];
    }
    // Peer status 2 updated at characteristic.
    else if ([[characteristic UUID] isEqual:_peerStatus2UpdatedAtType])
    {
        // Read the peer status 2 characteristic.
        [peripheral readValueForCharacteristic:[peerDescriptor characteristicPeerStatus2]];
    }
    // Peer status 3 updated at characteristic.
    else if ([[characteristic UUID] isEqual:_peerStatus3UpdatedAtType])
    {
        // Read the peer status 3 characteristic.
        [peripheral readValueForCharacteristic:[peerDescriptor characteristicPeerStatus3]];
    }
    // Peer status 4 updated at characteristic.
    else if ([[characteristic UUID] isEqual:_peerStatus4UpdatedAtType])
    {
        // Read the peer status 4 characteristic.
        [peripheral readValueForCharacteristic:[peerDescriptor characteristicPeerStatus4]];
    }
    // Peer status 5 updated at characteristic.
    else if ([[characteristic UUID] isEqual:_peerStatus5UpdatedAtType])
    {
        // Read the peer status 5 characteristic.
        [peripheral readValueForCharacteristic:[peerDescriptor characteristicPeerStatus5]];
    }
    // Peer status 1-5 characteristic.
    else if ([[characteristic UUID] isEqual:_peerStatus1Type] ||
             [[characteristic UUID] isEqual:_peerStatus2Type] ||
             [[characteristic UUID] isEqual:_peerStatus3Type] ||
             [[characteristic UUID] isEqual:_peerStatus4Type] ||
             [[characteristic UUID] isEqual:_peerStatus5Type])
    {
        // If there was a value, process it.
        if ([[characteristic value] length])
        {
            // If the peer is fully initialized (it's in the connected state), notify the delegate.
            if ([peerDescriptor state] == TSNPeerDescriptorStateConnected)
            {
                // Notify the delegate.
                if ([[self delegate] respondsToSelector:@selector(peerBluetooth:didReceivePeerStatus:fromPeerIdentifier:)])
                {
                    [[self delegate] peerBluetooth:self
                              didReceivePeerStatus:[[NSString alloc] initWithData:[characteristic value]
                                                                         encoding:NSUTF8StringEncoding]
                                fromPeerIdentifier:[peerDescriptor peerID]];
                }
            }
        }
    }

    // Detect when the peer is fully initialized and move it to the connected state.
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

// Updates the peer location characteristic.
- (void)updatePeerLocationCharacteristic:(CLLocation *)peerLocation
{
    // Lock.
    pthread_mutex_lock(&_mutex);

    // Set the peer location coordinate.
    _peerLocationCoordinate = [peerLocation coordinate];
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);

    // Update the characteristic value.
    if (_enabled)
    {
        [self updateValue:dataForLocationCoordinate([peerLocation coordinate])
        forCharacteristic:_characteristicPeerLocation];
    }
}

// Updates the peer status characteristic.
- (BOOL)updatePeerStatusCharacteristic:(NSString *)peerStatus
{
    // Get the status data. If it's too long, return NO.
    NSData * statusData = [peerStatus dataUsingEncoding:NSUTF8StringEncoding];
    if ([statusData length] > kMaxStatusDataLength)
    {
        return NO;
    }
    
    // Lock.
    pthread_mutex_lock(&_mutex);

    // Peer status 1-5 are updated in a round-robin pattern which prevents a fast sender
    // from overwriting a status that is still being read.
    CBMutableCharacteristic * characteristicPeerStatus;
    switch (_peerStatusIndex)
    {
        case 0:
            characteristicPeerStatus = _characteristicPeerStatus1UpdatedAt;
            _peerStatus1Data = statusData;
            break;
            
        case 1:
            characteristicPeerStatus = _characteristicPeerStatus2UpdatedAt;
            _peerStatus2Data = statusData;
            break;
            
        case 2:
            characteristicPeerStatus = _characteristicPeerStatus3UpdatedAt;
            _peerStatus3Data = statusData;
            break;
            
        case 3:
            characteristicPeerStatus = _characteristicPeerStatus4UpdatedAt;
            _peerStatus4Data = statusData;
            break;
            
        case 4:
            characteristicPeerStatus = _characteristicPeerStatus5UpdatedAt;
            _peerStatus5Data = statusData;
            break;
    }
    
    // Increment the peer status index. Loop around to 0 when we reach the end.
    if (++_peerStatusIndex == 5)
    {
        _peerStatusIndex = 0;
    }
    
    // Unlock.
    pthread_mutex_unlock(&_mutex);

    // If we're enabled, update the peer status characteristic value.
    if (_enabled)
    {
        // Get the current time interval as an NSData.
        NSTimeInterval timeInterval = [[[NSDate alloc] init] timeIntervalSince1970];
        NSData * value = [NSData dataWithBytes:&timeInterval
                                        length:sizeof(timeInterval)];
        
        // Update the value for the characteristic.
        [self updateValue:value
        forCharacteristic:characteristicPeerStatus];
    }

    // Success.
    return YES;
}

// Updates the value of a characteristic. Automatically handles the case when the transmit queue
// is full by enqueuing a characteristic update for later transmission.
- (void)updateValue:(NSData *)value
  forCharacteristic:(CBMutableCharacteristic *)characteristic
{
    // Update the characteristic value. If this fails, enqueuing a characteristic update for later transmission.
    if (![_peripheralManager updateValue:value
                       forCharacteristic:characteristic
                    onSubscribedCentrals:nil])
    {
        // Lock.
        pthread_mutex_lock(&_mutex);
        
        // Enqueue characteristic update descriptor for the failed update. It will be updated when peripheralManagerIsReadyToUpdateSubscribers:
        // is called back.
        [_pendingCharacteristicUpdates addObject:[[TSNCharacteristicUpdateDescriptor alloc] initWithValue:value
                                                                                           characteristic:characteristic]];
        
        // Unlock.
        pthread_mutex_unlock(&_mutex);
    }
}

@end
