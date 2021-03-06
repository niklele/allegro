//
//  MeasureView.swift
//  allegro
//
//  Created by Qingping He on 1/16/17.
//  Copyright © 2017 gigaunicorn. All rights reserved.
//

import Foundation
import UIKit
import Rational

class MeasureView: UIView {

    var geometry: MeasureGeometry = .zero {
        didSet {
            frame.size = geometry.frameSize
        }
    }

    var store: PartStore? {
        willSet {
            store?.unsubscribe(self)
        }
        didSet {
            store?.subscribe(self)
        }
    }

    var index: Int?
    
    var noteIdToNoteActionViews = [ ObjectIdentifier : NoteActionView ]()

    var isExtendEnabled: Bool = false

    fileprivate let staffLineThickness: CGFloat = 2

    fileprivate let barLayer: CAShapeLayer = {
        return CAShapeLayer()
    }()

    let tapGestureRecognizer: UITapGestureRecognizer = {
        let gr = UITapGestureRecognizer()
        return gr
    }()

    let longPressPanGestureRecognizer: UILongPressGestureRecognizer = {
        let gr = UILongPressGestureRecognizer()
        gr.cancelsTouchesInView = false // TODO: why?
        return gr
    }()

    // screenEdgeGR exists to prevent the other recognizers from being triggered when user tries to open the side menu
    fileprivate let screenEdgeGR: UIScreenEdgePanGestureRecognizer = {
        let gr = UIScreenEdgePanGestureRecognizer()
        gr.edges = [.right]
        return gr
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.addSublayer(barLayer)

        // iOS expects draw(rect:) to completely fill
        // the view region with opaque content. This causes
        // the view background to be black unless we disable this.
        self.isOpaque = false
        backgroundColor = .white

        let actionRecognizers: [(Selector, UIGestureRecognizer)] = [
            (#selector(tap), tapGestureRecognizer),
            (#selector(longPressPan), longPressPanGestureRecognizer),
            ]
        for (sel, gr) in actionRecognizers {
            gr.addTarget(self, action: sel)
            addGestureRecognizer(gr)
            gr.require(toFail: screenEdgeGR) // so user can open side menu without accidentally erasing, etc.
        }
        longPressPanGestureRecognizer.require(toFail: tapGestureRecognizer)
        addGestureRecognizer(screenEdgeGR)
    }

    deinit {
        store?.unsubscribe(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(_: rect)

        drawVerticalGridlines(rect: rect)
        drawStaffs(rect: rect)
        drawLedgerLineGuides(rect: rect)
    }

    private func drawStaffs(rect: CGRect) {
        let path = UIBezierPath()
        for (start, end) in geometry.staffLines {
            path.move(to: start)
            path.addLine(to: end)
        }
        path.lineWidth = staffLineThickness
        UIColor.black.setStroke()
        path.stroke()
    }

    private func drawLedgerLineGuides(rect: CGRect) {
        let path = UIBezierPath()
        for (start, end) in geometry.ledgerLineGuides {

            path.move(to: start)
            path.addLine(to: end)
        }

        path.lineCapStyle = .round
        let dashes: [CGFloat] = [1, 10]
        path.setLineDash(dashes, count: dashes.count, phase: 0)

        UIColor.lightGray.setStroke()
        path.stroke()
    }

    private func drawVerticalGridlines(rect: CGRect) {
        guard let store = store, let index = index else { return }

        let measure = store.measure(at: index, extend: isExtendEnabled)

        let lines = geometry.verticalGridlines(measure: measure)
        let path = UIBezierPath()

        for (start, end) in lines {

            path.move(to: start)
            path.addLine(to: end)
        }
        path.lineCapStyle = .round
        let dashes: [CGFloat] = [1, 10]
        path.setLineDash(dashes, count: dashes.count, phase: 0)

        UIColor.lightGray.setStroke()
        path.stroke()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let store = store, let index = index else { return }

        let measureVM = store.measure(at: index, extend: isExtendEnabled)
        let noteViewModels = measureVM.notes
        let g = geometry.noteGeometry

        var viewsToRemove = Set<UIView>(subviews)
        var viewsToAdd = Set<UIView>()
        let noteViews = noteViewModels
            .map {
                (nvm: NoteViewModel) -> NoteActionView in
                if let existingView = noteIdToNoteActionViews[ObjectIdentifier(nvm.note)] {
                    if existingView is RestView && nvm.note.rest || existingView is NoteView && !nvm.note.rest {
                        existingView.note = nvm
                        viewsToRemove.remove(existingView)
                        return existingView
                    }
                }

                let newView = nvm.note.rest ? RestView(note: nvm, geometry: g, store: store) : NoteView(note: nvm, geometry: g, store: store)
                viewsToAdd.insert(newView)
                return newView
            }

        viewsToRemove.forEach { $0.removeFromSuperview() }
        viewsToAdd.forEach { addSubview($0) }

        noteViews.forEach {
                $0.isSelected = store.selectedNote == $0.note.position
        }

        noteViews.forEach() { $0.delegate = self }
        
        noteIdToNoteActionViews = zip(noteViewModels, noteViews)
            .reduce([ ObjectIdentifier : NoteActionView ]()) {
                (dict: [ ObjectIdentifier : NoteActionView ], kv: (NoteViewModel, NoteActionView)) -> [ ObjectIdentifier : NoteActionView ]  in
                var out = dict
                out[ObjectIdentifier(kv.0.note)] = kv.1
                return out
            }

        UIView.animate(withDuration: 0.25) {
            let geometry = self.geometry
            // we're barring all the notes for now
            for (view, startX) in zip(noteViews, geometry.noteStartX) {

                UIView.setAnimationsEnabled(!viewsToAdd.contains(view))

                if let noteView = view as? NoteView {
                    let y = geometry.noteY(pitch: noteView.note.pitch)

                    noteView.noteOrigin = CGPoint(x: startX, y: y)
                    //noteView.stemEndY = geometry.noteStemEnd(pitch: noteView.note.pitch, originY: y)
                    noteView.shouldDrawFlag = true//fals
                } else if let restView = view as? RestView {
                    let size = restView.geometry.getRestSize(value: restView.note.note.value)
                    if restView.note.note.value == Note.Value.whole {
                        let y = geometry.staffY(pitch: 2)
                        restView.frame = CGRect(origin: CGPoint(x: startX, y: y), size: size)
                    } else if restView.note.note.value == Note.Value.half {
                        let y = geometry.staffY(pitch: 0)
                        restView.frame = CGRect(origin: CGPoint(x: startX, y: y - size.height), size: size)
                    } else {
                        let y = geometry.staffY(pitch: 0) - size.height / 2
                        restView.frame = CGRect(origin: CGPoint(x: startX, y: y), size: size)
                    }

                    restView.setDotPosition(geometry: geometry)
                }
            }
        }
        
        let barPath = UIBezierPath()
        
        for beam in measureVM.beams {
            var barStart = CGPoint.zero
            var barEnd = CGPoint.zero
            
            for (i, noteViewModel) in beam.enumerated() {
                guard let beamNoteView = noteIdToNoteActionViews[ObjectIdentifier(noteViewModel.note)] else { continue }
                guard let noteView = beamNoteView as? NoteView else { continue }
                noteView.shouldDrawFlag = false
                
                let flagStart = noteView.frame.origin + noteView.flagStart
                
                if (i == 0) {
                    barStart = flagStart
                }
                
                if (i == beam.count - 1) {
                    
                    func drawBar(barStart: CGPoint, barEnd: CGPoint, barPath: UIBezierPath) {
                        var next = barStart
                        barPath.move(to: next)
                        next = barEnd
                        barPath.addLine(to: next)
                        
                        let barThicknessOffset = noteViewModel.flipped ? -g.barThickness : g.barThickness
                        
                        next = CGPoint(x: barEnd.x, y: barEnd.y + barThicknessOffset)
                        barPath.addLine(to: next)
                        next = CGPoint(x: barStart.x, y: barStart.y + barThicknessOffset)
                        barPath.addLine(to: next)
                        barPath.close()
                    }
                    barEnd = flagStart.offset(dx: noteView.stemThickness, dy: 0)
                    drawBar(barStart: barStart, barEnd: barEnd, barPath: barPath)
                    
                    if noteViewModel.note.value == .sixteenth {
                        let offset = noteViewModel.flipped ? -g.barOffset: g.barOffset
                        barStart = barStart.offset(dx: 0, dy: offset)
                        barEnd = barEnd.offset(dx: 0, dy: offset)
                        
                        drawBar(barStart: barStart, barEnd: barEnd, barPath: barPath)
                    }
                }
            }
        }
        
        barLayer.path = barPath.cgPath
        barLayer.fillColor = UIColor.black.cgColor

        // we compute paths at the end because beams can change stuff
        for view in noteViews {
            guard let noteView = view as? NoteView else { continue }
            noteView.computePaths()
        }
    }

    func longPressPan(sender: UIGestureRecognizer) {
        guard let store = store else { return }

        if store.mode == .edit && sender.state == .ended {
            edit(sender: sender)
        }

        if store.mode == .erase {
            _ = erase(sender: sender)
        }
    }

    private func erase(sender: UIGestureRecognizer) -> Bool {
        guard store?.mode == .erase else { return false }
        
        let location = sender.location(in: self)

        if let nv = hitTest(location, with: nil) as? NoteActionView {
            guard let store = store, let index = index else { return false }
            return store.removeNote(fromMeasureIndex: index, at: nv.note.position)
        } else if sender is UITapGestureRecognizer {
            Snackbar(message: "you're in erase mode", duration: .short).show()
        }
        return false
    }

    func tap(sender: UIGestureRecognizer) {
        guard let store = store else { return }

        if store.mode == .edit {
            if deselectNote(sender: sender) {
                return // without editing
            }
            edit(sender: sender)
        }

        if store.mode == .erase {

            if erase(sender: sender) {
                return
            }
            store.mode = .edit
            Snackbar(message: "switched to edit mode", duration: .short).show()
        }
    }


    // returns true if a note was actually deselected
    private func deselectNote(sender: UIGestureRecognizer) -> Bool {
        let location = sender.location(in: self)
        guard let nv = hitTest(location, with: nil) as? NoteActionView else {
            return false
        }
        guard let store = store, let index = index else { return false }
        if store.currentMeasure == index && nv.note.position == store.selectedNote {
            store.selectedNote = nil
            return true
        }
        return false
    }

    private func edit(sender: UIGestureRecognizer) {
        guard store?.mode == .edit else {
            return
        }
        let location = sender.location(in: self)

        guard let store = store, let index = index else { return }

        let value = store.newNote

        // determine pitch
        let pitchRelativeToCenterLine = geometry.pointToPitch(location)

        // determine position
        let position = geometry.pointToPositionInTime(x: location.x)

        // instantiate note
        let (letter, octave) = NoteViewModel.pitchToLetterAndOffset(pitch: pitchRelativeToCenterLine)
        let note = Note(value: value, letter: letter, octave: octave)

        // attempt to insert
        let actualPosition = store.insert(note: note, intoMeasureIndex: index, at: position)

        if actualPosition == nil {
            Snackbar(message: "no space for note", duration: .short).show()
        }
    }
}

extension MeasureView: PartStoreObserver {
    func partStoreChanged() {
        guard let store = store else { return }

        // NB(btc): we adjust minimum press duration to allow erase panning to function properly.
        // one alternative is to have a separate pan gesture recognizer for erase panning and use the long press only for
        // edit mode
        switch store.mode {
        case .erase:
            longPressPanGestureRecognizer.minimumPressDuration = 0.01 // if this is zero, taps don't work
        case .edit:
            longPressPanGestureRecognizer.minimumPressDuration = 0.5 // default
        }

        setNeedsDisplay() // TODO(btc): perf: only re-draw when changing note selection
        setNeedsLayout()
    }
}

extension MeasureView: NoteActionDelegate {
    func actionRecognized(gesture: NoteAction, by view: UIView) {

        guard store?.mode == .edit else { return }

        guard let store = store, let index = index, let note = (view as? NoteActionView)?.note else { return }

        switch gesture {

        case .toggleDot, .toggleDoubleDot:
            if !store.toggleDot(inMeasure: index, at: note.position, action: gesture) {
                Snackbar(message: "not enough space to dot note", duration: .short).show()
            }

        case .sharp, .natural, .flat:
            let acc: Note.Accidental = gesture == .sharp ? .sharp : gesture == .flat ? .flat : .natural
            if !note.displayAccidental && acc == note.note.accidental {
                Snackbar(message: "note is already \(acc.description)", duration: .short).show()
                // we still set the accidental though. we want sound to play!
            }
            if !store.setAccidental(acc, inMeasure: index, at: note.position) {
                Snackbar(message: "failed to \(gesture) the note", duration: .short).show()
            }
        case .rest:
            if !store.toggleRest(inMeasure: index, at: note.position) {
                Snackbar(message: "strange... failed to toggle rest", duration: .short).show()
            }
        case .select:
            store.selectedNote = note.position

        case .move:
            guard let moved = store.removeAndReturnNote(fromMeasure: index, at: note.position) else { return }
            let location = view.center

            let pitchRelativeToCenterLine = geometry.pointToPitch(location)
            let position = geometry.pointToPositionInTime(x: location.x)

            if !moved.rest {
                let (letter, octave) = NoteViewModel.pitchToLetterAndOffset(pitch: pitchRelativeToCenterLine)
                moved.letter = letter
                moved.octave = octave
            }

            if let insertedPosition = store.insert(note: moved, intoMeasureIndex: index, at: position) {
                store.selectedNote = insertedPosition
            }
        }
    }
}

