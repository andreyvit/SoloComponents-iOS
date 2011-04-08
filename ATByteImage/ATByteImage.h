//
//  Copyright 2011 Andrey Tarantsov. Distributed under the MIT license.
//

#import <Foundation/Foundation.h>

@class ATByteImageContext;

@interface ATByteImage : NSObject {
    NSUInteger width;
    NSUInteger height;
    NSUInteger byteCount;
    NSUInteger bytesPerPixel;
    NSUInteger bytesPerRow;
    NSUInteger bitsPerComponent;
    unsigned char *bytes;
    CGColorSpaceRef colorSpace;
}

-(id)initWithSize:(CGSize)size;
-(id)initWithCGImage:(CGImageRef)image;
-(id)initWithImage:(UIImage *)image;

- (ATByteImage *)copy;

- (UIImage *)image;              // image with a copy of bytes
- (UIImage *)imageNoCopyData;    // image with the current bytes — be sure not to modify the bytes!
- (UIImage *)extractImage;       // passes ownership of the bytes to the returned image, sets bytes to NULL

- (ATByteImageContext *)newContext;

- (ATByteImageContext *)context;

@property(nonatomic, readonly, assign) NSUInteger width;
@property(nonatomic, readonly, assign) NSUInteger height;
@property(nonatomic, readonly, assign) CGSize size;

@property(nonatomic, readonly, assign) NSUInteger byteCount;
@property(nonatomic, readonly, assign) NSUInteger bytesPerPixel;
@property(nonatomic, readonly, assign) NSUInteger bytesPerRow;
@property(nonatomic, readonly, assign) NSUInteger bitsPerComponent;
@property(nonatomic, readonly, assign) unsigned char *bytes;
@property(nonatomic, readonly, assign) CGColorSpaceRef colorSpace;

-(void)clear;

-(void)invert;

-(void)replaceColorWithRed:(unsigned char)red green:(unsigned char)green blue:(unsigned char)blue;

@end


@interface ATByteImageContext : NSObject {
    ATByteImage *image;
    CGContextRef context;
}

-(id)initWithByteImage:(ATByteImage *)anImage;

@property(nonatomic, readonly, assign) CGContextRef CGContext;

@end
