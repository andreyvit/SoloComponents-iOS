//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "DemoViewController.h"
#import "DemoPageView.h"


@implementation DemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc {
    [super dealloc];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[self currentPageDidChangeInPagingView:self.pagingView];
}


#pragma mark -
#pragma mark ATPagingViewDelegate methods

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView {
	return 10;
}

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index {
	UIView *view = [pagingView dequeueReusablePage];
	if (view == nil) {
		view = [[[DemoPageView alloc] init] autorelease];
	}
	return view;
}

- (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView {
	self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", pagingView.currentPageIndex+1, pagingView.pageCount];
}


@end
