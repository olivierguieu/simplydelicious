//
//  MCODeliciousOperations.h
//  test3
//
//  Created by Olivier Guieu on 05/08/12.
//
//

#import <Foundation/Foundation.h>

@class MCODeliciousUser;

@interface MCODeliciousOperations : NSObject


+ (BOOL)addForUrl: (NSString*) strUrl Tag : (NSString*) tag WithDeliciousUser:(MCODeliciousUser*) deliciousUser;
+ (BOOL)addForUrl: (NSString*) strUrl Tag : (NSString*) tag WithLogin:(NSString*) login andPassword:(NSString*) password;

+ (NSString *)getDeliciousDescriptionForUrl: (NSString*) strUrl WithDeliciousUser:(MCODeliciousUser*) deliciousUser;
+ (NSString *)getDeliciousDescriptionForUrl: (NSString*) strUrl WithLogin:(NSString*) login andPassword:(NSString*) password;

+ (NSArray *)getDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithDeliciousUser:(MCODeliciousUser*) deliciousUser;
+ (NSArray *)getDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithLogin:(NSString*) login andPassword:(NSString*) password;

+ (NSArray *)getDeliciousTagsForUrl:(NSString*) strUrl ForSuggestedTags:(BOOL) bSuggestedtags WithDeliciousUser:(MCODeliciousUser*) deliciousUser;
+ (NSArray *)getDeliciousTagsForUrl:(NSString*) strUrl ForSuggestedTags:(BOOL) bSuggestedtags WithLogin:(NSString*) login andPassword:(NSString*) password;


+ (BOOL)uptadeTagsWithDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithDeliciousUser:(MCODeliciousUser*) deliciousUser;
+ (BOOL)uptadeTagsWithDeliciousSuggestedTagsForUrl: (NSString*) strUrl WithLogin:(NSString*) login andPassword:(NSString*) password;


+ (NSString *)getDeliciousBaseUrlWithLogin:(NSString*) login andPassword:(NSString*) password;

+ (BOOL)deleteLink:(NSString *) strUrl withDeliciousUser:(MCODeliciousUser*) deliciousUser;
+ (BOOL)deleteLink:(NSString *) strUrl withLogin:(NSString *) login andPassword:(NSString *) password;

+ (BOOL)deleteTag:(NSString *) strTag fromLink:(NSString *) strUrl withLogin:(NSString *) login andPassword:(NSString *) password;
+ (BOOL)deleteTag:(NSString *) strTag fromLink:(NSString *) strUrl withDeliciousUser:(MCODeliciousUser*) deliciousUser;

@end
