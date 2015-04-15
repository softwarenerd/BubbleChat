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
//  TSNNearbyPeerAnnotation.m
//

#import "TSNPeer.h"
#import "TSNNearbyPeerAnnotation.h"

// TSNNearbyPeerAnnotation (Internal) interface.
@interface TSNNearbyPeerAnnotation (Internal)
@end

// TSNNearbyPeerAnnotation implementation.
@implementation TSNNearbyPeerAnnotation
{
@private
}

// Properties.
@synthesize coordinate;
@synthesize title;
@synthesize subtitle;

// Class initializer.
- (instancetype)initWithPeer:(TSNPeer *)peer
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _peer = peer;
    title = [_peer name];
    coordinate = [[_peer location] coordinate];
    
    // Done.
    return self;
}

// Called as a result of dragging an annotation view.
- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate
{
    coordinate = newCoordinate;
}

@end

// TSNNearbyPeerAnnotation (Internal) implementation.
@implementation TSNNearbyPeerAnnotation (Internal)
@end
