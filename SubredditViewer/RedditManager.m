//
//  RedditManager.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/9/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "RedditManager.h"

@interface RedditManager()

@end

@implementation RedditManager

+ (id)sharedInstance {
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
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

- (NSMutableArray *)postsForSubreddit:(NSString *)subreddit {
    NSString *requestString = [NSString stringWithFormat:@"http://reddit.com/r/%@.json", subreddit];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];

    if (jsonData) {
        NSMutableArray *posts = [NSMutableArray array];
        NSArray *postData = [[jsonData objectForKey:@"data" ]objectForKey:@"children"];
        for (NSDictionary *post in postData) {
            NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:[post objectForKey:@"data"]];
            if (entry) {
                [posts addObject:entry];
            }
        }
        return posts;
    }
    else {
        NSLog(@"error loading subreddit: %@", error.localizedDescription);
        return nil;
    }
}

- (BOOL)vote:(NSInteger)vote forPost:(NSDictionary *)post {
    NSString *modhash = [self.accountInfo objectForKey:@"modhash"];
    NSString *fullname = [post objectForKey:@"name"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.reddit.com/api/vote"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSString *requestBody = [NSString stringWithFormat:@"uh=%@&id=%@&dir=%ld", modhash, fullname, (long)vote];
    request.HTTPBody = [requestBody dataUsingEncoding:NSUTF8StringEncoding];
    
    NSHTTPURLResponse *response;
    NSError *error;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    if (response.statusCode == 200) {
        return YES;
    }
    else {
        NSLog(@"error posting vote: %@", error.localizedDescription);
        return NO;
    }
}

@end
