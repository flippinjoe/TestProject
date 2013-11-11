//
//  TC_NSStringExtensions.m
//  MercuryCoreDev
//
//  Created by Michael Morrison on 6/17/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "TC_NSStringExtensions.h"

#define imini(a,b) ({int _a = (a), _b = (b); _a < _b ? _a : _b; })

@implementation NSString (TC_NSStringExtensions)

- (NSString *)stringByEncodingXMLEntities {
	NSMutableString *encodedString = [NSMutableString stringWithCapacity:0];
	[encodedString appendString:self];
	if ([encodedString length] > 0) {
		[encodedString replaceOccurrencesOfString:@"&nbsp;" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
		[encodedString replaceOccurrencesOfString:@"&" withString:@"&amp;" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
//		[encodedString replaceOccurrencesOfString:@"\'" withString:@"&apos;" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
//		[encodedString replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:NSLiteralSearch range:NSMakeRange(0, [encodedString length])];
	}
	
	return encodedString;
}

- (NSString *)stringByStrippingHTMLLinks {
	NSMutableString *strippedString = [self mutableCopy];
	NSRange linkRangeStart = [strippedString rangeOfString:@"<a href" options:NSCaseInsensitiveSearch];
	while (linkRangeStart.location != NSNotFound) {
		NSRange linkRangeEnd = [strippedString rangeOfString:@"</a>" options:NSCaseInsensitiveSearch];
		NSRange deleteRange = NSMakeRange(linkRangeStart.location, (linkRangeEnd.location + linkRangeEnd.length) - linkRangeStart.location);
		[strippedString deleteCharactersInRange:deleteRange];

		linkRangeStart = [strippedString rangeOfString:@"<a href" options:NSCaseInsensitiveSearch];
	}
	return strippedString;
}

- (NSString *)stringByEncodingHTMLEntities {
    NSArray *characters = [NSArray arrayWithObjects:@"&",     @"<",    @">",    nil];
    NSArray *entities   = [NSArray arrayWithObjects:@"&amp;", @"&lt;", @"&gt;", nil];

    NSMutableString *encoded = [NSMutableString stringWithString: self];
    int i, count = [characters count];
    for(i = 0; i < count; i++)
    {
      [encoded replaceOccurrencesOfString:[characters objectAtIndex: i] 
                               withString:[entities objectAtIndex:i] 
                                  options:NSLiteralSearch 
                                    range:NSMakeRange(0, [encoded length])];
    }
    return encoded;
}

-(NSString *)stringByStrippingHTMLTags{
	
	return [self stringByStrippingHTMLTags:[NSArray array]];
	
}

- (NSString *)stringByStrippingHTMLTags:(NSArray *)valid_tags
{
    //use to strip the HTML tags from the data
    NSScanner *scanner;
    NSString *text = nil;
    NSString *tag = nil;

	NSString *data = [self copy];;
	
    //set up the scanner
    scanner = [NSScanner scannerWithString:data];

    while([scanner isAtEnd] == NO) {
        //find start of tag
        [scanner scanUpToString:@"<" intoString:NULL];

        //find end of tag
        [scanner scanUpToString:@">" intoString:&text];

        //get the name of the tag
        if([text rangeOfString:@"</"].location != NSNotFound)
            tag = [text substringFromIndex:2]; //remove </
        else {
            tag = [text substringFromIndex:1]; //remove <
            //find out if there is a space in the tag
        if([tag rangeOfString:@" "].location != NSNotFound)
            //remove text after a space
            tag = [tag substringToIndex:[tag rangeOfString:@" "].location];
        }

        //if not a valid tag, replace the tag with a space
        if([valid_tags containsObject:tag] == NO)
            data = [data stringByReplacingOccurrencesOfString:
                [NSString stringWithFormat:@"%@>", text] withString:@""];
    }

    //return the cleaned up data
    return data;
}

- (NSString *)stringByTrimmingLengthToNearestWord:(NSUInteger)trimLength fromIndex:(NSUInteger)startIndex withEllipsis:(BOOL)ellipsis {
	if (([self length] - startIndex) > trimLength) {
		NSRange chopSpace = [self rangeOfString:@" " options:NSBackwardsSearch range:NSMakeRange(startIndex, trimLength)];
		NSString *trimmedString = [NSString stringWithFormat:ellipsis ? @"%@...":@"%@", [self substringToIndex:imini(chopSpace.location, [self length])]];
		return trimmedString;
	}

	return self;
}

- (NSString *)stringByTrimmingLengthToNearestWord:(NSUInteger)trimLength fromIndex:(NSUInteger)startIndex {
	return [self stringByTrimmingLengthToNearestWord:trimLength fromIndex:startIndex withEllipsis:TRUE];
}

- (NSString *)stringByTrimmingLengthToNearestWord:(NSUInteger)trimLength {
	return [self stringByTrimmingLengthToNearestWord:trimLength fromIndex:0 withEllipsis:TRUE];
}

@end
