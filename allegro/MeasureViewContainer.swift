//
//  MeasureViewContainer.swift
//  allegro
//
//  Created by Brian Tiger Chow on 1/18/17.
//  Copyright © 2017 gigaunicorn. All rights reserved.
//

import UIKit

class MeasureViewContainer: UIScrollView {

    var store: PartStore? {
        didSet {
            measureView.store = store
        }
    }

    fileprivate struct State {
        let rect: CGRect
        let scale: CGFloat
    }

    let measureView: MeasureView = {
        let v = MeasureView()
        v.staffLineThickness = 2
        return v
    }()

    init() {
        super.init(frame: .zero)
        backgroundColor = .white
        panGestureRecognizer.minimumNumberOfTouches = 2
        delegate = self
        isDirectionalLockEnabled = true

        minimumZoomScale = 0.5

        addSubview(measureView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        measureView.sizeOfParentsVisibleArea = bounds.size
        contentSize = measureView.bounds.size
    }
}

extension MeasureViewContainer: UIScrollViewDelegate {

    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
    }
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return measureView
    }
}
