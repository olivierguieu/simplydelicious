//
//  MCOFlipsideViewController.m
//  test3
//
//  Created by Olivier Guieu on 19/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MCOFlipsideViewController.h"
#import "MCOAppDelegate.h"
#import "MCODeliciousOperations.h"

#import "NSDateFormatter+Utilities.h"
#import "NSString+MD5.h"

#define CONFIRMUPDATETAGS_ALERTVIEW_TAG    8
#define TAG_ALERTVIEW_TAG   4
#define FAILEDUPDATE_ALERTVIEW_TAG  2

@interface MCOFlipsideViewController ()

@end

@implementation MCOFlipsideViewController

@synthesize delegate = _delegate;
@synthesize navigationItem;
@synthesize tableView;
@synthesize urlLabel, timestampLabel,descriptionLabel, deleteLinkButton, updateWithSuggestedTagsButton, addTagButton;
//@synthesize scrollView;

#pragma mark - Helpers for manipulating arrays of tags

- (NSArray *) getArrayOftags
{
    NSDictionary *jsonStringForCurrentUrl;
    jsonStringForCurrentUrl = [self.delegate getJSONForCurrentUrl];
    
    NSString *stringOfTags = [jsonStringForCurrentUrl objectForKey:@"tag"];
    NSArray *arrayOfTags = [stringOfTags componentsSeparatedByString:@" "];
    return arrayOfTags;
}

- (BOOL) removeTagFromArrayOfTags:(NSString *) tag
{
    NSMutableDictionary *jsonStringForCurrentUrl;
    jsonStringForCurrentUrl = [[self.delegate getJSONForCurrentUrl] mutableCopy];
    
    NSString *stringOfTags = [jsonStringForCurrentUrl objectForKey:@"tag"];
    NSArray *arrayOfTags = [stringOfTags componentsSeparatedByString:@" "];
    
    NSMutableString *newStringOfTags = [[NSMutableString alloc] initWithCapacity:100];
    BOOL isFirst=TRUE;
    for (NSString *str in arrayOfTags)
    {
        if ( [ str caseInsensitiveCompare:tag] && [str caseInsensitiveCompare:@" "])
        {
            if ( isFirst )
            {
                [newStringOfTags appendFormat:@"%@", str];
                isFirst=FALSE;
            }
            else
            {
                [newStringOfTags appendFormat:@" %@", str];
            }
        }
    }
    
    [jsonStringForCurrentUrl setValue:newStringOfTags  forKey:@"tag"];
    [newStringOfTags release];
    return [self.delegate updateJSONForCurrentUrl:jsonStringForCurrentUrl];
}


- (BOOL) updateArrayOfTags: (NSArray *) newArrayOfTags
{
    NSString * tags = [newArrayOfTags componentsJoinedByString:@" "];
    
    NSMutableDictionary *jsonStringForCurrentUrl;
    jsonStringForCurrentUrl = [[self.delegate getJSONForCurrentUrl] mutableCopy];
    [jsonStringForCurrentUrl  setObject:tags forKey:@"tag"];
    
    return [self.delegate updateJSONForCurrentUrl:jsonStringForCurrentUrl];
}

- (void) displayAlertWhenUpdateFails 
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Sorry but..." message:@"...update failed! Please try again." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    alert.tag= FAILEDUPDATE_ALERTVIEW_TAG;
    
    [alert show];
    [alert release];

}


#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *arrayOfTags = [self getArrayOftags];
    
	return [arrayOfTags count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSArray *arrayOfTags = [self getArrayOftags];
    
    return ( ( [arrayOfTags count] > 1 ) ? @"Tags" : @"Tag" );
}

- (UITableViewCell *)tableView:(UITableView *)tmpTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"TAGCell";
    
    UITableViewCell *cell = [tmpTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    NSArray *arrayOfTags = [self getArrayOftags];
    
    // Configure the cell...
    NSString *tagLabel = [arrayOfTags objectAtIndex:[indexPath row]];
    cell.textLabel.text = tagLabel;
    
    cell.accessoryType = UITableViewCellAccessoryNone; 
    return cell;
}

- (void)tableView:(UITableView *)myTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSArray *arrayOfTags = [self getArrayOftags];        
        NSString *tagLabel = [arrayOfTags objectAtIndex:[indexPath row]];

        // send delete Tag to Delicious
        if ([MCODeliciousOperations deleteTag:tagLabel fromLink:self.urlLabel.text  withDeliciousUser:self.delegate.deliciousUser] )
        {
            // remove row from JSON Source
            [self removeTagFromArrayOfTags:tagLabel];
            [myTableView reloadData];
        }
        else
        {
            [self displayAlertWhenUpdateFails];
        }
        
    }
}


#pragma mark - View Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 560.0);
    }
    return self;
}

//- (void)viewDidLoad
//{
////    UIBarButtonItem * addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addItem:)];
////    self.navigationItem.rightBarButtonItem = addButton;
// //   self.scrollView.contentSize = self.view.frame.size;
//
//}

- (void) viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    self.deleteLinkButton.enabled = [self.delegate isConnected];
    self.updateWithSuggestedTagsButton.enabled = [self.delegate isConnected];
    
    NSDictionary *jsonStringForCurrentUrl;
    jsonStringForCurrentUrl = [self.delegate getJSONForCurrentUrl];
    
    self.navigationItem.title = ( [jsonStringForCurrentUrl objectForKey:@"description"]  == [NSNull null] ) ? @"No description" : [jsonStringForCurrentUrl  objectForKey:@"description"];
  
    NSString *strTimeStamp = ( [jsonStringForCurrentUrl objectForKey:@"time"] == [NSNull null]) ? @"1970-01-01T01:01:01Z" : [jsonStringForCurrentUrl objectForKey:@"time"];  
    
    self.descriptionLabel.text = self.navigationItem.title;
    self.urlLabel.text = ([jsonStringForCurrentUrl objectForKey:@"href"] == [NSNull null]) ? @"No Url" :[jsonStringForCurrentUrl objectForKey:@"href"];;
    self.urlLabel.editable=FALSE;
    self.urlLabel.dataDetectorTypes = UIDataDetectorTypeLink;   

 
    NSString *strReformattedTimeStamp = [NSDateFormatter
                                  dateStringFromString:strTimeStamp
                                  sourceFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"
                                  destinationFormat:@"h:mm:ssa 'on' MMMM d, yyyy"];
    self.timestampLabel.text = strReformattedTimeStamp;

    [self.tableView reloadData];
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.delegate flipsideViewIsAboutToClose];
}


- (void)dealloc
{
    [navigationItem release];
    [tableView release];
    
    [urlLabel release];
    [timestampLabel release];
     
    [descriptionLabel release];
    
    [deleteLinkButton release];
    [updateWithSuggestedTagsButton release];
    
    [addTagButton release];
    
//    [scrollView release];

    [super dealloc];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}



#pragma mark - Adding new tag
- (IBAction) addTag:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Add new tag" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Cancel", nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag= TAG_ALERTVIEW_TAG;
    
   // UITextField *tag = [alert textFieldAtIndex:0];

    [alert show];
    [alert release];
}



#pragma mark - Actions

- (IBAction)updateWithSuggestedTags:(id)sender
{
    NSArray * suggestedTags = [MCODeliciousOperations getDeliciousSuggestedTagsForUrl:self.urlLabel.text WithDeliciousUser:self.delegate.deliciousUser];
    
    UIAlertView* alert;
    if ( [suggestedTags count] > 0 )
    {
        NSString * suggestedTagsString = [suggestedTags componentsJoinedByString:@","];

        NSString * tags = [[NSString alloc] initWithFormat:@"...confirm replacing existing tags by the following ones ? [%@]",suggestedTagsString];
        alert = [[UIAlertView alloc] initWithTitle:@"Do you ..." message:tags delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Cancel", nil];
        alert.tag= CONFIRMUPDATETAGS_ALERTVIEW_TAG;
        [tags release];
    }
    else
    {
        // No suggested tags found...
        alert = [[UIAlertView alloc] initWithTitle:@"No suggested tag found !" message:nil delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    }
    [alert show];
    [alert release];
}


- (IBAction)done:(id)sender
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        [self.delegate flipsideViewControllerDidFinish:self];
    }
    else
    {
        [self dismissModalViewControllerAnimated:YES];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{  

    if ( alertView.tag == TAG_ALERTVIEW_TAG )
    {
        // OK Clicked
        if (buttonIndex == 0) {
            
            UITextField *tagTextField = [alertView textFieldAtIndex:0];
           
            debug(@"%@", tagTextField.text);
            
            NSDictionary *jsonStringForCurrentUrl;
            jsonStringForCurrentUrl = [self.delegate getJSONForCurrentUrl];
            
            NSString *strUrl;
            strUrl = [jsonStringForCurrentUrl  objectForKey:@"href"];
            
            BOOL bRes = [MCODeliciousOperations addForUrl:strUrl Tag:tagTextField.text WithDeliciousUser:self.delegate.deliciousUser];
            
            debug(@"bRes : %d",bRes);
            
            if ( bRes)
            {
                [self updateArrayOfTags:[MCODeliciousOperations getDeliciousTagsForUrl:strUrl ForSuggestedTags:FALSE WithDeliciousUser:self.delegate.deliciousUser]];
                [self.tableView reloadData];
            }
            else
            {
                [self displayAlertWhenUpdateFails];
            }
        }
    }
    
    if ( alertView.tag == CONFIRMUPDATETAGS_ALERTVIEW_TAG )
    {
        // OK Clicked
        if (buttonIndex == 0) {
            debug(@"in alertView: OK Clicked !");
            
            NSDictionary *jsonStringForCurrentUrl;
            jsonStringForCurrentUrl = [self.delegate getJSONForCurrentUrl];
            
            NSString *strUrl;
            strUrl = [jsonStringForCurrentUrl  objectForKey:@"href"];
            
            BOOL bRes=[MCODeliciousOperations uptadeTagsWithDeliciousSuggestedTagsForUrl:strUrl WithDeliciousUser:self.delegate.deliciousUser];
            debug(@"bRes : %d",bRes);
            
            if ( bRes)
            {
                [self updateArrayOfTags:[MCODeliciousOperations getDeliciousSuggestedTagsForUrl:self.urlLabel.text WithDeliciousUser:self.delegate.deliciousUser]];
                [self.tableView reloadData];
            }
            else
            {
                [self displayAlertWhenUpdateFails];
            }
        }
    }
}


@end
