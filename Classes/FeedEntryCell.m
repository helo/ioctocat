#import "FeedEntryCell.h"
#import "GHFeedEntry.h"
#import "GHUser.h"
#import "GravatarLoader.h"
#import "NSDate+Nibware.h"

@implementation FeedEntryCell

@synthesize entry;

- (void)setEntry:(GHFeedEntry *)anEntry {
	[entry release];
	entry = [anEntry retain];
	titleLabel.text = entry.title;
	[entry.user addObserver:self forKeyPath:kUserGravatarKeyPath options:NSKeyValueObservingOptionNew context:nil];
	// Date
    dateLabel.text = [entry.date prettyDate];
	// Icon
	NSString *icon = [NSString stringWithFormat:@"%@.png", entry.eventType];
	iconView.image = [UIImage imageNamed:icon];
	// Gravatar
	gravatarView.image = entry.user.gravatar;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:object change:change context:context {
	if ([keyPath isEqualToString:kUserGravatarKeyPath]) {
		gravatarView.image = entry.user.gravatar;
	}
}

- (void)dealloc {
	[entry.user removeObserver:self forKeyPath:kUserGravatarKeyPath];
	[entry release];
	[dateLabel release];
	[titleLabel release];
	[gravatarView release];
	[iconView release];
    [super dealloc];
}

@end
