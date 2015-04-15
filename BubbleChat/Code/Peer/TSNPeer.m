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
//  TSNPeer.m
//

#import <CoreLocation/CoreLocation.h>
#import "TSNPeer.h"

// TSNPeer (Internal) interface.
@interface TSNPeer (Internal)
@end

// TSNPeer implementation.
@implementation TSNPeer
{
@private
}

// Class initializer.
- (instancetype)initWithIdentifier:(NSString *)identifier
                              name:(NSString *)name
                          location:(CLLocation *)location
                          distance:(CLLocationDistance)distance
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    _identifier = identifier;
    _name = name;
    _location = location;
    _disance = distance;
    _lastUpdated = [[NSDate alloc] init];
    
    // Done.
    return self;
}

@end

// TSNPeer (Internal) implementation.
@implementation TSNPeer (Internal)
@end
