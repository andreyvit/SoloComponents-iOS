//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "ATPagingView.h"


@implementation ATPagingView

@synthesize delegate=_delegate;

@end


@implementation ATPagingViewController


#pragma mark -
#pragma mark init/dealloc

- (id)init {
	if (self = [super initWithNibName:nil bundle:nil]) {
	}
	return self;
}

- (void)dealloc {
	[super dealloc];
}


#pragma mark -
#pragma mark View Loading

- (void)loadView {
	self.view = [[[ATPagingView alloc] init] autorelease];
	self.pagingView.delegate = self;
}


#pragma mark -
#pragma mark View Access

- (ATPagingView *)pagingView {
	return (ATPagingView *)self.view;
}

@end
