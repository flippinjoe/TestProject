//
//  MFlowItemParser.h
//  ArchTest1
//
//  Created by Stephen Tallent on 1/4/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

// !!!: Deprecated, No longer in use

#import <Foundation/Foundation.h>

@class MFlowItem;

@interface MFlowItemParser : NSObject <NSXMLParserDelegate> 
{
	
	NSMutableDictionary *items;
	
	MFlowItem *currentItem;
	
	NSDictionary *currentAttInfo;
	
	NSMutableString *currentCharacters;
	
	NSDateFormatter *dateFormatter;
}

@property(nonatomic, readonly)NSMutableDictionary *items;

-(id)initWithCompressedBlock:(NSString *)s;

-(id)getAttributeValueObjectForType:(NSInteger)type withStringValue:(NSString *)s withCardinality:(NSInteger)attCard;

@end
