Self-Contained Components for iOS
=================================

Two-file (.h / .m) useful components and utility classes that are dead-easy to drop into your iOS projects.

License: MIT (free for any use, no attribution required).

Follow us on twitter: [@SoloComponents](http://twitter.com/SoloComponents/).

Note: I want to collect as many open-source components as possible,
not just publish my own ones. If you have a useful iOS class that does
not depend on anything, feel free to fork, add and send me a pull
request!


ATPagingView
------------

ATPagingView is a wrapper around UIScrollView in (horizontal) paging
mode, with an API similar to UITableView.

Status: beta. Based on code that was in use by App Store apps.

You provide the page views by implementing two delegate methods:

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

You are also notified when the user navigates between pages:

    - (void)currentPageDidChangeInPagingView:(ATPagingView *)pagingView {
    	self.navigationItem.title = [NSString stringWithFormat:@"%d of %d", pagingView.currentPageIndex+1, pagingView.pageCount];
    }

You can use ATPagingView directly or derive your view controller from
ATPagingViewController.

ATPagingViewController is similar to UITableViewController and:

* defines `loadView` to create ATPagingView automatically,
* sets itself as a delegate of ATPagingView,
* calls `reloadData` in `viewWillAppear:` if the paging view is empty,
* additionally it forwards orientation events to the paging view (see below).

If you want to use ATPagingView without ATPagingViewController, you
need to:

* provide your delegate object using the `delegate` property,
* call `reloadData` to populate the view,
* if you want to support rotation, you need to invoke
  `willAnimateRotation` and `didRotate` methods from your view
  controller:

      - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
      	[self.pagingView willAnimateRotation];
      }

      - (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
      	[self.pagingView didRotate];
      }


ATArrayView
-----------

A container that arranges its items in rows and columns similar to the
thumbnails screen in Photos.app, the API is modeled after UITableView.

Status: beta.

Enjoy the familiar delegate methods:

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

There's ATArrayViewController which further reduces the amount of
boilerplate code you have to write. Similar to UITableViewController,
it:

* overrides `loadView` to create ATArrayView automatically,
* sets itself as a delegate of the array view,
* calls `reloadData` in `viewWillAppear:` if the array view is empty.


ATByteImage
-----------

Allows to easily use an image (CGImageRef) backed by a malloc'ed chunk
of memory. This means you can read or manipulate image bytes directly.

Status: ready for production use.

Using ATByteImage:

    ATByteImage *blurred = [[ATByteImage alloc] initWithSize:blurredSize];
    [blurred clear];

    ATByteImageContext *blurredContext = [blurred newContext];
    CGContextSetBlendMode(blurredContext.CGContext, kCGBlendModeNormal);
    ... draw using blurredContext.CGContext ...
    [blurredContext release];

  	UIImage *myOverlay = [blurred extractImage];

Here's another example. The following function is useful in background
image loading code:

    // Returns an uncompressed (decoded) UIImage, optimized for drawing speed.
    //
    // This is a middle ground between [UIImage imageNamed:] and a plain
    // [UIImage imageWithContentsOfFile:], as follows:
    //
    // * [UIImage imageWithContentsOfFile:] loads image data from disk and
    //   decodes it each time you display the image.
    //
    //   If you are using CATiledLayer to display a large image (and you should,
    //   since UIImageView is not recommended for images bigger than ~1024x1024),
    //   the whole JPEG will decoded for EACH tile you display.
    //
    // * [UIImage imageNamed:@"xxx"] only ever decodes the image once, just as you
    //   wanted. However it also caches the image and seems to sometimes (always?)
    //   not release the data even after you release your UIImage.
    //
    //   An app that loads several large images via 'imageNamed' will thus crash
    //   quite soon with unfamous "error 0".
    //
    //   Another undesired quality of 'imageNamed' is that the image is loaded and
    //   decoded when it is displayed for the first time, which means you can't
    //   really do the decoding in a background thread.
    //
    // * DecompressUIImage([UIImage imageWithContentsOfFile:@"xx.jpg"]) is the
    //   sweet spot between the two — it returns a fully decoded image which can
    //   be displayed quickly, and memory management is entirely up to you.
    //
    UIImage *DecompressUIImage(UIImage *image) {
    	ATByteImage *byteImage = [[[ATByteImage alloc] initWithImage:image] autorelease];
    	return [byteImage extractImage];
    }

