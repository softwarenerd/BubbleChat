//
//  TSNAtomicFlag.h
//  softwarenerd.org
//
//  Created by Brian Lambert on 1/5/15.
//  Copyright (c) 2015 Brian Lambert.
//

#import <Foundation/Foundation.h>
#import "libkern/OSAtomic.h"

// TSNAtomicFlag interface.
@interface TSNAtomicFlag : NSObject

// Returns YES, if the flag is clear; otherwise, NO.
- (BOOL)isClear;

// Returns YES, if the flag is set; otherwise, NO.
- (BOOL)isSet;

// Tries to set the flag. Returns YES, if the flag was successfully set; otherwise, NO.
- (BOOL)trySet;

// Tries to clear the flag. Returns YES, if the flag was successfully cleared; otherwise, NO.
- (BOOL)tryClear;

@end
