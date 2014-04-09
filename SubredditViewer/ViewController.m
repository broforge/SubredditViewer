//
//  ViewController.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/7/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (strong, nonatomic) NSArray *posts;
@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation ViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.operationQueue = [[NSOperationQueue alloc] init];
}

- (void)sendSubredditRequest:(NSString *)subreddit {
    NSString *requestString = [NSString stringWithFormat:@"http://reddit.com/r/%@.json", subreddit];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (data) {
        [self parseRedditData:data];
    }
    else {
        NSLog(@"connection error: %@", [error localizedDescription]);
    }
}

- (void)parseRedditData:(NSData *)data {
    NSError *error;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (jsonData) {
        self.posts = [[jsonData objectForKey:@"data" ]objectForKey:@"children"];
        NSLog(@"%@",[self.posts description]);
        [self.tableView reloadData];
    }
    else {
        NSLog(@"error parsing json: %@", [error localizedDescription]);
    }
}

#pragma mark - UITableViewDataSource 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSDictionary *post = [self.posts objectAtIndex:indexPath.row];
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1];
    imageView.image = nil;

    NSString *imageURL = [[post objectForKey:@"data"] objectForKey:@"thumbnail"];
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];
    [NSURLConnection sendAsynchronousRequest:imageRequest
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               dispatch_async(dispatch_get_main_queue(),
                                              ^{
                                                  UIImage *image = [UIImage imageWithData:data];
                                                  imageView.image = image;
                                                  [imageView setNeedsDisplay];
                                              });
                           }];
    
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:2];
    title.text = [[post objectForKey:@"data"] objectForKey:@"title"];
    
    UILabel *author = (UILabel *)[cell.contentView viewWithTag:3];
    author.text = [[post objectForKey:@"data"] objectForKey:@"author"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *post = [self.posts objectAtIndex:indexPath.row];
    NSURL *url = [NSURL URLWithString:[[post objectForKey:@"data"] objectForKey:@"url"]];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.tapGesture.enabled = YES;
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.view endEditing:YES];
    self.tapGesture.enabled = NO;
    
    if (searchBar.text.length > 0) {
        [self sendSubredditRequest:searchBar.text];
    }
}

#pragma mark - IBAction

- (IBAction)screenTapped:(id)sender {
    [self.view endEditing:YES];
    self.tapGesture.enabled = NO;
}
@end
