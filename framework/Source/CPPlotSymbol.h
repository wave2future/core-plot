#import <Foundation/Foundation.h>

@class CPLineStyle;
@class CPFill;

typedef enum _CPPlotSymbolType {
    CPPlotSymbolTypeNone,
    CPPlotSymbolTypeRectangle,
    CPPlotSymbolTypeEllipse,
    CPPlotSymbolTypeDiamond,
	CPPlotSymbolTypeTriangle,
	CPPlotSymbolTypeStar,
	CPPlotSymbolTypePentagon,
	CPPlotSymbolTypeHexagon,
	CPPlotSymbolTypeCross,
	CPPlotSymbolTypePlus,
	CPPlotSymbolTypeDash,
	CPPlotSymbolTypeSnow
} CPPlotSymbolType;


@interface CPPlotSymbol : NSObject <NSCopying> {
	@private
	CGSize size;
	CPPlotSymbolType symbolType;
	CPLineStyle *lineStyle;
	CPFill *fill;
}

@property (assign) CGSize size;
@property (assign) CPPlotSymbolType symbolType;
@property (retain) CPLineStyle *lineStyle;
@property (retain) CPFill *fill;

+(CPPlotSymbol *)crossPlotSymbol;
+(CPPlotSymbol *)ellipsePlotSymbol;
+(CPPlotSymbol *)rectanglePlotSymbol;
+(CPPlotSymbol *)plusPlotSymbol;
+(CPPlotSymbol *)starPlotSymbol;
+(CPPlotSymbol *)diamondPlotSymbol;
+(CPPlotSymbol *)trianglePlotSymbol;
+(CPPlotSymbol *)pentagonPlotSymbol;
+(CPPlotSymbol *)hexagonPlotSymbol;
+(CPPlotSymbol *)dashPlotSymbol;
+(CPPlotSymbol *)snowPlotSymbol;
//+(CPPlotSymbol *)plotSymbolWithString:(NSString *)aString;

-(id)copyWithZone:(NSZone *)zone;
-(void)renderInContext:(CGContextRef)theContext atPoint:(CGPoint)center;

@end
