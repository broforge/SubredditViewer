//
//  SubredditViewController.h
//  SubredditViewer
//
//  Created by BrotoMan on 4/7/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubredditViewController : UIViewController <NSURLConnectionDataDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (strong, nonatomic) NSDictionary *accountInfo;

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;
- (IBAction)screenTapped:(id)sender;
- (IBAction)starTapped:(id)sender;

@end
