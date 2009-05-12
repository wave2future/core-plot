
#import "CPGradient.h"
#import "CPUtilities.h"
#import "CPLayer.h"
#import "CPColorSpace.h"
#import "CPColor.h"


@interface CPGradient ()

@property (retain, readwrite) CPColorSpace *colorspace;
@property (assign, readwrite) CPGradientBlendingMode blendingMode;

-(void)_commonInit;
-(void)addElement:(CPGradientElement*)newElement;

-(CGShadingRef)axialGradientInRect:(CGRect)rect;
-(CGShadingRef)radialGradientInRect:(CGRect)rect context:(CGContextRef)context;

-(CPGradientElement *)elementAtIndex:(NSUInteger)index;

-(CPGradientElement)removeElementAtIndex:(NSUInteger)index;
-(CPGradientElement)removeElementAtPosition:(float)position;

@end

// C Fuctions for color blending
static void linearEvaluation   (void *info, const float *in, float *out);
static void chromaticEvaluation(void *info, const float *in, float *out);
static void inverseChromaticEvaluation(void *info, const float *in, float *out);
static void transformRGB_HSV(float *components);
static void transformHSV_RGB(float *components);
static void resolveHSV(float *color1, float *color2);


@implementation CPGradient

@synthesize colorspace;
@synthesize blendingMode;
@synthesize angle;
@synthesize gradientType;

#pragma mark -
#pragma mark Initialization
-(id)init
{
    if (self = [super init]) {
        [self _commonInit];
		
        self.blendingMode = CPLinearBlendingMode;
		self.angle = 0;
        self.gradientType = CPAxialGradientType;
    }
    return self;
}

-(void)_commonInit
{
	colorspace = [CPColorSpace genericRGBSpace];
    elementList = nil;
}

-(void)dealloc
{
	self.colorspace = nil;
    CGFunctionRelease(gradientFunction);
    CPGradientElement *elementToRemove = elementList;
    while (elementList != nil) {
        elementToRemove = elementList;
        elementList = elementList->nextElement;
        free(elementToRemove);
	}
    [super dealloc];
}

-(id)copyWithZone:(NSZone *)zone
{
    CPGradient *copy = [[[self class] allocWithZone:zone] init];
	
    CPGradientElement *currentElement = elementList;
    while (currentElement != nil) {
        [copy addElement:currentElement];
        currentElement = currentElement->nextElement;
    }
	
	copy.blendingMode = self.blendingMode;
	copy.angle = self.angle;
	copy.gradientType = self.gradientType;
	
    return copy;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        NSUInteger count = 0;
        CPGradientElement *currentElement = elementList;
        while (currentElement != nil) {
            [coder encodeValueOfObjCType:@encode(float) at:&(currentElement->color.red)];
            [coder encodeValueOfObjCType:@encode(float) at:&(currentElement->color.green)];
            [coder encodeValueOfObjCType:@encode(float) at:&(currentElement->color.blue)];
            [coder encodeValueOfObjCType:@encode(float) at:&(currentElement->color.alpha)];
            [coder encodeValueOfObjCType:@encode(float) at:&(currentElement->position)];
            
            count++;
            currentElement = currentElement->nextElement;
        }
        [coder encodeInteger:count forKey:@"CPGradientElementCount"];
        [coder encodeInt:blendingMode forKey:@"CPGradientBlendingMode"];
        [coder encodeFloat:angle forKey:@"CPGradientAngle"];
        [coder encodeInt:gradientType forKey:@"CPGradientType"];
		
        if ([[super class] conformsToProtocol:@protocol(NSCoding)]) {
			[(id <NSCoding>)super encodeWithCoder:coder];
		}
	} else {
        [NSException raise:NSInvalidArchiveOperationException format:@"Only supports NSKeyedArchiver coders"];
	}
}

-(id)initWithCoder:(NSCoder *)coder
{
    if ([[super class] conformsToProtocol:@protocol(NSCoding)]) {
        self = [(id <NSCoding>)super initWithCoder:coder];
    } else {
        self = [super init];
    }
    
    if (self) {
		[self _commonInit];
		
		self.gradientType = [coder decodeIntForKey:@"CPGradientType"];
		self.angle = [coder decodeFloatForKey:@"CPGradientAngle"];
		self.blendingMode = [coder decodeIntForKey:@"CPGradientBlendingMode"];
		
		NSUInteger count = [coder decodeIntegerForKey:@"CPGradientElementCount"];
		
		while (count != 0) {
			CPGradientElement newElement;
			
			[coder decodeValueOfObjCType:@encode(float) at:&(newElement.color.red)];
			[coder decodeValueOfObjCType:@encode(float) at:&(newElement.color.green)];
			[coder decodeValueOfObjCType:@encode(float) at:&(newElement.color.blue)];
			[coder decodeValueOfObjCType:@encode(float) at:&(newElement.color.alpha)];
			[coder decodeValueOfObjCType:@encode(float) at:&(newElement.position)];
			
			count--;
			[self addElement:&newElement];
		}
	}
    return self;
}

#pragma mark -
#pragma mark Factory Methods
+(CPGradient *)gradientWithBeginningColor:(CPColor *)begin endingColor:(CPColor *)end {
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    CPGradientElement color2;
	
	color1.color = CPRGBColorFromCGColor(begin.cgColor);
	color2.color = CPRGBColorFromCGColor(end.cgColor);
	
    color1.position = 0;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)aquaSelectedGradient {
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red   = 0.58;
    color1.color.green = 0.86;
    color1.color.blue  = 0.98;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red   = 0.42;
    color2.color.green = 0.68;
    color2.color.blue  = 0.90;
    color2.color.alpha = 1.00;
    color2.position = 11.5/23;
	
    CPGradientElement color3;
    color3.color.red   = 0.64;
    color3.color.green = 0.80;
    color3.color.blue  = 0.94;
    color3.color.alpha = 1.00;
    color3.position = 11.5/23;
	
    CPGradientElement color4;
    color4.color.red   = 0.56;
    color4.color.green = 0.70;
    color4.color.blue  = 0.90;
    color4.color.alpha = 1.00;
    color4.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
    [newInstance addElement:&color3];
    [newInstance addElement:&color4];
	
    return [newInstance autorelease];
}

+(CPGradient *)aquaNormalGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red = color1.color.green = color1.color.blue  = 0.95;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red = color2.color.green = color2.color.blue  = 0.83;
    color2.color.alpha = 1.00;
    color2.position = 11.5/23;
	
    CPGradientElement color3;
    color3.color.red = color3.color.green = color3.color.blue  = 0.95;
    color3.color.alpha = 1.00;
    color3.position = 11.5/23;
	
    CPGradientElement color4;
    color4.color.red = color4.color.green = color4.color.blue  = 0.92;
    color4.color.alpha = 1.00;
    color4.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
    [newInstance addElement:&color3];
    [newInstance addElement:&color4];
	
    return [newInstance autorelease];
}

+(CPGradient *)aquaPressedGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red = color1.color.green = color1.color.blue  = 0.80;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red = color2.color.green = color2.color.blue  = 0.64;
    color2.color.alpha = 1.00;
    color2.position = 11.5/23;
	
    CPGradientElement color3;
    color3.color.red = color3.color.green = color3.color.blue  = 0.80;
    color3.color.alpha = 1.00;
    color3.position = 11.5/23;
	
    CPGradientElement color4;
    color4.color.red = color4.color.green = color4.color.blue  = 0.77;
    color4.color.alpha = 1.00;
    color4.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
    [newInstance addElement:&color3];
    [newInstance addElement:&color4];
	
    return [newInstance autorelease];
}

+(CPGradient *)unifiedSelectedGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red = color1.color.green = color1.color.blue  = 0.85;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red = color2.color.green = color2.color.blue  = 0.95;
    color2.color.alpha = 1.00;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)unifiedNormalGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red = color1.color.green = color1.color.blue  = 0.75;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red = color2.color.green = color2.color.blue  = 0.90;
    color2.color.alpha = 1.00;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)unifiedPressedGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red = color1.color.green = color1.color.blue  = 0.60;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red = color2.color.green = color2.color.blue  = 0.75;
    color2.color.alpha = 1.00;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)unifiedDarkGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red = color1.color.green = color1.color.blue  = 0.68;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red = color2.color.green = color2.color.blue  = 0.83;
    color2.color.alpha = 1.00;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)sourceListSelectedGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red   = 0.06;
    color1.color.green = 0.37;
    color1.color.blue  = 0.85;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red   = 0.30;
    color2.color.green = 0.60;
    color2.color.blue  = 0.92;
    color2.color.alpha = 1.00;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)sourceListUnselectedGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red   = 0.43;
    color1.color.green = 0.43;
    color1.color.blue  = 0.43;
    color1.color.alpha = 1.00;
    color1.position = 0;
	
    CPGradientElement color2;
    color2.color.red   = 0.60;
    color2.color.green = 0.60;
    color2.color.blue  = 0.60;
    color2.color.alpha = 1.00;
    color2.position = 1;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    return [newInstance autorelease];
}

+(CPGradient *)rainbowGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement color1;
    color1.color.red   = 1.00;
    color1.color.green = 0.00;
    color1.color.blue  = 0.00;
    color1.color.alpha = 1.00;
    color1.position = 0.0;
	
    CPGradientElement color2;
    color2.color.red   = 0.54;
    color2.color.green = 0.00;
    color2.color.blue  = 1.00;
    color2.color.alpha = 1.00;
    color2.position = 1.0;
	
    [newInstance addElement:&color1];
    [newInstance addElement:&color2];
	
    newInstance.blendingMode = CPChromaticBlendingMode;
	
    return [newInstance autorelease];
}

+(CPGradient *)hydrogenSpectrumGradient
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    struct {float hue; float position; float width;} colorBands[4];
	
    colorBands[0].hue = 22;
    colorBands[0].position = 0.145;
    colorBands[0].width = 0.01;
	
    colorBands[1].hue = 200;
    colorBands[1].position = 0.71;
    colorBands[1].width = 0.008;
	
    colorBands[2].hue = 253;
    colorBands[2].position = 0.885;
    colorBands[2].width = 0.005;
	
    colorBands[3].hue = 275;
    colorBands[3].position = 0.965;
    colorBands[3].width = 0.003;
	
    int i;
    for(i = 0; i < 4; i++) {
		float color[4];
		color[0] = colorBands[i].hue - 180*colorBands[i].width;
		color[1] = 1;
		color[2] = 0.001;
		color[3] = 1;
		transformHSV_RGB(color);
		
		CPGradientElement fadeIn;
		fadeIn.color.red   = color[0];
		fadeIn.color.green = color[1];
		fadeIn.color.blue  = color[2];
		fadeIn.color.alpha = color[3];
		fadeIn.position = colorBands[i].position - colorBands[i].width;
		
		color[0] = colorBands[i].hue;
		color[1] = 1;
		color[2] = 1;
		color[3] = 1;
		transformHSV_RGB(color);
		
		CPGradientElement band;
		band.color.red   = color[0];
		band.color.green = color[1];
		band.color.blue  = color[2];
		band.color.alpha = color[3];
		band.position = colorBands[i].position;
		
		color[0] = colorBands[i].hue + 180*colorBands[i].width;
		color[1] = 1;
		color[2] = 0.001;
		color[3] = 1;
		transformHSV_RGB(color);
		
		CPGradientElement fadeOut;
		fadeOut.color.red   = color[0];
		fadeOut.color.green = color[1];
		fadeOut.color.blue  = color[2];
		fadeOut.color.alpha = color[3];
		fadeOut.position = colorBands[i].position + colorBands[i].width;
		
		[newInstance addElement:&fadeIn];
		[newInstance addElement:&band];
		[newInstance addElement:&fadeOut];
    }
	
    newInstance.blendingMode = CPChromaticBlendingMode;
	
    return [newInstance autorelease];
}

#pragma mark -
#pragma mark Modification
-(CPGradient *)gradientWithAlphaComponent:(float)alpha
{
    CPGradient *newInstance = [[[self class] alloc] init];
	
    CPGradientElement *curElement = elementList;
    CPGradientElement tempElement;
	
    while (curElement != nil) {
        tempElement = *curElement;
        tempElement.color.alpha = alpha;
        [newInstance addElement:&tempElement];
		
        curElement = curElement->nextElement;
    }
	
    return [newInstance autorelease];
}

-(CPGradient *)gradientWithBlendingMode:(CPGradientBlendingMode)mode {
    CPGradient *newGradient = [self copy];  
    newGradient.blendingMode = mode;
    return [newGradient autorelease];
}

// Adds a color stop with <color> at <position> in elementList
// (if two elements are at the same position then added immediately after the one that was there already)
-(CPGradient *)addColorStop:(CPColor *)color atPosition:(float)position
{
    CPGradient *newGradient = [self copy];
    CPGradientElement newGradientElement;
	
    //put the components of color into the newGradientElement - must make sure it is a RGB color (not Gray or CMYK)
	newGradientElement.color = CPRGBColorFromCGColor(color.cgColor);
    newGradientElement.position = position;
	
    //Pass it off to addElement to take care of adding it to the elementList
    [newGradient addElement:&newGradientElement];
	
    return [newGradient autorelease];
}

// Removes the color stop at <position> from elementList
-(CPGradient *)removeColorStopAtPosition:(float)position
{
    CPGradient *newGradient = [self copy];
    CPGradientElement removedElement = [newGradient removeElementAtPosition:position];
	
    if ( isnan(removedElement.position) ) {
        [NSException raise:NSRangeException format:@"-[%@ removeColorStopAtPosition:]: no such colorStop at position (%f)", [self class], position];
	}
	
    return [newGradient autorelease];
}

-(CPGradient *)removeColorStopAtIndex:(NSUInteger)index
{
    CPGradient *newGradient = [self copy];
    CPGradientElement removedElement = [newGradient removeElementAtIndex:index];
	
    if ( isnan(removedElement.position) ) {
		[NSException raise:NSRangeException format:@"-[%@ removeColorStopAtIndex:]: index (%i) beyond bounds", [self class], index];
	}
	
    return [newGradient autorelease];
}

#pragma mark -
#pragma mark Information

// Returns color at <position> in gradient
-(CGColorRef)colorStopAtIndex:(NSUInteger)index
{
    CPGradientElement *element = [self elementAtIndex:index];
	
    if (element != nil) {
#if defined(TARGET_IPHONE_SIMULATOR) || defined(TARGET_OS_IPHONE)
		CGFloat colorComponents[4] = {element->color.red, element->color.green, element->color.blue, element->color.alpha};
		return CGColorCreate(colorspace.cgColorSpace, colorComponents);
#else
        return CGColorCreateGenericRGB(element->color.red, element->color.green, element->color.blue, element->color.alpha);
#endif
		
	}
	
    [NSException raise:NSRangeException format:@"-[%@ colorStopAtIndex:]: index (%i) beyond bounds", [self class], index];
	
    return NULL;
}

-(CGColorRef)colorAtPosition:(float)position
{
    float components[4];
	CGColorRef gradientColor;
	
    switch (blendingMode) {
        case CPLinearBlendingMode:
			linearEvaluation(&elementList, &position, components);				break;
        case CPChromaticBlendingMode:
			chromaticEvaluation(&elementList, &position, components);			break;
        case CPInverseChromaticBlendingMode:
			inverseChromaticEvaluation(&elementList, &position, components);	break;
    }
    
	if (components[3] != 0) {
		//undo premultiplication that CG requires
#if defined(TARGET_IPHONE_SIMULATOR) || defined(TARGET_OS_IPHONE)
		CGFloat colorComponents[4] = {components[0]/components[3], components[1]/components[3], components[2]/components[3], components[3]};
		gradientColor = CGColorCreate(colorspace.cgColorSpace, colorComponents);
#else
		gradientColor = CGColorCreateGenericRGB(components[0]/components[3], components[1]/components[3], components[2]/components[3], components[3]);
#endif
		
	} else {
#if defined(TARGET_IPHONE_SIMULATOR) || defined(TARGET_OS_IPHONE)
		CGFloat colorComponents[4] = {components[0], components[1], components[2], components[3]};
		gradientColor = CGColorCreate(colorspace.cgColorSpace, colorComponents);
#else
		gradientColor = CGColorCreateGenericRGB(components[0], components[1], components[2], components[3]);
#endif
	}
	
	return gradientColor;
}

#pragma mark -
#pragma mark Drawing
-(void)drawSwatchInRect:(CGRect)rect inContext:(CGContextRef)context
{
    [self fillRect:rect inContext:context];
}

-(void)fillRect:(CGRect)rect inContext:(CGContextRef)context
{
	CGShadingRef myCGShading;
	
    CGContextSaveGState(context);
	
    CGContextClipToRect(context, *(CGRect *)&rect);
	
	switch (self.gradientType) {
		case CPAxialGradientType:
			myCGShading = [self axialGradientInRect:rect];
			break;
		case CPRadialGradientType:
			myCGShading = [self radialGradientInRect:rect context:context];
			break;
	}
	
    CGContextDrawShading(context, myCGShading);
	
    CGShadingRelease(myCGShading);
    CGContextRestoreGState(context);
}

-(void)fillPathInContext:(CGContextRef)context
{
	if (!CGContextIsPathEmpty(context)) {
		CGShadingRef myCGShading;
		
		CGContextSaveGState(context);
		
		CGRect bounds = CGContextGetPathBoundingBox(context);
		CGContextClip(context);
		
		switch (self.gradientType) {
			case CPAxialGradientType:
				myCGShading = [self axialGradientInRect:bounds];
				break;
			case CPRadialGradientType:
				myCGShading = [self radialGradientInRect:bounds context:context];
				break;
		}
		
		CGContextDrawShading(context, myCGShading);
		
		CGShadingRelease(myCGShading);
		CGContextRestoreGState(context);
	}
}

#pragma mark -
#pragma mark Private Methods
-(CGShadingRef)axialGradientInRect:(CGRect)rect
{
    // First Calculate where the beginning and ending points should be
    CGPoint startPoint;
    CGPoint endPoint;
	
    if (self.angle == 0)	{
        startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));	// right of rect
        endPoint   = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));	// left  of rect
    } else if (self.angle == 90) {
        startPoint = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));	// bottom of rect
        endPoint   = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));	// top    of rect
    } else { // ok, we'll do the calculations now
        CGFloat x, y;
        float sina, cosa, tana;
		
        CGFloat length;
        CGFloat deltax, deltay;
		
        float rangle = self.angle * M_PI/180;	//convert the angle to radians
		
        if (fabsf(tan(rangle))<=1) {  //for range [-45,45], [135,225]
            x = CGRectGetWidth(rect);
            y = CGRectGetHeight(rect);
            
            sina = sin(rangle);
            cosa = cos(rangle);
            tana = tan(rangle);
            
            length = x/fabsf(cosa)+(y-x*fabsf(tana))*fabsf(sina);
            
            deltax = length*cosa/2;
            deltay = length*sina/2;
		} else {		//for range [45,135], [225,315]
            x = CGRectGetHeight(rect);
            y = CGRectGetWidth(rect);
            
			rangle -= M_PI/2;
			
            sina = sin(rangle);
            cosa = cos(rangle);
            tana = tan(rangle);
            
            length = x/fabsf(cosa)+(y-x*fabsf(tana))*fabsf(sina);
            
            deltax = -length*sina/2;
            deltay = length*cosa/2;
        }
		
        startPoint = CGPointMake(CGRectGetMidX(rect)-deltax, CGRectGetMidY(rect)-deltay);
        endPoint   = CGPointMake(CGRectGetMidX(rect)+deltax, CGRectGetMidY(rect)+deltay);
    }
	
    //Calls to CoreGraphics
    CGShadingRef myCGShading = CGShadingCreateAxial(self.colorspace.cgColorSpace, startPoint, endPoint, gradientFunction, false, false);
	
	return myCGShading;
}

-(CGShadingRef)radialGradientInRect:(CGRect)rect context:(CGContextRef)context
{
    CGPoint startPoint, endPoint;
    CGFloat startRadius, endRadius;
    CGFloat scalex, scaley;
	
    startPoint = endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
	
	startRadius = -1;
    if (CGRectGetHeight(rect)>CGRectGetWidth(rect)) {
        scalex = CGRectGetWidth(rect)/CGRectGetHeight(rect);
        startPoint.x /= scalex;
        endPoint.x /= scalex;
        scaley = 1;
        endRadius = CGRectGetHeight(rect)/2;
    } else {
        scalex = 1;
        scaley = CGRectGetHeight(rect)/CGRectGetWidth(rect);
        startPoint.y /= scaley;
        endPoint.y /= scaley;
        endRadius = CGRectGetWidth(rect)/2;
    }
	
	CGContextScaleCTM    (context, scalex, scaley);
	
    CGShadingRef myCGShading = CGShadingCreateRadial(self.colorspace.cgColorSpace, startPoint, startRadius, endPoint, endRadius, gradientFunction, true, true);
	
	return myCGShading;
}

-(void)setBlendingMode:(CPGradientBlendingMode)mode;
{
    blendingMode = mode;
	
    // Choose what blending function to use
    void *evaluationFunction;
    switch(blendingMode)
    {
        case CPLinearBlendingMode:
			evaluationFunction = &linearEvaluation;
			break;
        case CPChromaticBlendingMode:
			evaluationFunction = &chromaticEvaluation;
			break;
        case CPInverseChromaticBlendingMode:
			evaluationFunction = &inverseChromaticEvaluation;
			break;
    }
	
    // replace the current CoreGraphics Function with new one
    if (gradientFunction != NULL) {
        CGFunctionRelease(gradientFunction);
	}
	
    CGFunctionCallbacks evaluationCallbackInfo = {0 , evaluationFunction, NULL};	// Version, evaluator function, cleanup function
	
    static const CGFloat input_value_range   [2] = { 0, 1 };					// range  for the evaluator input
    static const CGFloat output_value_ranges [8] = { 0, 1, 0, 1, 0, 1, 0, 1 };	// ranges for the evaluator output (4 returned values)
	
    gradientFunction = CGFunctionCreate(&elementList,					//the two transition colors
										1, input_value_range  ,		//number of inputs (just fraction of progression)
										4, output_value_ranges,		//number of outputs (4 - RGBa)
										&evaluationCallbackInfo);		//info for using the evaluator function
}

-(void)addElement:(CPGradientElement *)newElement
{
    if (elementList == nil || newElement->position < elementList->position) {
        CPGradientElement *tmpNext = elementList;
        elementList = malloc(sizeof(CPGradientElement));
        *elementList = *newElement;
        elementList->nextElement = tmpNext;
    } else {
        CPGradientElement *curElement = elementList;
		
        while ( curElement->nextElement != nil && 
			   !((curElement->position <= newElement->position) && 
				 (newElement->position < curElement->nextElement->position)) ) {
            curElement = curElement->nextElement;
        }
		
        CPGradientElement *tmpNext = curElement->nextElement;
        curElement->nextElement = malloc(sizeof(CPGradientElement));
        *(curElement->nextElement) = *newElement;
        curElement->nextElement->nextElement = tmpNext;
    }
}

-(CPGradientElement)removeElementAtIndex:(NSUInteger)index
{
    CPGradientElement removedElement;
	
    if (elementList != nil) {
        if (index == 0) {
            CPGradientElement *tmpNext = elementList;
            elementList = elementList->nextElement;
            
            removedElement = *tmpNext;
            free(tmpNext);
            
            return removedElement;
        }
		
        NSUInteger count = 1;		//we want to start one ahead
        CPGradientElement *currentElement = elementList;
        while (currentElement->nextElement != nil) {
            if (count == index) {
                CPGradientElement *tmpNext  = currentElement->nextElement;
                currentElement->nextElement = currentElement->nextElement->nextElement;
                
                removedElement = *tmpNext;
                free(tmpNext);
				
                return removedElement;
            }
			
            count++;
            currentElement = currentElement->nextElement;
        }
    }
	
    // element is not found, return empty element
    removedElement.color.red   = 0.0;
    removedElement.color.green = 0.0;
    removedElement.color.blue  = 0.0;
    removedElement.color.alpha = 0.0;
    removedElement.position = NAN;
    removedElement.nextElement = nil;
	
    return removedElement;
}

-(CPGradientElement)removeElementAtPosition:(float)position {
    CPGradientElement removedElement;
	
    if (elementList != nil) {
        if (elementList->position == position) {
            CPGradientElement *tmpNext = elementList;
            elementList = elementList->nextElement;
            
            removedElement = *tmpNext;
            free(tmpNext);
            
            return removedElement;
        } else {
            CPGradientElement *curElement = elementList;
            while (curElement->nextElement != nil) {
                if (curElement->nextElement->position == position) {
                    CPGradientElement *tmpNext = curElement->nextElement;
                    curElement->nextElement = curElement->nextElement->nextElement;
                    
                    removedElement = *tmpNext;
                    free(tmpNext);
					
                    return removedElement;
                }
            }
        }
    }
	
    // element is not found, return empty element
    removedElement.color.red   = 0.0;
    removedElement.color.green = 0.0;
    removedElement.color.blue  = 0.0;
    removedElement.color.alpha = 0.0;
    removedElement.position = NAN;
    removedElement.nextElement = nil;
	
    return removedElement;
}

-(CPGradientElement *)elementAtIndex:(NSUInteger)index
{
    NSUInteger count = 0;
    CPGradientElement *currentElement = elementList;
	
    while (currentElement != nil) {
        if (count == index) {
            return currentElement;
		}
		
        count++;
        currentElement = currentElement->nextElement;
    }
	
    return nil;
}

#pragma mark -
#pragma mark Core Graphics
void linearEvaluation (void *info, const float *in, float *out) 
{
    float position = *in;
	
    if (*(CPGradientElement **)info == nil) {
        out[0] = out[1] = out[2] = out[3] = 1;
        return;
    }
	
    //This grabs the first two colors in the sequence
    CPGradientElement *color1 = *(CPGradientElement **)info;
    CPGradientElement *color2 = color1->nextElement;
	
    //make sure first color and second color are on other sides of position
    while (color2 != nil && color2->position < position) {
        color1 = color2;
        color2 = color1->nextElement;
    }
    //if we don't have another color then make next color the same color
    if (color2 == nil) {
        color2 = color1;
    }
	
    //----------FailSafe settings----------
    //color1->red   = 1; color2->red   = 0;
    //color1->green = 1; color2->green = 0;
    //color1->blue  = 1; color2->blue  = 0;
    //color1->alpha = 1; color2->alpha = 1;
    //color1->position = 0.5;
    //color2->position = 0.5;
    //-------------------------------------
	
    if (position <= color1->position) {
        out[0] = color1->color.red; 
        out[1] = color1->color.green;
        out[2] = color1->color.blue;
        out[3] = color1->color.alpha;
    } else if (position >= color2->position)	{
        out[0] = color2->color.red; 
        out[1] = color2->color.green;
        out[2] = color2->color.blue;
        out[3] = color2->color.alpha;
    } else {
        //adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
        position = (position-color1->position)/(color2->position - color1->position);
		
        out[0] = (color2->color.red   - color1->color.red  )*position + color1->color.red; 
        out[1] = (color2->color.green - color1->color.green)*position + color1->color.green;
        out[2] = (color2->color.blue  - color1->color.blue )*position + color1->color.blue;
        out[3] = (color2->color.alpha - color1->color.alpha)*position + color1->color.alpha;
    }
	
    //Premultiply the color by the alpha.
    out[0] *= out[3];
    out[1] *= out[3];
    out[2] *= out[3];
}

//Chromatic Evaluation - 
//	This blends colors by their Hue, Saturation, and Value(Brightness) right now I just 
//	transform the RGB values stored in the CPGradientElements to HSB, in the future I may
//	streamline it to avoid transforming in and out of HSB colorspace *for later*
//
//	For the chromatic blend we shift the hue of color1 to meet the hue of color2. To do
//	this we will add to the hue's angle (if we subtract we'll be doing the inverse
//	chromatic...scroll down more for that). All we need to do is keep adding to the hue
//  until we wrap around the colorwheel and get to color2.
void chromaticEvaluation(void *info, const float *in, float *out)
{
    float position = *in;
	
    if (*(CPGradientElement **)info == nil) {
        out[0] = out[1] = out[2] = out[3] = 1;
        return;
    }
	
    // This grabs the first two colors in the sequence
    CPGradientElement *color1 = *(CPGradientElement **)info;
    CPGradientElement *color2 = color1->nextElement;
	
    float c1[4];
    float c2[4];
	
    // make sure first color and second color are on other sides of position
    while (color2 != nil && color2->position < position) {
        color1 = color2;
        color2 = color1->nextElement;
    }
    
    // if we don't have another color then make next color the same color
    if (color2 == nil) {
        color2 = color1;
    }
	
    c1[0] = color1->color.red; 
    c1[1] = color1->color.green;
    c1[2] = color1->color.blue;
    c1[3] = color1->color.alpha;
	
    c2[0] = color2->color.red; 
    c2[1] = color2->color.green;
    c2[2] = color2->color.blue;
    c2[3] = color2->color.alpha;
	
    transformRGB_HSV(c1);
    transformRGB_HSV(c2);
    resolveHSV(c1,c2);
	
    if (c1[0] > c2[0]) { // if color1's hue is higher than color2's hue then
		c2[0] += 360;   // we need to move c2 one revolution around the wheel
	}
	
	
    if (position <= color1->position) {
        out[0] = c1[0]; 
        out[1] = c1[1];
        out[2] = c1[2];
        out[3] = c1[3];
    } else if (position >= color2->position) {
        out[0] = c2[0]; 
        out[1] = c2[1];
        out[2] = c2[2];
        out[3] = c2[3];
    } else {
        //adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
        position = (position-color1->position)/(color2->position - color1->position);
		
        out[0] = (c2[0] - c1[0])*position + c1[0]; 
        out[1] = (c2[1] - c1[1])*position + c1[1];
        out[2] = (c2[2] - c1[2])*position + c1[2];
        out[3] = (c2[3] - c1[3])*position + c1[3];
    }
	
    transformHSV_RGB(out);
	
    //Premultiply the color by the alpha.
    out[0] *= out[3];
    out[1] *= out[3];
    out[2] *= out[3];
}

// Inverse Chromatic Evaluation - 
//	Inverse Chromatic is about the same story as Chromatic Blend, but here the Hue
//	is strictly decreasing, that is we need to get from color1 to color2 by decreasing
//	the 'angle' (i.e. 90º -> 180º would be done by subtracting 270º and getting -180º...
//	which is equivalent to 180º mod 360º
void inverseChromaticEvaluation(void *info, const float *in, float *out)
{
    float position = *in;
	
    if (*(CPGradientElement **)info == nil) {
        out[0] = out[1] = out[2] = out[3] = 1;
        return;
    }
	
    // This grabs the first two colors in the sequence
    CPGradientElement *color1 = *(CPGradientElement **)info;
    CPGradientElement *color2 = color1->nextElement;
	
    float c1[4];
    float c2[4];
	
    //make sure first color and second color are on other sides of position
    while (color2 != nil && color2->position < position) {
        color1 = color2;
        color2 = color1->nextElement;
    }
    
    // if we don't have another color then make next color the same color
    if (color2 == nil) {
        color2 = color1;
    }
	
    c1[0] = color1->color.red; 
    c1[1] = color1->color.green;
    c1[2] = color1->color.blue;
    c1[3] = color1->color.alpha;
	
    c2[0] = color2->color.red; 
    c2[1] = color2->color.green;
    c2[2] = color2->color.blue;
    c2[3] = color2->color.alpha;
	
    transformRGB_HSV(c1);
    transformRGB_HSV(c2);
    resolveHSV(c1,c2);
	
    if (c1[0] < c2[0]) //if color1's hue is higher than color2's hue then 
        c1[0] += 360;	//	we need to move c2 one revolution back on the wheel
	
	
    if (position <= color1->position) {
        out[0] = c1[0]; 
        out[1] = c1[1];
        out[2] = c1[2];
        out[3] = c1[3];
    }
    else if (position >= color2->position) {
        out[0] = c2[0]; 
        out[1] = c2[1];
        out[2] = c2[2];
        out[3] = c2[3];
    }
    else {
        //adjust position so that it goes from 0 to 1 in the range from color 1 & 2's position 
        position = (position-color1->position)/(color2->position - color1->position);
		
        out[0] = (c2[0] - c1[0])*position + c1[0]; 
        out[1] = (c2[1] - c1[1])*position + c1[1];
        out[2] = (c2[2] - c1[2])*position + c1[2];
        out[3] = (c2[3] - c1[3])*position + c1[3];
    }
	
    transformHSV_RGB(out);
	
    // Premultiply the color by the alpha.
    out[0] *= out[3];
    out[1] *= out[3];
    out[2] *= out[3];
}

void transformRGB_HSV(float *components) //H,S,B -> R,G,B
{
    float H, S, V;
    float R = components[0],
	G = components[1],
	B = components[2];
	
    float MAX = R > G ? (R > B ? R : B) : (G > B ? G : B);
	float MIN = R < G ? (R < B ? R : B) : (G < B ? G : B);
	
    if (MAX == MIN) {
        H = NAN;
	} else if (MAX == R) {
        if (G >= B) {
            H = 60*(G-B)/(MAX-MIN)+0;
		} else {
            H = 60*(G-B)/(MAX-MIN)+360;
		}
	} else if (MAX == G) {
		H = 60*(B-R)/(MAX-MIN)+120;
	} else if (MAX == B) {
		H = 60*(R-G)/(MAX-MIN)+240;
	}
	
    S = MAX == 0 ? 0 : 1 - MIN/MAX;
    V = MAX;
	
    components[0] = H;
    components[1] = S;
    components[2] = V;
}

void transformHSV_RGB(float *components) //H,S,B -> R,G,B
{
	float R, G, B;
	float H = fmodf(components[0],359);	//map to [0,360)
	float S = components[1];
	float V = components[2];
	
	int   Hi = (int)floorf(H/60.) % 6;
	float f  = H/60-Hi;
	float p  = V*(1-S);
	float q  = V*(1-f*S);
	float t  = V*(1-(1-f)*S);
	
	switch (Hi) {
		case 0:	R=V;G=t;B=p;	break;
		case 1:	R=q;G=V;B=p;	break;
		case 2:	R=p;G=V;B=t;	break;
		case 3:	R=p;G=q;B=V;	break;
		case 4:	R=t;G=p;B=V;	break;
		case 5:	R=V;G=p;B=q;	break;
    }
	
	components[0] = R;
	components[1] = G;
	components[2] = B;
}

void resolveHSV(float *color1, float *color2)	// H value may be undefined (i.e. graycale color)
{                                               //	we want to fill it with a sensible value
	if (isnan(color1[0]) && isnan(color2[0])) {
		color1[0] = color2[0] = 0;
	}
	else if (isnan(color1[0])) {
		color1[0] = color2[0];
	}
	else if (isnan(color2[0])) {
		color2[0] = color1[0];
	}
}

@end
