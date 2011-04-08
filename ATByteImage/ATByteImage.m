//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import "ATByteImage.h"


@implementation ATByteImage

@synthesize width;
@synthesize height;
@synthesize byteCount;
@synthesize bytesPerPixel;
@synthesize bytesPerRow;
@synthesize bitsPerComponent;
@synthesize bytes;
@synthesize colorSpace;

-(id)initWithSize:(CGSize)size {
    if (self = [super init]) {
        width = size.width;
        height = size.height;
        byteCount = height * width * 4;
        bytesPerPixel = 4;
        bytesPerRow = bytesPerPixel * width;
        bitsPerComponent = 8;
        bytes = malloc(byteCount);
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    return self;
}

-(id)initWithCGImage:(CGImageRef)image {
    if (self = [self initWithSize:CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))]) {
        ATByteImageContext *context = [self newContext];
        CGContextDrawImage(context.CGContext, CGRectMake(0, 0, width, height), image);
        [context release];
    }
    return self;
}

-(id)initWithImage:(UIImage *)image {
    if (self = [self initWithCGImage:image.CGImage]) {
    }
    return self;
}

-(void)dealloc {
    CGColorSpaceRelease(colorSpace);
    if (bytes)
        free(bytes), bytes = NULL;
    [super dealloc];
}

- (CGSize)size {
    return CGSizeMake(width, height);
}

- (CGImageRef)newCGImageUsingCopy:(BOOL)copy freeWhenDone:(BOOL)freeWhenDone {
    unsigned char *bytesToUse = bytes;
    if (copy) {
        bytesToUse = malloc(byteCount);
        memcpy(bytesToUse, bytes, byteCount);
    }
    NSData *dataRef = [NSData dataWithBytesNoCopy:bytesToUse length:byteCount freeWhenDone:freeWhenDone];
    CGDataProviderRef dstDataProvider = CGDataProviderCreateWithCFData((CFDataRef) dataRef);
    CGImageRef result = CGImageCreate(width, height, bitsPerComponent,
                                      bytesPerPixel*bitsPerComponent, bytesPerRow,
                                      colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big,
                                      dstDataProvider, NULL, NO, kCGRenderingIntentDefault) ;
    CGDataProviderRelease(dstDataProvider);
    return result;
}

- (UIImage *)image {
    CGImageRef imageRef = [self newCGImageUsingCopy:YES freeWhenDone:NO];
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return result;
}

- (UIImage *)imageNoCopyData {
    CGImageRef imageRef = [self newCGImageUsingCopy:NO freeWhenDone:YES];
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return result;
}

- (UIImage *)extractImage {
    CGImageRef imageRef = [self newCGImageUsingCopy:NO freeWhenDone:YES];
    UIImage *result = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    bytes = NULL;
    return result;
}

- (ATByteImageContext *)newContext {
    return [[ATByteImageContext alloc] initWithByteImage:self];
}

- (ATByteImageContext *)context {
    return [[self newContext] autorelease];
}

-(void)clear {
    memset(bytes, 0, byteCount);
}

-(void)invert {
    for (int i = 0; i < byteCount; ++i) {
        if (i % 4 == 3) continue; // skip alpha channel
        bytes[i] = 255 - bytes[i];
    }
}

-(void)replaceColorWithRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue {
    for (int i = 0; i < byteCount; i += 4) {
        CGFloat alpha = bytes[i+3] / 255.0;
        bytes[i]   = (int) (red   * alpha + 0.5);
        bytes[i+1] = (int) (green * alpha + 0.5);
        bytes[i+2] = (int) (blue  * alpha + 0.5);
    }
}

- (ATByteImage *)copy {
    ATByteImage *result = [[ATByteImage alloc] initWithSize:CGSizeMake(width, height)];
    memcpy(result->bytes, bytes, byteCount);
    return result;
}

@end


@implementation ATByteImageContext

@synthesize CGContext=context;

-(id)initWithByteImage:(ATByteImage *)anImage {
    if (self = [super init]) {
        image = [anImage retain];
        context = CGBitmapContextCreate(image.bytes, image.width, image.height,
                                        image.bitsPerComponent, image.bytesPerRow, image.colorSpace,
                                        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    }
    return self;
}

-(void)dealloc {
    CGContextRelease(context);
    [image release], image = nil;
    [super dealloc];
}

@end
