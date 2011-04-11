//
//  monkeyViewController.h
//  monkey
//
//  Created by Robert Diamond on 4/9/11.
//  Copyright 2011 none. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface monkeyViewController : UIViewController<AVAudioPlayerDelegate> {
	NSUInteger hiddenLocation;
	NSTimer *clock;
	NSUInteger elapsed_seconds;
	AVAudioPlayer *avp;
	AVAudioPlayer *win;
}

@property (nonatomic, assign) IBOutlet UIButton *startButton;
@property (nonatomic, assign) IBOutlet UITextField *timeRemaining;
@property (nonatomic, assign) IBOutlet UILabel *where;

- (IBAction)startGame:(id)sender;
- (void)guess:(id)sender;
- (void)tick:(NSTimer *)timer;
- (void)resetGame;
@end

