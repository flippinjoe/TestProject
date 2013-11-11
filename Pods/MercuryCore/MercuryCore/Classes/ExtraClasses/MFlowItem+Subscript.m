//
//  MFlowItem+Subscript.m
//  MercuryCoreLib
//
//  Created by Joseph Ridenour on 9/25/13.
//
//

#import "MFlowItem+Subscript.h"

@implementation MFlowItem (Subscript)
- (id)objectForKeyedSubscript:(NSString *)subscript
{ return [self valueForKey:subscript]; }
@end
