#import "HacStringAdditions.h"

@implementation NSString (HacStringAdditions)

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target
										withString:(NSString *)replacement
// This functionality already exists in NSString on 10.5, but since we're building for 10.4, we have to implement it ourselves.
{
	NSMutableString *mutableString = [NSMutableString stringWithString:self];
	[mutableString replaceOccurrencesOfString:target withString:replacement options:NSLiteralSearch range:NSMakeRange(0, [self length])];
	return [NSString stringWithString:mutableString];
}

@end
