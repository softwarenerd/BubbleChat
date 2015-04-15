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
//  UIView+Extensions.h
//

#import <UIKit/UIKit.h>

// UIView (Extensions) interface.
@interface UIView (Extensions)

// Gets the x of the view.
- (CGFloat)x;

// Gets the y of the view.
- (CGFloat)y;

// Gets the width of the view.
- (CGFloat)width;

// Gets the height of the view.
- (CGFloat)height;

// Gets the right of the view.
- (CGFloat)right;

// Gets the bottom of the view.
- (CGFloat)bottom;

// Gets the size of the view.
- (CGSize)size;

// Moves the view to the specified X locaiton.
- (void)moveFrameToOriginX:(CGFloat)x;

// Moves the view to the specified Y locaiton.
- (void)moveFrameToOriginY:(CGFloat)y;

// Moves the view to the specified X, Y locaiton.
- (void)moveFrameToOriginX:(CGFloat)x y:(CGFloat)y;

// Sets the width of the view.
- (void)setWidth:(CGFloat)width;

// Sets the height of the view.
- (void)setHeight:(CGFloat)height;

// Sets the width and height of the view.
- (void)setWidth:(CGFloat)width height:(CGFloat)height;

// Moves the view to the specified X locaiton and sets its width.
- (void)moveFrameToOriginX:(CGFloat)x setWidth:(CGFloat)width;

// Moves the view to the specified Y locaiton and sets its height.
- (void)moveFrameToOriginY:(CGFloat)y setHeight:(CGFloat)height;

@end
