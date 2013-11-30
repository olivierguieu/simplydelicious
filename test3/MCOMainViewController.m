//
//  MCOMainViewController.m
//  test3
//
//  Created by Olivier Guieu on 19/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MCOMainViewController.h"
#import "MCOAppDelegate.h"
#import "MCODeliciousOperations.h"

#import "MBProgressHUD.h"
#import <Twitter/Twitter.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import <QuartzCore/QuartzCore.h>


#define MAX_ITEMS_TO_FETCH 5000

#define LOGINPWD_ALERTVIEW_TAG          1
#define ERROR_ALERTVIEW_TAG             2
#define INCORRECTLOGIN_ALERTVIEW_TAG    4
#define SHARE_ALERTVIEW_TAG             8
#define CONFIRMDELETELINK_ALERTVIEW_TAG    16
#define ERROR_FAILED_TO_DELETE_LINK 32

@interface MCOMainViewController ()
@end

@implementation MCOMainViewController

@synthesize flipsidePopoverController = _flipsidePopoverController;
@synthesize webView; 
@synthesize toolbarItem;
@synthesize nextButtonBarButtonItem,previousButtonBarButtonItem, reloadButtonBarButtonItem, shareButtonBarButtonItem, infoButtonBarButtonItem;
@synthesize textViewTitle;

@synthesize previousButtonBrowseBarButtonItem, nextButtonBrowseBarButtonItem;

@synthesize downloadProgressView, downloadUIView;

// Delicious information
@synthesize deliciousUser;

#pragma mark - Load Delicious Data

- (void)showDownLoadProgressView : (BOOL) show
{
    [UIView beginAnimations:NULL context:NULL];
    [UIView setAnimationDuration:2.0]; 
    if ( show ) {
        self.webView.alpha = 0.25;
        self.downloadProgressView.alpha = 1;
        self.downloadUIView.alpha = .5;
    }
    else {
        self.webView.alpha = 1;
        self.downloadProgressView.alpha = 0;
        self.downloadUIView.alpha = 0;
    }
    [UIView commitAnimations];
}

- (void) deleteCurrentUrl
{
    [arrayOfUrls removeObjectAtIndex:currentUrl];
    [self.flipsidePopoverController dismissPopoverAnimated:YES];    
    [self displayCurrentUrl:TRUE]; 
}



- (NSString *)getDeliciousBaseUrl
{
    return [MCODeliciousOperations getDeliciousBaseUrlWithLogin:self.deliciousUser.login andPassword:self.deliciousUser.pwd];
}



- (void)loadDeliciousData : (int) maxItemToFetch
{
    if ( [self.deliciousUser.login length] * [self.deliciousUser.pwd length] == 0 )
    {
        [self showLoginInfo:nil];
        return;
    }
    else 
    {
        if ( [self isConnected ] == TRUE ) 
        {
            isCorrectDeliciousLoginPwd = [self.deliciousUser isCorrectLoginPwd];
            if ( isCorrectDeliciousLoginPwd == FALSE ) 
            {
                [self displayAlertViewForIncorrectLoginPwd]; 
                return;
            }
        }
        else
        {
            [self displayAlertViewForNoNetwork];
            return;
        }
    }
    

    
    [self showDownLoadProgressView: TRUE]; // execute the animations listed above
    
    NSString *strUrl  = [[NSString alloc] initWithFormat:@"%@/json/posts/all?count=%d",[self getDeliciousBaseUrl], MAX_ITEMS_TO_FETCH];
    
    debug(@"Url...<%@>", strUrl);
    
    NSURL *url = [NSURL URLWithString:strUrl];
    
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request setDelegate:self];
    [request setShowAccurateProgress:YES];
    [request setDownloadProgressDelegate:self.downloadProgressView];
    
    NSTimeInterval timeInterval;
    timeInterval = request.timeOutSeconds;    
    [request setTimeOutSeconds:timeInterval *2];    

    [request startAsynchronous];
    
    [strUrl release];
}

- (void)requestFinished:(ASIHTTPRequest *)request
{    
    NSString *responseString = [request responseString];
    NSDictionary *responseDict = [responseString JSONValue];
    NSDictionary *postsDict = [responseDict  objectForKey:@"posts"];
    
    [arrayOfDicts removeAllObjects];
    [arrayOfUrls removeAllObjects];
    
    if ( [postsDict count] == 0 )
    {
        [arrayOfUrls release];
        arrayOfUrls = nil;
        return;
    }
    
    arrayOfDicts = [[NSMutableDictionary alloc] initWithCapacity:MAX_ITEMS_TO_FETCH];    
    arrayOfUrls = [[NSMutableArray alloc] initWithCapacity:MAX_ITEMS_TO_FETCH];
    
    for (NSDictionary *dict in postsDict)
    {
        //DEBUG
        // debug(@"%@", [dict description]);
        
        NSDictionary *post = [dict objectForKey:@"post"];
        
        //DEBUG
        // debug(@"%@", [post description]);
        
        [arrayOfUrls addObject:[post objectForKey:@"href"]];
        [arrayOfDicts setObject:post forKey:[post objectForKey:@"href"]];
    }
    
    [arrayOfUrls shuffle];
    currentUrl = 0;
    
    
    [self showDownLoadProgressView: FALSE];
    [self displayCurrentUrl:FALSE];
    [self reflectReachabilityChanged];
}


#pragma mark - View LifeCycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	// Do any additional setup after loading the view, typically from a nib.    
    canDisplayDeliciousInformationOnTag = true;
    
    // round corners of downloadUIView
    CALayer *tmpLayer = [downloadUIView layer];
    [tmpLayer setCornerRadius: 5];
    tmpLayer.masksToBounds = YES;

    webView.delegate = self;

    self.deliciousUser = [[MCODeliciousUser alloc] init];
    if ( [self.deliciousUser getStoredLoginPwd] == FALSE )
    {
        [self.deliciousUser reset];
    }
    
    [self loadDeliciousData: MAX_ITEMS_TO_FETCH];
}

- (void)dealloc
{
    [_flipsidePopoverController release];
    
    [webView release];
    
    [arrayOfUrls release];
    [arrayOfDicts release];
    
    [nextButtonBarButtonItem release];
    [previousButtonBarButtonItem release];
    [reloadButtonBarButtonItem release];
    
    [shareButtonBarButtonItem release];
    
    [infoButtonBarButtonItem release];
    
    [toolbarItem release];
    
    [textViewTitle release];
    
    [previousButtonBrowseBarButtonItem release];
    [nextButtonBrowseBarButtonItem release];
    
    [downloadProgressView release];
    [downloadUIView release];
    
    
    // Delicious information
    [deliciousUser release];
    
    [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - Flipside View Controller

- (void)flipsideViewControllerDidFinish:(MCOFlipsideViewController *)controller
{
    [self.flipsidePopoverController dismissPopoverAnimated:YES];
    [self flipsideViewIsAboutToClose];
}

- (void)flipsideViewIsAboutToClose
{
    [self reflectReachabilityChanged];
}

#pragma mark - button click handlers

- (IBAction)showUrlInfo:(id)sender
{
    self.nextButtonBarButtonItem.enabled=FALSE;
    self.previousButtonBarButtonItem.enabled=FALSE;
    self.reloadButtonBarButtonItem.enabled=FALSE;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (!self.flipsidePopoverController) {
            MCOFlipsideViewController *controller = [[[MCOFlipsideViewController alloc] initWithNibName:@"MCOFlipsideViewController" bundle:nil] autorelease];
            controller.delegate = self;
            
            self.flipsidePopoverController = [[[UIPopoverController alloc] initWithContentViewController:controller] autorelease];
        }
        
        if ([self.flipsidePopoverController isPopoverVisible]) {
            [self.flipsidePopoverController dismissPopoverAnimated:YES];
        } else {
            [self.flipsidePopoverController presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    else
    {
        MCOFlipsideViewController *controller = [[[MCOFlipsideViewController alloc] initWithNibName:@"MCOFlipsideViewController" bundle:nil] autorelease];
        controller.delegate = self;
        [self presentModalViewController:controller animated:YES];

    }
}

- (IBAction)showLoginInfo:(id)sender
{
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Delicious account information" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Cancel", nil];
    alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    alert.tag= LOGINPWD_ALERTVIEW_TAG;
    
    UITextField *username = [alert textFieldAtIndex:0];
    UITextField *password = [alert textFieldAtIndex:1];
    
    username.text=self.deliciousUser.login;
    password.text=self.deliciousUser.pwd;
    
    
    [alert show];
    [alert release];
}

- (IBAction)deleteDeliciousLink:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Confirm link deletion ?" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Cancel", nil];
    alert.tag= CONFIRMDELETELINK_ALERTVIEW_TAG;
    [alert show];
    [alert release];
}


#pragma mark - Events handling
- (NSDictionary *)getJSONForCurrentUrl
{
    if ( arrayOfUrls == nil )
        return nil;
    
    if ( currentUrl < 0 || currentUrl > [arrayOfUrls count] )
        return nil;
    
    NSString *tmpCurrentUrl;
    tmpCurrentUrl = [arrayOfUrls objectAtIndex:currentUrl];
    
    NSDictionary *jsonStringForCurrentUrl;
    jsonStringForCurrentUrl = [arrayOfDicts objectForKey:tmpCurrentUrl];
    
    return  jsonStringForCurrentUrl;
}

- (BOOL)updateJSONForCurrentUrl:(NSDictionary*) newjsonStringForCurrentUrl
{
    if ( arrayOfUrls == nil )
        return FALSE;
    
    if ( currentUrl < 0 || currentUrl > [arrayOfUrls count] )
        return FALSE;
    
    NSString *tmpCurrentUrl;
    tmpCurrentUrl = [arrayOfUrls objectAtIndex:currentUrl];
    
    [arrayOfDicts  setObject:newjsonStringForCurrentUrl forKey:tmpCurrentUrl];
    
    return  TRUE;
}


- (void) displayCurrentUrl: (BOOL) bDisplayProgressBar
{
    canDisplayDeliciousInformationOnTag = TRUE;
    
    // cf http://stackoverflow.com/questions/3799918/how-to-clear-back-forward-list-in-uiwebview-on-iphone
    id internalWebView=[[self.webView _documentView] webView];
    [internalWebView setMaintainsBackForwardList:NO];
    [internalWebView setMaintainsBackForwardList:YES];
    
    //self.infoButtonBarButtonItem.enabled= FALSE;

    self.nextButtonBrowseBarButtonItem.enabled= FALSE;
    self.previousButtonBrowseBarButtonItem.enabled= FALSE;

    if ( bDisplayProgressBar) [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    if ( [arrayOfUrls count] ==  currentUrl )
        currentUrl = 0;
    
    if ( currentUrl < 0)
        currentUrl = [arrayOfUrls count] - 1;
    
    //URL Request Object
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:[arrayOfUrls objectAtIndex:currentUrl]] ];
    
    //Load the request in the UIWebView.
    [webView loadRequest:requestObj];
    
    // MAJ de la barre de text
    NSString * loadingString;
    if ([arrayOfUrls count] > 0)  
    {
        loadingString = [[NSString alloc] initWithFormat:@"Loading %d/%d",(currentUrl+1),[arrayOfUrls count]];
    }
    else 
    {
        loadingString = [[NSString alloc] initWithFormat:@"Loading..."];
    }
    
    self.textViewTitle.text = loadingString;
    [loadingString release];
}


- (void)displayShiftedUrlAction:(int) shift 
{
    currentUrl=currentUrl+shift;    
    [self displayCurrentUrl:TRUE]; 
}

- (IBAction)reloadDeliciousData:(id)sender
{
    [self loadDeliciousData: MAX_ITEMS_TO_FETCH];
}

- (IBAction)displayNextUrlAction:(id)sender 
{
    [self displayShiftedUrlAction:1];
}

- (IBAction)displayPreviousUrlAction:(id)sender
{
    [self displayShiftedUrlAction:(-1)];
}


- (NSString *)getCurrentUrlTitleLeftTruncatedAt: (int) maxChar
{
    NSString *strTitle= [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if ( maxChar > 0 )
    {
        int truncateSize = ([strTitle length]>maxChar) ? maxChar : [strTitle length];
        return  [[strTitle substringToIndex:truncateSize] stringByAppendingString:@"..."];
    }
    else
        return strTitle;
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    debug(@"in shouldStartLoadWithRequest with action <%d> for Url<%@>" , navigationType, request );
    return TRUE;
}

- (void)webViewDidStartLoad:(UIWebView *)tmpWebView 
{    
    debug(@"in webViewDidStartLoad for Url<%@>, loading <%d>" , tmpWebView.request, tmpWebView.loading );
}

- (void) handleEndOfLoad
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) 
    {
        self.textViewTitle.text = [self getCurrentUrlTitleLeftTruncatedAt:20];
    } 
    else
    {
        self.textViewTitle.text = [self getCurrentUrlTitleLeftTruncatedAt:30];
    }
    
//    on n'active le bouton d'infos que si l'url actuelle est egale à celle du currentUrl... MARCHE MAL :-(
//    NSString *strCurrentURL = self.webView.request.URL.absoluteString;
//    NSString *strExpectedURL = [arrayOfUrls objectAtIndex:currentUrl];
//    self.infoButtonBarButtonItem.enabled = [strCurrentURL isEqualToString:strExpectedURL];
    
    self.previousButtonBrowseBarButtonItem.enabled=self.webView.canGoBack;
    self.nextButtonBrowseBarButtonItem.enabled=self.webView.canGoForward;
    canDisplayDeliciousInformationOnTag = !self.webView.canGoBack;
    
    self.infoButtonBarButtonItem.enabled = canDisplayDeliciousInformationOnTag;
}

- (void)webViewDidFinishLoad:(UIWebView *)tmpWebView 
{    
    debug(@"in webViewDidFinishLoad for Url<%@>, loading <%d>" ,tmpWebView.request, tmpWebView.loading );
    [self handleEndOfLoad];
}

- (void)webView:(UIWebView *) tmpWebView didFailLoadWithError:(NSError *)error 
{
    debug(@"in didFailLoadWithError <%d> for Url<%@>" , [error code],[arrayOfUrls objectAtIndex:currentUrl] );
    [self handleEndOfLoad];
 
    // cf    http://stackoverflow.com/questions/1024748/how-do-i-fix-nsurlerrordomain-error-999-in-iphone-3-0-os   
    if([error code] == NSURLErrorCancelled) 
    {
        return; // Ignore this error 
    }
    
    NSString *errorMsg = nil;
    
    if ( [[arrayOfUrls objectAtIndex:currentUrl] length ] > 0 )
    {
        //ASIHTTPRequestErrorDomain
        if ([[error domain] isEqualToString:NSURLErrorDomain]) {
            switch ([error code]) {
                case NSURLErrorCannotFindHost:
                    errorMsg = NSLocalizedString(@"Cannot find specified host. Modify Link.", nil);
                    break;
                case NSURLErrorCannotConnectToHost:
                    errorMsg = NSLocalizedString(@"Cannot connect to specified host. Server may be down.", nil);
                    break;
                case NSURLErrorNotConnectedToInternet:
                    errorMsg = NSLocalizedString(@"Cannot connect to the internet. Service may not be available.", nil);
                    break;
                default:
                    errorMsg = [error localizedDescription];
                    break;
            }
        } else {
            errorMsg = [error localizedDescription];
        }
        
        NSString *alertTitle;
        if ( [[error userInfo] objectForKey:NSErrorFailingURLStringKey] != nil) 
        {
            alertTitle=[[NSString alloc] initWithFormat:@"Error Loading url <%@>!",[[error userInfo] objectForKey:NSErrorFailingURLStringKey]  ];
        }
        else
        {
            alertTitle=[[NSString alloc] initWithFormat:@"Error Loading url !" ];
        }
    
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertTitle
                                                            message:errorMsg
                                                           delegate:self 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        
        //clear webView... 
        // cette methode semble provoquer des problemes de memoire plus tard... 
        // [self.webView stringByEvaluatingJavaScriptFromString:@"document.open();document.close()"];
        // un autre moyen ... 
        [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"about:blank"]]];
        
        [alertView show];
        [alertView release];
        [alertTitle release];
    }
}

#pragma mark - Alerts et leurs traitements

- (void) displayAlertViewForIncorrectLoginPwd
{
    UIAlertView* alert;
    alert = [[UIAlertView alloc] initWithTitle:@"Delicious account information" message:@"Incorrect login / pwd ..." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Cancel", nil];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    alert.tag= INCORRECTLOGIN_ALERTVIEW_TAG;
    
    [alert show];
    [alert release];
}

- (void) displayAlertViewForNoNetwork
{
    NSString* msg = @"Network access is required for this application to work properly ... Please try again later...";
    UIAlertView* av = [[UIAlertView alloc] initWithTitle:nil
                                                 message:msg
                                                delegate:self
                                       cancelButtonTitle:@"Ok"
                                       otherButtonTitles:nil];
    [av show];
    [av release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{  
    if ( alertView.tag == INCORRECTLOGIN_ALERTVIEW_TAG )
    {
        // OK Clicked
        if (buttonIndex == 0) {            
            [self showLoginInfo:nil];
        }
    }

    if ( alertView.tag == LOGINPWD_ALERTVIEW_TAG )
    {
        // OK Clicked
        if (buttonIndex == 0) {
            
            MCODeliciousUser *newDeliciousUser;
            newDeliciousUser= [[MCODeliciousUser alloc] init];
       
            UITextField *username = [alertView textFieldAtIndex:0];
            UITextField *password = [alertView textFieldAtIndex:1];
  
            newDeliciousUser.login = username.text;
            newDeliciousUser.pwd = password.text;
            
            // on ne peut verifier l exactitude du login/pwd que s'il y a reseau ... et donc on fait confiance ...
            if ( [self isConnected] == FALSE ) 
            {
                [newDeliciousUser saveLoginPwd];
                self.deliciousUser = newDeliciousUser;
                
                [self displayAlertViewForNoNetwork];
                return;
            }
            else
            {
                if ( [newDeliciousUser isCorrectLoginPwd] )
                {
                    [newDeliciousUser saveLoginPwd];
                    self.deliciousUser = newDeliciousUser;
                    
                    // on ne force plus systématiquement le refresh après le Ok...
                    // [self loadDeliciousData: MAX_ITEMS_TO_FETCH];
                    if ( [arrayOfUrls count] == 0 ) [self loadDeliciousData: MAX_ITEMS_TO_FETCH];
                        
                }
                else {
                    [self displayAlertViewForIncorrectLoginPwd];
                }
            }
        } 
        
    }
    if ( alertView.tag == ERROR_ALERTVIEW_TAG)
    {
        if (buttonIndex == 1) {
            //OK clicked
            currentUrl++;
            [self displayCurrentUrl:TRUE]; 
        } 
    }
    if ( alertView.tag == CONFIRMDELETELINK_ALERTVIEW_TAG )
    {
        // OK Clicked
        if (buttonIndex == 0) {
            debug (@"in alertView: OK Clicked !");
            
            NSDictionary *jsonStringForCurrentUrl;
            jsonStringForCurrentUrl = [self getJSONForCurrentUrl];
            
            NSString *strUrl;
            strUrl = [jsonStringForCurrentUrl  objectForKey:@"href"];
            
            BOOL bRes = [MCODeliciousOperations deleteLink:strUrl withDeliciousUser:self.deliciousUser];
            debug(@"bRes : %d",bRes);
            
            if ( bRes)
            {
                [self deleteCurrentUrl];
            }
            else
            {
                UIAlertView* alert;
                alert = [[UIAlertView alloc] initWithTitle:@"Something went wrong" message:@"Failed to delete link, please use Delicious web site ..." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                alert.alertViewStyle = UIAlertViewStyleDefault;
                alert.tag=  ERROR_FAILED_TO_DELETE_LINK;
                
                [alert show];
                [alert release];
            }
        }
    }

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ( actionSheet.tag == SHARE_ALERTVIEW_TAG)
    {
        debug (@"buttonIndex<%d>", buttonIndex);
        
        NSString *strTitle;
        strTitle = [self getCurrentUrlTitleLeftTruncatedAt:-1];
            
        NSString *strCurrentURL = self.webView.request.URL.absoluteString;
        NSURL *url = [NSURL URLWithString:strCurrentURL];

        if (buttonIndex == 0 && [MFMailComposeViewController canSendMail]) {
            //Mail it clicked
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            picker.mailComposeDelegate = self;
            
            [picker setSubject:@"Sharing url from SimplyDelicious"];
                       
            // Fill out the email body text
            NSString *emailBody;
            emailBody = [[NSString alloc] initWithFormat:@"Check this Url !<BR> <a href='%@'>%@</a>", strCurrentURL, strCurrentURL];
            [picker setMessageBody:emailBody isHTML:YES];
            
            [self presentModalViewController:picker animated:YES];
            [picker release];

        } 
        if (buttonIndex == 1)
        {
            //Tweet it clicked
            if ([TWTweetComposeViewController canSendTweet])
            {
                TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
                [tweetSheet setInitialText:@"Tweeting from SimplyDelicious! :)"];

                [tweetSheet addURL:url];
                
                [self presentModalViewController:tweetSheet animated:YES];
                [tweetSheet release];
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry" 
                                                                    message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup" 
                                                                   delegate:self 
                                                          cancelButtonTitle:@"OK" 
                                                          otherButtonTitles:nil];
                [alertView show];
                [alertView release];
            }

        }
        if (buttonIndex == 2)
        {
            NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
            
            if ( 6 == [[versionCompatibility objectAtIndex:0] intValue] )
            {
                //Facebook  it clicked
                
                if([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
                    
                    SLComposeViewController *controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
                    [controller setInitialText:strTitle];
                    [controller addURL:url];
                    
                    [self presentViewController:controller animated:YES completion:Nil];
                    
                    
                    SLComposeViewControllerCompletionHandler myBlock = ^(SLComposeViewControllerResult result){
                        NSString *output= nil;
                        switch (result) {
                            case SLComposeViewControllerResultCancelled:
                                output= NSLocalizedString(@"Action Cancelled", nil);
                                debug (@"cancelled");
                                break;
                            case SLComposeViewControllerResultDone:
                                output= NSLocalizedString(@"Post Successful", nil);
                                debug (@"success");
                                break;
                            default:
                                break;
                        }
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Facebook" message:output delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil)  otherButtonTitles:nil];
                        [alert show];
                        [alert release];
                        [controller dismissViewControllerAnimated:YES completion:Nil];
                    };
                    controller.completionHandler =myBlock;
                }
            }
        }

    }
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error 
{	
	[self dismissModalViewControllerAnimated:YES];
}



#pragma mark - sendMail button

- (IBAction)shareButtonTapped:(id) sender
{
    UIActionSheet *popupQuery;
    
    NSArray *versionCompatibility = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    
    if ( 6 == [[versionCompatibility objectAtIndex:0] intValue] )
    {
        /// iOS6 is installed
        popupQuery = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share...",nil) delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Mail it",nil) , NSLocalizedString(@"Tweet it",nil) , NSLocalizedString(@"on Facebook",nil) ,nil];
        
    }
    else if ( 5 == [[versionCompatibility objectAtIndex:0] intValue] )
    {
        popupQuery = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share...",nil) delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Mail it",nil) , NSLocalizedString(@"Tweet it",nil) , nil];
    }
    else
    {
        popupQuery = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Share...",nil) delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Mail it",nil), nil , nil];
        
    }
    
    popupQuery.actionSheetStyle = UIActionSheetStyleBlackOpaque;
    popupQuery.tag = SHARE_ALERTVIEW_TAG;
	[popupQuery showInView:self.view];
	[popupQuery release];
}


#pragma mark - embedded browser
- (IBAction)previousInBrowser:(id)sender
{
    [self.webView goBack];    
}

- (IBAction)nextInBrowser:(id)sender
{
    [self.webView goForward];
}

#pragma mark - enable/disable buttons if network or no network

- (BOOL) isConnected
{
    MCOAppDelegate *tmpAppDelegate;
    tmpAppDelegate = (MCOAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    return [tmpAppDelegate isConnected];
}

- (void )reflectReachabilityChanged
{
    BOOL  isConnected = [self isConnected];
    self.nextButtonBarButtonItem.enabled=isConnected && ( [arrayOfUrls count] > 0 ) ;
    self.previousButtonBarButtonItem.enabled=isConnected && ( [arrayOfUrls count] > 0 );
    self.reloadButtonBarButtonItem.enabled=isConnected;
    
    self.shareButtonBarButtonItem.enabled=isConnected;

}

@end
