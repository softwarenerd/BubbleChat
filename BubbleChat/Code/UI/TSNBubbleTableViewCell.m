//
//  TSNBubbleTableViewCell.m
//  BubbleChat
//
//  Created by Brian Lambert on 4/14/15.
//  Copyright (c) 2015 Brian Lambert. All rights reserved.
//

#import "TSNBubbleTableViewCell.h"

// TSNBubbleTableViewCell (Internal) interface.
@interface TSNBubbleTableViewCell (Internal)
@end

// TSNBubbleTableViewCell implementation.
@implementation TSNBubbleTableViewCell
{
@private
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

// Returns the height.
- (CGFloat)height
{
    return 0.0;
}

@end

// TSNBubbleTableViewCell (Internal) implementation.
@implementation TSNBubbleTableViewCell (Internal)
@end
