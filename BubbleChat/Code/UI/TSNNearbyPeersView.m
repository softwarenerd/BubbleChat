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
//  TSNNearbyPeersView.m
//

#import <TSNThreading.h>
#import <MapKit/MapKit.h>
#import "TSNAppContext.h"
#import "TSNNearbyPeersView.h"
#import "TSNLocalPeerAnnotation.h"
#import "TSNNearbyPeerAnnotation.h"

// TSNNearbyPeersView (MKMapViewDelegate) interface.
@interface TSNNearbyPeersView (MKMapViewDelegate) <MKMapViewDelegate>
@end

// TSNNearbyPeersView (Internal) interface.
@interface TSNNearbyPeersView (Internal)

// buttonResetTouchUpInside action.
- (void)buttonResetTouchUpInsideAction:(UIButton *)sender;

// TSNLocationUpdatedNotification callback.
- (void)locationUpdatedNotificationCallback:(NSNotification *)notification;

// TSNPeersUpdatedNotification callback.
- (void)peersUpdatedNotificationCallback:(NSNotification *)notification;

@end

// TSNNearbyPeersView implementation.
@implementation TSNNearbyPeersView
{
@private
    // The current location of the local peer.
    CLLocation * _location;
    
    // The map view.
    MKMapView * _mapView;
    
    // The reset button.
    UIButton * _buttonReset;

    // The local peer annotation.
    TSNLocalPeerAnnotation * _localPeerAnnotation;
    
    // The nearby peer annotations dictionary.
    NSMutableDictionary * _nearbyPeerAnnotations;
}

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
{
    // Initialize superclass.
    self = [super initWithFrame:frame];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Allocate, initialize, and add the map view, if it has not been added already.
    _mapView = [[MKMapView alloc] initWithFrame:[self bounds]];
    [_mapView setZoomEnabled:YES];
    [_mapView setScrollEnabled:YES];
    [_mapView setRotateEnabled:NO];
    [_mapView setPitchEnabled:NO];
    [_mapView setShowsBuildings:YES];
    [_mapView setShowsUserLocation:NO];
    [_mapView setShowsPointsOfInterest:YES];
    [_mapView setDelegate:(id<MKMapViewDelegate>)self];
    [self addSubview:_mapView];

    // Allocate, initialize, and add the reset button.
    _buttonReset = [UIButton buttonWithType:UIButtonTypeCustom];
    [_buttonReset setFrame:CGRectMake(10.0, 10.0, 50.0, 50.0)];
    [_buttonReset setImage:[UIImage imageNamed:@"Reset"]
                  forState:UIControlStateNormal];
    [_buttonReset setAdjustsImageWhenHighlighted:YES];
    [_buttonReset addTarget:self action:@selector(buttonResetTouchUpInsideAction:)
           forControlEvents:UIControlEventTouchUpInside];
    [_mapView addSubview:_buttonReset];
    
    // Allocate, initialize, and add the local peer annotation.
    _localPeerAnnotation = [[TSNLocalPeerAnnotation alloc] init];
    [_mapView addAnnotation:_localPeerAnnotation];

    // Allocate and initialize the nearby peer annotations dictionary.
    _nearbyPeerAnnotations = [[NSMutableDictionary alloc] init];

    // Get the default notification center.
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    
    // Add our observers.
    [notificationCenter addObserver:self
                           selector:@selector(locationUpdatedNotificationCallback:)
                               name:TSNLocationUpdatedNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(peersUpdatedNotificationCallback:)
                               name:TSNPeersUpdatedNotification
                             object:nil];
    
    // Done.
    return self;
}

// Dealloc.
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// TSNNearbyPeersView (MKMapViewDelegate) implementation.
@implementation TSNNearbyPeersView (MKMapViewDelegate)

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay
{
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView
            viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[TSNLocalPeerAnnotation class]])
    {
        static NSString * const identifierAnnotationLocalPeer = @"AnnotationLocalPeer";
        
        MKAnnotationView * annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifierAnnotationLocalPeer];
        if (annotationView)
        {
            [annotationView setAnnotation:annotation];
        }
        else
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifierAnnotationLocalPeer];
        }
        
        [annotationView setCanShowCallout:YES];
        [annotationView setImage:[UIImage imageNamed:@"LocalPeer"]];
        return annotationView;
    }
    else if ([annotation isKindOfClass:[TSNNearbyPeerAnnotation class]])
    {
        static NSString * const identifierAnnotationNearbyPeer = @"AnnotationNearbyPeer";
        
        MKAnnotationView * annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifierAnnotationNearbyPeer];
        if (annotationView)
        {
            [annotationView setAnnotation:annotation];
        }
        else
        {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifierAnnotationNearbyPeer];
        }
        
        [annotationView setCanShowCallout:YES];
        [annotationView setImage:[UIImage imageNamed:@"NearbyPeer"]];
        return annotationView;
    }
    else
    {
        return nil;
    }
}

@end

// TSNNearbyPeersView (Internal) implementation.
@implementation TSNNearbyPeersView (Internal)

// buttonResetTouchUpInside action.
- (void)buttonResetTouchUpInsideAction:(UIButton *)sender
{
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance([_location coordinate], 50, 50);
    MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
    [_mapView setRegion:adjustedRegion
               animated:YES];
}

// TSNLocationUpdatedNotification callback.
- (void)locationUpdatedNotificationCallback:(NSNotification *)notification
{
    OnMainThread(^{
        // Note whether this is the first location update.
        BOOL firstLocationUpdate = !_location;
        
        // Save the location.
        _location = [notification object];
        
        // Update the local peer annotation.
        if (_localPeerAnnotation)
        {
            [_localPeerAnnotation setCoordinate:[_location coordinate]];
        }
        
        // Update the region on the first location update.
        if (firstLocationUpdate)
        {
            MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance([_location coordinate], 50, 50);
            MKCoordinateRegion adjustedRegion = [_mapView regionThatFits:viewRegion];
            [_mapView setRegion:adjustedRegion
                       animated:YES];
        }
    });
}

// TSNPeersUpdatedNotification callback.
- (void)peersUpdatedNotificationCallback:(NSNotification *)notification
{
    OnMainThread(^{
        // Get the peers from the app context.
        NSArray * peers = [[TSNAppContext singleton] peers];
        
        // If there are no peers, remove all peer annotations.
        if (![peers count])
        {
            // If there are any peer annotations, remove them all.
            if ([_nearbyPeerAnnotations count])
            {
                [_mapView removeAnnotations:[_nearbyPeerAnnotations allValues]];
                [_nearbyPeerAnnotations removeAllObjects];
            }
            
            // Done.
            return;
        }
        
        // Enumerate the peers and add / update peer annotations, as needed.
        CLLocationDistance maxDistance = 0.0;
        NSMutableDictionary * peerAnnotationsAdded = [[NSMutableDictionary alloc] initWithCapacity:[peers count]];
        NSMutableDictionary * peerAnnotationsProcessed = [[NSMutableDictionary alloc] initWithCapacity:[peers count]];
        for (TSNPeer * peer in peers)
        {
            if ([peer disance] > maxDistance)
            {
                maxDistance = [peer disance];
            }
            
            // See if we have a peer annotation for this peer. If we do, update it and note that we processed it.
            // If we don't, create it and note that we added it.
            TSNNearbyPeerAnnotation * peerAnnotation = [_nearbyPeerAnnotations objectForKey:[peer identifier]];
            if (peerAnnotation)
            {
                [peerAnnotation setCoordinate:[[peer location] coordinate]];
                peerAnnotationsProcessed[[peer identifier]] = peerAnnotation;
            }
            else
            {
                peerAnnotation = [[TSNNearbyPeerAnnotation alloc] initWithPeer:peer];
                peerAnnotationsAdded[[peer identifier]] = peerAnnotation;
            }
        }
        
        // Find peer annotations that are no longer needed.
        NSMutableDictionary * peerAnnotationsToRemove = [[NSMutableDictionary alloc] init];
        for (TSNNearbyPeerAnnotation * peerAnnotation in [_nearbyPeerAnnotations allValues])
        {
            NSString * peerIdentifier = [[peerAnnotation peer] identifier];
            if (!peerAnnotationsProcessed[peerIdentifier] && !peerAnnotationsAdded[peerIdentifier])
            {
                peerAnnotationsToRemove[peerIdentifier] = peerAnnotation;
            }
        }
        
        // Remove any peer annotations that need to be removed.
        if ([peerAnnotationsToRemove count])
        {
            [_nearbyPeerAnnotations removeObjectsForKeys:[peerAnnotationsToRemove allKeys]];
            [_mapView removeAnnotations:[peerAnnotationsToRemove allValues]];
        }
        
        // Add any peer annotations that need to be added.
        if ([peerAnnotationsAdded count])
        {
            [_nearbyPeerAnnotations addEntriesFromDictionary:peerAnnotationsAdded];
            [_mapView addAnnotations:[peerAnnotationsAdded allValues]];
        }
    });
}

@end
