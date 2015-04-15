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
//  TSNAppViewController.m
//

#import "TSNAppViewController.h"
#import "TSNAppView.h"

// TSNAppViewController (TSNAppViewDelegate) interface.
@interface TSNAppViewController (TSNAppViewDelegate) <TSNAppViewDelegate>
@end

// TSNAppViewController (Internal) interface.
@interface TSNAppViewController (Internal)
@end

// TSNAppViewController implementation.
@implementation TSNAppViewController
{
@private
    // The app view.
    TSNAppView * _appView;
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
    
    // Allocate and initialize the app view.
    _appView = [[TSNAppView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [_appView setDelegate:(id<TSNAppViewDelegate>)self];
    
    // Done.
	return self;
}

// Creates the view that the controller manages.
- (void)loadView
{
    // Set the view.
    [self setView:_appView];
}

// Returns the supported interface orientations.
- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeLeft | UIInterfaceOrientationMaskLandscapeRight;
}

// Returns a value which indicates whether the view should autorotate.
- (BOOL)shouldAutorotate
{
    return YES;
}

@end

// TSNAppViewController (TSNAppViewDelegate) implementation.
@implementation TSNAppViewController (TSNAppViewDelegate)
@end

// TSNAppViewController (Internal) implementation.
@implementation TSNAppViewController (Internal)
@end

