//
//  File.swift
//  
//
//  Created by Dominik Butz on 18/8/2022.
//

import Foundation
import SwiftUI

public struct DYLineSettings {
    var lineColor: Color
    var lineStrokeStyle:  StrokeStyle
    var lineDropShadow: Shadow?
    var showAppearAnimation: Bool
    var lineAnimationDuration: TimeInterval

    var selectorLineWidth: CGFloat
    var selectorLineColor: Color
    
    var interpolationType: InterpolationType
    
    var allowUserInteraction: Bool
    
    var lineAreaGradient: LinearGradient?
    var lineAreaGradientDropShadow: Shadow?
    
    var labelViewOffset: CGSize
    
    var xValueSelectedDataPointLineColor: Color?
    var xValueSelectedDataPointLineStrokeStyle: StrokeStyle
    
    var yValueSelectedDataPointLineColor: Color?
    var yValueSelectedDataPointLineStrokeStyle: StrokeStyle
   
    
    /// Description
    /// - Parameters:
    ///   - lineColor: The color of the line graph.
    ///   - lineStrokeStyle: The stroke style of the line graph.
    ///   - lineDropShadow: A drop shadow displayed underneath the line. Default value is nil.
    ///   - showAppearAnimation:  If set to true, the line will be drawn from left to right when the view appears, otherwise it will appear instantly. Default value is true. 
    ///   - lineAnimationDuration:  the duration in seconds during which the line is drawn when the view appears.
    ///   - selectorLineWidth: width of the selector line (appears when user drags on the grid).
    ///   - selectorLineColor: color of the selector line.
    ///   - interpolationType: Determines if the paths between the points are drawn by linear interpolation or by a quad-curve. Default value is quad-curve (rounded).
    ///   - allowUserInteraction: Determines if swiping horizontally over the chart will make the selector move along the line from point to point. Default value is true.
    ///   - lineAreaGradient: Linear gradient area underneath the line. Turns the line mark into an area mark.
    ///   - lineAreaGradientDropShadow: A drop shadow displayed underneath the line area gradient. Default value is nil.
    ///   - labelViewOffset: In case a label view is returned in the line chart labelView closure, this value determines the offset of the label view relative to the data point. Default is (0, -12)
    ///   - xValueSelectedDataPointLineColor:  Color of a vertical marker line drawn from the currently selected data point to the x-axis. Default value is orange. If set to nil, no marker line will be shown.
    ///   - xValueSelectedDataPointLineStrokeStyle: Stroke style of a vertical marker line drawn from the currently selected data point to the x-axis.
    ///   - yValueSelectedDataPointLineColor: Color of a horizontal marker line drawn from the currently selected data point to the y-axis. Default value is orange. If set to nil, no marker line will be shown.
    ///   - yValueSelectedDataPointLineStrokeStyle: Stroke style of a horizontal marker line drawn from the currently selected data point to the y-axis.
    public init(lineColor: Color = .orange, lineStrokeStyle: StrokeStyle = StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, miterLimit: 80, dash: [], dashPhase: 0), lineDropShadow: Shadow? = nil, showAppearAnimation: Bool = true, lineAnimationDuration: TimeInterval = 1.4, selectorLineWidth: CGFloat = 2, selectorLineColor: Color = .orange, interpolationType: InterpolationType = .quadCurve, allowUserInteraction: Bool = true, lineAreaGradient: LinearGradient? = LinearGradient(gradient: Gradient(colors: [Color.orange, .white]), startPoint: .top, endPoint: .bottom), lineAreaGradientDropShadow: Shadow? = nil, labelViewOffset: CGSize = CGSize(width: 0, height: -12), xValueSelectedDataPointLineColor:Color = Color.orange,   xValueSelectedDataPointLineStrokeStyle: StrokeStyle = StrokeStyle(lineWidth: 2, dash: [3]),  yValueSelectedDataPointLineColor: Color = .orange, yValueSelectedDataPointLineStrokeStyle: StrokeStyle = StrokeStyle(lineWidth: 2, dash: [3])) {
        self.lineColor = lineColor
        self.lineStrokeStyle = lineStrokeStyle
        self.lineDropShadow = lineDropShadow
        self.showAppearAnimation = showAppearAnimation
        self.lineAnimationDuration = lineAnimationDuration
        self.selectorLineWidth = selectorLineWidth
        self.selectorLineColor = selectorLineColor
        self.interpolationType = interpolationType
        self.allowUserInteraction = allowUserInteraction
        self.lineAreaGradient = lineAreaGradient
        self.lineAreaGradientDropShadow = lineAreaGradientDropShadow
        self.labelViewOffset = labelViewOffset
        self.xValueSelectedDataPointLineColor = xValueSelectedDataPointLineColor
        self.yValueSelectedDataPointLineColor = yValueSelectedDataPointLineColor
        self.yValueSelectedDataPointLineStrokeStyle = yValueSelectedDataPointLineStrokeStyle
        self.xValueSelectedDataPointLineStrokeStyle = xValueSelectedDataPointLineStrokeStyle
    }
    
    
}
