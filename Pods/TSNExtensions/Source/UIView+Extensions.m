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
//  UIView+Extensions.m
//

#import "UIView+Extensions.h"

// UIView (Extensions) implementation.
@implementation UIView (Extensions)

// Gets the x of the view.
- (CGFloat)x
{
    return [self frame].origin.x;
}

// Gets the y of the view.
- (CGFloat)y
{
    return [self frame].origin.y;
}

// Gets the width of the view.
- (CGFloat)width
{
    return [self bounds].size.width;
}

// Gets the height of the view.
- (CGFloat)height
{
    return [self bounds].size.height;
}

// Gets the right of the view.
- (CGFloat)right
{
    CGRect frame = [self frame];
    return frame.origin.x + frame.size.width;
}

// Gets the bottom of the view.
- (CGFloat)bottom
{
    CGRect frame = [self frame];
    return frame.origin.y + frame.size.height;
}

// Gets the size of the view.
- (CGSize)size
{
    return [self bounds].size;
}

// Moves the view to the specified X locaiton.
- (void)moveFrameToOriginX:(CGFloat)x
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(x, frame.origin.y, frame.size.width, frame.size.height)];
}

// Moves the view to the specified Y locaiton.
- (void)moveFrameToOriginY:(CGFloat)y
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(frame.origin.x, y, frame.size.width, frame.size.height)];
}

// Moves the view to the specified X, Y locaiton.
- (void)moveFrameToOriginX:(CGFloat)x y:(CGFloat)y
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(x, y, frame.size.width, frame.size.height)];
}

// Sets the width of the view.
- (void)setWidth:(CGFloat)width
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(frame.origin.x, frame.origin.y, width, frame.size.height)];
}

// Sets the height of the view.
- (void)setHeight:(CGFloat)height
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, height)];
}

// Sets the width and height of the view.
- (void)setWidth:(CGFloat)width height:(CGFloat)height
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(frame.origin.x, frame.origin.y, width, height)];
}

// Moves the view to the specified X locaiton and sets its width.
- (void)moveFrameToOriginX:(CGFloat)x setWidth:(CGFloat)width
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(x, frame.origin.y, width, frame.size.height)];
}

// Moves the view to the specified Y locaiton and sets its height.
- (void)moveFrameToOriginY:(CGFloat)y setHeight:(CGFloat)height
{
    CGRect frame = [self frame];
    [self setFrame:CGRectMake(frame.origin.x, y, frame.size.width, height)];
}

@end
