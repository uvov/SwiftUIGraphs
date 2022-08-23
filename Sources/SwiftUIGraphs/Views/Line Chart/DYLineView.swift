//
//  File.swift
//  
//
//  Created by Dominik Butz on 23/8/2022.
//

import Foundation
import SwiftUI


internal struct DYLineView: View, DataPointConversion {

    var lineDataSet: DYLineDataSet
    var yAxisSettings: YAxisSettingsNew
    var yAxisScaler: YAxisScaler
    @State private var selectedIndex: Int = 0
   // @Binding var userTouchingChart: Bool
    @Binding var touchingXPosition: CGFloat? // User Y touch location
    @Binding var selectorLineOffset: CGFloat
    
    @State private var lineEnd: CGFloat = 0 // for line animation
    @State private var showSupplementaryViews: Bool = false  // for supplementary views appear animation

    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                self.line()
                if let _ = self.lineDataSet.pointView, self.showSupplementaryViews {
                    self.points()
                }
                

                self.selectorView()
                
                
            }.onAppear {
               // self.selectedIndex = self.lineDataSet.selectedIndex
                self.showLine()
            }.onChange(of: self.touchingXPosition) { newValue in
      
                if newValue == nil {
                    let index = self.fractionIndexFor(xPosition: self.selectorLineOffset, geo: geo)
                    self.setSelected(index: index)
                    
                }
            }
        }
    }
    
    private func showLine() {

        guard self.lineDataSet.settings.showAppearAnimation  else {
            return
            
        }
        
        withAnimation(.easeIn(duration: self.lineDataSet.settings.lineAnimationDuration)) {
            self.lineEnd = 1
           // self.showLineSegments = true // for different color line segments
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + self.lineDataSet.settings.lineAnimationDuration) {
            withAnimation(.easeIn) {
                self.showSupplementaryViews = true
            }
        }
    }
    
    
    private func line()->some View {
      GeometryReader { geo in
        Group {
            if self.lineDataSet.dataPoints.count >= 2 {
                self.pathFor(width: geo.size.width, height: geo.size.height, closeShape: false)
                    .trim(from: 0, to: self.lineDataSet.settings.showAppearAnimation ? self.lineEnd : 1)
                    .stroke(style: self.lineDataSet.settings.lineStrokeStyle)
                    .foregroundColor(self.lineDataSet.settings.lineColor)
                    .shadow(color: self.lineDataSet.settings.lineDropShadow?.color ?? .clear, radius: self.lineDataSet.settings.lineDropShadow?.radius ?? 0, x:  self.lineDataSet.settings.lineDropShadow?.x ?? 0, y:  self.lineDataSet.settings.lineDropShadow?.y ?? 0)
            }
        }
      }
 
    }
    
    private func points()->some View {
      GeometryReader { geo in

         //   let yScale = self.yScaleFor(height: geo.size.height)
            let height = geo.size.height
            let width = geo.size.width
            let xMinMax = lineDataSet.xValuesMinMax
          ForEach(lineDataSet.dataPoints) { dataPoint in
              self.lineDataSet.pointView?(dataPoint)
                  .position(x: self.convertToCoordinate(value: dataPoint.xValue, min: xMinMax.min, max: xMinMax.max, length: width), y: height - self.convertToCoordinate(value: dataPoint.yValue, min: self.yAxisMinMax(settings: self.yAxisSettings).min, max: self.yAxisMinMax(settings: self.yAxisSettings).max, length: height))
              
            }
       }
        
    }
    
    private func selectorView()->some View {
        
        GeometryReader { geo in
            let xPosition = self.touchingXPosition == nil ? self.convertToCoordinate(value: self.lineDataSet.dataPoints[self.selectedIndex].xValue, min: self.lineDataSet.xValuesMinMax.min, max: self.lineDataSet.xValuesMinMax.max, length: geo.size.width) : self.selectorLineOffset
            let path = self.pathFor(width: geo.size.width, height: geo.size.height, closeShape: false)
            let yPosition = path.point(to: xPosition).y
            self.lineDataSet.selectorView
                .position(x: xPosition, y: yPosition)
                .animation(Animation.spring().speed(4))
                
        }
    }
    
    private func fractionIndexFor(xPosition: CGFloat, geo: GeometryProxy)->CGFloat {
        let convertedXValues = self.lineDataSet.dataPoints.map({convertToCoordinate(value: $0.xValue, min: self.lineDataSet.xValuesMinMax.min, max: self.lineDataSet.xValuesMinMax.max, length: geo.size.width)})
        for i in 0..<convertedXValues.count {
            let currentValue = convertedXValues[i]
            let lastValue = i > 0 ? convertedXValues[i - 1] : nil
            if xPosition == currentValue {
                return CGFloat(i)
            } else if let lastValue = lastValue, xPosition < currentValue, xPosition > lastValue {
                let normalizedFraction = Double.normalizationFactor(value: Double(xPosition), maxValue: Double(currentValue), minValue: Double(lastValue))
                 return CGFloat(i - 1) + CGFloat(normalizedFraction)
            }
        }

        
        return 0
    }
    
    private func setSelected(index: CGFloat) {
        if index.truncatingRemainder(dividingBy: 1) >= 0.5 && index < CGFloat(self.lineDataSet.dataPoints.count - 1) {
            self.selectedIndex = Int(index) + 1
        } else {
            self.selectedIndex = Int(index)
        }
    }
    
//    let index = self.fractionIndexFor(xPosition: xPos , geo: geo)

//    if index.truncatingRemainder(dividingBy: 1) >= 0.5 && index < CGFloat(self.dataPoints.count  - 1) {
//        self.selectedIndex = Int(index) + 1
//    } else {
//        self.selectedIndex = Int(index)
//    }
    
    
    //MARK: Path drawing
    
    func pathFor(width: CGFloat, height: CGFloat, closeShape: Bool)->Path {
        Path { path in

           path  = self.drawCompletePathWith(path: &path, height: height, width: width)

            // Finally close the subpath off by looping around to the beginning point.
            if closeShape {
                path.addLine(to: CGPoint(x: width, y: height))
                path.addLine(to: CGPoint(x: 0, y: height))
                path.closeSubpath()
            }
        }
    }
    
    func drawCompletePathWith(path: inout Path, height: CGFloat, width: CGFloat)->Path {
        
        guard let firstYValue = lineDataSet.dataPoints.first?.yValue else {return path}
        
        var point0 = CGPoint(x: 0, y: height - self.convertToCoordinate(value: firstYValue, min: self.yAxisMinMax(settings: self.yAxisSettings).min, max: self.yAxisMinMax(settings: self.yAxisSettings).max, length: height))
        path.move(to: point0)
        var index:Int = 0
        
        for _ in lineDataSet.dataPoints {
            if index != 0 {

                point0 = self.connectPointsWith(path: &path, index: index, point0: point0, height: height, width: width)
             
            }
            index += 1
            
        }
        
        return path
        
    }
    
    private func connectPointsWith(path: inout Path, index: Int, point0: CGPoint, height: CGFloat, width: CGFloat)->CGPoint {

        let mappedYValue = self.convertToCoordinate(value: lineDataSet.dataPoints[index].yValue, min: self.yAxisMinMax(settings: self.yAxisSettings).min, max: self.yAxisMinMax(settings: self.yAxisSettings).max, length: height)
        let xMinMax = lineDataSet.xValuesMinMax
        let mappedXValue = self.convertToCoordinate(value: lineDataSet.dataPoints[index].xValue, min: xMinMax.min, max: xMinMax.max, length: width)
        let point1 = CGPoint(x: mappedXValue, y: height - mappedYValue)
        if self.lineDataSet.settings.interpolationType == .quadCurve {
            let midPoint = CGPoint.midPointForPoints(p1: point0, p2: point1)
            path.addQuadCurve(to: midPoint, control: CGPoint.controlPointForPoints(p1: midPoint, p2: point0))
            path.addQuadCurve(to: point1, control: CGPoint.controlPointForPoints(p1: midPoint, p2: point1))
        }
        path.addLine(to: point1)
        return point1
    }

    
}


