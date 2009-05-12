//
//  CPTestAppScatterPlotController.m
//  CPTestApp-iPhone
//
//  Created by Brad Larson on 5/11/2009.
//

#import "CPTestAppScatterPlotController.h"


@implementation CPTestAppScatterPlotController

#pragma mark -
#pragma mark Initialization and teardown
/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		NSLog(@"Init");
        // Custom initialization
    }
    return self;
}
*/

- (void)dealloc 
{
	[dataForPlot release];
    [super dealloc];
}

- (void)viewDidLoad 
{
    // Create graph
    graph = [[CPXYGraph alloc] init];
	graph.frame = self.view.bounds;
	
	CGFloat grayColorComponents[4] = {0.7, 0.7, 0.7, 1.0};
	CGColorRef grayColor =  CGColorCreate([CPColorSpace genericRGBSpace].cgColorSpace, grayColorComponents);

	graph.fill = [CPFill fillWithColor:[CPColor colorWithCGColor:grayColor]];
	CGColorRelease(grayColor);
	
	CGFloat darkGrayColorComponents[4] = {0.2, 0.2, 0.2, 0.3};
	grayColor =  CGColorCreate([CPColorSpace genericRGBSpace].cgColorSpace, darkGrayColorComponents);
	
	graph.plotArea.fill = [CPFill fillWithColor:[CPColor colorWithCGColor:grayColor]];
	CGColorRelease(grayColor);
	
	[self.view.layer addSublayer:graph];
    
    // Setup plot space
    CPCartesianPlotSpace *plotSpace = (CPCartesianPlotSpace *)graph.defaultPlotSpace;
    plotSpace.xRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1.0) length:CPDecimalFromFloat(2.0)];
    plotSpace.yRange = [CPPlotRange plotRangeWithLocation:CPDecimalFromFloat(1.0) length:CPDecimalFromFloat(2.0)];
        
    // Create a second plot that uses the data source method
	CPScatterPlot *dataSourceLinePlot = [[[CPScatterPlot alloc] init] autorelease];
    dataSourceLinePlot.identifier = @"Data Source Plot";
	dataSourceLinePlot.dataLineStyle.lineWidth = 1.f;
    dataSourceLinePlot.dataLineStyle.lineColor = [CPColor redColor];
    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];

	// Add plot symbols
	CPPlotSymbol *greenCirclePlotSymbol = [CPPlotSymbol ellipsePlotSymbol];
	CGFloat greenColorComponents[4] = {0.0, 1.0, 0.0, 1.0};
	CGColorRef greenColor =  CGColorCreate([CPColorSpace genericRGBSpace].cgColorSpace, greenColorComponents);
	greenCirclePlotSymbol.fill = [CPFill fillWithColor:[CPColor colorWithCGColor:greenColor]];
    greenCirclePlotSymbol.size = CGSizeMake(10.0, 10.0);
    dataSourceLinePlot.defaultPlotSymbol = greenCirclePlotSymbol;
	CGColorRelease(greenColor);
	
    // Add some initial data
	NSDecimalNumber *x1 = [NSDecimalNumber decimalNumberWithString:@"1.3"];
	NSDecimalNumber *x2 = [NSDecimalNumber decimalNumberWithString:@"1.7"];
	NSDecimalNumber *x3 = [NSDecimalNumber decimalNumberWithString:@"2.8"];
	NSDecimalNumber *y1 = [NSDecimalNumber decimalNumberWithString:@"1.3"];
	NSDecimalNumber *y2 = [NSDecimalNumber decimalNumberWithString:@"2.3"];
	NSDecimalNumber *y3 = [NSDecimalNumber decimalNumberWithString:@"2"];
	
    NSMutableArray *contentArray = [NSMutableArray arrayWithObjects:
									[NSMutableDictionary dictionaryWithObjectsAndKeys:x1, @"x", y1, @"y", nil],
									[NSMutableDictionary dictionaryWithObjectsAndKeys:x2, @"x", y2, @"y", nil],
									[NSMutableDictionary dictionaryWithObjectsAndKeys:x3, @"x", y3, @"y", nil],
									nil];
	self.dataForPlot = contentArray;
	
	
	
    [super viewDidLoad];
}



/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecords {
    return [dataForPlot count];
}

-(NSNumber *)numberForPlot:(CPPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    NSDecimalNumber *num = [[dataForPlot objectAtIndex:index] valueForKey:(fieldEnum == CPScatterPlotFieldX ? @"x" : @"y")];
    if ( fieldEnum == CPScatterPlotFieldY ) num = [num decimalNumberByAdding:[NSDecimalNumber one]];
    return num;
}

#pragma mark -
#pragma mark Accessors

@synthesize dataForPlot;


@end
