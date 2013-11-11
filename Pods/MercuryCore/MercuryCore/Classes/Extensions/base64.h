//
//  base64.h
//  OmniTest
//
//  Created by Paul Forstman on 7/30/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//


@interface NSString (TCBase64)

+ (NSString *) stringWithBase64Encoding:(NSString *)string;

@end
