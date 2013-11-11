//
//  TC_CXMLExtensions.h
//  XmlTesting
//
//  Created by Stephen Tallent on 8/6/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "CXMLNode.h"

@interface CXMLNode (TC_CXMLExtensions)

//-(NSString*)TC_StringValue;
- (CXMLNode *)singleNodeForXPath:(NSString *)xpath error:(NSError **)error;
- (NSString *)attributeStringForName:(NSString *)name;
- (NSString *)attributeStringForIndex:(NSInteger)idx; 
@end
