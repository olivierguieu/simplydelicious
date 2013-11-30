//
//  MCOMainViewController.h
//  test3
//
//  Created by Olivier Guieu on 19/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MCOFlipsideViewController.h"
#import "MCODeliciousUser.h"
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface MCOMainViewController : UIViewController <UIWebViewDelegate,UIAlertViewDelegate, MCOFlipsideViewControllerDelegate, UIActionSheetDelegate,MFMailComposeViewControllerDelegate>
{
    NSMutableArray *arrayOfUrls;
    NSMutableDictionary *arrayOfDicts;
    
    int         currentUrl;
        
    BOOL        isNetworkReachable;
    BOOL        isCorrectDeliciousLoginPwd;
    
    BOOL        internetActive;
    BOOL        hostActive;
    
    BOOL        canDisplayDeliciousInformationOnTag;

}


// Delicious information
@property (strong, nonatomic) MCODeliciousUser          *deliciousUser;

@property (strong, nonatomic) UIPopoverController       *flipsidePopoverController;
@property (strong, nonatomic) IBOutlet UIWebView        *webView;

@property (strong, nonatomic) IBOutlet UIToolbar        *toolbarItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem  *nextButtonBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem  *previousButtonBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem  *reloadButtonBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem  *infoButtonBarButtonItem;
@property (strong, nonatomic) IBOutlet UITextView       *textViewTitle;

@property (strong, nonatomic) IBOutlet UIBarButtonItem  *shareButtonBarButtonItem;

@property (strong, nonatomic) IBOutlet UIBarButtonItem  *previousButtonBrowseBarButtonItem;
@property (strong, nonatomic) IBOutlet UIBarButtonItem  *nextButtonBrowseBarButtonItem;

@property (strong, nonatomic) IBOutlet UIProgressView   *downloadProgressView;
@property (strong, nonatomic) IBOutlet UIView           *downloadUIView;


- (IBAction)previousInBrowser:(id)sender;
- (IBAction)nextInBrowser:(id)sender;

- (IBAction)showUrlInfo:(id)sender;
- (IBAction)showLoginInfo:(id)sender;

- (IBAction)reloadDeliciousData:(id)sender;
- (IBAction)displayNextUrlAction:(id)sender;
- (IBAction)displayPreviousUrlAction:(id)sender;

- (IBAction)shareButtonTapped:(id) sender;

- (NSString *)getCurrentUrlTitleLeftTruncatedAt: (int) maxChar;
- (void)loadDeliciousData : (int) maxItemToFetch;
- (void) handleEndOfLoad;

- (void)showDownLoadProgressView : (BOOL) show;

- (void) deleteCurrentUrl;
- (void) displayCurrentUrl: (BOOL) bDisplayProgressBar;

- (void) displayAlertViewForIncorrectLoginPwd;
- (void) displayAlertViewForNoNetwork;

- (BOOL) isConnected;
- (void )reflectReachabilityChanged;

- (NSString *)getDeliciousBaseUrl;

- (BOOL)updateJSONForCurrentUrl:(NSDictionary*) newjsonStringForCurrentUrl;

- (NSDictionary *)getJSONForCurrentUrl;

@end
