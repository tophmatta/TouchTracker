//
//  DrawView.swift
//  TouchTracker
//
//  Created by Toph on 2/8/17.
//  Copyright © 2017 Toph. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate {
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var moveRecognizer: UIPanGestureRecognizer!
    var longPressRecognizer: UILongPressGestureRecognizer!
    
    var selectedLineIndex: Int? {
        
        didSet {
            
            if selectedLineIndex == nil {
                
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
                
            }
            
        }
        
    }

    
    var finishedLineColor: (purple: UIColor, cyan: UIColor) = (UIColor.purple, UIColor.cyan) {
        
        didSet {
            
            setNeedsDisplay()
            
        }
        
    }
    
    
    var currentLineColor: UIColor = UIColor.red {
        
        didSet {
            
            setNeedsDisplay()
            
        }
        
    }
    
    var lineThickness: CGFloat = 10 {
        
        didSet {
            
            setNeedsDisplay()
            
        }
        
    }
    
    var currentLineThickness: CGFloat = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        addGestureRecognizer(longPressRecognizer)
        
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveLine))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
        
    }
    
    
    func longPress(gestureRecognizer: UIGestureRecognizer) {
        
        print("Recongized a long press")
        
        if gestureRecognizer.state == .began {
            
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLineAtPoint(point)
            
            if selectedLineIndex != nil {
                
                currentLines.removeAll(keepingCapacity: false)
                
            }
            
            else if gestureRecognizer.state == .ended {
                
                selectedLineIndex = nil
                
            }
            
            setNeedsDisplay()
        }
        
    }
    
    func tap(gestureRecognizer: UIGestureRecognizer) {
        
        print("Recognized a tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLineAtPoint(point)
        
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            
            // Make DrawView the target of menu item action messages
            becomeFirstResponder()
            
            // Create a new "delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteLine))
            
            menu.menuItems = [deleteItem]
            
            // Tell the menu where it should come from and show it
            menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), in: self)
            
            menu.setMenuVisible(true, animated: true)
            
        }
        
        else {
            
            // Hide the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
            
        }
        
        setNeedsDisplay()
    }
    
    func doubleTap(gestureRecognizer: UITapGestureRecognizer) {
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        
        currentLines.removeAll(keepingCapacity: false)
        finishedLines.removeAll(keepingCapacity: false)
        
        setNeedsDisplay()
        
        
    }
    
    
    func strokeLine(_ line: Line) {
        
        let path = UIBezierPath()
        path.lineWidth = line.thickness
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
        
    }
    
    override func draw(_ rect: CGRect) {
        
        currentLineColor.setStroke()
        
        
        for (_, line) in currentLines {
            
            strokeLine(line)
            
        }
        
        for line in finishedLines {
            
            let angle = calculateAngleBetween(line.begin, andEndLinePoint: line.end)
            
            if angle >= 0 {
                
                finishedLineColor.purple.setStroke()
                
            }
                
            else {
                
                finishedLineColor.cyan.setStroke()
                
            }
            
            strokeLine(line)
            
            setNeedsDisplay()
        }
        
        
        if let index = selectedLineIndex {
            
            UIColor.green.setStroke()
            
            let selectedLine = finishedLines[index]
            strokeLine(selectedLine)
            
        }
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            
            let location = touch.location(in: self)
            
            let newLine = Line(begin: location, end: location, thickness: lineThickness)
            
            let key = NSValue(nonretainedObject: touch)
            
            currentLines[key] = newLine
            
        }
        
        setNeedsDisplay()
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            
            let key = NSValue(nonretainedObject: touch)
            
            currentLines[key]?.end = touch.location(in: self)
            currentLines[key]?.thickness = currentLineThickness
            
        }
        
        
        setNeedsDisplay()
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            
            let key = NSValue(nonretainedObject: touch)
            
            if var line = currentLines[key] {
                
                line.end = touch.location(in: self)
                
                finishedLines.append(line)
                currentLines.removeValue(forKey: key)
                
            }
            
        }
        
        currentLineThickness = 0
        
        setNeedsDisplay()
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        currentLines.removeAll()
        
        currentLineThickness = 0
        
        setNeedsDisplay()
        
    }
    
    override var canBecomeFirstResponder: Bool {
        
        return true
        
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        return true
        
    }
    
    func calculateAngleBetween(_ beginLinePoint: CGPoint, andEndLinePoint endLinePoint: CGPoint) -> CGFloat {
        
        
        let xDelta = beginLinePoint.x - endLinePoint.x
        let yDelta = beginLinePoint.y - endLinePoint.y
        
        let deltaDivided = yDelta/xDelta
        
        let angleInRadians = atan(deltaDivided)
        let angleInDegrees = angleInRadians * (180/CGFloat.pi)
                
        return angleInDegrees
        
        
    }
    
    func indexOfLineAtPoint(_ point: CGPoint) -> Int? {
        
        // Find a line close to point
        
        for (index, line) in finishedLines.enumerated() {
            
            let begin = line.begin
            let end = line.end
            
            // Check a few points on the line
            for t in stride(from: 0, to: 1.0, by: 0.05) {
                
                let x = begin.x + ((end.x - begin.x) * CGFloat(t))
                let y = begin.y + ((end.y - begin.y) * CGFloat(t))
                
                // If the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    
                    return index
                    
                }
                
            }
            
        }
        
        // If nothing is close enough to the tapped point, then we did not select a line
        return nil
        
    }
    
    func deleteLine(sender: AnyObject) {
        
        // Remove the selected line from the list of finishedLines
        if let index = selectedLineIndex {
            
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            // Redraw everything
            setNeedsDisplay()
            
        }
        
    }
    
    
    func moveLine(gestureRecognizer: UIPanGestureRecognizer) {
        
        // Retrive velocity in view and map it to thickness offset
        let velocityInView = gestureRecognizer.velocity(in: self)
        let thicknessOffset = CGFloat(((velocityInView.x > 0 ? velocityInView.x : -velocityInView.x) + (velocityInView.y > 0 ? velocityInView.y : -velocityInView.y))/100)
        
        // Update current line thickness only if new value is greater than old one
        currentLineThickness = currentLineThickness > lineThickness + thicknessOffset ? currentLineThickness : lineThickness + thicknessOffset
        
        // If there is no long press gesture currently recognized, don't move selected line around
        if longPressRecognizer.state != .changed {
            
            print("no action taken")
            
            return
            
        }
        
        // If line is selected...
        if let index = selectedLineIndex {
            
            // When the pan recognizer changes its position...
            if gestureRecognizer.state == .changed {
                
                // How far has the pan moved?
                let translation = gestureRecognizer.translation(in: self)
                
                // Add the translation to the current beginning and end points of the line
                finishedLines[index].begin.x += translation.x
                finishedLines[index].begin.y += translation.y
                finishedLines[index].end.x += translation.x
                finishedLines[index].end.y += translation.y
                
                gestureRecognizer.setTranslation(CGPoint.zero, in: self)
                
                // Redraw the screen
                setNeedsDisplay()
                
            }
            
            else if gestureRecognizer.state == .ended {
                
                print("ended")
                
                selectedLineIndex = nil
                currentLines.removeAll(keepingCapacity: false)
                
            }
        }
        else {
            
            // If no line is selected, do not do anything
            return
            
        }
        
    }
    
}
