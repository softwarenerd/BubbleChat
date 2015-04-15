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
//  TSNAppView.m
//

#import <UIColor+Extensions.h>
#import <UIView+Extensions.h>
#import <TSNAtomicFlag.h>
#import <TSNThreading.h>
#import "TSNAppView.h"
#import "TSNNearbyPeersView.h"
#import "TSNBubbleView.h"

// TSNAppView (UITabBarDelegate) interface.
@interface TSNAppView (UITabBarDelegate) <UITabBarDelegate>
@end

// TSNAppView (Internal) interface.
@interface TSNAppView (Internal)

// UIKeyboardWillShowNotification callback.
- (void)keyboardWillShowNotificationCallback:(NSNotification *)notification;

// UIKeyboardWillHideNotification callback.
- (void)keyboardWillHideNotificationCallback:(NSNotification *)notification;

@end

// TSNAppView implementation.
@implementation TSNAppView
{
@private
    UIView * _viewContainer;
    
    // The workspace view. It contains the view for whatever tab is selected.
    UIView * _viewWorkspace;
    
    // The nearby peers tab bar item.
    UITabBarItem * _tabBarItemNearbyPeers;

    // The bubble tab bar item.
    UITabBarItem * _tabBarItemBubble;
    
    // The tab bar.
    UITabBar * _tabBar;
    
    // The nearby peers view.
    TSNNearbyPeersView * _nearbyPeersView;

    // The bubble view.
    TSNBubbleView * _bubbleView;
    
    // The current workspace view.
    UIView * _viewCurrentWorkspaceView;

    // In background atomic flag.
    TSNAtomicFlag * _atomicFlagInBackground;
}

// Class initializer.
- (instancetype)initWithFrame:(CGRect)frame
{
    // Initialize superclass.
    self = [super initWithFrame:frame];
    
    // Handle errors.
    if (!self)
    {
        return nil;
    }
    
    // Initialize.
    [self setBackgroundColor:[UIColor whiteColor]];
    [self setAutoresizesSubviews:YES];
    [self setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    
    // Get the height of the status bar. The workspace begins below it.
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;

    // Allocate, initialize, and add the container view. It is resized when the keyboard shows.
    _viewContainer = [[UIView alloc] initWithFrame:CGRectMake(0.0, statusBarHeight, [self width], [self height] - statusBarHeight)];
    [_viewContainer setBackgroundColor:[UIColor whiteColor]];
    [_viewContainer setAutoresizesSubviews:YES];
    [self addSubview:_viewContainer];
    
    // The default tint color for all UIViews is what we need to tint the tab bar items below.
    UIColor * highlightTintColor = [self tintColor];
    
    // Set-up font title text attributes for the tab bar items.
    UIFont * tabBarItemFont = [UIFont systemFontOfSize:12.0];
    NSDictionary * normalTabBarItemTitleTextAttributes = @{NSFontAttributeName:                 tabBarItemFont,
                                                           NSForegroundColorAttributeName:      [UIColor darkGrayColor]};
    NSDictionary * selectedTabBarItemTitleTextAttributes = @{NSFontAttributeName:               tabBarItemFont,
                                                             NSForegroundColorAttributeName:    highlightTintColor};

    // Allocate and initialize the nearby peers tab bar item.
    _tabBarItemNearbyPeers = [[UITabBarItem alloc] initWithTitle:@"Nearby Peers"
                                                           image:[UIImage imageNamed:@"NearbyPeers"]
                                                             tag:0];
    [_tabBarItemBubble setTitleTextAttributes:normalTabBarItemTitleTextAttributes
                                     forState:UIControlStateNormal];
    [_tabBarItemBubble setTitleTextAttributes:selectedTabBarItemTitleTextAttributes
                                     forState:UIControlStateSelected];
    
    // Allocate and initialize the bubble tab bar item.
    _tabBarItemBubble = [[UITabBarItem alloc] initWithTitle:@"Bubble"
                                                      image:[UIImage imageNamed:@"Bubble"]
                                                        tag:0];
    [_tabBarItemBubble setTitleTextAttributes:normalTabBarItemTitleTextAttributes
                                     forState:UIControlStateNormal];
    [_tabBarItemBubble setTitleTextAttributes:selectedTabBarItemTitleTextAttributes
                                     forState:UIControlStateSelected];
    
   
    // Allocate, initialize and add the tab bar.
    _tabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0.0, [_viewContainer height] - 49.0, [_viewContainer width], 49.0)];
    [_tabBar setBarStyle:UIBarStyleDefault];
    [_tabBar setItems:@[_tabBarItemNearbyPeers, _tabBarItemBubble]];
    [_tabBar setDelegate:(id<UITabBarDelegate>)self];
    [_tabBar setSelectedItem:_tabBarItemNearbyPeers];
    [_tabBar setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
    [_viewContainer addSubview:_tabBar];
    
    // Allocate, initialize, and add the workspace view. It contains the view for whatever tab is selected.
    _viewWorkspace = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, [_viewContainer width], [_viewContainer height] - [_tabBar height])];
    [_viewWorkspace setAutoresizesSubviews:YES];
    [_viewWorkspace setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
    [_viewWorkspace setBackgroundColor:[UIColor whiteColor]];
    [_viewContainer addSubview:_viewWorkspace];
    
    // Calculate the workspace frame. It is the frame for each of the possible workspace views below.
    CGRect workspaceFrame = [_viewWorkspace bounds];
    
    // Allocate, initialize, and add the nearby peers view.
    _nearbyPeersView = [[TSNNearbyPeersView alloc] initWithFrame:workspaceFrame];
    [_viewWorkspace addSubview:_nearbyPeersView];
    _viewCurrentWorkspaceView = _nearbyPeersView;
    
    // Allocate, initialize, and add the bubble view.
    _bubbleView = [[TSNBubbleView alloc] initWithFrame:workspaceFrame];
        
    // Add our observers.
    NSNotificationCenter * notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillShowNotificationCallback:)
                               name:UIKeyboardWillShowNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(keyboardWillHideNotificationCallback:)
                               name:UIKeyboardWillHideNotification
                             object:nil];

    // Done.
	return self;
}

// Dealloc.
- (void)dealloc
{
    // Remove our observers.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// TSNAppView (UITabBarDelegate) implementation.
@implementation TSNAppView (UITabBarDelegate)

// Called when a new view is selected by the user (but not programatically).
- (void)tabBar:(UITabBar *)tabBar
 didSelectItem:(UITabBarItem *)item
{
    // Select the new workspace view, if the mode has changed.
    UIView * newWorkspaceView;
    if (item == _tabBarItemNearbyPeers)
    {
        newWorkspaceView = _viewCurrentWorkspaceView != _nearbyPeersView ? _nearbyPeersView : nil;
    }
    else if (item == _tabBarItemBubble)
    {
        newWorkspaceView = _viewCurrentWorkspaceView != _bubbleView ? _bubbleView : nil;
    }
    else
    {
        // Bug.
        return;
    }
    
    // If we have a new workspace view, transition to it.
    if (newWorkspaceView)
    {
        [UIView transitionFromView:_viewCurrentWorkspaceView
                            toView:newWorkspaceView
                          duration:0.15
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:nil];
        _viewCurrentWorkspaceView = newWorkspaceView;
    }
}

@end

// TSNAppView (Internal) implementation.
@implementation TSNAppView (Internal)

// UIKeyboardWillShowNotification callback.
- (void)keyboardWillShowNotificationCallback:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    CGRect keyboardFrame = [[dictionary objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect screenBounds = [self convertRect:[self bounds]
                                     toView:nil];
    CGFloat containerViewShrinkHeight = (screenBounds.origin.y + screenBounds.size.height) - keyboardFrame.origin.y;
    [UIView beginAnimations:nil
                    context:NULL];
    [UIView setAnimationDuration:[dictionary[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[dictionary[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [_viewContainer setFrame:CGRectMake(0.0, [_viewContainer y], [_viewContainer width], [_viewContainer height] - containerViewShrinkHeight)];
    [UIView commitAnimations];
}

// UIKeyboardWillHideNotification callback.
- (void)keyboardWillHideNotificationCallback:(NSNotification *)notification
{
    NSDictionary * dictionary = [notification userInfo];
    [UIView beginAnimations:nil
                    context:NULL];
    [UIView setAnimationDuration:[dictionary[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[dictionary[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    CGFloat statusBarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    [_viewContainer setFrame:CGRectMake(0.0, statusBarHeight, [self width], [self height] - statusBarHeight)];
    [UIView commitAnimations];
}

@end


