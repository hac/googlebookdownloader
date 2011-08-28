#import "GoogleBooksAPI.h"

#import <RegexKit/RegexKit.h>

@implementation GoogleBooksAPI

#pragma mark -
#pragma mark HTML Scraping

+ (BOOL)overviewPageExistsForBookWithId:(NSString *)bookId
// Check whether the book exists.
{
	NSString *overviewPath = [NSString stringWithFormat:@"http://books.google.com/books?id=%@", bookId];
	NSString *overviewHTML = [NSString stringWithContentsOfURL:[NSURL URLWithString:overviewPath]];

	return ([overviewHTML length] > 0);
}

+ (NSString *)titleForBookWithId:(NSString *)bookId
// Scrape a book's preview page for its title.
{
	NSString *bookInfoPath = [NSString stringWithFormat:@"http://books.google.com/books?id=%@&printsec=frontcover", bookId];
	NSString *bookInfoHTML = [NSString stringWithContentsOfURL:[NSURL URLWithString:bookInfoPath]];

	// Scrape the page for the book title.
	NSString *openHeadingTag = @"<meta name=\"title\" content=\"";
	NSString *closeHeadingTag = @"\"/>";
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

@end
