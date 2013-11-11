//
//  MFlowContainerParser.m
//  ArchTest1
//
//  Created by Stephen Tallent on 1/15/10.
//  Copyright 2010 Mercury Intermedia. All rights reserved.
//

#import <objc/runtime.h>
#import "MFlowContainerParser.h"
#import "TC_NSDataExtensions.h"
#import "MFlowItem.h"


NSInteger relationSorter(id num1, id num2, void *context);

static NSDateFormatter *dateFormatter;

@interface MFlowContainerParser ()
@property(nonatomic, assign, readwrite) MFlowContainerResponseStatus responseStatus;
@property(strong, nonatomic, readwrite) NSNumber *expressedVersionNumber;
@property(strong, nonatomic, readwrite) NSNumber *ttlSeconds;
@property(strong, nonatomic, readwrite) NSArray *sortedRelationNodes;
@property(strong, nonatomic, readwrite) NSMutableArray *pubItemIDs;
@property(strong, nonatomic, readwrite) NSMutableDictionary *linkedAttNameIDs;
@property(strong, nonatomic, readwrite, getter=getNewItems) NSMutableDictionary *newItems;
@property(strong, nonatomic, readwrite) NSMutableString *removedItems;

@property (nonatomic, strong, readwrite) NSMutableArray *unsortedRelationNodes;
@property (nonatomic, strong, readwrite) NSData *unparsedData;
@property (nonatomic, assign, readwrite) BOOL compressed;

-(void)parseContainerObjects:(xmlTextReaderPtr)reader;
-(void)parseContainerItem:(xmlTextReaderPtr)reader;

-(void)parseItemObjects:(xmlTextReaderPtr)reader;
-(void)parseItems:(xmlTextReaderPtr)reader;


@end

@implementation MFlowContainerParser

-(id)initWithXMLData:(NSData *)d{
	
	self = [super init];
	
	self.pubItemIDs = [NSMutableArray arrayWithCapacity:0];
	self.unsortedRelationNodes = [NSMutableArray arrayWithCapacity:0];
	self.unparsedData = d;
	self.linkedAttNameIDs = [NSMutableDictionary dictionaryWithCapacity:0];
	self.newItems = [NSMutableDictionary dictionaryWithCapacity:0];
	self.removedItems = [NSMutableString stringWithCapacity:0];
	
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"EN"];
        [dateFormatter setDateFormat:@"MM/dd/yyyy hh:mm:ss a"];
    }
	
	return self;
}


-(void)parse {
	
	NSString *path = @"";
	xmlTextReaderPtr reader = xmlReaderForMemory([self.unparsedData bytes],[self.unparsedData length],
                                [path UTF8String], nil, 
								(XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
	
	if (!reader) {
		NSLog(@"Failed to load xmlreader");
		return;
	}
	
	char *elementName;
	char *attValue;
	char *errorAttValue;
	
	while (true) {
		
		if (!xmlTextReaderRead(reader)) break;
		
	
		switch (xmlTextReaderNodeType(reader)) {
			
			case XML_READER_TYPE_ELEMENT:
				
				elementName = (char*)xmlTextReaderConstName(reader);
				
				if (strcmp(elementName,"root") == 0) {
					
					
					// Get the response status
					attValue = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"status");
					errorAttValue = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"error");
					
					if (errorAttValue != nil) {
						self.responseStatus = MFlowContainerResponseError;
					} else if (attValue == nil) {
						self.responseStatus = MFlowContainerResponseFull;
					} else if (strcmp(attValue, "unchanged") == 0) {
						self.responseStatus = MFlowContainerResponseUnchanged;
					} else if (strcmp(attValue, "delta") == 0) {
						self.responseStatus = MFlowContainerResponseDelta;
					} else {
						self.responseStatus = MFlowContainerResponseFull;
					}
					
					xmlFree(attValue);
					
					// Get the compression mode
					attValue = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"CompressionMode");
									
					if (attValue != nil && strcmp(attValue,"gzip") == 0) self.compressed = YES;
					
					xmlFree(attValue);

					
					// removed items
					attValue = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"RemovedItems");
					if (attValue != nil) {
						[self.removedItems appendString:[NSString stringWithCString:attValue encoding:NSUTF8StringEncoding]];
						xmlFree(attValue);
					}

				} else if (strcmp(elementName,"Containers") == 0) {
					
					[self parseContainerObjects:reader];
					
					
				} else if (strcmp(elementName,"Items") == 0) {
					
					[self parseItemObjects:reader];
					
					continue;
				}
				
				//xmlFree(elementName);
				
				continue;
				
			case XML_READER_TYPE_TEXT:
				//The current tag has a text value, stick it into the current person
				//temp = (char*)xmlTextReaderConstValue(reader);
				//currentTagValue = [NSString stringWithCString:temp encoding:NSUTF8StringEncoding];
				
				continue;
				
			default: continue;
		}
	}
	
	xmlFreeTextReader(reader);
	
}

-(void)parseContainerObjects:(xmlTextReaderPtr)reader{
	char *tagValue;
	char *elementName;
	NSString *currentTagValue;
	NSData *gutsData;
	NSData *gutsInflated;
	NSString *path = @"";
	xmlTextReaderPtr subreader;
	
	
	// This method basically gets down to the <root><Containers><Item> node, whether compressed or not.
	// Once there, it passes off a pointer to a reader to the specific parsing method.  If its compressed,
	// its a pointer to a new reader, if its not compressed, its the pointer to the main reader
	
	// if we aren't compressed, we can pass the reader along.  If we are, the block below will extract the data
	// and then pass it along
	
	if (!self.compressed) {
		// the next node read will be the <root><Containers><Item> node, so lets pass off the reader ptr
		[self parseContainerItem:reader];

	}
	
	while (true) {
		
		if (!xmlTextReaderRead(reader)) break;
		
		switch (xmlTextReaderNodeType(reader)) {
			
			case XML_READER_TYPE_ELEMENT:
				
				continue;

			case XML_READER_TYPE_TEXT:
				//The current tag has a text value, stick it into the current person
				tagValue = (char*)xmlTextReaderConstValue(reader);
				if (tagValue != nil) {
					
					currentTagValue = [NSString stringWithCString:tagValue encoding:NSUTF8StringEncoding];
					gutsData = [NSData dataWithBase64EncodedString:currentTagValue];
					gutsInflated = [gutsData gzipInflate];
					
					subreader = xmlReaderForMemory([gutsInflated bytes],[gutsInflated length], 
                                [path UTF8String], nil, 
								(XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
					
					[self parseContainerItem:subreader];
					
					xmlFreeTextReader(subreader);
					
				}
			
			case XML_READER_TYPE_END_ELEMENT:
				elementName = (char*)xmlTextReaderConstName(reader);
				if (strcmp(elementName, "Containers") == 0) {
					return;
				} 

			default: continue;
		}
	
	}
	
}
-(void)parseContainerItem:(xmlTextReaderPtr)reader{
	char *elementName;
	char *elementValue;
	char *attValue;
	
	char *subElementValue;

	NSDictionary *tmpDict;
	
	while (true) {
		
		if (!xmlTextReaderRead(reader)) break;
		
		switch (xmlTextReaderNodeType(reader)) {
			
			case XML_READER_TYPE_ELEMENT:
				elementName = (char*)xmlTextReaderConstName(reader);
				if (strcmp(elementName, "Att") == 0) {
					
					attValue = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"Name");
					
					if (strcmp(attValue, "ExpressedVersionNumber") == 0) {
						
						elementValue = (char*)xmlTextReaderReadString(reader);
						self.expressedVersionNumber = [NSNumber numberWithInt:atoi(elementValue)];
						xmlFree(elementValue);
						
					} else if (strcmp(attValue, "TtlSeconds") == 0) {
						
						elementValue = (char*)xmlTextReaderReadString(reader);
						self.ttlSeconds = [NSNumber numberWithInt:atoi(elementValue)];
						xmlFree(elementValue);
						
					} else if (strcmp(attValue, "ManifestXml") == 0) {
						
						elementValue = (char*)xmlTextReaderReadString(reader);
						//-------------
						xmlTextReaderPtr manifestReader = xmlReaderForMemory(elementValue,strlen(elementValue), nil, nil, 
																			 (XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));
						
						while (true) {
							if (!xmlTextReaderRead(manifestReader)) break;
							
							switch (xmlTextReaderNodeType(manifestReader)) {
			
								case XML_READER_TYPE_ELEMENT:
									subElementValue = (char*)xmlTextReaderConstName(manifestReader);
									if (strcmp(subElementValue, "Relation") == 0) {
										
										char *iid = (char*)xmlTextReaderGetAttribute(manifestReader, (const xmlChar * )"IID");
										char *cid = (char*)xmlTextReaderGetAttribute(manifestReader, (const xmlChar * )"CID");
										char *aid = (char*)xmlTextReaderGetAttribute(manifestReader, (const xmlChar * )"AID");
										char *seq = (char*)xmlTextReaderGetAttribute(manifestReader, (const xmlChar * )"Seq");
																	  
										tmpDict = [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSString stringWithCString:iid encoding:NSUTF8StringEncoding], @"IID",
												   [NSString stringWithCString:cid encoding:NSUTF8StringEncoding], @"CID",
												   [NSString stringWithCString:aid encoding:NSUTF8StringEncoding], @"AID",
												   [NSString stringWithCString:seq encoding:NSUTF8StringEncoding], @"Seq",nil];
										[self.unsortedRelationNodes addObject:tmpDict];
										
										xmlFree(iid);
										xmlFree(cid);
										xmlFree(aid);
										xmlFree(seq);
									}
									
									continue;
								default: continue;
							}
						}
						
						self.sortedRelationNodes = [self.unsortedRelationNodes sortedArrayUsingFunction:relationSorter context:NULL];
						
						xmlFree(elementValue);
						xmlFreeTextReader(manifestReader);
						
						//------------
						
					}
					
					xmlFree(attValue);
					
				} else if (strcmp(elementName, "PublishedItem") == 0) {
					
					attValue = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"IID");
					
					[self.pubItemIDs addObject:[NSString stringWithCString:attValue encoding:NSUTF8StringEncoding]];
					
					xmlFree(attValue);
				}
				
				continue;
				
			case XML_READER_TYPE_TEXT:
				
				continue;
			
			case XML_READER_TYPE_END_ELEMENT:
				elementName = (char*)xmlTextReaderConstName(reader);
				if (strcmp(elementName, "Item") == 0) {
					return;
				}
				
			default: continue;
		}
	
	}
		
}

//-----------------------------
NSInteger relationSorter(id num1, id num2, void *context)
{
    NSDictionary *v1 = num1;
    NSDictionary *v2 = num2;
	NSString *tmp1;
	NSString *tmp2;
	
	tmp1 = [v1 objectForKey:@"IID"];
	tmp2 = [v2 objectForKey:@"IID"];
	
	if ( tmp1.intValue < tmp2.intValue ){
		return NSOrderedAscending;
	} else if (tmp1.intValue > tmp2.intValue){
		return NSOrderedDescending;
	} else {
		
		tmp1 = [v1 objectForKey:@"AID"];
		tmp2 = [v2 objectForKey:@"AID"];
		
		if ( tmp1.intValue < tmp2.intValue ){
			return NSOrderedAscending;
		} else if (tmp1.intValue > tmp2.intValue){
			return NSOrderedDescending;
		} else {
			
			tmp1 = [v1 objectForKey:@"Seq"];
			tmp2 = [v2 objectForKey:@"Seq"];
			
			if ( tmp1.intValue < tmp2.intValue ){
				return NSOrderedAscending;
			} else if (tmp1.intValue > tmp2.intValue){
				return NSOrderedDescending;
			} else {
				return NSOrderedSame;
			}
			
		}
		
	}
	
}
//-----------------------------
-(void)parseItemObjects:(xmlTextReaderPtr)reader{
	char *tagValue;
	char *elementName;
	NSString *currentTagValue;
	NSData *gutsData;
	NSData *gutsInflated;
	NSString *path = @"";
	xmlTextReaderPtr subreader;
	
	
	// This method basically gets down to the <root><Containers><Item> node, whether compressed or not.
	// Once there, it passes off a pointer to a reader to the specific parsing method.  If its compressed,
	// its a pointer to a new reader, if its not compressed, its the pointer to the main reader
	
	// if we aren't compressed, we can pass the reader along.  If we are, the block below will extract the data
	// and then pass it along
	
	if (!self.compressed) {
		// the next node read will be the <root><Containers><Item> node, so lets pass off the reader ptr
		[self parseItems:reader];
		return;
	}
	
	while (true) {
		
		if (!xmlTextReaderRead(reader)) break;
		
		switch (xmlTextReaderNodeType(reader)) {
			
			case XML_READER_TYPE_ELEMENT:
				
				continue;

			case XML_READER_TYPE_TEXT:
				//The current tag has a text value, stick it into the current person
				tagValue = (char*)xmlTextReaderConstValue(reader);
				if (tagValue != nil) {
					
					currentTagValue = [NSString stringWithCString:tagValue encoding:NSUTF8StringEncoding];
					gutsData = [NSData dataWithBase64EncodedString:currentTagValue];
					gutsInflated = [gutsData gzipInflate];
					
					//
					NSMutableData *resultData = [NSMutableData dataWithCapacity:0];
					NSString *wrapperStart = @"<root><Items>";
					NSString *wrapperEnd = @"</Items></root>";
					[resultData appendData:[wrapperStart dataUsingEncoding:NSASCIIStringEncoding]];
					[resultData appendData:gutsInflated];
					[resultData appendData:[wrapperEnd dataUsingEncoding:NSASCIIStringEncoding]];
					
					subreader = xmlReaderForMemory([resultData bytes],[resultData length], 
                                [path UTF8String], nil, 
								(XML_PARSE_NOBLANKS | XML_PARSE_NOCDATA | XML_PARSE_NOERROR | XML_PARSE_NOWARNING));

					[self parseItems:subreader];
					
					xmlFreeTextReader(subreader);
					
				}
				continue;
			
			case XML_READER_TYPE_END_ELEMENT:
				elementName = (char*)xmlTextReaderConstName(reader);
				if (strcmp(elementName, "Items") == 0) {
					return;
				} 
				continue;

			default: continue;
		}
	
	}

}

-(void)parseItems:(xmlTextReaderPtr)reader{
	
	char *elementName;
	MFlowItem *currentItem = nil;
	NSString *currentAttName;
	NSString *currentAttValue;
	//int currentAttID = 0;
	int currentAttTID = 0;
	int currentAttCard = 0;
	bool stopParsing = false;
	bool myBool = false;
    NSDate* dateValue;
	
	while (true) {
		
		if (stopParsing) break;
		
		if (!xmlTextReaderRead(reader)) break;
		
		
		switch (xmlTextReaderNodeType(reader)) {
				
			case XML_READER_TYPE_ELEMENT:
				elementName = (char*)xmlTextReaderConstName(reader);
				
				if (strcmp(elementName, "Item") == 0) {
					
					currentItem = [[MFlowItem alloc] init];
					
					char *iid = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"IID");
					[currentItem setObject: [NSNumber numberWithInteger:atoi(iid) ]
									forKey: @"ItemID"];
					xmlFree(iid);
					
					char *tid = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"TID");
					[currentItem setObject: [NSNumber numberWithInteger:atoi(tid) ]
									forKey: @"TypeID"];
					xmlFree(tid);
					
									
				} else if (strcmp(elementName, "Att") == 0){
					
					
					char *attName = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"Name");
					char *aid = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"AID");
					char *atid = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"ATID");
					
					currentAttName = [NSString stringWithCString:attName encoding:NSUTF8StringEncoding];
					currentAttValue = nil;
					//currentAttID = atoi(aid);
					currentAttTID = atoi(atid);
					
					if (currentAttTID == 10) {
						char *card = (char*)xmlTextReaderGetAttribute(reader, (const xmlChar * )"Card");
						currentAttCard = atoi(card);
						xmlFree(card);
						
						[self.linkedAttNameIDs setObject:currentAttName
											 forKey:[NSString stringWithCString:aid encoding:NSUTF8StringEncoding]];
						
						if (currentAttCard == 1){
							[currentItem setObject:[NSDictionary dictionary] forKey:currentAttName];
						} else {
							[currentItem setObject:[NSMutableArray arrayWithCapacity:10] forKey:currentAttName];
						}
						
					} else {
						
						// clang says this isn't needed.  too bad.  i liked it.
						//currentAttCard = 0;
					
					}
					
					xmlFree(attName);
					xmlFree(aid);
					xmlFree(atid);

				}
				
				
				continue;
			
			case XML_READER_TYPE_TEXT:
				//NSLog(@"XML_READER_TYPE_TEXT");

				currentAttValue = [NSString stringWithCString:(char*)xmlTextReaderConstValue(reader) 
													 encoding:NSUTF8StringEncoding];
				continue;
				
			case XML_READER_TYPE_END_ELEMENT:
				// this is temp code
				elementName = (char*)xmlTextReaderConstName(reader);
				//NSLog(@"XML_READER_TYPE_END_ELEMENT");
				if (strcmp(elementName, "Att") == 0) {
					NSString *tmp;
					int tmpN;
					switch (currentAttTID) {
						case 1: //short text
						case 2: //long text
							tmp = (currentAttValue == nil) ? @"": currentAttValue;
							[currentItem setObject:tmp
											forKey:currentAttName];
							break;
							
						case 3: //number
							tmpN = (currentAttValue == nil) ? 0 : [currentAttValue intValue];
							[currentItem setObject:[NSNumber numberWithInteger:tmpN] forKey:currentAttName];
							
							break;
							
						case 4: //money
						case 9: //decimal
							tmp = (currentAttValue == nil) ? @"": currentAttValue;

							[currentItem setObject:[NSDecimalNumber decimalNumberWithString:tmp] 
											forKey:currentAttName];
							break;
							
						case 5: //date
							
							if ( currentAttValue == nil ){
								[currentItem setObject:@"" forKey:currentAttName];
							} else {
                                @synchronized(self) {
                                    dateValue = [dateFormatter dateFromString:currentAttValue];
                                }
                                if (dateValue != nil) {
                                    [currentItem setObject:dateValue forKey:currentAttName];
                                } else {
                                    [currentItem setObject:@"" forKey:currentAttName];
                                }
							}
							break;
							
						case 6: // bool
							if( currentAttValue != nil && [currentAttValue compare:@"True"] == NSOrderedSame ){
								myBool = true;
							} else {
								myBool = false;
							}
							[currentItem setObject:[NSNumber numberWithBool:myBool] forKey:currentAttName];
							break;
							
						//case 10: //linked
						//	if (currentAttCard == 1){
						//		[currentItem setObject:[NSDictionary dictionary] forKey:currentAttName];
						//	} else {
						//		[currentItem setObject:[NSMutableArray arrayWithCapacity:10] forKey:currentAttName];
						//	}
						//	break;
							
						default:
							break;
					}

					
					
					
				} else if (strcmp(elementName, "Item") == 0) {
					if(currentItem)
                    {
                        [self.newItems setObject: currentItem forKey: [currentItem.ItemID stringValue] ];
                    }
					
					//[currentItem release];
					//stopParsing = true;
					
				}
				continue;
				
			default: continue;
		}
		
	}
}


@end
