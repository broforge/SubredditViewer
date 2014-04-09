//
//  LoginViewController.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/8/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "LoginViewController.h"
#import "SubredditViewController.h"

@interface LoginViewController ()

@property (strong, nonatomic) NSDictionary *accountInfo;

@end

@implementation LoginViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (BOOL)login:(NSString *)username password:(NSString *)password {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com/api/login/%@",username]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [[NSString stringWithFormat:@"api_type=json&user=%@&passwd=%@",username,password] dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBody;
    NSHTTPURLResponse *response = NULL;
    NSError *error = NULL;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (data) {
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        self.accountInfo = [[jsonData objectForKey:@"json"] objectForKey:@"data"];
        return YES;
    }
    
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowSubredditView"]) {
        SubredditViewController *viewController = [segue destinationViewController];
        viewController.accountInfo = self.accountInfo;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBAction

- (IBAction)signInButtonPressed:(id)sender {
    
    if ([self login:self.usernameField.text password:self.passwordField.text]) {
        [self performSegueWithIdentifier:@"ShowSubredditView" sender:nil];
    }
    else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:nil
                              message:@"Incorrect username and/or password"
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
