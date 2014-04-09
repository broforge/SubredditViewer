//
//  LoginViewController.h
//  SubredditViewer
//
//  Created by BrotoMan on 4/8/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
- (IBAction)signInButtonPressed:(id)sender;
- (IBAction)screenTapped:(id)sender;

@end
