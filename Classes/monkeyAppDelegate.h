//
//  monkeyAppDelegate.h
//  monkey
//
//  Created by Robert Diamond on 4/9/11.
//  Copyright 2011 none. All rights reserved.
//

#import <UIKit/UIKit.h>

@class monkeyViewController;

@interface monkeyAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    monkeyViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet monkeyViewController *viewController;

@end

