//
//  TC_NSMutableDataExtensions.h
//  CNN
//
//  Created by Stephen Tallent on 8/5/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableData (TC_NSMutableDataExtensions)

- (BOOL) encryptWithKey: (NSString *) key;

- (BOOL) decryptWithKey: (NSString *) key;

@end
