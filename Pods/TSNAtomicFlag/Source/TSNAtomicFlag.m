//
//  TSNAtomicFlag.m
//  softwarenerd.org
//
//  Created by Brian Lambert on 1/5/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import "TSNAtomicFlag.h"

// TSNAtomicFlag (Internal) interface.
@interface TSNAtomicFlag (Internal)
@end

// TSNAtomicFlag implementation.
@implementation TSNAtomicFlag
{
@private
    // The flag.
    volatile int32_t _flag;
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
    
    // Done.
    return self;
}

// Returns YES, if the flag is clear; otherwise, NO.
- (BOOL)isClear
{
    return OSAtomicCompareAndSwap32Barrier(0, 0, &_flag);
}

// Returns YES, if the flag is set; otherwise, NO.
- (BOOL)isSet
{
    return OSAtomicCompareAndSwap32Barrier(1, 1, &_flag);
}

// Tries to set the flag. Returns YES, if the flag was successfully set; otherwise, NO.
- (BOOL)trySet
{
    return OSAtomicCompareAndSwap32Barrier(0, 1, &_flag);
}

// Tries to clear the flag. Returns YES, if the flag was successfully cleared; otherwise, NO.
- (BOOL)tryClear
{
    return OSAtomicCompareAndSwap32Barrier(1, 0, &_flag);
}

@end

// TSNAtomicFlag (Internal) implementation.
@implementation TSNAtomicFlag (Internal)
@end
