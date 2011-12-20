//
//  BufferedNavigationController.h
//  CherryPop
//
//  Created by Andrew Armstrong on 21/11/11.
//  Copyright (c) 2011 Scramble Media. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UINavigationController.h>

@interface BufferedNavigationController : UINavigationController <UINavigationControllerDelegate>

- (void) pushCodeBlock:(void (^)())codeBlock;
- (void) runNextBlock;

@property (nonatomic, retain) NSMutableArray* stack;
@property (nonatomic, assign) bool transitioning;

@end
