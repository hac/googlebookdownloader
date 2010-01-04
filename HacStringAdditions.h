#import <Foundation/Foundation.h>

@interface NSString (HacStringAdditions)

- (NSString *)stringByReplacingOccurrencesOfString:(NSString *)target
										withString:(NSString *)replacement;

@end
