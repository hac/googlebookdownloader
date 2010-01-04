#import "GoogleBooksAPI.h"

#import <RegexKit/RegexKit.h>

@implementation GoogleBooksAPI

#pragma mark -
#pragma mark HTML Scraping

+ (NSString *)titleForBookWithId:(NSString *)bookId
// Scrape a book's preview page for its title.
{
	NSString *bookInfoPath = [NSString stringWithFormat:@"http://books.google.com/books?id=%@&printsec=frontcover", bookId];
	NSString *bookInfoHTML = [NSString stringWithContentsOfURL:[NSURL URLWithString:bookInfoPath]];
	
	// Scrape the page for the book title.
	NSString *openHeadingTag = @"<h1 class=title dir=ltr>";
	NSString *closeHeadingTag = @"</h1>";
	NSRange headingRange = [bookInfoHTML rangeOfString:openHeadingTag];
	if (headingRange.location != NSNotFound)
	{
		bookInfoHTML = [bookInfoHTML substringWithRange:NSMakeRange(headingRange.location+[openHeadingTag length], 1000)];
		headingRange = [bookInfoHTML rangeOfString:closeHeadingTag];
		if (headingRange.location != NSNotFound)
		{
			bookInfoHTML = [bookInfoHTML substringToIndex:headingRange.location];
			
			// Strip any HTML tags that sneaked into the heading:
			RKRegex *htmlTagPattern = [RKRegex regexWithRegexString:@"<(.|\n)*?>" options:RKCompileCaseless];
			bookInfoHTML = [bookInfoHTML stringByMatching:htmlTagPattern replace:RKReplaceAll withReferenceString:@""];
			
			return bookInfoHTML;
		}
	}
	
	// This method will fail in the future when/if the HTML of Google Books changes.
	return nil;
}

#pragma mark -
#pragma mark JSON Fetching

+ (NSString *)initialJsonIndexForBookWithId:(NSString *)bookId
// Ask for page 0 to get a list of all page numbers and the URLs of the first few pages.
{
	NSString *imageIndexPath = [NSString stringWithFormat:@"http://books.google.com/books?id=%@&pg=0&jscmd=click3", bookId];
	NSString *imageIndexString = [NSString stringWithContentsOfURL:[NSURL URLWithString:imageIndexPath]];
	return imageIndexString;
}

+ (NSString *)jsonIndexByAskingForPage:(NSString *)pageNumber
						 ForBookWithId:(NSString *)bookId
// Ask for a specific page. Typically we will get the URL for the page number we asked for, the URL for previous page number, and the URLs for the next three.
// This is because if you are previewing a page, the next three pages and the previous one will be cached, as you are more likely to scroll down than up.
// We also get a list of page numbers which we don't need.
{
	NSString *imageIndexPath = [NSString stringWithFormat:@"http://books.google.com/books?id=%@&pg=%@&jscmd=click3", bookId, pageNumber];
	NSString *imageIndexString = [NSString stringWithContentsOfURL:[NSURL URLWithString:imageIndexPath]];
	return imageIndexString;
}

@end
