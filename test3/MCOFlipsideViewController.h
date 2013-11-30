//
//  MCOFlipsideViewController.h
//  test3
//
//  Created by Olivier Guieu on 19/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCODeliciousUser.h"


@class MCOFlipsideViewController;

@protocol MCOFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(MCOFlipsideViewController *)controller;
- (NSDictionary *)getJSONForCurrentUrl;
- (BOOL)updateJSONForCurrentUrl:(NSDictionary*) newjsonStringForCurrentUrl;
- (void)flipsideViewIsAboutToClose;
- (NSString *)getDeliciousBaseUrl;
- (MCODeliciousUser *) deliciousUser;
- (void) deleteCurrentUrl;
- (BOOL) isConnected;
@end

@interface MCOFlipsideViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
{
}

@property (nonatomic, retain) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (strong, nonatomic) IBOutlet UITextView *urlLabel;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (strong, nonatomic) IBOutlet UILabel *timestampLabel;
@property (assign, nonatomic) id <MCOFlipsideViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UIButton *addTagButton;
@property (strong, nonatomic) IBOutlet UIButton *deleteLinkButton;
@property (strong, nonatomic) IBOutlet UIButton *updateWithSuggestedTagsButton;

//@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;


- (NSArray *)getArrayOftags;
- (IBAction)done:(id)sender;
- (IBAction) addTag:(id)sender;
- (IBAction)updateWithSuggestedTags:(id)sender;

@end
