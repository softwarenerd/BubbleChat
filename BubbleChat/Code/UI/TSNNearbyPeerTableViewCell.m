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
//  TSNNearbyPeerTableViewCell.m
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import "TSNNearbyPeerTableViewCell.h"

// The date formatter.
static NSDateFormatter * sDateFormatter;

// TSNNearbyPeerTableViewCell (Internal) interface.
@interface TSNNearbyPeerTableViewCell (Internal)
@end

// TSNNearbyPeerTableViewCell implementation.
@implementation TSNNearbyPeerTableViewCell
{
@private
    // The container view.
    UIView * _viewContainer;
    
    // The date / time label.
    UILabel * _labelDateTime;
    
    // The peer name label.
    UILabel * _labelPeerName;
    
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
- (instancetype)initWithPeer:(TSNPeer *)peer
                     message:(NSString *)message
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
    [self setAutoresizesSubviews:YES];
    [self setBackgroundColor:[UIColor clearColor]];
    
    // Allocate, initialize, and add the container view.
    _viewContainer = [[UIView alloc] initWithFrame:CGRectMake(4.0, 4.0, 0.0, 0.0)];
    [_viewContainer setOpaque:YES];
    [_viewContainer setBackgroundColor:[UIColor colorWithRGB:0xe5e5e5]];
    [[_viewContainer layer] setCornerRadius:8.0];
    [self addSubview:_viewContainer];
    
    // Allocate, initialize, and add the date / time label.
    _labelDateTime = [[UILabel alloc] initWithFrame:CGRectMake(8.0, 4.0, 0.0, 0.0)];
    [_labelDateTime setOpaque:NO];
    [_labelDateTime setClipsToBounds:YES];
    [_labelDateTime setBackgroundColor:[UIColor clearColor]];
    [_labelDateTime setTextColor:[UIColor blackColor]];
    [_labelDateTime setText:[sDateFormatter stringFromDate:[[NSDate alloc] init]]];
    [_labelDateTime setFont:[UIFont systemFontOfSize:10.0]];
    [_labelDateTime sizeToFit];
    [_viewContainer addSubview:_labelDateTime];
    
    // Set the max right.
    CGFloat maxRight = [_labelDateTime right];
    
    // Allocate, initialize, and add the peer name label.
    _labelPeerName = [[UILabel alloc] initWithFrame:CGRectMake(8.0, [_labelDateTime bottom] + 3.0, 0.0, 0.0)];
    [_labelPeerName setOpaque:NO];
    [_labelPeerName setClipsToBounds:YES];
    [_labelPeerName setBackgroundColor:[UIColor clearColor]];
    [_labelPeerName setTextColor:[UIColor blackColor]];
    NSString * peerName = [peer name];
    if ([peerName length] > 30)
    {
        peerName = [NSString stringWithFormat:@"%@...", [peerName substringWithRange:NSMakeRange(0, 30)]];
    }
    [_labelPeerName setText:peerName];
    [_labelPeerName setFont:[UIFont systemFontOfSize:12.0]];
    [_labelPeerName sizeToFit];
    [_viewContainer addSubview:_labelPeerName];
    
    // Set the max right.
    maxRight = MAX(maxRight, [_labelPeerName right]);
    
    // Allocate, initialize, and add the message label.
    _labelMessage = [[UILabel alloc] initWithFrame:CGRectMake(8.0, [_labelPeerName bottom] + 3.0, 0.0, 0.0)];
    [_labelMessage setOpaque:NO];
    [_labelMessage setClipsToBounds:YES];
    [_labelMessage setBackgroundColor:[UIColor clearColor]];
    CGFloat screenWidth = [[UIScreen mainScreen] bounds].size.width;
    UIFont * font = [UIFont systemFontOfSize:14.0];
    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
    NSMutableAttributedString * attributedString = [[NSMutableAttributedString alloc] initWithString:message
                                                                                          attributes:@{NSFontAttributeName:             font,
                                                                                                       NSForegroundColorAttributeName:  [UIColor blackColor],
                                                                                                       NSParagraphStyleAttributeName:   paragraphStyle}];
    CGSize size = [attributedString boundingRectWithSize:CGSizeMake(screenWidth - 40.0, CGFLOAT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                 context:nil].size;
    [_labelMessage setWidth:size.width
                     height:size.height];
    [_labelMessage setAttributedText:attributedString];
    [_viewContainer addSubview:_labelMessage];
    
    // Set the max right.
    maxRight = MAX(maxRight, [_labelMessage right]);
    
    // Adjust the size of the view container.
    [_viewContainer setWidth:maxRight + 8.0
                      height:[_labelMessage bottom] + 4.0];
    
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

// TSNNearbyPeerTableViewCell (Internal) implementation.
@implementation TSNNearbyPeerTableViewCell (Internal)
@end
