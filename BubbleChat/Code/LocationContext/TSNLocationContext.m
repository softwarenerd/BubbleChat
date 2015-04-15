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
//  BubbleChat
//  TSNLocationContext.m
//

#import <TSNThreading.h>
#import "TSNLocationContext.h"

// TSNLocationContext (CLLocationManagerDelegate) interface.
@interface TSNLocationContext (CLLocationManagerDelegate) <CLLocationManagerDelegate>
@end

// TSNLocationContext (Internal) interface.
@interface TSNLocationContext (Internal)
@end

// TSNLocationContext implementation.
@implementation TSNLocationContext
{
@private
    // A value which indicates whether we're enabled.
    BOOL _enabled;
    
    // The Core Location manager.
    CLLocationManager * _locationManager;
}

// Class initializer.
- (instancetype)init
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Allocate and initialize the Core Location manager.
    _locationManager = [[CLLocationManager alloc] init];
    [_locationManager setActivityType:CLActivityTypeFitness];
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [_locationManager setDelegate:(id<CLLocationManagerDelegate>)self];
    
    // Done.
    return self;
}

// Starts the location context.
- (void)start
{
    if (!_enabled)
    {
        _enabled = YES;
        CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
        if (authorizationStatus == kCLAuthorizationStatusNotDetermined)
        {
            [_locationManager requestAlwaysAuthorization];
        }
        else if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)
        {
            [_locationManager startUpdatingLocation];
        }
    }
}

// Stops the location context.
- (void)stop
{
    if (_enabled)
    {
        _enabled = NO;
        [_locationManager stopUpdatingLocation];
    }
}

@end

// TSNLocationContext (CLLocationManagerDelegate) implementation.
@implementation TSNLocationContext (CLLocationManagerDelegate)

/*
 *  locationManager:didChangeAuthorizationStatus:
 *
 *  Discussion:
 *    Invoked when the authorization status changes for this application.
 */
- (void)locationManager:(CLLocationManager *)manager
didChangeAuthorizationStatus:(CLAuthorizationStatus)authorizationStatus
{
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)
    {
        if (_enabled)
        {
            [_locationManager startUpdatingLocation];
        }
    }
    else
    {
        [_locationManager stopUpdatingLocation];
    }
}

/*
 *  locationManager:didUpdateLocations:
 *
 *  Discussion:
 *    Invoked when new locations are available.  Required for delivery of
 *    deferred locations.  If implemented, updates will
 *    not be delivered to locationManager:didUpdateToLocation:fromLocation:
 *
 *    locations is an array of CLLocation objects in chronological order.
 */
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations
{
    // Get the last known location.
    CLLocation * location = [locations lastObject];
        
    // Notify the delegate.
    if ([[self delegate] respondsToSelector:@selector(locationContext:didUpdateLocation:)])
    {
        [[self delegate] locationContext:self
                       didUpdateLocation:location];
    }
}

@end

// TSNLocationContext (Internal) implementation.
@implementation TSNLocationContext (Internal)
@end
