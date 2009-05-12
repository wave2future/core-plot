
#import <Foundation/Foundation.h>

@class CPLineStyle;
@class CPPlotSpace;
@class CPPlotRange;

@interface CPAxis : NSObject {    
	CPPlotSpace *plotSpace;
	CPPlotRange *range;
    NSArray *majorTickLocations;
    NSArray *minorTickLocations;
    CGFloat majorTickLength;
    CGFloat minorTickLength;
    CPLineStyle *axisLineStyle;
    CPLineStyle *majorTickLineStyle;
    CPLineStyle *minorTickLineStyle;
}

@property (nonatomic, readwrite, retain) NSArray *majorTickLocations;
@property (nonatomic, readwrite, retain) NSArray *minorTickLocations;
@property (nonatomic, readwrite, assign) CGFloat minorTickLength;
@property (nonatomic, readwrite, assign) CGFloat majorTickLength;
@property (nonatomic, readwrite, retain) CPPlotRange *range;
@property (nonatomic, readwrite, retain) CPPlotSpace *plotSpace;
@property (nonatomic, readwrite, retain) CPLineStyle *axisLineStyle;
@property (nonatomic, readwrite, retain) CPLineStyle *majorTickLineStyle;
@property (nonatomic, readwrite, retain) CPLineStyle *minorTickLineStyle;

@end

@interface CPAxis (AbstractMethods)

-(void)drawInContext:(CGContextRef)theContext;

@end
