#import "HacHTMLDocument.h"

#import "HacStringAdditions.h"

@implementation HacHTMLDocument

+ (NSString *)htmlWithTitle:(NSString *)title
					   body:(NSString *)body
{
	NSString *html = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Template"
																						ofType:@"html"
																				   inDirectory:nil]];
	html = [html stringByReplacingOccurrencesOfString:@"[html.title]" withString:title];
	html = [html stringByReplacingOccurrencesOfString:@"[html.body]" withString:body];
	return html;
}

@end
