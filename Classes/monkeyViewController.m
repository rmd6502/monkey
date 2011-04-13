//
//  monkeyViewController.m
//  monkey
//
//  Created by Robert Diamond on 4/9/11.
//  Copyright 2011 none. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "monkeyViewController.h"

@implementation monkeyViewController
@synthesize startButton;
@synthesize timeRemaining;
@synthesize where;


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	CGColorSpaceRef csp = CGColorSpaceCreateDeviceRGB();
	CGColorRef col1 = [UIColor cyanColor].CGColor;
	CGFloat comps[4] = {0};
	memcpy(comps, CGColorGetComponents(col1), 4 * sizeof(CGFloat));
	comps[0] = 0.75;
	CGColorRef col2 = CGColorCreate(csp, comps);
    comps[0] = 0;
    for (int i=0; i < 3; ++i) comps[i] *= .7;
    col1 = CGColorCreate(csp, comps);
	//CGColorRef col2 = [UIColor whiteColor].CGColor;
	const CGColorRef cols[] = {col1, col2};
	CFArrayRef collist = CFArrayCreate(nil, (const void **)cols, sizeof(cols)/sizeof(CGColorRef), NULL);
	CGFloat locs[] = {.99,0.0};
	
	UIButton *b1 = (UIButton *)[self.view viewWithTag:1001];
	CGContextRef ctx = CGBitmapContextCreate(nil, b1.bounds.size.width, b1.bounds.size.height, 8, 4 * b1.bounds.size.width, csp, kCGImageAlphaPremultipliedLast);
	CGGradientRef grad = CGGradientCreateWithColors(csp, collist, locs);
	CGContextDrawRadialGradient(ctx, grad, CGPointMake(b1.bounds.size.width/2,b1.bounds.size.height/2), 1, CGPointMake(b1.bounds.size.width/2,b1.bounds.size.height/2), b1.bounds.size.width/2, kCGGradientDrawsAfterEndLocation);
	CGImageRef bg = CGBitmapContextCreateImage(ctx);
	UIImage *im = [UIImage imageWithCGImage:bg];
	
	for (int i=1001; i < 1010; ++i) {
		UIButton *b = (UIButton *)[self.view viewWithTag:i];
		[b addTarget:self action:@selector(guess:) forControlEvents:UIControlEventTouchUpInside];
		[b setBackgroundImage:im forState:UIControlStateNormal];
	}
	CGImageRelease(bg);
	CFRelease(collist);
	CGColorRelease(col2);
    CGColorRelease(col1);
	CGGradientRelease(grad);
	CGColorSpaceRelease(csp);
	[self resetGame];
	
	NSError *error = nil;
	NSURL *noiseURL = [[NSBundle mainBundle] 
					   URLForResource:@"buzzer" 
					   withExtension:@"mp3"];
	avp = [[AVAudioPlayer alloc] 
						  initWithContentsOfURL:noiseURL error:&error];
	if (error) {
		NSLog(@"failed to load sound: %@", [error localizedDescription]);
		return;
	}
	noiseURL = [[NSBundle mainBundle] 
				URLForResource:@"win" 
				withExtension:@"m4a"];
	win = [[AVAudioPlayer alloc] 
		   initWithContentsOfURL:noiseURL error:&error];
	[avp setDelegate:self];
	[avp setVolume:1.0];
	[avp prepareToPlay];
	[win setDelegate:self];
	[win setVolume:1.0];
	[win prepareToPlay];
	
	[self becomeFirstResponder];
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"motion %@", event);
	if (motion == UIEventSubtypeMotionShake) {
		[self startGame:nil];
	}
}

- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	NSLog(@"motion began %@", event);
	if (motion == UIEventSubtypeMotionShake) {
		[self startGame:nil];
	}
}

- (void) viewDidUnload {
	[avp release];
	[win release];
	[super viewDidUnload];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
}

- (void)resetGame {
	CABasicAnimation *trans = [CABasicAnimation animation];
	trans.keyPath = @"transform.scale";
	trans.repeatCount = HUGE_VALF;
	trans.duration = 0.5;
	trans.autoreverses = YES;
	trans.removedOnCompletion = NO;
	trans.fillMode = kCAFillModeForwards;
	trans.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	trans.fromValue = [NSNumber numberWithFloat:0.9];
	trans.toValue = [NSNumber numberWithFloat:1.1];
	[self.startButton.titleLabel.layer addAnimation:trans forKey:@"pulse"];
	for (int i=1001; i < 1010; ++i) [(UIButton *)[self.view viewWithTag:i] setEnabled:NO];
	elapsed_seconds = 0;
}

- (IBAction)startGame:(id)sender {
	for (int i=1001; i < 1010; ++i) {
		UIButton *b = (UIButton *)[self.view viewWithTag:i];
		[b setImage:nil forState:UIControlStateNormal];
		[b setTitle:@"?" forState:UIControlStateNormal];
		b.enabled = YES;
	}
	[self.startButton.titleLabel.layer removeAllAnimations];
	NSUInteger isCorrect = 0;
	SecRandomCopyBytes(kSecRandomDefault, sizeof(NSUInteger), (void *)&isCorrect);
	hiddenLocation = isCorrect % 9;
	elapsed_seconds = 0;
	[timeRemaining setText:@"00:00:00"];
	if (clock) {
		[clock invalidate];
	}
	clock = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick:) userInfo:nil repeats:YES];
}

- (BOOL)canBecomeFirstResponder { return YES; }

- (void)guess:(id)sender {
	UIButton *guessed = (UIButton *)sender;
	guessed.enabled = NO;
	
	CATransition *trans = [[CATransition alloc] init];
	trans.duration = 0.25;
	trans.type = kCATransitionFade;
	[guessed.layer addAnimation:trans forKey:@"Fade"];
	[trans release];
	[CATransaction begin];
	if (guessed.tag - 1001 == hiddenLocation) {
		[guessed setTitle:@"" forState:UIControlStateNormal];
		[guessed setImage:[UIImage imageNamed:@"monkey_toy"] forState:UIControlStateNormal];
		[clock invalidate];
		clock = nil;
		[self resetGame];
		[win play];
	} else {
		[guessed setTitle:@"×" forState:UIControlStateNormal];
		[avp stop];
		[avp prepareToPlay];
		[avp play];
	}
	[CATransaction commit];
}

- (void)tick:(NSTimer *)timer {
	++elapsed_seconds;
	[timeRemaining setText:[NSString stringWithFormat:@"%02d:%02d:%02d",
							elapsed_seconds / 3600, (elapsed_seconds % 3600) / 60, elapsed_seconds % 60]];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    [super dealloc];
}
						 

@end
