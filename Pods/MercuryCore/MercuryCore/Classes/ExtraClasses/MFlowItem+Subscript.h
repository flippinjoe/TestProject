//
//  MFlowItem+Subscript.h
//  MercuryCoreLib
//
//  Created by Joseph Ridenour on 9/25/13.
//
//

#import "MFlowItem.h"

@interface MFlowItem (Subscript)
- (id)objectForKeyedSubscript:(NSString *)subscript;
@end
