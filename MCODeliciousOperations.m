//
//  MCODeliciousOperations.m
//  test3
//
//  Created by Olivier Guieu on 05/08/12.
//
//

#import "MCODeliciousOperations.h"
#import "MCODeliciousUser.h"

#import "XPathQuery.h"

#import "DebugOutput.h"


@implementation MCODeliciousOperations


#pragma mark - 
#pragma mark - Helpers

+ (NSString *)getDeliciousBaseUrlWithLogin:(NSString*) login andPassword:(NSString*) password;
{
    NSString *strUrl  = [[NSString alloc] initWithFormat:@"https://%@:%@@api.del.icio.us/v1",login, password] ;
    return [strUrl autorelease];
}

+ (BOOL)callDeliciousUrlWithString:(NSString *) urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL bRes = FALSE;
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"Cache-Control" value:@"no-cache"];
    
    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        
        NSString *response = [request responseString];
        
        debug (@"%@",response);

        NSArray *myTmpArray;
        myTmpArray = PerformXMLXPathQuery( [response dataUsingEncoding:NSUTF8StringEncoding] , @"//result/@code");
                
        NSString *nodeContent;
        NSString *nodeName;
        
        for (id object in myTmpArray) {
            nodeContent = [object valueForKey:@"nodeContent"];
            nodeName = [object valueForKey:@"nodeName"];
            
            if ( [nodeName compare:@"code" ] == 0 )
            {
                if ( [nodeContent compare:@"done"] == 0)
                {
                    bRes = TRUE;
                    break;
                }
            }
        }
    }
    return bRes;
}

+ (BOOL)uptadeTagsForUrl:(NSString*) strUrl WithArrayOfTag:(NSArray *) arrayOfTags WithLogin:(NSString*) login andPassword:(NSString*) password
{
    NSString * descriptionForUrl = [[self getDeliciousDescriptionForUrl:strUrl WithLogin:login andPassword:password]stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // cleaning up the arrayoftags
    NSMutableArray * arrayToAdd = [[NSMutableArray alloc] initWithCapacity:([arrayOfTags count]==0)?10:[arrayOfTags count]];
    for ( NSString *tag in arrayOfTags)
    {
        if ( [tag caseInsensitiveCompare:@" "])
            [arrayToAdd addObject:tag];
    }
    NSString * tags = [[arrayToAdd componentsJoinedByString:@","] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    // cf http://delicious.com/developers#title1
    
    NSString *tmpStrURL  = [[NSString alloc] initWithFormat:@"%@/posts/add?url=%@&description=%@&replace=yes&tags=%@",[MCODeliciousOperations getDeliciousBaseUrlWithLogin:login andPassword:password], strUrl, descriptionForUrl, tags];
    
   debug(@"Url...<%@>", tmpStrURL);
    
    BOOL bRes = [self callDeliciousUrlWithString:tmpStrURL];
    debug(@"bRes : %d",bRes);

    [tmpStrURL release];
    [arrayToAdd release];

    
    return bRes;
}


#pragma mark - add tag
+ (BOOL)addForUrl: (NSString*) strUrl Tag : (NSString*) tag WithDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return [MCODeliciousOperations addForUrl:strUrl Tag:tag WithLogin:deliciousUser.login andPassword:deliciousUser.pwd];
    
}

+ (BOOL)addForUrl: (NSString*) strUrl Tag : (NSString*) tag WithLogin:(NSString*) login andPassword:(NSString*) password
{
    NSArray * tagsForUrl = [self getDeliciousTagsForUrl:strUrl ForSuggestedTags:FALSE WithLogin:login andPassword:password];
    NSMutableArray * allTagsForUrl = [[NSMutableArray alloc] initWithArray:tagsForUrl];
    [allTagsForUrl addObject:tag];

    BOOL bRes = [MCODeliciousOperations uptadeTagsForUrl:strUrl WithArrayOfTag:allTagsForUrl WithLogin:login andPassword: password];
    debug(@"bRes : %d",bRes);
    
    [allTagsForUrl release];
    
    return bRes;
}


#pragma mark - get Description
+ (NSString *)getDeliciousDescriptionForUrl: (NSString*) strUrl WithDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return [MCODeliciousOperations getDeliciousDescriptionForUrl:strUrl WithLogin:deliciousUser.login andPassword:deliciousUser.pwd];
}

+ (NSString *)getDeliciousDescriptionForUrl: (NSString*) strUrl WithLogin:(NSString*) login andPassword:(NSString*) password
{
    // https://api.del.icio.us/v1/posts/get? - get bookmark for a single date, or fetch specific items
    
    NSString * strDescription;
    
    NSString *tmpStrURL = [[NSString alloc] initWithFormat:@"%@/json/posts/get?url=%@",[MCODeliciousOperations getDeliciousBaseUrlWithLogin:login andPassword:password], strUrl];
    
    NSURL *url = [NSURL URLWithString:tmpStrURL];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"Cache-Control" value:@"no-cache"];

    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        
        NSString *response = [request responseString];
        debug(@"%@",response);
        
//         {"bookmark_key": "put7C1hKyc364cTRRJTwMt8zjR9PNAY1Y1vnt1ryVAE=", "tags": "", "posts": [{"post": {"private": "yes", "href": "http://albacorebuild.net/", "hash": "051ff2711b87b0fb0aceeacb7304b017", "description": "Albacore: Dolphin-Safe Rake Tasks For .NET Systems", "time": "2010-12-10T05:26:59Z", "shared": "no", "tag": ".net tools ruby programming", "extended": ""}}], "user": "olivier.guieu", "dt": "2010-12-10", "network_key": "IH-N3q8xHM49E3Pnd4ff8gQNlZwEPihPP2VRJ5u9uOc=", "inbox_key": "lajTnck1ejEIQfAI85OxzfZWLyilml89Q6i3Wwau-r4="}
//
        
        NSDictionary *responseDict = [response JSONValue];
        NSDictionary *postsDict = [responseDict  objectForKey:@"posts"];
        for (NSDictionary *dict in postsDict)
        {
            NSDictionary *postDict = [dict  objectForKey:@"post"];
            strDescription = [postDict objectForKey:@"description"];
        }
        
        // on remplcae nil par une chaine vide...
        if ( strDescription == nil)
            strDescription = @"";
     }
    [tmpStrURL release];
    return strDescription;
}


#pragma mark - Updating tags 

+ (BOOL)uptadeTagsWithDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return [MCODeliciousOperations uptadeTagsWithDeliciousSuggestedTagsForUrl:strUrl WithLogin:deliciousUser.login andPassword:deliciousUser.pwd];
}

+ (BOOL)uptadeTagsWithDeliciousSuggestedTagsForUrl:(NSString*) strUrl WithLogin:(NSString*) login andPassword:(NSString*) password
{
    NSArray * suggestedTagsForUrl = [self getDeliciousTagsForUrl:strUrl ForSuggestedTags:TRUE WithLogin:login andPassword:password];
   
    BOOL bRes = [MCODeliciousOperations uptadeTagsForUrl:strUrl WithArrayOfTag:suggestedTagsForUrl WithLogin:login andPassword: password];
    debug(@"bRes : %d",bRes);
    return bRes;
 }

#pragma mark - getting tags

+ (NSArray *)getDeliciousTagsForUrl:(NSString*) strUrl ForSuggestedTags:(BOOL) bSuggestedtags WithDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return [MCODeliciousOperations getDeliciousTagsForUrl:strUrl  ForSuggestedTags:bSuggestedtags WithLogin:deliciousUser.login andPassword:deliciousUser.pwd];
}

+ (NSArray *)getDeliciousTagsForUrl:(NSString*) strUrl ForSuggestedTags:(BOOL) bSuggestedtags WithLogin:(NSString*) login andPassword:(NSString*) password
{
    NSMutableArray *arrayWhereToStockTags= [[[NSMutableArray alloc] initWithCapacity:10] autorelease];

    NSString *tmpStrURL;
    if ( bSuggestedtags)
    {
        tmpStrURL = [[NSString alloc] initWithFormat:@"%@/json/posts/suggest?url=%@",[MCODeliciousOperations getDeliciousBaseUrlWithLogin:login andPassword:password], strUrl];
    }
    else
    {
        tmpStrURL = [[NSString alloc] initWithFormat:@"%@/json/posts/get?url=%@",[MCODeliciousOperations getDeliciousBaseUrlWithLogin:login andPassword:password], strUrl];
    }
    
    NSURL *url = [NSURL URLWithString:tmpStrURL];
    
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request addRequestHeader:@"Cache-Control" value:@"no-cache"];

    [request startSynchronous];
    NSError *error = [request error];
    if (!error) {
        
        NSString *response = [request responseString];
        debug(@"%@",response);
        
        // No Data response
        // {"result": {"code": "no suggestions"}}
        // else
        // Printing description of response:
        //{"suggest": [{"popular": {"tag": ".net"}}, {"popular": {"tag": "objective-c"}}, {"popular": {"tag": "bridge"}}, {"recommended": {"tag": "cocoa"}}, {"recommended": {"tag": "Cocoa#.Replacement/"}}, {"recommended": {"tag": "MacOSX"}}, {"recommended": {"tag": "mono"}}]}
        
        NSDictionary *responseDict = [response JSONValue];
        
        if ( bSuggestedtags )
        {
            NSDictionary *postsDict = [responseDict  objectForKey:@"suggest"];
            
            for (NSDictionary *dict in postsDict)
            {
                debug(@"%@", [dict description]);
                NSDictionary *post = [dict objectForKey:@"recommended"];
                if ( [post count] > 0 )
                {
                    debug(@"%@", [post objectForKey:@"tag"]);
                    [arrayWhereToStockTags addObject:[post objectForKey:@"tag"]];
                }
            }      
        }
        else
        {
            NSDictionary *postsDict = [responseDict  objectForKey:@"posts"];
 
            for (NSDictionary *post in postsDict)
            {
                NSDictionary *postInfo= [post objectForKey:@"post"];
                 NSArray *arrayOfTags = [[postInfo objectForKey:@"tag"] componentsSeparatedByString:@" "];
                [arrayWhereToStockTags addObjectsFromArray:arrayOfTags];
            }
   
        }
    }
    [tmpStrURL release];
    return [NSArray arrayWithArray:arrayWhereToStockTags];
}

+ (NSArray *)getDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return  [MCODeliciousOperations getDeliciousSuggestedTagsForUrl:strUrl WithLogin:deliciousUser.login andPassword:deliciousUser.pwd];
}

+ (NSArray *)getDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithLogin:(NSString*) login andPassword:(NSString*) password
{
    return [MCODeliciousOperations getDeliciousTagsForUrl:strUrl ForSuggestedTags:TRUE WithLogin:login andPassword:password];
}


#pragma mark - Deleting Links

+ (BOOL)deleteLink:(NSString *) strUrl withDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return [MCODeliciousOperations deleteLink:strUrl withLogin:deliciousUser.login andPassword:deliciousUser.pwd];
}

+ (BOOL)deleteLink:(NSString *) strUrl withLogin:(NSString *) login andPassword:(NSString *) password
{
    //https://api.del.icio.us/v1/posts/delete? &url={URL}

    BOOL bRes = FALSE;
    
    NSString *tmpStrURL  = [[NSString alloc] initWithFormat:@"%@/posts/delete?url=%@",[MCODeliciousOperations getDeliciousBaseUrlWithLogin:login andPassword:password], strUrl];
    
    bRes = [self callDeliciousUrlWithString:tmpStrURL];
    [tmpStrURL release];
    
    debug(@"bRes : %d",bRes);
    
    return bRes;
}

#pragma mark - Deleting Tags

+ (BOOL)deleteTag:(NSString *) strTag fromLink:(NSString *)strUrl withLogin:(NSString *) login andPassword:(NSString *) password;
{
    
    //https://api.del.icio.us/v1/posts/delete? &url={URL}
    
    // http://apis.io/Delicious
    //curl -X PUT -u 'username:password' -d 'replace=no&shared=no' https://api.del.icio.us/v1/posts/add
    //posts/add
//    Add a post to Delicious. The URL of the item. The description of the item. Notes for the item. Tags for the item (space delimited). Datestamp of the item (format "CCYY-MM-DDThh:mm:ssZ"). Requires a LITERAL "T" and "Z" like in ISO8601 at http://www.cl.cam.ac.uk/~mgk25/iso-time.html for example: "1984-09-01T14:21:31Z" Don't replace post if given url has already been posted. Make the item private.
//
    
    NSArray * existingTags = [MCODeliciousOperations getDeliciousTagsForUrl:strUrl ForSuggestedTags:NO WithLogin:login andPassword:password];
    
    NSMutableArray *targetTags=[[NSMutableArray alloc] initWithCapacity:[existingTags count]];
    
    for (NSString *str in existingTags)
    {
        if ( [ str caseInsensitiveCompare:strTag] && [str caseInsensitiveCompare:@" "])
        {
            [targetTags addObject:str];
        }
    }
    
    BOOL bRes = [MCODeliciousOperations uptadeTagsForUrl:strUrl WithArrayOfTag:targetTags WithLogin:login andPassword:password];
    debug(@"bRes : %d",bRes);
    
    [targetTags release];
    
    return bRes;
    
}

+ (BOOL)deleteTag:(NSString *) strTag fromLink:(NSString *) strUrl withDeliciousUser:(MCODeliciousUser*) deliciousUser
{
    return [MCODeliciousOperations deleteTag:strTag fromLink:strUrl  withLogin:deliciousUser.login andPassword:deliciousUser.pwd];
}


@end
