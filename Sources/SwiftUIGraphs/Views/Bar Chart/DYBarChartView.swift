//
//  DYStackedBarChartView.swift
//  
//
//  Created by Dominik Butz on 2/9/2022.
//

import SwiftUI

public struct DYBarChartView: View, PlotAreaChart {

    var barDataSets: [DYBarDataSet]
    var settings: DYBarChartSettings
    var yAxisSettings: YAxisSettings
    var xAxisSettings: XAxisSettings
    var yAxisScaler: AxisScaler
    var yAxisValueAsString: (Double)->String
    #if os(iOS)
    let generator = UISelectionFeedbackGenerator()
    #endif
    var markerLines: [MarkerLine] = []
    @Binding private var selectedBarDataSet: DYBarDataSet?
    @State var showBars: Bool = false

    /// DYBarChartView Initializer
    /// - Parameters:
    ///   - barDataSets: an array of bar data sets, each of which holds the data for one bar.
    ///   - selectedBarDataSet: the bar data set that corresponds to the user's selection (by tapping).
    public init(barDataSets: [DYBarDataSet], selectedBarDataSet: Binding<DYBarDataSet?>) {
        self.settings = DYBarChartSettings()
        self.xAxisSettings = DYBarChartXAxisSettings()
        self.yAxisSettings = YAxisSettings()
        self.barDataSets = barDataSets
        self._selectedBarDataSet = selectedBarDataSet
        self.yAxisValueAsString = {yValue in yValue.toDecimalString(maxFractionDigits: 0)}

        // 初始化scaler时确保有有效值
        let minValue = barDataSets.map({$0.negativeYValue}).min() ?? 0
        let maxValue = barDataSets.map({$0.positiveYValue}).max() ?? 0
        self.yAxisScaler = AxisScaler(min: minValue, max: max(maxValue, 0.1), maxTicks: 10)
    }

    public var body: some View {
        GeometryReader { geo in
            if self.barDataSets.count >= 1 {
                VStack(spacing: 0) {
                    HStack(spacing:0) {
                        if self.yAxisSettings.showYAxis && yAxisSettings.yAxisPosition == .leading {
                            self.yAxisView(yValueAsString: self.yAxisValueAsString)
                        }

                        ZStack {
                            if self.yAxisSettings.showYAxisGridLines {
                                self.yAxisGridLinesView()
                            }

                            ForEach(markerLines) { markerLine in
                                self.markerLineView(markerLine: markerLine).clipped()
                            }

                            self.bars(totalSize: geo.size)
                        }
                        .frame(width: self.plotAreaFrameWidth(proxy: geo))
                        .background(settings.plotAreaBackgroundGradient)

                        if self.yAxisSettings.showYAxis && yAxisSettings.yAxisPosition == .trailing {
                            self.yAxisView(yValueAsString: self.yAxisValueAsString, yAxisPosition: .trailing)
                        }
                    }

                    if self.xAxisSettings.showXAxis {
                        self.xAxisView().frame(maxHeight: xAxisSettings.xAxisViewHeight)
                    }
                }
            } else {
                self.placeholderGrid(xAxisLineCount: 12, yAxisLineCount: 10)
                    .opacity(0.5)
                    .padding()
                    .transition(AnyTransition.opacity)
            }
        }
        #if os(iOS)
        .onAppear {
            self.generator.prepare()
        }
        #endif
    }

    private func bars(totalSize: CGSize) -> some View {
        GeometryReader { proxy in
            let totalHeight = max(proxy.size.height, 0.1) // 防止高度为0
            let totalWidth = max(proxy.size.width, 0.1)   // 防止宽度为0
            let barWidth = self.barWidth(totalWidth: totalWidth)
            let yMinMax = self.yAxisScaler.axisMinMax
            let yRange = max(yMinMax.max - yMinMax.min, 0.1) // 防止范围为0

            ForEach(barDataSets) { dataSet in
                if let index = self.indexFor(dataSet: dataSet) {
                    let positiveBarHeight = (dataSet.positiveYValue / yRange) * totalHeight
                    let negativeBarHeight = (abs(dataSet.negativeYValue) / yRange) * totalHeight

                    let positiveBarYOrigin = totalHeight - max(0, yMinMax.min)
                        .convertToCoordinate(min: yMinMax.min, max: yMinMax.max, length: totalHeight)
                    let negativeBarYOrigin = totalHeight - min(0, yMinMax.max)
                        .convertToCoordinate(min: yMinMax.min, max: yMinMax.max, length: totalHeight)

                    let positiveBarYPosition = positiveBarYOrigin - positiveBarHeight / 2
                    let negativeBarYPosition = negativeBarYOrigin + negativeBarHeight / 2

                    let totalBarHeight = positiveBarHeight + negativeBarHeight
                    let yPosition = totalBarHeight > 0 ?
                        ((positiveBarHeight / totalBarHeight) * positiveBarYPosition +
                         (negativeBarHeight / totalBarHeight) * negativeBarYPosition) :
                        positiveBarYOrigin

                    BarViewPair(
                        dataSet: dataSet,
                        index: index,
                        selectedBarDataSet: self.$selectedBarDataSet,
                        dataSetCount: self.barDataSets.count,
                        totalHeight: totalHeight,
                        barWidth: barWidth,
                        positiveBarYPosition: positiveBarYPosition,
                        negativeBarYPosition: negativeBarYPosition,
                        settings: settings,
                        yAxisScaler: yAxisScaler
                    )
                    .position(
                        x: self.convertToXCoordinate(index: index, totalWidth: totalWidth),
                        y: yPosition
                    )
                    .onTapGesture {
                        guard self.settings.allowUserInteraction else { return }
                        #if os(iOS)
                        self.generator.selectionChanged()
                        #endif
                        withAnimation {
                            self.selectedBarDataSet = self.selectedBarDataSet == dataSet ? nil : dataSet
                        }
                    }
                }
            }
        }
    }

    private func barYPosition(barHeight: CGFloat, totalHeight: CGFloat, originY: CGFloat, valueNegative: Bool)->CGFloat {
        let halfBarHeight = valueNegative ? -barHeight / 2 : +barHeight / 2
        return originY - halfBarHeight
   
    }
    
    private func xAxisView()-> some View {
        GeometryReader { proxy in
            let totalWidth = proxy.size.width
            
            ZStack(alignment: .center) {
                
                let labels = self.xAxisLabelStrings()
                let labelSteps = self.xAxisLabelSteps(totalWidth: totalWidth)
                
                ForEach(labels, id:\.self) { label in
                    let i = self.indexFor(labelString: label)
                    if  i % labelSteps == 0 {
                        self.xAxisIntervalLabelViewFor(label: label, index: i, totalWidth: totalWidth)
                    }
                    
                }
            }
        }
        .padding(.leading, yAxisSettings.showYAxis && yAxisSettings.yAxisPosition == .leading ?  yAxisSettings.yAxisViewWidth : 0)
       // .padding(.leading, settings.lateralPadding.leading )
        .padding(.trailing, yAxisSettings.showYAxis && yAxisSettings.yAxisPosition == .trailing ? yAxisSettings.yAxisViewWidth : 0)

    }
    
    private func xAxisIntervalLabelViewFor(label: String, index: Int, totalWidth: CGFloat)-> some View {
        Text(label).font(Font(self.xAxisSettings.labelFont)).lineLimit(2).position(x: self.convertToXCoordinate(index: index, totalWidth: totalWidth), y: 10)
    }
    
    
    //MARK: Marker line

    func markerLineView(markerLine: MarkerLine)-> some View {
        
        GeometryReader { geo in
            let height = geo.size.height
            let width = geo.size.width
            let minY = self.yAxisScaler.axisMinMax.min
            let maxY = self.yAxisScaler.axisMinMax.max
            
            Path { p in
          
                let startPointY = height - markerLine.coordinate.convertToCoordinate(min: minY, max: maxY, length: height)
                let endPointY = height - markerLine.coordinate.convertToCoordinate(min: minY, max: maxY, length: height)
                
                p.move(to: CGPoint(x: 0, y: startPointY))
                p.addLine(to: CGPoint(x: width, y: endPointY))
                p.closeSubpath()
                
            }.stroke(style: markerLine.strokeStyle)
            .foregroundColor(markerLine.color)
            
        }
        
        
    }
    
    // MARK: Helper Funcs
    
    private func barWidth(totalWidth: CGFloat) -> CGFloat {
        return max((totalWidth / 2) / CGFloat(max(self.barDataSets.count, 1)), 0.1)
    }

    public func xAxisLabelStrings()->[String] {
        return self.barDataSets.map({$0.xAxisLabel})
    }
    
   private func indexFor(labelString:String)->Int {
       return self.xAxisLabelStrings().firstIndex(where: {$0 == labelString}) ?? 0
   }
    
    private func indexFor(dataSet: DYBarDataSet) -> Int? {
        return self.barDataSets.firstIndex(where: {$0.id == dataSet.id})
    }

    private func convertToXCoordinate(index: Int, totalWidth: CGFloat) -> CGFloat {
        let barWidth = self.barWidth(totalWidth: totalWidth)
        let barCount = CGFloat(max(self.barDataSets.count, 1))
        let spacerWidth = (totalWidth - barWidth * barCount) / CGFloat(barCount + 1)
        return spacerWidth + barWidth / 2.0 + CGFloat(index) * (spacerWidth + barWidth)
    }
}

internal struct BarViewPair: View {

    let dataSet: DYBarDataSet
    let index: Int
    @Binding var selectedBarDataSet: DYBarDataSet?
    var dataSetCount: Int
    let totalHeight: CGFloat
    let barWidth: CGFloat
    let positiveBarYPosition: CGFloat
    let negativeBarYPosition: CGFloat
    let settings: DYBarChartSettings
    var yAxisScaler: AxisScaler
    @State var selectionScale: CGFloat = 1
    @State var showSelectionBorder: Bool = false
    
    var body: some View {
        let yMinMax = self.yAxisScaler.axisMinMax
        let positiveBarHeight =  dataSet.positiveYValue / (yMinMax.max - yMinMax.min) * totalHeight
        let negativeBarHeight = abs(dataSet.negativeYValue) / (yMinMax.max - yMinMax.min) * totalHeight

        let shouldShowPositiveLabel: Bool = positiveBarYPosition - positiveBarHeight / 2 + settings.labelViewOffset.height  > settings.minimumTopEdgeBarLabelMargin
        let shouldShowNegativeLabel = negativeBarYPosition + negativeBarHeight / 2 - settings.labelViewOffset.height < totalHeight - settings.minimumBottomEdgeBarLabelMargin
        let totalBarHeight = positiveBarHeight + negativeBarHeight
//        let barsYPosition = (positiveBarHeight / totalBarHeight) * positiveBarYPosition + (negativeBarHeight / totalBarHeight) * negativeBarYPosition
        let shadow = dataSet == selectedBarDataSet ? settings.selectedBarDropShadow ?? settings.barDropShadow : settings.barDropShadow

        VStack(spacing: 0) {
            // positive bar
           
            if positiveBarHeight > 0 {
                //Spacer(minLength: 0)
                StackedBarView(fractions: dataSet.positiveFractions, width: barWidth, height: positiveBarHeight, index: index, yAxisScaler: yAxisScaler, labelView: shouldShowPositiveLabel ?  dataSet.labelView?(dataSet.positiveYValue) : nil, labelViewOffset: settings.labelViewOffset, shouldAnimate: settings.showAppearAnimation)
                
            }
            
            // negative bar
            if negativeBarHeight > 0 {
                StackedBarView(fractions: dataSet.negativeFractions, width: barWidth, height: negativeBarHeight, index: index, yAxisScaler: yAxisScaler, labelView: shouldShowNegativeLabel ?  dataSet.labelView?(dataSet.negativeYValue) : nil, labelViewOffset: settings.labelViewOffset, shouldAnimate: settings.showAppearAnimation)
               // Spacer(minLength: 0)
            }
            
            
        }
        .frame(width: barWidth, height: totalBarHeight)
        .overlay( // selected bar border
            self.selectionBorder
        )
        .scaleEffect(self.selectionScale, anchor: scaleEffectAnchor)
        .shadow(color: shadow?.color ?? .clear, radius:  shadow?.radius ?? 0, x:  shadow?.x ?? 0, y: shadow?.y ?? 0)
        .onChange(of: self.selectedBarDataSet, perform: { newValue in
            if let selectedBarSet = newValue, selectedBarSet == dataSet {
                withAnimation(Animation.spring()) {
                    self.selectionScale = 1.08
                }
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(Animation.spring()) {
                        self.selectionScale = 1
                    }
                }
            }
        }).onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 * TimeInterval( self.dataSetCount)) {
                withAnimation {
                    self.showSelectionBorder = true
                }
            }
        }
   
    }
    
    var selectionBorder: some View {
        Group {
            if self.showSelectionBorder {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(dataSet == selectedBarDataSet ? settings.selectedBarBorderColor : .clear, lineWidth: max(1, min(self.barWidth * 0.1, 3)))
                    .animation(.easeInOut, value: selectedBarDataSet)
            }
        }
    }
    
    var scaleEffectAnchor: UnitPoint {
        if dataSet.positiveYValue > 0 && dataSet.negativeYValue > 0 {
            return .center
        } else if dataSet.positiveYValue > 0 {
            return .bottom
        } else if dataSet.negativeYValue < 0 {
            return .top
        }
   
        return .center
    }
    
}

internal struct StackedBarView: View {
    
    let fractions: [DYBarDataFraction]
    let width: CGFloat
    let height: CGFloat
    let index: Int
    //@Binding var selectedIndex: Int?
    var yAxisScaler: AxisScaler
    var labelView: AnyView?
    let labelViewOffset: CGSize
    let shouldAnimate: Bool

    @State private var barHeightFactor: CGFloat = 0
    @State private var showLabelView: Bool = false
    
    var body: some View {
        
        ZStack {

            VStack(spacing: 0) {
                ForEach(fractions) { fraction in
                    let fractionHeight = abs(fraction.value) /  abs(valueSum) * height
                    Rectangle().fill(fraction.gradient)
                        .frame(height: fractionHeight)
                        .overlay(barHeightFactor == 1 || shouldAnimate == false ?  MaxSizeOptionalView(maxSize: CGSize(width: self.width, height: fractionHeight - 3), view: fraction.labelView?()) : nil)
                        
                }
            }
            .frame(width: width, height: height)
            .clipShape(RoundedCornerRectangle(tl: 5, tr: 5, bl: 0, br: 0).rotation(Angle(degrees: valueSum > 0 ? 0 : 180)))
            .scaleEffect(x: 1,  y: shouldAnimate ?  self.barHeightFactor : 1, anchor: valueSum >= 0 ? .bottom : .top)
            .overlay(self.labelOverlay())

        }
        .onAppear {
            if shouldAnimate {
                withAnimation(Animation.default.delay(0.1 * Double(index))) {
                    self.barHeightFactor = 1
                }
            }
            
            if let _ = self.labelView, shouldAnimate {
                withAnimation(Animation.default.delay(0.11 * Double(index))) {
                    self.showLabelView = true
                }
            }
        }
    }

    
    func labelOverlay()-> some View {
        Group {
            if let labelView = labelView, (showLabelView || shouldAnimate == false) {
                 labelView
                    .fixedSize()
                    .offset(x: barLabelTotalOffset.width, y: barLabelTotalOffset.height).transition(.opacity)
            }
        }
    }
    
    var valueSum: CGFloat {
        return fractions.map({$0.value}).reduce(0, +)
    }
    
    var barLabelTotalOffset: CGSize {

        let heightOffset: CGFloat = valueSum > 0 ?  -height / 2 + labelViewOffset.height : height / 2 - labelViewOffset.height
       
        return CGSize(width: labelViewOffset.width, height: heightOffset)

    }

}

public extension View where Self == DYBarChartView {
    
    /// background of the plot area
    /// - Parameter gradient: a linear gradient. Default is system background color.
    /// - Returns: modified DYBarChartView
    func background(gradient: LinearGradient)->DYBarChartView {
       var modView = self
        modView.settings.plotAreaBackgroundGradient = gradient
        return modView
        
    }
    
    /// userInteraction
    /// - Parameter enabled: if set to true, the user can interact with the chart by tapping each bar
    /// - Returns: modified DYBarChartView
    func userInteraction(enabled: Bool = true)->DYBarChartView  {
        var modView = self
        modView.settings.allowUserInteraction = enabled
        return modView
    }
    
    
    /// animation
    /// - Parameter showAppearAnimation: determines if bars should "grow" out of the 0 marker one by one. If set to false, all bars will be visible at once when the view appears. Default is true.
    /// - Returns: modified DYBarChartView
    func animation(_ showAppearAnimation: Bool)->DYBarChartView {
        var modView = self
        modView.settings.showAppearAnimation = showAppearAnimation
        return modView
    }
    
    
    /// barDropShadow
    /// - Parameter shadow: add a shadow under each bar
    /// - Returns: modified DYBarChartView
    func barDropShadow(_ shadow: Shadow)->DYBarChartView  {
        var modView = self
        modView.settings.barDropShadow = shadow
        return modView
    }
    
    
    /// labelViewOffset of the stacked bar top and bottom label
    /// - Parameter offset: offset relative to the top and bottom edge of the stacked bar. default is width 0 and height -10. The height offset is multiplied by -1 in case there the sum of the negative fraction values is < 0.
    /// - Returns: modified DYBarChartView
    func labelViewOffset( _ offset: CGSize)->DYBarChartView  {
        var modView = self
        modView.settings.labelViewOffset = offset
        return modView
        
    }
    
    /// selectedBar: settings for the selected bar.
    /// - Parameters:
    ///   - borderColor: border color of the selected bar. Default is yellow.
    ///   - dropShadow: drop shadow of the selected bar. default is nil (= no different drop shadow under the selected bar )
    /// - Returns: modified DYBarChartView
    func selectedBar(borderColor: Color, dropShadow: Shadow? = nil)->DYBarChartView {
        var modView = self
        modView.settings.selectedBarBorderColor = borderColor
        modView.settings.selectedBarDropShadow = dropShadow
        return modView
    }
    
    
    /// bar label minimum edge margin - if top / bottom distance of a given text label is lower, the label will not be displayed
    /// - Parameters:
    ///   - top: top minimum edge margin
    ///   - bottom: bottom minimum edge margin
    /// - Returns: modified DYBarChartView
    func barLabelMinimumEdgeMargin(top: CGFloat = 0, bottom: CGFloat = 10)->DYBarChartView {
        var modView = self
        modView.settings.minimumTopEdgeBarLabelMargin = top
        modView.settings.minimumBottomEdgeBarLabelMargin = bottom
        return modView
    }
    
//MARK: x-Axis Settings
    
    /// showXaxis
    /// - Parameter show: determines if the x-axis view should be visible. Default is true.
    /// - Returns: modified DYBarChartView
    func showXaxis(_ show: Bool)->DYBarChartView {
        var modView = self
        modView.xAxisSettings.showXAxis = show
        return modView
    }
    
    /// xAxisViewHeight
    /// - Parameter height: the height of the x-axis view. default is 20.
    /// - Returns: modified  DYBarChartView
    func xAxisViewHeight(_ height: CGFloat)->DYBarChartView {
        var modView = self
        modView.xAxisSettings.xAxisViewHeight = height
        return modView
    }
    
    #if os(macOS)
    /// xAxisLabelFont - font for all x-axis bar labels
    /// - Parameter font: An NSFont
    /// - Returns: modified DYBarChartView
    func xAxisLabelFont(_ font: NSFont)->DYBarChartView {
        var modView = self
        modView.xAxisSettings.labelFont = font
        return modView
        
    }
    
    #else
    /// xAxisLabelFont - font for all x-axis bar labels
    /// - Parameter font: A UIFont
    /// - Returns: modified DYBarChartView
    func xAxisLabelFont(_ font: UIFont)->DYBarChartView {
        var modView = self
        modView.xAxisSettings.labelFont = font
        return modView
        
    }
    #endif

    
//MARK: y-Axis Settings
    
    /// showYaxis
    /// - Parameter show:  determines if the y-axis view should be visible. Default is true.
    /// - Returns: modified DYBarChartView
    func showYaxis(_ show: Bool)->DYBarChartView {
        var modView = self
        modView.yAxisSettings.showYAxis = show
        return modView
    }

    
    /// yAxisPosition
    /// - Parameter position: .leading or .trailing. Default is .leading.
    /// - Returns: modified DYBarChartView
    func yAxisPosition(_ position: Edge.Set)->DYBarChartView  {
        var modView = self
        modView.yAxisSettings.yAxisPosition = position
        return modView
    }

    /// yAxisViewWidth
    /// - Parameter width: the width of the y-axis view. default is 35.
    /// - Returns:  modified DYBarChartView
    func yAxisViewWidth(_ height: CGFloat)->DYBarChartView  {
        var modView = self
        modView.yAxisSettings.yAxisViewWidth = height
        return modView
    }
    
    
    /// yAxisStringValue
    /// - Parameter stringValue: a closure to format y-Axis label strings depending on the number value. Default is a format as integer string (no fraction digits)
    /// - Returns: modified DYBarChartView
    func yAxisLabelStringValue(_ stringValue: @escaping (Double)->String)->DYBarChartView {
        var modView = self
        modView.yAxisValueAsString = stringValue
        return modView
    }
    
    #if os(macOS)
    /// yAxisLabelFont - font for all y-axis tick labels
    /// - Parameter font: An NSFont
    /// - Returns: modified DYBarChartView
    func yAxisLabelFont(_ font: NSFont)->DYBarChartView {
        var modView = self
        modView.yAxisSettings.labelFont = font
        return modView
        
    }
    #else
    /// yAxisLabelFont - font for all y-axis tick labels
    /// - Parameter font: A UIFont
    /// - Returns: modified DYBarChartView
    func yAxisLabelFont(_ font: UIFont)->DYBarChartView {
        var modView = self
        modView.yAxisSettings.labelFont = font
        return modView
        
    }
    #endif
    


    
    /// yAxisGridLines: horizontal grid lines
    /// - Parameters:
    ///   - showGridLines: show the horizontal grid lines
    ///   - gridLineColor: horizontal grid line color
    ///   - gridLineStrokeStyle: vertical grid line stroke style
    ///   - zeroGridLineColor: color of the 0-grid line. default nil: no separate zero grid line
    ///   - zeroGridLineStrokeStyle: stroke style of the 0-grid line. default nil.
    /// - Returns: modified DYBarChartView
    func yAxisGridLines(showGridLines: Bool = true, gridLineColor: Color = Color.secondary.opacity(0.5), gridLineStrokeStyle: StrokeStyle = StrokeStyle(lineWidth: 1, dash: [3]))->DYBarChartView  {
        var modView = self
        var yAxisSettings = modView.yAxisSettings
        yAxisSettings.showYAxisGridLines = showGridLines
        yAxisSettings.yAxisGridLineColor = gridLineColor
        yAxisSettings.yAxisGridLinesStrokeStyle = gridLineStrokeStyle
        modView.yAxisSettings = yAxisSettings
        return modView 
        
    }
    
    /// markerGridLine: Additional grid line e.g. to mark a y-target-value.
    /// - Parameters:
    ///   - yCoordinate: y-coordinate of the grid line
    ///   - color: color of the marker grid line
    ///   - strokeStyle: stroke style of the marker grid line
    /// - Returns: modified DYLineChartView
    func markerGridLine(yCoordinate: Double, color: Color, strokeStyle: StrokeStyle = StrokeStyle(lineWidth: 1, dash: [3]))->DYBarChartView {
        let markerLine = MarkerLine(coordinate: yCoordinate, color: color, strokeStyle: strokeStyle, orientation: .horizontal)
        var modView = self
        modView.markerLines.append(markerLine)
        return modView
        
    }
    
    
    func yAxisScalerOverride(minMax: (min:Double?, max:Double?)? = nil, interval: Double? = nil, maxTicks: Int = 10) ->DYBarChartView   {
            var modView  = self
            modView.yAxisSettings.yAxisMinMaxOverride = minMax
            modView.yAxisSettings.yAxisIntervalOverride = interval
            modView.configureYAxisScaler(min: modView.barDataSets.map({$0.negativeYValue}).min() ?? 0, max: modView.barDataSets.map({$0.positiveYValue}).max() ?? 0, maxTicks: maxTicks)
            return modView
    
    }

    
    
}





//struct DYStackedBarChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        DYStackedBarChartView()
//    }
//}
