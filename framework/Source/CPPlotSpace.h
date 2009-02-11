
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "CPLayer.h"


@class CPPlotArea;

@interface CPPlotSpace : CPLayer {
    CPPlotArea *plotArea;
	id <NSCopying, NSObject> identifier;
}

@property (nonatomic, readwrite, assign) CPPlotArea *plotArea;
@property (nonatomic, readwrite, copy) id <NSCopying, NSObject> identifier;

@end


@interface CPPlotSpace (AbstractMethods)

-(CGPoint)viewPointForPlotPoint:(NSArray *)decimalNumbers;
-(NSArray *)plotPointForViewPoint:(CGPoint)point;

@end
