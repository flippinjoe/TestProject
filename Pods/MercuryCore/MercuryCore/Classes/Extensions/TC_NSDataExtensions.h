//
//  TC_NSDataExtensions.h
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 9/10/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSData (TC_NSDataExtensions)

- (NSData *) gzipInflate;
- (NSData *) gzipDeflate;

+ (NSData *) dataWithBase64EncodedString:(NSString *) string;
- (id) initWithBase64EncodedString:(NSString *) string;
	
- (NSString *) base64Encoding;
- (NSString *) base64EncodingWithLineLength:(unsigned int) lineLength;

- (BOOL) hasPrefix:(NSData *) prefix;
- (BOOL) hasPrefixBytes:(void *) prefix length:(unsigned int) length;

@end
