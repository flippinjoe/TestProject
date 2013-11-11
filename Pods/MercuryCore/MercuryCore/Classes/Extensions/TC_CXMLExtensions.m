//
//  TC_CXMLExtensions.m
//  XmlTesting
//
//  Created by Stephen Tallent on 8/6/08.
//  Copyright 2008 Mercury Intermedia. All rights reserved.
//

#import "TC_CXMLExtensions.h"


@implementation CXMLNode (TC_CXMLExtensions)

- (CXMLNode *)singleNodeForXPath:(NSString *)xpath error:(NSError **)error{
	NSArray *itemNodes;
	
	itemNodes = [self nodesForXPath:xpath error:error];
	
	if (itemNodes.count == 0){
		return nil;
	} else {
		return [itemNodes objectAtIndex:0];
	}
}


- (NSString *)attributeStringForName:(NSString *)name
{
xmlChar *theXMLString;
// TODO -- look for native libxml2 function for finding a named attribute (like xmlGetProp)
const xmlChar *theName = (const xmlChar *)[name UTF8String];

xmlAttrPtr theCurrentNode = _node->properties;
while (theCurrentNode != NULL)
	{
	if (xmlStrcmp(theName, theCurrentNode->name) == 0)
		{
		//CXMLNode *theAttribute = [CXMLNode nodeWithLibXMLNode:(xmlNodePtr)theCurrentNode];
		//return(theAttribute);
		theXMLString = xmlNodeListGetString(theCurrentNode->doc, theCurrentNode->children, YES);
		NSString *s = [NSString stringWithUTF8String:(const char *)theXMLString];
		xmlFree(theXMLString);
		return s;
		}
	theCurrentNode = theCurrentNode->next;
	}
return(NULL);
}


- (NSString *)attributeStringForIndex:(NSInteger)idx {
	xmlChar *theXMLString;
	xmlAttrPtr theCurrentNode;
	
	theCurrentNode = _node->properties;

	for (int i = 0; i < idx; i++) {
		theCurrentNode = theCurrentNode->next;
	}

	theXMLString = xmlNodeListGetString(theCurrentNode->doc, theCurrentNode->children, YES);
	NSString *s = [NSString stringWithUTF8String:(const char *)theXMLString];
	xmlFree(theXMLString);
	return s;
	
}


/*

theXMLString = xmlNodeListGetString(_node->doc, _node->children, YES);
	theFreeReminderFlag = YES;
	}

NSString *theStringValue = NULL;
if (theXMLString != NULL)
	{
	theStringValue = [NSString stringWithUTF8String:(const char *)theXMLString];
 
 */
@end
