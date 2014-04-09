//
//  RedditManager.h
//  SubredditViewer
//
//  Created by BrotoMan on 4/9/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RedditManager : NSObject

@property (strong, nonatomic) NSDictionary *accountInfo;
@property (strong, nonatomic) NSArray *posts;

+ (id)sharedInstance;

- (BOOL)login:(NSString *)username password:(NSString *)password error:(NSError **)loginError;
- (NSMutableArray *)postsForSubreddit:(NSString *)subreddit;
- (BOOL)vote:(NSInteger)vote forPost:(NSDictionary *)post;

@end
