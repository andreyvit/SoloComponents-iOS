//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import <Foundation/Foundation.h>

@protocol ATPagingViewDelegate;


@interface ATPagingView : UIView {
	id<ATPagingViewDelegate> _delegate;
}

@property(nonatomic, assign) id<ATPagingViewDelegate> delegate;

@end


@protocol ATPagingViewDelegate <NSObject>

@end


@interface ATPagingViewController : UIViewController <ATPagingViewDelegate> {
}

- (id)init;

@property(nonatomic, readonly) ATPagingView *pagingView;

@end
