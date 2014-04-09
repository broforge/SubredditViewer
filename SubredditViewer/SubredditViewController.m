//
//  SubredditViewController.m
//  SubredditViewer
//
//  Created by BrotoMan on 4/7/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import "SubredditViewController.h"
#import "WebViewController.h"
#import "RedditManager.h"
#import <KiipSDK/KiipSDK.h>

@interface SubredditViewController ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;
@property (strong, nonatomic) NSString *subreddit;
@property (strong, nonatomic) NSMutableArray *posts;
@property (strong, nonatomic) NSMutableDictionary *selectedPost;
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
    
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateFormat:@"MMM dd, yyyy HH:mm"];
}

- (void)loadSubreddit:(NSString *)subreddit {
    if (![subreddit isEqualToString:self.subreddit]) {
        [self.posts removeAllObjects];
        [self.tableViewController.tableView reloadData];
    }
    self.subreddit = subreddit;
    
    RedditManager *reddit = [RedditManager sharedInstance];
    NSMutableArray *posts = [reddit postsForSubreddit:self.subreddit];
    if (posts) {
        self.posts = posts;
        [self.tableViewController.tableView reloadData];
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
    
    UILabel *title = (UILabel *)[cell.contentView viewWithTag:2];
    title.text = [post objectForKey:@"title"];
    
    UILabel *author = (UILabel *)[cell.contentView viewWithTag:3];
    author.text = [post objectForKey:@"author"];
    
    UILabel *date = (UILabel *)[cell.contentView viewWithTag:5];
    NSDate *postDate = [NSDate dateWithTimeIntervalSince1970:[[post objectForKey:@"created_utc"] doubleValue]];
    date.text = [self.dateFormatter stringFromDate:postDate];
    
    UIButton *button = (UIButton *)[cell.contentView viewWithTag:6];
    [button addTarget:self action:@selector(starTapped:) forControlEvents:UIControlEventTouchUpInside];
    
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

    NSInteger vote;
    id likeValue;
    if ([title isEqualToString:@"Up"]) {
        vote = 1;
        likeValue = @(1);
    }
    else if ([title isEqualToString:@"Down"]) {
        vote = -1;
        likeValue = @(0);
    }
    else {
        vote = 0;
        likeValue = [NSNull null];
    }
    
    RedditManager *reddit = [RedditManager sharedInstance];
    if ([reddit vote:vote forPost:self.selectedPost]) {
        [self.selectedPost setObject:likeValue forKey:@"likes"];
        [self.tableViewController.tableView reloadData];

        if (vote == 1) {
            [self showKiipMoment];
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
