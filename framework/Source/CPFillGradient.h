//
//  CPFillGradient.h
//  CorePlot
//

#import <Foundation/Foundation.h>
#import "CPFill.h"

@class CPGradient;

@interface CPFillGradient : CPFill <NSCopying> {
	CPGradient *fillGradient;
}

-(id)initWithGradient:(CPGradient *)aGradient;
-(void)fillRect:(CGRect)theRect inContext:(CGContextRef)theContext;
-(void)fillPathInContext:(CGContextRef)theContext;
-(id)copyWithZone:(NSZone *)zone;

@end
