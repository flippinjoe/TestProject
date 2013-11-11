//
//  TC_NSMutableDataExtensions.m
//  CNN
//
//  Created by Stephen Tallent on 8/5/09.
//  Copyright 2009 Mercury Intermedia. All rights reserved.
//

#import <CommonCrypto/CommonCryptor.h>

#import "TC_NSMutableDataExtensions.h"


@implementation NSMutableData (TC_NSMutableDataExtensions)

- (BOOL) encryptWithKey: (NSString *) key
	{
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char * keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero( keyPtr, sizeof(keyPtr) ); // fill with zeroes (for padding)

	// fetch key data
	[key getCString: (char *)keyPtr maxLength: sizeof(keyPtr) encoding: NSUTF8StringEncoding];

	// encrypts in-place, since this is a mutable data object
	size_t numBytesEncrypted = 0;
	CCCryptorStatus result = CCCrypt( kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES256,
	NULL /* initialization vector (optional) */, 
	[self mutableBytes], [self length], /* input */
	[self mutableBytes], [self length], /* output */
	&numBytesEncrypted );
	return ( result == kCCSuccess );
}

- (BOOL) decryptWithKey: (NSString *) key
	{
	// 'key' should be 32 bytes for AES256, will be null-padded otherwise
	char * keyPtr[kCCKeySizeAES256+1]; // room for terminator (unused)
	bzero( keyPtr, sizeof(keyPtr) ); // fill with zeroes (for padding)

	// fetch key data
	[key getCString: (char *)keyPtr maxLength: sizeof(keyPtr) encoding: NSUTF8StringEncoding];

	// encrypts in-place, since this is a mutable data object
	size_t numBytesEncrypted = 0;
	CCCryptorStatus result = CCCrypt( kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, keyPtr, kCCKeySizeAES256,
	NULL /* initialization vector (optional) */, 
	[self mutableBytes], [self length], /* input */
	[self mutableBytes], [self length], /* output */
	&numBytesEncrypted );

	return ( result == kCCSuccess );
}
@end
