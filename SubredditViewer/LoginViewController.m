//
//  LoginViewController.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/8/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "LoginViewController.h"
#import "RedditManager.h"
#import "SubredditViewController.h"

@interface LoginViewController ()

@end

@implementation LoginViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBAction

- (IBAction)signInButtonPressed:(id)sender {
    RedditManager *reddit = [RedditManager sharedInstance];
    NSError *error;
    if ([reddit login:self.usernameField.text password:self.passwordField.text error:&error]) {
        [self performSegueWithIdentifier:@"ShowSubredditView" sender:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:nil
                              message:[error localizedDescription]
                              delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles: nil];
        [alert show];
    }
}

- (IBAction)screenTapped:(id)sender {
    [self.view endEditing:YES];
}

@end
