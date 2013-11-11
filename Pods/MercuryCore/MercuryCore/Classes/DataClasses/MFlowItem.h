
//  Created by Stephen Tallent on 5/14/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.

#import <Foundation/Foundation.h>


@interface MFlowItem : NSObject <NSCoding> {
	NSMutableDictionary *dictionary;
}

@property(nonatomic, readonly, strong) NSNumber *ItemID;
@property(nonatomic, readonly, strong) NSNumber *TypeID;
@property(nonatomic, readonly, strong) NSString *ItemName;
@property(nonatomic, readonly, strong) NSNumber *ExpressedVersionNumber;

-(id)copyWithZone:(NSZone *)z;
- (id)initWithCapacity:(NSUInteger)capacity;

- (void)setObject:(id)anObject forKey:(id)aKey;
- (id)objectForKey:(id)aKey;
- (void)setValue:(id)anObject forKey:(id)aKey;
- (id)valueForKey:(id)aKey;
- (id)valueForKeyIfValid:(id)aKey;
- (BOOL)hasValueForKey:(id)aKey;
- (void)removeObjectForKey:(id)aKey;
- (NSUInteger)count;

/** JOE: 9/18/12
 *  Removing Duplicate Declaration
 *
 *  - (id)objectForKey:(id)aKey;
**/
- (id)objectForKeyIfValid:(id)aKey;
- (BOOL)hasObjectForKey:(id)aKey;
- (NSEnumerator *)keyEnumerator;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;

- (id)valueForKeyPath:(NSString *)keyPath;
- (NSArray *)allKeys;

- (NSComparisonResult)compare:(MFlowItem *)item;
- (NSString *)deepDescription;

@end
