//
//  RangeSelector.swift
//  Tuton
//
//  Created by Carl Goldsmith on 11/03/2016.
//  Copyright © 2016 Tuton. All rights reserved.
//

import Foundation
import UIKit

enum RangeSelectorType: Int {
    case singleValue = 0
    case minMaxValue = 1
}

@IBDesignable class RangeSelector: UIControl, UIScrollViewDelegate {
    @IBInspectable var rangeSelectorType: RangeSelectorType = .singleValue
    //MARK:- Range Variables
    //MARK: Values to be Used
    /**
     * An array of string values that can be displayed instaed of just a range of numbers. These will take precedence over the TotalRange.
     */
    var valuesToScrollThrough: [String]? {
        didSet {
            if self.valuesToScrollThrough != nil {
                self.currentMaxValue = valuesToScrollThrough!.count - 1
            }
        }
    }
    
    /**
     * The total range of values that will be displayed to the user. Set this if you are just hoping to display a range of numerical values. If you are using valuesToScrollThrough, you do not need to set this at all.
     */
    var totalRange: Int {
        get {
            if valuesToScrollThrough != nil {
                return valuesToScrollThrough!.count
            } else if _totalRange == nil {
                _totalRange = 10
            }
            
            return _totalRange!
        }
        
        set {
            _totalRange = newValue
        }
    }
    
    //MARK: Current Values
    /**
     * The current min value of the range selector (Int)
    */
    var currentMinValue = 0 {
        didSet {
            self.sendActions(for: UIControlEvents.valueChanged)
            self.updateLabelContent()
        }
    }
    
    /**
     * The current max value of the range selector (Int).
     */
    var currentMaxValue = 0 {
        didSet {
            self.sendActions(for: UIControlEvents.valueChanged)
            self.updateLabelContent()
        }
    }
    
    /**
     * The current min value of the range selector if you are using custom values (String).
     */
    var currentMinValueString: String? {
        return self.valueForIndex(self.currentMinValue)
    }
    
    /**
     * The current max value of the range selector if you are using custom values (String).
     */
    var currentMaxValueString: String? {
        return self.valueForIndex(self.currentMaxValue)
    }
    
    
    //MARK:- Visual Traits
    //MARK: User-Definable
    /**
     * The background image used by the bar.
     */
    @IBInspectable var barImage: UIImage? = UIImage(named: "RangeSelectorBarBackground.png")
    
    /**
     * The width of the central line.
     */
    @IBInspectable var lineWidth: CGFloat = 2.0
    
    /**
     * The colour of the bars.
    */
    @IBInspectable var barColor: UIColor = .blue
    
    
    /**
     * The colour of the min bar (will use barColor if not set)
    */
    var minBarColor: UIColor {
        get {
            if _minBarColor != nil {
                return _minBarColor!
            } else {
                return barColor
            }
        }
        
        set {
            _minBarColor = newValue
        }
    }
    
    /**
     * The colour of the max bar (will use barColor if not set)
     */
    var maxBarColor: UIColor {
        get {
            if _maxBarColor != nil {
                return _maxBarColor!
            } else {
                return barColor
            }
        }
        
        set {
            _maxBarColor = newValue
        }
    }
    
    
    /**
     * Adjusts the gap between each variable. Default is 30.
     */
    var gapBetweenValues: CGFloat = 30.0
    
    /**
     * The height of the bar itself.
    */
    let barHeight: CGFloat = 29.0
    
    /**
     * The margin between the bottom of the bar and the bottom of the view (you probably don't want to alter this).
    */
    let bottomMargin: CGFloat = 8
    
    /**
     * The distance by which the line extends beyond the bar itself.
    */
    let lineExtension: CGFloat = 5.0
    
    //MARK: Calculated
    private var lineHeight: CGFloat { return barHeight + lineExtension }
    
    
    //MARK: Helpers
    private var _minBarColor: UIColor?
    private var _maxBarColor: UIColor?
    
    private var _totalRange: Int?
    
    private var isSwapping = false
    private var maxActive = false {
        didSet {
            self.updatePositions(true)
        }
    }
    
    private var _sidePadding: CGFloat?
    private var sidePadding: CGFloat {
        if _sidePadding == nil {
            _sidePadding = UIScreen.main.bounds.width
        }
        
        return _sidePadding!
    }
    
    private var _rangeBar: UIView?
    private var rangeBar: UIView {
        if _rangeBar == nil {
            _rangeBar = UIView()
            _rangeBar!.translatesAutoresizingMaskIntoConstraints = false
            
            //reasons for the width calculation for future reference:
            //the side padding is so that when the scroll bounces we don't get whitespace
            //adding the view width is to make sure the view can be centred at its lowest value
            //then we add in the space that will actually be used
            _rangeBar!.frame = CGRect(x: -sidePadding, y: 0, width: (sidePadding * 2) + self.frame.width + (CGFloat(totalRange) * gapBetweenValues), height: barHeight)
            if barImage != nil {
                _rangeBar!.backgroundColor = UIColor(patternImage: barImage!)
            }
        }
        
        return _rangeBar!
    }
    
    private var _minLine: UIView?
    var minLine: UIView {
        if _minLine == nil {
            _minLine = UIView(frame: CGRect(x: 0, y: 0, width: lineWidth, height: lineHeight))
            _minLine!.backgroundColor = .blue
            _minLine!.translatesAutoresizingMaskIntoConstraints = false
        }
        
        return _minLine!
    }
    
    fileprivate var _minLabel: UILabel?
    var minLabel: UILabel {
        if _minLabel == nil {
            _minLabel = UILabel()
            
            _minLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
            _minLabel!.textAlignment = .center
            _minLabel?.contentMode = .center
            
            _minLabel?.translatesAutoresizingMaskIntoConstraints = false
            
            let gestRec = UITapGestureRecognizer(target: self, action: #selector(RangeSelector.makeMinActive))
            _minLabel!.addGestureRecognizer(gestRec)
            _minLabel!.isUserInteractionEnabled = true
            
            _minLabel!.text = self.valueForScrollPosition(CGFloat(self.currentMinValue) * self.gapBetweenValues)
            _minLabel?.sizeToFit()
        }
        
        return _minLabel!
    }
    
    fileprivate var _maxLine: UIView?
    var maxLine: UIView {
        if _maxLine == nil {
            _maxLine = UIView(frame: CGRect(x: 0, y: 0, width: lineWidth, height: lineHeight))
            _maxLine!.backgroundColor = .blue
            _maxLine!.translatesAutoresizingMaskIntoConstraints = false
        }
        
        return _maxLine!
    }
    
    fileprivate var _maxLabel: UILabel?
    var maxLabel: UILabel {
        if _maxLabel == nil {
            _maxLabel = UILabel()
            
            _maxLabel?.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.subheadline)
            _maxLabel!.textAlignment = .center
            _maxLabel?.contentMode = .center
            
            _maxLabel?.translatesAutoresizingMaskIntoConstraints = false
            
            let gestRec = UITapGestureRecognizer(target: self, action: #selector(RangeSelector.makeMaxActive))
            _maxLabel!.addGestureRecognizer(gestRec)
            _maxLabel!.isUserInteractionEnabled = true
            
            self.currentMaxValue = self.totalRange - 1
            _maxLabel!.text = self.valueForScrollPosition(CGFloat(self.currentMaxValue) * self.gapBetweenValues)
            _maxLabel?.sizeToFit()
        }
        
        return _maxLabel!
    }
    
    fileprivate var _rangeScrollBar: UIScrollView?
    var rangeScrollBar: UIScrollView {
        if _rangeScrollBar == nil {
            _rangeScrollBar = UIScrollView()
            _rangeScrollBar?.translatesAutoresizingMaskIntoConstraints = false
            
            _rangeScrollBar!.frame = CGRect(x: 0, y: self.frame.height - bottomMargin - barHeight, width: self.frame.width, height: barHeight)
            
            _rangeScrollBar!.addSubview(rangeBar)
            
            _rangeScrollBar!.isUserInteractionEnabled = true
            _rangeScrollBar!.bounces = true
            _rangeScrollBar!.alwaysBounceHorizontal = true
            _rangeScrollBar!.alwaysBounceVertical = false
            _rangeScrollBar!.showsHorizontalScrollIndicator = false
            _rangeScrollBar!.showsVerticalScrollIndicator = false
            
            _rangeScrollBar?.contentSize = CGSize(width: rangeBar.frame.width - (sidePadding * 2), height: barHeight)
            _rangeScrollBar!.delegate = self
            
        }
        return _rangeScrollBar!
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        print("Draw rect called")
        
        self.addSubview(rangeScrollBar)
        
        self.addSubview(minLine)
        self.addSubview(minLabel)
        
        self.addSubview(maxLabel)
        self.addSubview(maxLine)
        
        maxLabel.sizeToFit()
        
        self.updatePositions(false)
        
        if !self.maxActive {
            self.maxLabel.alpha = 0.5
            self.minLabel.alpha = 1.0
        } else {
            self.minLabel.alpha = 0.5
            self.maxLabel.alpha = 1.0
        }
    }
    
    override var intrinsicContentSize : CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 84)
    }
    
    //MARK: Data Retrieval based on Scroll Position
    func valueIndexForScrollPosition(_ pos: CGFloat) -> Int {
        return max( min( Int(pos/self.gapBetweenValues), self.totalRange - 1 ), 0 )
    }
    
    func valueForScrollPosition(_ pos: CGFloat) -> String {
        if self.valuesToScrollThrough != nil {
            return self.valuesToScrollThrough![self.valueIndexForScrollPosition(pos)].uppercased()
        } else {
            return "\(self.valueIndexForScrollPosition(pos))"
        }
    }
    
    func valueForIndex(_ index: Int) -> String {
        if self.valuesToScrollThrough != nil {
            return self.valuesToScrollThrough![index].uppercased()
        } else {
            return "\(index)"
        }
    }
    
    //MARK: Scrolling Methods
    func scrollPositionForItem(_ itemIndex: Int) -> CGFloat {
        return (self.gapBetweenValues * CGFloat(itemIndex) + self.frame.width/2) + self.gapBetweenValues/2
    }
    
    func scrollToPositionForItem(_ itemIndex: Int) {
        let scrollRect = CGRect(x: self.scrollPositionForItem(itemIndex) - self.frame.width/2, y: 0, width: self.frame.width, height: self.rangeScrollBar.frame.height)
        self.rangeScrollBar.scrollRectToVisible(scrollRect, animated: false)
    }
    
    //MARK: Position Management for Labels/Lines
    var _minVerticalConstraint: NSLayoutConstraint?
    var minVerticalConstraint: NSLayoutConstraint {
        if _minVerticalConstraint == nil {
            _minVerticalConstraint = self.verticalConstraintForLabel(minLabel)
        }
        return _minVerticalConstraint!
    }
    
    var _minHorizontalCenterConstraint: NSLayoutConstraint? = nil
    var minHorizontalCenterConstraint: NSLayoutConstraint {
        if _minHorizontalCenterConstraint == nil {
            _minHorizontalCenterConstraint = self.horizontalCentreConstraintForLabel(self.minLabel)
        }
        
        return _minHorizontalCenterConstraint!
    }
    
    var _minInactiveConstraint: NSLayoutConstraint? = nil
    var minInactiveConstraint: NSLayoutConstraint {
        if _minInactiveConstraint == nil {
            _minInactiveConstraint = NSLayoutConstraint(item: minLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 8.0)
        }
        
        return _minInactiveConstraint!
    }
    
    var _maxVerticalConstraint: NSLayoutConstraint?
    var maxVerticalConstraint: NSLayoutConstraint {
        if _maxVerticalConstraint == nil {
            _maxVerticalConstraint = self.verticalConstraintForLabel(maxLabel)
        }
        return _maxVerticalConstraint!
    }
    
    var _maxHorizontalCenterConstraint: NSLayoutConstraint? = nil
    var maxHorizontalCenterConstraint: NSLayoutConstraint {
        if _maxHorizontalCenterConstraint == nil {
            _maxHorizontalCenterConstraint = self.horizontalCentreConstraintForLabel(self.maxLabel)
        }
        
        return _maxHorizontalCenterConstraint!
    }
    
    var _maxInactiveConstraint: NSLayoutConstraint? = nil
    var maxInactiveConstraint: NSLayoutConstraint {
        if _maxInactiveConstraint == nil {
            _maxInactiveConstraint = NSLayoutConstraint(item: maxLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: -8.0)
        }
        
        return _maxInactiveConstraint!
    }
    
    var _minLeftConstraints: Array<NSLayoutConstraint>?
    
    func verticalConstraintForLabel(_ label: UILabel) -> NSLayoutConstraint {
        return NSLayoutConstraint(item: label, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1.0, constant: -10.0)
    }
    
    func horizontalCentreConstraintForLabel(_ label: UILabel) -> NSLayoutConstraint{
        return NSLayoutConstraint(item: label, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
    }
    
    func updatePositions(_ animated: Bool) {
        guard self.subviews.contains(self.maxLabel) && self.subviews.contains(self.minLabel) && self.subviews.contains(self.maxLine) && self.subviews.contains(self.minLine) else { return }
        
        self.isSwapping = true
        
        switch self.rangeSelectorType {
        case .singleValue:
            self.maxLabel.isHidden = true
            self.maxLine.isHidden = true
            self.rangeRectangle?.isHidden = true
            break
            
        case .minMaxValue:
            self.maxLabel.isHidden = false
            self.maxLine.isHidden = false
            self.rangeRectangle?.isHidden = false
            break
        }
        
        
        self.layoutIfNeeded()
        
        if !self.constraints.contains(self.minVerticalConstraint) {
            self.addConstraint(self.minVerticalConstraint)
        }
        
        if !self.constraints.contains(self.maxVerticalConstraint) {
            self.addConstraint(self.maxVerticalConstraint)
        }
        
        if !self.maxActive {
            if self.constraints.contains(self.maxHorizontalCenterConstraint) {
                self.removeConstraint(self.maxHorizontalCenterConstraint)
            }
            
            if self.constraints.contains(self.minInactiveConstraint) {
                self.removeConstraint(self.minInactiveConstraint)
            }
            
            if !self.constraints.contains(self.minHorizontalCenterConstraint) {
                self.addConstraint(self.minHorizontalCenterConstraint)
            }
            
            if !self.constraints.contains(self.maxInactiveConstraint) {
                self.addConstraint(self.maxInactiveConstraint)
            }
            
        } else {
            if !self.constraints.contains(self.maxHorizontalCenterConstraint) {
                self.addConstraint(self.maxHorizontalCenterConstraint)
            }
            
            if !self.constraints.contains(self.minInactiveConstraint) {
                self.addConstraint(self.minInactiveConstraint)
            }
            
            if self.constraints.contains(self.maxInactiveConstraint) {
                self.removeConstraint(self.maxInactiveConstraint)
            }
            
            if self.constraints.contains(self.minHorizontalCenterConstraint) {
                self.removeConstraint(self.minHorizontalCenterConstraint)
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.8, animations: { () -> Void in
                self.layoutIfNeeded()
                self.swapActiveLabel()
                //                self.updateScrollLines(self.rangeScrollBar)
            }, completion: { (success) -> Void in
                self.isSwapping = false
            })
        } else {
            print("Non animated version called")
            self.layoutIfNeeded()
            self.updateScrollLines(self.rangeScrollBar)
            self.swapActiveLabel()
            self.isSwapping = false
        }
    }
    
    func swapActiveLabel() {
        self.minLabel.alpha = self.maxActive ? 0.5 : 1.0
        self.maxLabel.alpha = self.maxActive ? 1.0 : 0.5
        
        self.scrollToPositionForItem(self.maxActive ? self.currentMaxValue : self.currentMinValue)
    }
    
    /**
     * Switches the focus to the min label
    */
    func makeMinActive() {
        self.maxActive = false
    }
    
    func makeMaxActive() {
        self.maxActive = true
    }
    
    func updateLabelContent() {
        self.minLabel.text = self.valueForIndex(self.currentMinValue)
        self.maxLabel.text = self.valueForIndex(self.currentMaxValue)
    }
    
    func updateCurrentValue(_ scrollOffest: CGPoint) {
        guard !self.isSwapping else {return}
        
        let newVal = self.valueIndexForScrollPosition(scrollOffest.x)
        if !self.maxActive {
            if newVal != self.currentMinValue {
                self.currentMinValue = newVal
            }
        } else {
            if newVal != self.currentMaxValue {
                self.currentMaxValue = newVal
            }
        }
    }
    
    func updateScrollLines(_ scrollView: UIScrollView) {
        self.maxLine.center.y = self.rangeScrollBar.center.y - 3
        self.minLine.center.y = self.rangeScrollBar.center.y - 3
        
        if !self.maxActive {
            self.minLine.center.x = self.center.x
            self.maxLine.center.x = -scrollView.contentOffset.x + self.scrollPositionForItem(self.currentMaxValue)
        } else {
            self.maxLine.center.x = self.center.x
            self.minLine.center.x = -scrollView.contentOffset.x + self.scrollPositionForItem(self.currentMinValue)
        }
        
        self.drawRangeRectangle()
    }
    
    var rangeRectangle: UIView? = nil
    
    func drawRangeRectangle() {
        guard self.rangeSelectorType == .minMaxValue else { return }
        
        let newFrame = CGRect(x: self.minLine.center.x, y: self.frame.height - (8 + 29), width: self.maxLine.center.x - self.minLine.center.x, height: 29)
        
        if rangeRectangle == nil {
            rangeRectangle = UIView(frame: newFrame)
            rangeRectangle!.backgroundColor = .blue
            rangeRectangle!.isUserInteractionEnabled = false
            rangeRectangle!.alpha = 0.3
            self.addSubview(rangeRectangle!)
        }
        
        rangeRectangle?.frame = newFrame
    }
    
    func scrollViewShouldScroll(_ scrollView: UIScrollView) -> Bool {
        guard self.rangeSelectorType == .minMaxValue else { return true }
        
        let offset = self.maxActive ? -gapBetweenValues/2 : gapBetweenValues/2
        let newVal = self.valueIndexForScrollPosition(scrollView.contentOffset.x + CGFloat(offset))
        
        if !self.maxActive {
            if newVal < self.currentMaxValue {
                return true
            } else {
                return false
            }
        } else {
            if newVal > self.currentMinValue {
                return true
            } else {
                return false
            }
        }
    }
    
    //MARK: - Delegates
    //MARK: UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard self.scrollViewShouldScroll(scrollView) else {
            self.scrollToPositionForItem(self.maxActive ? self.currentMaxValue : self.currentMinValue)
            return
        }
        
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: 0)
        
        self.updateCurrentValue(scrollView.contentOffset)
        self.updateScrollLines(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return false
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for subview in subviews as [UIView] {
            if !subview.isHidden && subview.alpha > 0 && subview.isUserInteractionEnabled && subview.point(inside: convert(point, to: subview), with: event) {
                return true
            }
        }
        return false
    }
}
