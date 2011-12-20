//
//  BufferedNavigationController.m
//  CherryPop
//
//  Created by Andrew Armstrong on 21/11/11.
//  Copyright (c) 2011 Scramble Media. All rights reserved.
//

#import "BufferedNavigationController.h"

@implementation BufferedNavigationController
@synthesize transitioning = _transitioning;
@synthesize stack = _stack;

- (void)dealloc {
    [self.stack removeAllObjects];
    self.stack = nil;
    
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.stack = [[[NSMutableArray alloc] init] autorelease];
        self.navigationBar.tintColor = [UIColor colorWithRed:211.0f/255 green:62.0f/255 blue:62.0f/255 alpha:1];
    }
    
    return self;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    @synchronized(self.stack) {
        if (self.transitioning) {
            void (^codeBlock)(void) = [^{
                [super popViewControllerAnimated:animated];
            } copy];
            [self.stack addObject:codeBlock];
            [codeBlock release];
            
            // We cannot show what viewcontroller is currently animated now
            return nil;
        } else {
            return [super popViewControllerAnimated:animated];
        }
    }
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
    @synchronized(self.stack) {
        if (self.transitioning) {
            // Copy block so its no longer on the (real software) stack
            void (^codeBlock)(void) = [^{
                [super setViewControllers:viewControllers animated:animated];
            } copy];
            
            // Add to the stack list and then release
            [self.stack addObject:codeBlock];
            [codeBlock release];
        } else {
            [super setViewControllers:viewControllers animated:animated];
        }
    }
}

- (void) pushCodeBlock:(void (^)())codeBlock{
    @synchronized(self.stack) {
        [self.stack addObject:[[codeBlock copy] autorelease]];
        
        if (!self.transitioning)
            [self runNextBlock];
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    @synchronized(self.stack) {
        if (self.transitioning) {
            void (^codeBlock)(void) = [^{
                [super pushViewController:viewController animated:animated];
            } copy];
            [self.stack addObject:codeBlock];
            [codeBlock release];
        } else {
            [super pushViewController:viewController animated:animated];
        }
    }
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    @synchronized(self.stack) {
        self.transitioning = true;
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    @synchronized(self.stack) {
        self.transitioning = false;

        [self runNextBlock];
    }
}

- (void) runNextBlock {
    if (self.stack.count == 0)
        return;
    
    void (^codeBlock)(void) = [self.stack objectAtIndex:0];
    
    // Execute block, then remove it from the stack (which will dealloc)
    codeBlock();
    
    [self.stack removeObjectAtIndex:0];
}

@end
