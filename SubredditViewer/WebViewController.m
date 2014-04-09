//
//  WebViewController.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/8/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}
@end
