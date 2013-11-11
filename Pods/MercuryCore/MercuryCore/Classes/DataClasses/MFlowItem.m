//
//  MFlowItem.m
//  MercuryCoreDev
//
//  Created by Stephen Tallent on 5/14/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import "MFlowItem.h"


@implementation MFlowItem

- (id)init {
	return [self initWithCapacity:0];
}

- (id)initWithCapacity:(NSUInteger)capacity {
	self = [super init];
	if (self != nil)
	{
		dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
	}
	return self;
}

-(id)initWithDictionary:(NSDictionary *)d{
	self = [super init];
	if (self != nil) {
		dictionary = [[NSMutableDictionary alloc] initWithDictionary:d copyItems:true];
	}
	return self;
}
//---- These two methods allow the MFlowItem to handle messages that aren't defined on it.
// this is most likely to happen when someone tries to use an instance of a subclass, like NewsStory
// on an instance that is really of MFlowItem.  This is usually when an item gets written out to disk
// in a cache as an MFlowItem, but later on they assume its a newstory.

// TODO: Remove method because we don't normally subclass and archive mflow items. This is old cruft.

- (void)forwardInvocation:(NSInvocation *)anInvocation{
	
    __unsafe_unretained NSString *s = NSStringFromSelector([anInvocation selector]);
    
    // JR 9/27/13
    // This isn't needed since we moved to arc.  Causes crash when attempting to use
//    [anInvocation retainArguments];
    
	[anInvocation setTarget:dictionary];
	[anInvocation setSelector:@selector(objectForKey:)];
	[anInvocation setArgument:&s atIndex:2];
	[anInvocation invoke];
	
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
		
	return [dictionary methodSignatureForSelector:@selector(objectForKey:)];
	
}
//----

-(id)copyWithZone:(NSZone *)z{
	return [[MFlowItem alloc] initWithDictionary:dictionary]; 
}

- (id)valueForKeyPath:(NSString *)keyPath {
	return [dictionary valueForKeyPath:keyPath];
}

- (void)setObject:(id)anObject forKey:(id)aKey {
	[dictionary setObject:anObject forKey:aKey];
}

- (void)setValue:(id)anObject forKey:(id)aKey {
	[dictionary setValue:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey {
	[dictionary removeObjectForKey:aKey];
}

- (NSUInteger)count {
	return [dictionary count];
}

- (id)objectForKey:(id)aKey {
	return [dictionary objectForKey:aKey];
}

- (id)valueForKey:(id)aKey {
	return [dictionary valueForKey:aKey];
}

- (id)objectForKeyIfValid:(id)aKey
{
	return [self hasObjectForKey: aKey] ? [self objectForKey: aKey] : nil;
}

- (id)valueForKeyIfValid:(id)aKey
{
	return [self hasValueForKey: aKey] ? [self valueForKey: aKey] : nil;
}

- (id)objectForKeyIfExists:(id)aKey
{
	return [self hasValueForKey: aKey] ? [self valueForKey: aKey] : nil;
}

- (BOOL)hasObjectForKey:(id)aKey
{
	BOOL	hasObject = NO;
	id		testObject = [dictionary objectForKey: aKey];
	
	if (testObject != nil) {
		if (![testObject isKindOfClass: [NSDictionary class]] || [[testObject allKeys] count])
			hasObject = YES;
	}
	
	return hasObject;
}

- (BOOL)hasValueForKey:(id)aKey
{
	return [self hasObjectForKey: aKey];
}

- (NSEnumerator *)keyEnumerator
{
	return [dictionary objectEnumerator];
}

- (NSArray *)allKeys{
	return [dictionary allKeys];
}

- (id)initWithCoder:(NSCoder *)decoder{
	dictionary = [decoder decodeObjectForKey:@"items"];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder{
	[encoder encodeObject:dictionary forKey:@"items"];
}
//-----------------------

-(NSNumber*) ItemID{
	return [dictionary objectForKey:@"ItemID"];
}

-(NSNumber*) TypeID{
	return [dictionary objectForKey:@"TypeID"];
}

-(NSString *)ItemName{
	return [dictionary objectForKey:@"ItemName"];
}

-(NSString *)description{
	
	return [NSString stringWithFormat:@"ItemID: %@ ItemName: %@",[self ItemID],[self ItemName]];
}

-(NSString *)deepDescription{
	
	return [NSString stringWithFormat:@"ItemID: %@\n%@",[self ItemID], dictionary];
}

-(NSNumber*) ExpressedVersionNumber{
	return [dictionary objectForKey:@"ExpressedVersionNumber"];
}

- (NSComparisonResult)compare:(MFlowItem *)item{
	
	NSComparisonResult idComp = [self.ItemID compare:item.ItemID];
	
	if (idComp == NSOrderedSame) {
		
		return [self.ExpressedVersionNumber compare:item.ExpressedVersionNumber];
		
	} else {
		
		return idComp;

	}

}
//-----------------------

@end
