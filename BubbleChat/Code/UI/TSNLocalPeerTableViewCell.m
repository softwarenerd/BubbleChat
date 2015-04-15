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
//  TSNLocalPeerTableViewCell.m
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import "TSNLocalPeerTableViewCell.h"

// The date formatter.
static NSDateFormatter * sDateFormatter;

// TSNLocalPeerTableViewCell (Internal) interface.
@interface TSNLocalPeerTableViewCell (Internal)
@end

// TSNLocalPeerTableViewCell implementation.
@implementation TSNLocalPeerTableViewCell
{
@private
    // The container view.
    UIView * _viewContainer;
    
    // The date / time label.
    UILabel * _labelDateTime;
    
    // The peer name label.
    UILabel * _labelName;
    
    // The message label.
    UILabel * _labelMessage;
    
    // The height.
    CGFloat _height;
}

// Static initialization.
+ (void)initialize
{
    // NSDateFormatter is expensive to alloc.
    sDateFormatter = [[NSDateFormatter alloc] init];
    [sDateFormatter setTimeZone:[NSTimeZone localTimeZone]];
    [sDateFormatter setDateFormat:@"HH:mm:ss z"];
}

// Class initializer.
- (instancetype)initWithMessage:(NSString *)message
{
    // Initialize superclass.
    self = [super init];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    [self setOpaque:NO];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setAutoresizesSubviews:YES];
    
    // Allocate, initialize, and add the container view.
    _viewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, 4.0, 0.0, 0.0)];
    [_viewContainer setOpaque:YES];
    [_viewContainer setBackgroundColor:[UIColor colorWithRGB:0x16a085]];
    [[_viewContainer layer] setCornerRadius:8.0];
    [_viewContainer setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self addSubview:_viewContainer];
    
    // Allocate, initialize, and add the date / time label.
    _labelDateTime = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 4.0, 0.0, 0.0)];
    [_labelDateTime setOpaque:NO];
    [_labelDateTime setClipsToBounds:YES];
    [_labelDateTime setBackgroundColor:[UIColor clearColor]];
    [_labelDateTime setTextColor:[UIColor colorWithRGB:0xecf0f1]];
    [_labelDateTime setText:[sDateFormatter stringFromDate:[[NSDate alloc] init]]];
    [_labelDateTime setFont:[UIFont systemFontOfSize:10.0]];
    [_labelDateTime sizeToFit];
    [_viewContainer addSubview:_labelDateTime];
    
    // Set the max width.
    CGFloat maxWidth = [_labelDateTime width];
    
    // Allocate, initialize, and add the name label.
    _labelName = [[UILabel alloc] initWithFrame:CGRectMake(0.0, [_labelDateTime bottom] + 3.0, 0.0, 0.0)];
    [_labelName setOpaque:NO];
    [_labelName setClipsToBounds:YES];
    [_labelName setBackgroundColor:[UIColor clearColor]];
    [_labelName setTextColor:[UIColor whiteColor]];
    [_labelName setLineBreakMode:NSLineBreakByTruncatingTail];
    [_labelName setText:@"You"];
    [_labelName setFont:[UIFont systemFontOfSize:12.0]];
    [_labelName sizeToFit];
    [_viewContainer addSubview:_labelName];
    
    // Set the max width.
    maxWidth = MAX(maxWidth, [_labelName width]);
    
    // Allocate, initialize, and add the message label.
    _labelMessage = [[UILabel alloc] initWithFrame:CGRectMake(0.0, [_labelName bottom] + 3.0, 0.0, 0.0)];
    [_labelMessage setOpaque:NO];
    [_labelMessage setClipsToBounds:YES];
    [_labelMessage setBackgroundColor:[UIColor clearColor]];
    [_labelMessage setTextColor:[UIColor whiteColor]];
    [_labelMessage setLineBreakMode:NSLineBreakByTruncatingTail];
    [_labelMessage setText:message];
    [_labelMessage setFont:[UIFont systemFontOfSize:14.0]];
    [_labelMessage sizeToFit];
    [_viewContainer addSubview:_labelMessage];
    
    // Set the max width.
    maxWidth = MAX(maxWidth, [_labelMessage width]);
    
    // Adjust the size and position of the view container.
    CGFloat viewContainerWidth = maxWidth + 16.0;
    [_viewContainer setFrame:CGRectMake([self width] - viewContainerWidth - 4.0, 4.0, viewContainerWidth, [_labelMessage bottom] + 4.0)];
    
    // Slide everything over to the right.
    [_labelDateTime moveFrameToOriginX:viewContainerWidth - [_labelDateTime width] - 8.0];
    [_labelName moveFrameToOriginX:viewContainerWidth - [_labelName width] - 8.0];
    [_labelMessage moveFrameToOriginX:viewContainerWidth - [_labelMessage width] - 8.0];
    
    // Set the height.
    _height = [_viewContainer bottom] + 4.0;
    
    // Done.
    return self;
}

// Gets the height.
- (CGFloat)height
{
    return _height;
}

@end

// TSNLocalPeerTableViewCell (Internal) implementation.
@implementation TSNLocalPeerTableViewCell (Internal)
@end
