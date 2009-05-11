
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>
#import "CPLayer.h"

@class CPAxisSet;

@interface CPPlotSpace : CPLayer {
	id <NSCopying, NSObject> identifier;
	CPAxisSet* axisSet;
}

@property (nonatomic, readwrite, copy) id <NSCopying, NSObject> identifier;
@property (nonatomic, readwrite, retain) CPAxisSet* axisSet;

@end


@interface CPPlotSpace (AbstractMethods)

-(CGPoint)viewPointForPlotPoint:(NSArray *)decimalNumbers;
-(NSArray *)plotPointForViewPoint:(CGPoint)point;

@end
