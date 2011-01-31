//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "DemoViewController.h"
#import "DemoItemView.h"


@implementation DemoViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}


#pragma mark -
#pragma mark ATArrayViewDelegate methods

- (NSInteger)numberOfItemsInArrayView:(ATArrayView *)arrayView {
	return 97;
}

- (UIView *)viewForItemInArrayView:(ATArrayView *)arrayView atIndex:(NSInteger)index {
	DemoItemView *itemView = (DemoItemView *) [arrayView dequeueReusableItem];
	if (itemView == nil) {
		itemView = [[[DemoItemView alloc] init] autorelease];
	}
	return itemView;
}

@end
