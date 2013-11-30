 //
//  MCODeliciousUser.m
//  test3
//
//  Created by Olivier Guieu on 30/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MCODeliciousUser.h"
#import "MCODeliciousOperations.h"

#import "RNEncryptor.h"
#import "RNDecryptor.h"

#import "ASIHTTPRequest.h"

#import "MCOAppDelegate.h"

//#define CRYPT_PWD 0
#undef CRYPT_PWD

#define CRYPT_KEY @"MARGOT"


@implementation MCODeliciousUser

@synthesize pwd, login;

- (void) reset
{
    self.login=@"";
    self.pwd=@"";
}



- (BOOL) getStoredLoginPwd
{
    BOOL bRes = FALSE;
    
    // check for user/pwd...
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [paths objectAtIndex:0]; 
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"login.plist"]; 
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    
    if (![fileManager fileExistsAtPath: path]) 
    {
        NSString *bundle = [[NSBundle mainBundle] pathForResource:@"login" ofType:@"plist"]; 
        
        [fileManager copyItemAtPath:bundle toPath: path error:&error];
    }
    
    
    if ([fileManager fileExistsAtPath: path])     {
        NSMutableDictionary *savedStock = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
        
        //load from savedStock example int value
        self.login = [savedStock objectForKey:@"login"];
        

        if ( [[savedStock objectForKey:@"pwd"] length] > 0 )
        {
#ifdef CRYPT_PWD
            NSError *error = [[NSError alloc] init];
            @try {
                // NSData *decrypted = [[RNCryptor AES256Cryptor] decryptData:[savedStock objectForKey:@"pwd"] password:CRYPT_KEY error:&error];
                
                
                NSData *decrypted = [RNDecryptor decryptData:[savedStock objectForKey:@"pwd"]
                                                withPassword:CRYPT_KEY
                                                       error:&error];
                self.pwd = [[NSString alloc] initWithData:decrypted encoding:NSUTF8StringEncoding];
                
            }
            @catch (NSException *exception) {
                debug(@"main: Caught %@: %@", [exception name], [exception reason]);
                self.pwd = [savedStock objectForKey:@"pwd"];
            }
            @finally
            {
                [error release];
            }            
#else
            self.pwd = [savedStock objectForKey:@"pwd"];
#endif
        }
        else
        {
            self.pwd=@"";
        }
        
        [savedStock release];
        
        bRes=TRUE;
        
    }
    
    return bRes;
}

- (BOOL) saveLoginPwd 
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"login.plist"];            

    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    
    [data setObject:login forKey:@"login"];
    

    if ( [pwd length] > 0 )
    {
#ifdef CRYPT_PWD
        NSData *dataToEncrypt = [pwd dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = [[NSError alloc] init];
        
        @try {
            //NSData *encrypted = [[RNCryptor AES256Cryptor] encryptData:dataToEncrypt password:CRYPT_KEY error:&error];
            NSData *encrypted = [RNEncryptor encryptData:dataToEncrypt
                                            withSettings:kRNCryptorAES256Settings
                                                password:CRYPT_KEY
                                                   error:&error];
            [data setObject:encrypted  forKey:@"pwd"];
        }
        @catch (NSException *exception) {
            debug(@"main: Caught %@: %@", [exception name], [exception reason]);
            [data setObject:pwd  forKey:@"pwd"];
        }
        @finally {
            [error release];
        }
#else
        [data setObject:pwd  forKey:@"pwd"];
#endif
    }
    else
    {
        [data setObject:pwd  forKey:@""];
    }
    

    
    [data writeToFile: path atomically:YES];
    [data release];

    return TRUE;
}

- (BOOL) isCorrectLoginPwd
{
    BOOL bRes = FALSE;
    
    // curl -u user:pwd https://api.del.icio.us/v1/json/posts/recent?count=1
    // {"result": {"code": "access denied"}}
    //NSString *strUrl  = [[NSString alloc] initWithFormat:@"https://%@:%@@api.del.icio.us/v1/json/posts/recent?count=1",self.login, self.pwd];
    
    NSString *strUrl  = [[NSString alloc] initWithFormat:@"%@/json/posts/recent?count=1",[MCODeliciousOperations getDeliciousBaseUrlWithLogin:self.login andPassword:self.pwd]];
    
    debug(@"Url...<%@>", strUrl);
    
    NSURL *url = [NSURL URLWithString:strUrl];
    
    // Clear all cookies & session information
    [ASIHTTPRequest clearSession];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    NSTimeInterval timeInterval;
    timeInterval = request.timeOutSeconds;    
    [request setTimeOutSeconds:timeInterval * 2]; 
    [request setNumberOfTimesToRetryOnTimeout:2];
    
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) 
    {      
        NSString *response = [request responseString];
        debug(@"%@",response);
        
        // check if reply <> {"result": {"code": "access denied"}}
        
        NSDictionary *responseDict = [response JSONValue];
        NSDictionary *responseCode = [responseDict  objectForKey:@"result"];
        NSString *returnCode = [responseCode objectForKey:@"code"];
        
        if ( [returnCode compare:@"access denied"] )
        { 
            bRes = FALSE;
        }
        else 
        {
            bRes= TRUE;
        }                
    }
    else {
//        Printing description of error:
//        Error Domain=ASIHTTPRequestErrorDomain Code=3 "Authentication needed" UserInfo=0xde9f260 {NSLocalizedDescription=Authentication needed}        
        if ( ! [[error domain] isEqualToString:@"ASIHTTPRequestErrorDomain"]) 
        {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unknown Error"
                                                                message:@"Network has been lost, unable to check validity of login/pwd, please try later..."
                                                               delegate:self 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            
            [alertView show];
            [alertView release];
        }
    }
    [strUrl release];
    
    debug(@"bRes : %d",bRes);
    
    return bRes;
}


- (void) dealloc
{
    [login release];
    [pwd release];

    [super dealloc];
}
@end
