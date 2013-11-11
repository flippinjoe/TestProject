//
//  TC_NSStringExtensions.h
//  MercuryCoreDev
//
//  Created by Michael Morrison on 6/17/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString (TC_NSStringExtensions)

- (NSString *)stringByEncodingXMLEntities;
- (NSString *)stringByStrippingHTMLLinks;
- (NSString *)stringByEncodingHTMLEntities;
- (NSString *)stringByStrippingHTMLTags;
- (NSString *)stringByStrippingHTMLTags:(NSArray *)valid_tags;
- (NSString *)stringByTrimmingLengthToNearestWord:(NSUInteger)trimLength fromIndex:(NSUInteger)startIndex withEllipsis:(BOOL)ellipsis;
- (NSString *)stringByTrimmingLengthToNearestWord:(NSUInteger)trimLength fromIndex:(NSUInteger)startIndex;
- (NSString *)stringByTrimmingLengthToNearestWord:(NSUInteger)trimLength;

@end
