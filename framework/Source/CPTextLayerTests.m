
#import "CPTextLayerTests.h"
#import "CPTextLayer.h"
#import <QuartzCore/QuartzCore.h>

@interface CPTextLayer (UnitTesting)
- (void)gtm_unitTestEncodeState:(NSCoder*)inCoder;
@end

@implementation CPTextLayer (UnitTesting)

- (void)gtm_unitTestEncodeState:(NSCoder*)inCoder {
    [super gtm_unitTestEncodeState:inCoder];
    
    [inCoder encodeObject:self.text forKey:@"Text"];
    [inCoder encodeFloat:self.fontSize forKey:@"FontSize"];
    [inCoder encodeObject:self.fontName forKey:@"FontName"];
    [inCoder encodeObject:[CIColor colorWithCGColor:fontColor] forKey:@"FontColor"];
    CGRect frame = [self frame];
    [inCoder encodeRect:NSMakeRect(frame.origin.x, frame.origin.y, CGRectGetWidth(frame), CGRectGetHeight(frame)) forKey:@"FrameRect"];
    
}

@end


@implementation CPTextLayerTests
- (void)testDefaultFont {
    STAssertEqualObjects(@"Helvetica", [CPTextLayer defaultFontName], @"Default font is not Helvetica");
}

- (void)testInit {
    id expectedString = @"testInit-expectedString";
    CGFloat expectedFontSize = 12.;
    
    CPTextLayer *layer = [[CPTextLayer alloc] initWithString:expectedString fontSize:expectedFontSize];
    
    GTMAssertObjectStateEqualToStateNamed(layer, @"CPTextLayerTests-testInit1", @"state following initWithString:fontSize: is incorrect");
}

- (void)testDrawInContext {
    
    CPTextLayer *layer = [[CPTextLayer alloc] initWithString:@"testInit-expectedString" fontSize:12];
    
    GTMAssertObjectImageEqualToImageNamed(layer, @"CPTextLayerTests-testRendering1", @"Rendered image does not match");
    
    
    layer.text = @"testInit-expectedString2";
    GTMAssertObjectEqualToStateAndImageNamed(layer, @"CPTextLayerTests-testRendering2", @"Rendered image does not match");
    
    layer.text = @"testInit-expectedString3";
    layer.fontSize = 10.;
    GTMAssertObjectEqualToStateAndImageNamed(layer, @"CPTextLayerTests-testRendering3", @"Rendered image does not match");
    
    layer.fontSize = 100.;
    GTMAssertObjectEqualToStateAndImageNamed(layer, @"CPTextLayerTests-testRendering4", @"Rendered image does not match");
	
	[layer release];
}
@end
