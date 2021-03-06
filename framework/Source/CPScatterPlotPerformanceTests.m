#import "CPScatterPlotPerformanceTests.h"
#import "CPScatterPlot.h"
#import "CPExceptions.h"
#import "CPPlotRange.h"
#import "CPScatterPlot.h"
#import "CPCartesianPlotSpace.h"
#import "CPUtilities.h"
#import "CPLineStyle.h"
#import "CPFill.h"
#import "CPPlotSymbol.h"
#import "GTMTestTimer.h"


@implementation CPScatterPlotPerformanceTests
@synthesize plot;

- (void)setUp
{
    
    CPCartesianPlotSpace *plotSpace = [[[CPCartesianPlotSpace alloc] init] autorelease];
    plotSpace.bounds = CGRectMake(0., 0., 100., 100.);
    
    
    self.plot = [[[CPScatterPlot alloc] init] autorelease];
    [plotSpace addSublayer:self.plot];
    self.plot.frame = plotSpace.bounds;
    
    self.plot.plotSpace = plotSpace;
    self.plot.identifier = @"Scatter Plot";
	
    self.plot.dataSource = self;
}


- (void)tearDown
{
    self.plot = nil;
}


- (void)setPlotRanges {
    [(CPCartesianPlotSpace*)[[self plot] plotSpace] setXRange:[self xRange]];
    [(CPCartesianPlotSpace*)[[self plot] plotSpace] setYRange:[self yRange]];
}

/**
 Verify that CPScatterPlot can render 1e5 points in less than 1 second.
 */
- (void)testRenderScatterTimeLimit
{
    self.nRecords = 1e5;
    [self buildData];
	[self setPlotRanges];
    
    //set up CGContext
    CGContextRef ctx = GTMCreateUnitTestBitmapContextOfSizeWithData(self.plot.bounds.size, NULL);
    
    GTMTestTimer *t = GTMTestTimerCreate();
    
    // render several times
    for(NSInteger i = 0; i<3; i++) {
        GTMTestTimerStart(t);
        self.plot.dataNeedsReloading = YES;
        [self.plot drawInContext:ctx];
        GTMTestTimerStop(t);
    }
    
    //verify performance
    STAssertTrue(GTMTestTimerGetSeconds(t)/GTMTestTimerGetIterations(t) < 1.0, @"rendering took more than 1 second for 1e5 points. Avg. time = %g", GTMTestTimerGetSeconds(t)/GTMTestTimerGetIterations(t));
    
    // clean up
    GTMTestTimerRelease(t);
    CFRelease(ctx);
}

- (void)testRenderScatterStressTest {
    
    self.nRecords = 1e6;
    [self buildData];
    [self setPlotRanges];
    
    GTMAssertObjectImageEqualToImageNamed(self.plot, @"CPScatterPlotTests-testRenderStressTest", @"Should render a sine wave.");
    
}
@end
