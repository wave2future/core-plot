//
//  CPPlotSymbolTests.m
//  CorePlot
//

#import <Cocoa/Cocoa.h>
#import "CPPlotSymbolTests.h"
#import "CPExceptions.h"
#import "CPPlotRange.h"
#import "CPScatterPlot.h"
#import "CPCartesianPlotSpace.h"
#import "CPUtilities.h"
#import "CPPlotSymbol.h"


@implementation CPPlotSymbolTests

@synthesize plot;

- (void)setUpPlotSpace
{
    
    CPCartesianPlotSpace *plotSpace = [[[CPCartesianPlotSpace alloc] init] autorelease];
    plotSpace.bounds = CGRectMake(0.0, 0.0, 110.0, 110.0);
    
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(-1) 
                                                   length:CPDecimalFromInt(self.nRecords+1)];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromInt(-1)
                                                   length:CPDecimalFromInt(self.nRecords+1)];
    
    
    self.plot = [[[CPScatterPlot alloc] init] autorelease];
    [plotSpace addSublayer:self.plot];
    self.plot.frame = plotSpace.bounds;
    self.plot.dataLineStyle = nil;
    self.plot.plotSpace = plotSpace;
    self.plot.dataSource = self;
}

- (void)tearDown
{
    self.plot = nil;
}

- (void)buildData
{
	NSUInteger n = self.nRecords;
	
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:n*n];
    for (NSUInteger i=0; i<n; i++) {
		for (NSUInteger j=0; j<n; j++) {
			[arr insertObject:[NSDecimalNumber numberWithUnsignedInteger:j] atIndex:i*n+j];
		}
	}
    self.xData = arr;
    
    arr = [NSMutableArray arrayWithCapacity:n*n];
    for (NSUInteger i=0; i<n; i++) {
		for (NSUInteger j=0; j<n; j++) {
 			[arr insertObject:[NSDecimalNumber numberWithUnsignedInteger:i] atIndex:i*n+j];
		}
	}
    self.yData = arr;
}

- (void)testPlotSymbols
{
	self.nRecords = 1;
    [self buildData];
	[self setUpPlotSpace];
    self.plot.identifier = @"Plot Symbols";
    
	CPPlotSymbol *plotSymbol = [[[CPPlotSymbol alloc] init] autorelease];
    plotSymbol.size = CGSizeMake(100.0, 100.0);
	
	for (NSUInteger i=CPPlotSymbolTypeNone; i<=CPPlotSymbolTypeSnow; i++) {
		plotSymbol.symbolType = i;
		self.plot.defaultPlotSymbol = plotSymbol;

		NSString *plotName = [NSString stringWithFormat:@"CPPlotSymbolTests-testSymbol%lu", (unsigned long)i];
		NSString *errorMessage = [NSString stringWithFormat:@"Should plot symbol #%lu", (unsigned long)i];
        [self.plot setNeedsDisplay];
		
		GTMAssertObjectImageEqualToImageNamed(self.plot, plotName, errorMessage);		
	}
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecords 
{
	NSUInteger n = self.nRecords;
    return n*n;
}


@end
