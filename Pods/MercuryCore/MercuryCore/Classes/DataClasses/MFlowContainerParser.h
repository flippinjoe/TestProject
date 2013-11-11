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

@interface MFlowContainerParser : NSObject

@property(nonatomic, assign, readonly) MFlowContainerResponseStatus responseStatus;
@property(strong, nonatomic, readonly) NSNumber *expressedVersionNumber;
@property(strong, nonatomic, readonly) NSNumber *ttlSeconds;
@property(strong, nonatomic, readonly) NSArray *sortedRelationNodes;
@property(strong, nonatomic, readonly) NSMutableArray *pubItemIDs;
@property(strong, nonatomic, readonly) NSMutableDictionary *linkedAttNameIDs;
@property(strong, nonatomic, readonly, getter=getNewItems) NSMutableDictionary *newItems;
@property(strong, nonatomic, readonly) NSMutableString *removedItems;

- (id)initWithXMLData:(NSData *)d;

- (void)parse;

@end
