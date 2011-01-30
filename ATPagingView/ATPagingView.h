//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import <Foundation/Foundation.h>

@protocol ATPagingViewDelegate;


@interface ATPagingView : UIView {
	// subviews
	UIScrollView *_scrollView;

	// properties
	id<ATPagingViewDelegate> _delegate;
	CGFloat _gapBetweenPages;
	NSInteger _pagesToPreload;

	// state
	NSInteger _pageCount;
	NSInteger _currentPageIndex;
	NSMutableSet *_recycledPages;
	NSMutableSet *_visiblePages;
	BOOL _rotationInProgress;
}

@property(nonatomic, assign) id<ATPagingViewDelegate> delegate;

@property(nonatomic, assign) CGFloat gapBetweenPages;

@property(nonatomic, assign) NSInteger pagesToPreload;

@property(nonatomic, readonly) NSInteger pageCount;

@property(nonatomic, assign, readonly) NSInteger currentPageIndex;

- (UIView *)viewForPageAtIndex:(NSUInteger)index;

- (UIView *)dequeueReusablePage;

- (void)willAnimateRotation;

- (void)didRotate;

@end


@protocol ATPagingViewDelegate <NSObject>

- (NSInteger)numberOfPagesInPagingView:(ATPagingView *)pagingView;

- (UIView *)viewForPageInPagingView:(ATPagingView *)pagingView atIndex:(NSInteger)index;

@end


@interface ATPagingViewController : UIViewController <ATPagingViewDelegate> {
}

@property(nonatomic, readonly) ATPagingView *pagingView;

@end
