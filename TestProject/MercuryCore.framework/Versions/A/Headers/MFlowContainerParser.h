//
//  MFlowContainerParser.h
//  ArchTest1
//
//  Created by Stephen Tallent on 1/15/10.
//  Copyright 2010 Merc!. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/parser.h>
#import <libxml/xmlreader.h>

#import "MFlowContainer.h"

@interface MFlowContainerParser : NSObject {
	NSData *unparsedData;
	
	MFlowContainerResponseStatus responseStatus;
	
	NSNumber *expressedVersionNumber;
	NSNumber *ttlSeconds;
	
	NSMutableArray *pubItemIDs;
	
	NSMutableArray *unsortedRelationNodes;
	NSArray *sortedRelationNodes;
	
	NSMutableDictionary *linkedAttNameIDs;
	NSMutableDictionary *newItems;
	
	NSDateFormatter *dateFormatter;
	
	NSMutableString *removedItems; 
	
	bool compressed;
}

@property(nonatomic, readonly) MFlowContainerResponseStatus responseStatus;
@property(nonatomic, readonly) NSNumber *expressedVersionNumber;
@property(nonatomic, readonly) NSNumber *ttlSeconds;
@property(nonatomic, readonly) NSArray *sortedRelationNodes;
@property(nonatomic, readonly) NSMutableArray *pubItemIDs;
@property(nonatomic, readonly) NSMutableDictionary *linkedAttNameIDs;
@property(nonatomic, readonly, getter=getNewItems) NSMutableDictionary *newItems;
@property(nonatomic, readonly) NSMutableString *removedItems;

-(id)initWithXMLData:(NSData *)d;

-(void)parse;

-(void)parseContainerObjects:(xmlTextReaderPtr)reader;
-(void)parseContainerItem:(xmlTextReaderPtr)reader;

-(void)parseItemObjects:(xmlTextReaderPtr)reader;
-(void)parseItems:(xmlTextReaderPtr)reader;

@end
