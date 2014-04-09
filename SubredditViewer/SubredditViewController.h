//
//  SubredditViewController.h
//  SubredditViewer
//
//  Created by BrotoMan on 4/7/14.
//  Copyright (c) 2014 BrotoMan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubredditViewController : UIViewController <NSURLConnectionDataDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGesture;

- (IBAction)screenTapped:(id)sender;

@end
