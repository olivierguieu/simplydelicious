//
//  MCODeliciousUser.h
//  test3
//
//  Created by Olivier Guieu on 30/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MCODeliciousUser : NSObject

- (void) reset;
- (BOOL) getStoredLoginPwd;
- (BOOL) saveLoginPwd;

- (BOOL) isCorrectLoginPwd;

// Delicious information
@property (strong, nonatomic) NSString *login;
@property (strong, nonatomic) NSString *pwd;


@end
