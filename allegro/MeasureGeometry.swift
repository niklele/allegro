//
//  MeasureGeometry.swift
//  allegro
//
//  Created by Brian Tiger Chow on 2/1/17.
//  Copyright © 2017 gigaunicorn. All rights reserved.
//

import Rational
import UIKit

// We are surrounded by space.
// And that space contains lots of things. 
// And these things have shapes.
// In MeasureGeometry, we are concerned with the nature of these things.

struct MeasureGeometry {

    typealias Line = (start: CGPoint, end: CGPoint)

    struct State {

        let visibleSize: CGSize
        let selectedNoteDuration: Rational

        init(visibleSize: CGSize, selectedNoteDuration: Rational) {
            self.visibleSize = visibleSize
            self.selectedNoteDuration = selectedNoteDuration
        }
    }

    static let zero = MeasureGeometry(state: State(visibleSize: .zero, selectedNoteDuration: 1))

    let state: State

    let staffCount = 5
    let numLedgerLinesAbove = 4
    let numLedgerLinesBelow = 4

    var minNoteWidth: CGFloat {
        return 1.5 * staffHeight
    }

    var staffDrawStart: CGFloat {
        return DEFAULT_MARGIN_PTS + CGFloat(numLedgerLinesAbove) * staffHeight
    }

    var staffHeight: CGFloat {
        return (state.visibleSize.height - 2 * DEFAULT_MARGIN_PTS) / CGFloat(staffCount + 1)
    }

    var heightOfSemitone: CGFloat {
        return staffHeight / 2
    }

    // it's a lot easier to compute width than height, so they are provided independently to allow clients to minimize
    // arithmetic operations

    var totalWidth: CGFloat {
        let minNoteWidth = Rational(Int(self.minNoteWidth))
        let numNotesPerMeasure = 1 / state.selectedNoteDuration
        let visibleWidth = state.visibleSize.width
        let reservedWidth = (minNoteWidth * numNotesPerMeasure).cgFloat
        return max(reservedWidth, visibleWidth)
    }

    // as an optimization, this could be defined as a lazy let getter
    var totalHeight: CGFloat {
        // - 1 because we're counting the spaces between ledger lines
        // 2 * Margin because we leave a little space above the top and bottom ledger lines
        let numSpacesBetweenAllLines: CGFloat = CGFloat(staffCount + numLedgerLinesAbove + numLedgerLinesBelow - 1)
        return staffHeight * numSpacesBetweenAllLines + 2 * DEFAULT_MARGIN_PTS
    }

    // deprecated. TODO remove in favor of frameSize
    var totalSize: CGSize {
        return CGSize(width: totalWidth, height: totalHeight)
    }

    var frameSize: CGSize {
        return totalSize
    }

    var stemLength: CGFloat {
        return 2 * staffHeight
    }

    var noteHeight: CGFloat {
        return staffHeight
    }

    var noteGeometry: NoteGeometry {
        return NoteGeometry(staffHeight: staffHeight)
    }

    var staffLines: [Line] {
        var lines = [Line]()
        for i in stride(from: 0, to: staffCount, by: 1) {
            let y = staffDrawStart + CGFloat(i) * staffHeight
            let start = CGPoint(x: 0, y: y)
            let end = CGPoint(x: totalWidth, y: y)
            lines.append(Line(start, end))
        }
        return lines
    }

    var ledgerLineGuides: [Line] {
        var arr = [Line]()
        for i in stride(from: 0, to: numLedgerLinesAbove, by: 1) {
            let y = DEFAULT_MARGIN_PTS + staffHeight * CGFloat(i)
            let start = CGPoint(x: 0, y: y)
            let end = CGPoint(x: totalWidth, y: y)
            arr.append(Line(start, end))
        }
        for i in stride(from: 0, to: numLedgerLinesBelow, by: 1) {
            let m = DEFAULT_MARGIN_PTS
            let numLinesAbovePlusNumStaffs = CGFloat(numLedgerLinesAbove + staffCount)
            let y = m + numLinesAbovePlusNumStaffs * staffHeight + staffHeight * CGFloat(i)
            let start = CGPoint(x: 0, y: y)
            let end = CGPoint(x: totalWidth, y: y)
            arr.append(Line(start, end))
        }
        return arr
    }

    // uh this doesn't really do anything but we'll just delete some time later
    func verticalGridlines(measure: MeasureViewModel) -> [Line] {
        let offsets = [CGFloat]()
        
        let lines = offsets.map { Line(CGPoint(x: $0, y: 0), CGPoint(x: $0, y: totalHeight))}
        return lines
    }

    func touchRemainedInPosition(measure: MeasureViewModel,
                                 start: CGPoint,
                                 end: CGPoint) -> Bool {
        let startPos = pointToPositionInTime(measure: measure,
                                             x: start.x)
        let endPos = pointToPositionInTime(measure: measure,
                                           x: end.x)
        return startPos == endPos
    }

    func noteY(pitch: Int) -> CGFloat {
        return staffDrawStart + staffHeight * 2 - staffHeight / 2 * CGFloat(pitch) - noteHeight / 2
    }

    func noteX(position: Rational, timeSignature: Rational) -> CGFloat {
        return position.cgFloat / timeSignature.cgFloat * totalWidth
    }

    func noteStemEnd(pitch: Int, originY y: CGFloat) -> CGFloat {
        return pitch > 0 ? y + noteHeight + stemLength : y - stemLength
    }

    func pointToPitch(_ point: CGPoint) -> Int {
        let numSpacesBetweenAllLines: CGFloat = CGFloat(staffCount + numLedgerLinesAbove + numLedgerLinesBelow - 1)
        return Int(round(-(point.y - DEFAULT_MARGIN_PTS) / heightOfSemitone + numSpacesBetweenAllLines))
    }

    func pointToPositionInTime(measure: MeasureViewModel,
                               x: CGFloat) -> Rational {
        let ratioOfScreenWidth: Rational = Rational(Int(x), Int(totalWidth)) ?? 0
        return (ratioOfScreenWidth * measure.timeSignature).lowestTerms
    }

    typealias Interval = (start: CGFloat, end: CGFloat)
    
    // whitespace is the region between the notes that are not covered by the bounding boxes
    func computeNoteStartX(measure: MeasureViewModel) -> [CGFloat] {
        var whitespace = [Interval]()
        var blackspace = [Interval]()
        
        var totalBlackspace = CGFloat(0)
        let defaultWidth = state.visibleSize.width
        
        guard measure.notes.count > 0 else { return [CGFloat]() }
        let g = noteGeometry
        var last = CGFloat(0)
        
        // Calculate the whitespace intervals between notes if there are any
        // Also merges consecutive notes into contiguous interval
        for note in measure.notes {
            let noteCenterX = Rational(Int(defaultWidth)) * note.position / measure.timeSignature
            let bbox = g.getBoundingBox(note: note)
            
            let defaultX = max(last,noteCenterX.cgFloat - bbox.size.width / 2)
            whitespace.append(Interval(last, defaultX))
            blackspace.append(Interval(defaultX, defaultX + bbox.width))
            
            last = defaultX + bbox.width
            totalBlackspace += bbox.width
        }
        
        // add the whitespace after the last note
        if last < defaultWidth {
            whitespace.append(Interval(last, defaultWidth))
        }
        
        let totalWhitespace = whitespace.reduce(0) {$0 + $1.end - $1.start}
        
        if totalWhitespace > 0 && totalBlackspace < defaultWidth {
            let whitespaceScaling = (defaultWidth - totalBlackspace) / totalWhitespace
            
            var whitespaceBefore = CGFloat(0)
            
            for (i, space) in whitespace.enumerated() {
                let diff = (space.end - space.start) * whitespaceScaling
                let start = whitespaceBefore
                let end = space.start + diff
                
                whitespaceBefore += diff
                whitespace[i] = Interval(start, end)
            }
            
            blackspace = zip(whitespace, blackspace).map {
                Interval(
                    $0.end,
                    $0.end + $1.end - $1.start
                )
            }
        }
        
        // right now blackspace includes the necessary space for an accidental if it exists
        // we now remove that to get the start position of the note frame by itself
        let startX = zip(blackspace, measure.notes).map {
            $0.start + g.frame.origin.x - g.getBoundingBox(note: $1).origin.x
        }
        
        return startX
    }
}

