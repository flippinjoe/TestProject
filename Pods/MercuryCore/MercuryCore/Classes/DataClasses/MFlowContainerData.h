//
//  MFlowContainerData.h
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 5/11/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MFlowContainerData : NSObject <NSCoding> {
	//-- Codable
	NSNumber* ttlSeconds;
	NSDate* dataRetrievalDate;
	NSNumber* containerVersion;
	NSArray* relationNodes;
	NSDictionary *linkedAttNameIDs;
	NSArray* publishedItemIDs;
	NSDictionary* masterItems;
	//--
	//bool hasData;
}

@property(nonatomic, strong) NSNumber *ttlSeconds;
@property(nonatomic, strong) NSDate *dataRetrievalDate;
@property(nonatomic, strong) NSNumber *containerVersion;
@property(nonatomic, strong) NSArray *relationNodes;
@property(nonatomic, strong) NSDictionary *linkedAttNameIDs;
@property(nonatomic, strong) NSArray *publishedItemIDs;
@property(nonatomic, strong) NSDictionary *masterItems;

@property(nonatomic, readonly) bool dataStale;

@end
