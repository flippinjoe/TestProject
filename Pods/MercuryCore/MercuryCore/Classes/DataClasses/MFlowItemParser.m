//
//  MFlowItemParser.m
//  ArchTest1
//
//  Created by Stephen Tallent on 1/4/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import "MFlowItemParser.h"
#import "TC_NSDataExtensions.h"
#import "MFlowItem.h"

@implementation MFlowItemParser

@synthesize items;

-(id)initWithCompressedBlock:(NSString *)s{
    
	self = [super init];
	
	
	dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"EN"];
	[dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
	
	NSData *gutsData = [NSData dataWithBase64EncodedString:s];

	NSData *gutsInflated = [gutsData gzipInflate];

	NSString *gutsXMLString1 = [[NSString alloc] initWithData:gutsInflated encoding:NSUTF8StringEncoding];
	
	NSString *gutsXMLString2 = [NSString stringWithFormat:@"<root><Items>%@</Items></root>",gutsXMLString1];
	
	
	NSXMLParser *p = [[NSXMLParser alloc] initWithData:[gutsXMLString2 dataUsingEncoding:NSUTF8StringEncoding]];
	
	items = [[NSMutableDictionary alloc] initWithCapacity:0];
	
	[p setDelegate: self];
	
	[p parse];
	
	return self;
}
/*
- (void)parserDidStartDocument:(NSXMLParser *)parser{
	NSLog(@"parserDidStartDocument");
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
	NSLog(@"parserDidEndDocument");
}*/

- (void)parser:(NSXMLParser *)parser 
	 didStartElement:(NSString *)elementName 
		namespaceURI:(NSString *)namespaceURI 
	   qualifiedName:(NSString *)qualifiedName 
		  attributes:(NSDictionary *)attributeDict{
	
		
	//NSLog(@"didStartElement: %@ %@",elementName, attributeDict);
	
	if ([elementName compare:@"Item"] == NSOrderedSame) {
		
		currentItem = [[MFlowItem alloc] init];
		[currentItem setObject: [NSNumber numberWithInteger:[[attributeDict objectForKey:@"IID"] integerValue]]
						forKey: @"ItemID"];
		[currentItem setObject: [NSNumber numberWithInteger:[[attributeDict objectForKey:@"TID"] integerValue]]
						forKey: @"TypeID"];
		
		return;
	}
	
	if ([elementName compare:@"Att"] == NSOrderedSame) {
		
		currentAttInfo = attributeDict;
		
		return;
	}
	
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	
	
	if (currentCharacters == nil) {
		currentCharacters = [[NSMutableString alloc] initWithCapacity:0];
	}
	
	[currentCharacters appendString:string];
	
}
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	

	//NSLog(@"didEndElement: %@",elementName);
	
	if ([elementName compare:@"Item"] == NSOrderedSame) {
		
		[items setObject:currentItem forKey:[currentItem.ItemID stringValue]];
		
		return;
	}
	
	if ([elementName compare:@"Att"] == NSOrderedSame) {
		
		
		NSInteger type = [[currentAttInfo objectForKey:@"ATID"] integerValue];
		NSInteger card = 0;
		NSString *c = [currentAttInfo objectForKey:@"Card"];
		if (c != nil) {
			card = [c integerValue];
		}
		id val = nil;// = [self getAttributeValueObjectForType:type withStringValue:currentCharacters withCardinality:card];
		
		
		bool myBool; 
		NSString *s = currentCharacters;
	
		switch (type) {
			case 1: //short text
			case 2: //long text
				
				val = s;
				
				break;
				
			case 3: //number
				
				val = [NSNumber numberWithInteger:[s integerValue]];
				
				break;
				
			case 4: //money
			case 9: //decimal
				
				val = [NSDecimalNumber decimalNumberWithString:s];
				
				break;
				
			case 5: //date
				
				if ( [s compare:@""] == NSOrderedSame){
					val = s;
				} else {
					val = [dateFormatter dateFromString:s];
				}
				
				break;
				
			case 6: // bool
				
				if( [s compare:@"True"] == NSOrderedSame ){
					myBool = true;
				} else {
					myBool = false;
				}
				val = [NSNumber numberWithBool:myBool];
				break;
				
			case 10: //linked
				if (card == 1){
					val = [NSDictionary dictionary];
				} else {
					val = [NSMutableArray arrayWithCapacity:10];
				}
				break;
				
			default:
				break;
		}
		
		
		
		[currentItem setObject:val forKey:[currentAttInfo objectForKey:@"Name"]];
		
		currentCharacters = nil;
		
		
	}
	
	
}

-(id)getAttributeValueObjectForType:(NSInteger)type withStringValue:(NSString *)s withCardinality:(NSInteger)attCard{
	bool myBool; 
	
	switch (type) {
		case 1: //short text
		case 2: //long text
			
			return s;
			
			break;
			
		case 3: //number
			
			return [NSNumber numberWithInteger:[s integerValue]];
			
			break;
			
		case 4: //money
		case 9: //decimal
			
			return [NSDecimalNumber decimalNumberWithString:s];
			
			break;
			
		case 5: //date
			
			if ( [s compare:@""] == NSOrderedSame){
				return s;
			} else {
				return [dateFormatter dateFromString:s];
			}
			
			break;
			
		case 6: // bool
			
			if( [s compare:@"True"] == NSOrderedSame ){
				myBool = true;
			} else {
				myBool = false;
			}
			return [NSNumber numberWithBool:myBool];
			break;
			
		case 10: //linked
			if (attCard == 1){
				return [NSDictionary dictionary];
			} else {
				return [NSMutableArray arrayWithCapacity:10];
			}
			break;
			
		default:
			
			return nil;
			break;
	}
	
}



@end
