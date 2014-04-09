//
//  SubredditViewController.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/7/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "SubredditViewController.h"
#import "WebViewController.h"
#import <KiipSDK/KiipSDK.h>

@interface SubredditViewController ()

@property (strong, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSMutableDictionary *selectedPost;
@property (strong, nonatomic) NSString *subreddit;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (weak, nonatomic) UITableViewController *tableViewController;

@end

@implementation SubredditViewController

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.operationQueue = [[NSOperationQueue alloc] init];
    
    self.posts = [NSMutableArray array];
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"MMM dd, yyyy HH:mm"];
}

- (void)loadSubreddit:(NSString *)subreddit {
    if (![subreddit isEqualToString:self.subreddit]) {
        [self.posts removeAllObjects];
    }
    self.subreddit = subreddit;
    NSString *requestString = [NSString stringWithFormat:@"http://reddit.com/r/%@.json", self.subreddit];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    NSError *error;
    NSURLResponse *response;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (data) {
        [self parseRedditData:data];
    }
    else {
        NSLog(@"error loading subreddit: %@", error.localizedDescription);
    }
}

- (void)parseRedditData:(NSData *)data {
    NSError *error;
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (jsonData) {
        [self.posts removeAllObjects];
        NSArray *postData = [[jsonData objectForKey:@"data" ]objectForKey:@"children"];
        for (NSDictionary *post in postData) {
            NSMutableDictionary *entry = [NSMutableDictionary dictionaryWithDictionary:[post objectForKey:@"data"]];
            if (entry) {
                [self.posts addObject:entry];
            }
        }
        [self.tableViewController.tableView reloadData];
    }
    else {
        NSLog(@"error parsing subreddit posts: %@", error.localizedDescription);
    }
}

- (void)starTapped:(id)sender {
    CGPoint senderPosition = [sender convertPoint:CGPointZero toView:self.tableViewController.tableView];
    NSIndexPath *indexPath = [self.tableViewController.tableView indexPathForRowAtPoint:senderPosition];
    
    self.selectedPost = [self.posts objectAtIndex:indexPath.row];
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Vote"
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Up", @"None", @"Down", nil];
    [actionSheet showInView:self.view];
}

- (void)refresh:(id)sender {
    [self loadSubreddit:self.subreddit];
    [(UIRefreshControl *)sender endRefreshing];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ShowWebView"]) {
        WebViewController *viewController = [segue destinationViewController];
        viewController.url = [NSURL URLWithString:[self.selectedPost objectForKey:@"url"]];
    }
    else if ([segue.identifier isEqualToString:@"EmbedTableViewController"]) {
        self.tableViewController = [segue destinationViewController];
        
        __weak id this = self;
        self.tableViewController.tableView.delegate =  this;
        self.tableViewController.tableView.dataSource = this;
        
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
        self.tableViewController.refreshControl = refreshControl;
    }
}

#pragma mark - UITableViewDataSource 

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    NSDictionary *post = [self.posts objectAtIndex:indexPath.row];
    
    UIImageView *star = (UIImageView *)[cell.contentView viewWithTag:4];
    NSNumber *likes = [post objectForKey:@"likes"];
    if ((id)likes == [NSNull null]) {
        star.image = [UIImage imageNamed:@"star"];
    }
    else if (likes.integerValue == 0) {
        star.image = [UIImage imageNamed:@"starDown"];
    }
    else {
        star.image = [UIImage imageNamed:@"starUp"];
    }
    
    UIImageView *icon = (UIImageView *)[cell.contentView viewWithTag:1];
    icon.image = nil;

    NSString *imageURL = [post objectForKey:@"thumbnail"];
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURL]
                                                  cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                              timeoutInterval:60];
    
    [NSURLConnection sendAsynchronousRequest:imageRequest
                                       queue:self.operationQueue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               UIImage *image = [UIImage imageWithData:data];
                               dispatch_async(dispatch_get_main_queue(),
                                              ^{
                                                  icon.image = image;
                                                  [icon setNeedsDisplay];
                                              });
                           }];
    
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:2];
    title.text = [post objectForKey:@"title"];
    
    UILabel *author = (UILabel *)[cell.contentView viewWithTag:3];
    author.text = [post objectForKey:@"author"];
    
    UILabel *date = (UILabel *)[cell.contentView viewWithTag:5];
    NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:[[post objectForKey:@"created_utc"] doubleValue]];
    date.text = [self.dateFormatter stringFromDate:postDate];
    
    UIButton *button = (UIButton *)[cell.contentView viewWithTag:6];
    [button addTarget:self action:@selector(starTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    self.selectedPost = [self.posts objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"ShowWebView" sender:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.tapGesture.enabled = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.view endEditing:YES];
    self.tapGesture.enabled = NO;
    
    if (searchBar.text.length > 0) {
        [self loadSubreddit:searchBar.text];
    }
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([title isEqualToString:@"Cancel"]) {
        return;
    }
    
    NSString *modhash = [self.accountInfo objectForKey:@"modhash"];
    NSString *fullname = [self.selectedPost objectForKey:@"name"];
    
    NSURL *url = [NSURL URLWithString:@"http://www.reddit.com/api/vote"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];

    NSInteger dir;
    id likes;
    if ([title isEqualToString:@"Up"]) {
        dir = 1;
        likes = @(1);
    }
    else if ([title isEqualToString:@"Down"]) {
        dir = -1;
        likes = @(0);
    }
    else {
        dir = 0;
        likes = [NSNull null];
    }

    NSString *body = [NSString stringWithFormat:@"uh=%@&id=%@&dir=%ld", modhash, fullname, (long)dir];
    NSData *requestBody = [body dataUsingEncoding:NSUTF8StringEncoding];
    request.HTTPBody = requestBody;
    
    NSHTTPURLResponse *response;
    NSError *error;
    if ([NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error]) {
        NSInteger statusCode = response.statusCode;
        if (statusCode == 200) {
            if (dir == 1) {
                [self showKiipMoment];
            }
            [self.selectedPost setObject:likes forKey:@"likes"];
            [self.tableViewController.tableView reloadData];
        }
        else {
            NSLog(@"error posting vote: %@", error.localizedDescription);
        }
    }
}

#pragma mark - Kiip

- (void)showKiipMoment {
    [[Kiip sharedInstance] saveMoment:@"UpVoted" withCompletionHandler:^(KPPoptart* popTart, NSError* error)
     {
         if (error) {
             NSLog(@"error showing kiip moment: %@", error.localizedDescription);
         }
         else if (popTart) {
             [popTart show];
         }
         else if (!popTart) {
             NSLog(@"error showing kiip moment: no rewards available");
         }
     }];

}

#pragma mark - IBAction

- (IBAction)screenTapped:(id)sender {
    [self.view endEditing:YES];
    self.tapGesture.enabled = NO;
    self.searchBar.text = self.subreddit;
}



@end
