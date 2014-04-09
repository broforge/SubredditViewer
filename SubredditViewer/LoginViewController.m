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

- (BOOL)login:(NSString *)username password:(NSString *)password error:(NSError **)loginError {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.reddit.com/api/login/%@",username]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    NSData *requestBody = [[NSString stringWithFormat:@"api_type=json&user=%@&passwd=%@",username,password] dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBody;
    NSHTTPURLResponse *response;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    NSDictionary *accountData = [[jsonData objectForKey:@"json"] objectForKey:@"data"];
    if (accountData) {
        self.accountInfo = accountData;
        return YES;
    }

    NSDictionary *errorDetails;
    NSArray *requestError = [[jsonData objectForKey:@"json"] objectForKey:@"errors"];
    if (requestError) {
        NSArray *description = [requestError objectAtIndex:0];
        NSMutableString *fullDescription = [[NSMutableString alloc] init];
        for (NSString *item in description) {
            [fullDescription appendFormat:@"%@\n", item];
        }
        errorDetails = [NSDictionary dictionaryWithObject:fullDescription forKey:NSLocalizedDescriptionKey];
    }
    else {
        errorDetails = [NSDictionary dictionaryWithObject:@"connection error" forKey:NSLocalizedDescriptionKey];
    }
    
    *loginError = [NSError errorWithDomain:@"com.pnd.subredditviewer" code:0 userInfo:errorDetails];
    return NO;
}

#pragma mark - Segue

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
    NSError *error;
    if ([self login:self.usernameField.text password:self.passwordField.text error:&error]) {
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
