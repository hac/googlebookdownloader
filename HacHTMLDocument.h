#import <Foundation/Foundation.h>

@interface HacHTMLDocument : NSString
{
}

+ (NSString *)htmlWithTitle:(NSString *)title
					   body:(NSString *)body;

@end
