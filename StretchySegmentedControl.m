#import "StretchySegmentedControl.h"

@implementation StretchySegmentedControl

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
	[super resizeWithOldSuperviewSize:oldBoundsSize];
	
	int i;
	for (i = 0; i < [self segmentCount]; i++)
	{
		[self setWidth:[self frame].size.width/[self segmentCount]
			forSegment:i];
	}
}

@end