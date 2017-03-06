//
//  SimpleMeasure.swift
//  allegro
//
//  Created by Brian Tiger Chow on 2/16/17.
//  Copyright © 2017 gigaunicorn. All rights reserved.
//

import Rational

struct Measure {

    static let defaultTimeSignature: Rational = 4/4

    var keySignature: Key // eg. G Major or d minor
    var timeSignature: Rational

    private(set) var freespace: Rational

    private(set) var frees: [FreePos] = [] {
        didSet {
            freespace = frees.reduce(0) { $0 + $1.duration }
        }
    }

    private(set) var notes: [NotePos] = [] {
        didSet {
            frees = computeFrees()
        }
    }
    
    private(set) var ties: [Tie] = [Tie]()
    private(set) var triplets: [Triplet] = [Triplet]()

    var capacity: Rational {
        return timeSignature
    }

    let start: Rational = 0

    var end: Rational {
        return timeSignature
    }

    init(timeSignature: Rational = Measure.defaultTimeSignature, keySignature: Key = .cMajor) {
        self.timeSignature = timeSignature
        self.keySignature = keySignature

        // didSet callbacks are not triggered in constructors, so we have to manually initialize the freespace.
        // we cannot call computeFrees() until all properties are initialized, so we initialize them to junk values to
        // appease the compiler
        frees = []
        freespace = 0
        frees = computeFrees()
        freespace = frees.reduce(0) { $0 + $1.duration }
    }

    func note(at position: Rational) -> Note? {
        guard let i = index(of: position) else { return nil }
        return notes[i].note
    }

    mutating func removeNote(at position: Rational) -> Bool {
        return removeAndReturnNote(at: position) != nil
    }

    mutating func removeAndReturnNote(at position: Rational) -> Note? {
        guard let i = index(of: position) else { return nil }
        // check if note is part of triplet or tie
        if let tie = notes[i].note.tie {
            // contains tie
            let success = removeTie(tie: tie)
            if (success == false || notes[i].note.tie != nil) {
                Log.error?.message("Error removing tie")
            }
        }
        if let triplet = notes[i].note.triplet {
            // contains triplet
            let success = triplet.removeNote(notePos: notes[i])
            if (success == false || notes[i].note.triplet != nil) {
                Log.error?.message("Error removing note from triplet")
            }
            // if triplet.isEmpty(), remove it from triplets array
            if (triplet.isEmpty()) {
                let removeSuccess = removeTriplet(triplet: triplet)
                if (removeSuccess == false) {
                    Log.error?.message("Error removing triplet from model")
                }
            }
        }
        return notes.remove(at: i).note
    }

    // TODO(btc): speed this up with binary search
    func index(of position: Rational) -> Int? {
        for (i, np) in notes.enumerated() {
            if np.pos == position {
                return i
            }
        }
        return nil
    }

    func freespaceRight(of position: Rational) -> Rational {
        var total: Rational = 0
        for fp in frees {
            if fp.contains(position) {
                total = total + fp.freespaceRight(of: position)
            } else if fp.startsAfter(position) {
                total = total + fp.duration
            }
        }
        return total
    }

    func freespaceLeft(of position: Rational) -> Rational {
        var total: Rational = 0
        for free in frees {
            if free.contains(position) {
                total = total + free.freespaceLeft(of: position)
            } else if free.endsBefore(position) {
                total = total + free.duration
            }
        }
        return total
    }

    func indexToInsert(_ position: Rational) -> Int {
        if let index = notes.indexOfFirstMatch({ $0.startsAtOrAfter(position) }) {
            return index
        }
        return notes.endIndex
    }

    mutating func nudgeRight(startingAt index: Int, toTheRightOf position: Rational) {
        var endOfPreviousNote = position
        for i in stride(from: index, to: notes.endIndex, by: 1) {
            notes[i].pos = max(notes[i].pos, endOfPreviousNote)
            endOfPreviousNote = notes[i].end
        }
    }

    mutating func nudgeLeft(startingAt index: Int, toTheLeftOf position: Rational) {
        var startOfNextNote = position
        for i in stride(from: index, through: 0, by: -1) {
            notes[i].end = min(startOfNextNote, notes[i].end)
            startOfNextNote = notes[i].pos
        }
    }

    mutating func insert(note: Note, at initialDesiredPosition: Rational) -> Rational? {
        var np = NotePos(pos: initialDesiredPosition, note: note)

        if np.end > end { // too late
            np.end = end
        }
        if np.start < start { // too early
            return nil
        }
        if note.duration > freespace { // not enough space
            return nil
        }

        let indexToInsert = self.indexToInsert(np.pos)

        while (true) {
            let bumpsIntoNoteOnTheLeft = notes.indices.contains(indexToInsert - 1) && notes[indexToInsert-1].overlaps(with: np)
            let bumpsIntoNoteOnTheRight = notes.indices.contains(indexToInsert) && notes[indexToInsert].overlaps(with: np)

            if bumpsIntoNoteOnTheLeft {
                let prev = notes[indexToInsert-1]
                let freespaceL = freespaceLeft(of: np.pos)
                let overlap = prev.lengthOfOverlap(with: np)
                let amountWeAreAbleToNudgeLeft = min(freespaceL, overlap)
                let newEndOfPreviousNote = prev.end - amountWeAreAbleToNudgeLeft
                nudgeLeft(startingAt: indexToInsert - 1, toTheLeftOf: newEndOfPreviousNote)
                np.pos = newEndOfPreviousNote
                continue
            }
            if bumpsIntoNoteOnTheRight {
                let next = notes[indexToInsert]
                let freespaceR = freespaceRight(of: np.end)
                let overlap = np.lengthOfOverlap(with: next)
                let amountWeAreAbleToNudgeRight = min(overlap, freespaceR)
                let newStartOfNextNote = next.start + amountWeAreAbleToNudgeRight
                nudgeRight(startingAt: indexToInsert, toTheRightOf: newStartOfNextNote)
                np.end = newStartOfNextNote
                continue
            }
            break
        }
        notes.insert(np, at: indexToInsert)
        return np.pos
    }

    // Changes the dot on a note in O(n)
    // returns success of the operation
    // Removes original note, adds a dot, and inserts with nudge
    mutating func dotNote(at position: Rational, dot: Note.Dot) -> Bool {
        // remove original note and add a dot
        guard let note = removeAndReturnNote(at: position) else { return false }
        let originalDot = note.dot
        note.dot = dot

        // re-insert with new dot
        if insert(note: note, at: position) != nil {
            return true
        }

        // re-insert original note if we were unable to insert dotted note with nudge
        note.dot = originalDot
        if insert(note: note, at: position) == nil && DEBUG {
            Log.error?.message("Unable to re-insert note after failed dotting. Developer Error.")
        }
        return false
    }
    
    // adds a Tie to this measure
    // returns true on success
    mutating func addTie(startPos: Rational, endPos: Rational) -> Bool {
        guard let startNote = note(at: startPos) else {return false}
        guard let endNote = note(at: endPos) else { return false}
        ties.append(Tie(startNote: startNote, endNote: endNote))
        return true
    }
    
    // removes a Tie from this measure
    mutating func removeTie(tie: Tie) -> Bool {
        let filteredTies = ties.filter { $0 != tie }
        if (filteredTies.count < ties.count) {
            ties = filteredTies
            return true
        }
        return false
    }
    
    // Takes nominal duration of single note in triplet, returns true if triplet can be added
    func hasSpaceForTriplet(noteDuration: Rational) -> Bool {
        return (self.freespace >= noteDuration * 2)
    }
    
    // adds a Triplet to this measure
    // returns true on success
    mutating func addTriplet(notes: [NotePos]) -> Bool {
        guard let newTriplet = Triplet(notesArr: notes) else {return false}
        triplets.append(newTriplet)
        return true
    }
    
    // adds a note to a triplet in the measure
    mutating func addNoteToTriplet(notePos: NotePos, triplet: Triplet) -> Bool {
        return triplet.addNote(notePos: notePos)
    }
    
    // remove a triplet object from the measure
    mutating func removeTriplet(triplet: Triplet) -> Bool {
        let filteredTriplets = triplets.filter { $0 != triplet }
        if (filteredTriplets.count < triplets.count) {
            triplets = filteredTriplets
            return true
        }
        return false
    }

    // Finds the nearest previous note with the same letter if it exists
    func getPrevLetterMatch(for letter: Note.Letter, at position: Rational) -> Note? {
        var match: Note? = nil
        var foundOrig = false
        for notePosition in notes.reversed() {
            let curr = notePosition.note

            // find original note
            if notePosition.pos == position {
                foundOrig = true
                continue
            }
            // find previous note with same letter
            if foundOrig && curr.letter == letter {
                match = notePosition.note
                break
            }
        }
        return match
    }

    private func computeFrees() -> [FreePos] {
        if notes.isEmpty {
            return [FreePos(pos: start, duration: capacity)]
        }

        var arr: [FreePos] = []
        for (i, np) in notes.enumerated() {


            if i == notes.startIndex { // if first note isn't at position 0, add the free space that runs up to the start of the note

                // first
                if np.pos != 0 {
                    arr.append(FreePos(pos: 0, duration: np.pos))
                }
            } else { // otherwise add the space between the last note and the next note

                // middle: add space to the left of current |np|
                if let fp = notes[i-1].freespaceBetween(np) {
                    arr.append(fp)
                }
            }

            if (i == notes.endIndex - 1) { // add the space after the end of the note if space exists

                // last: add space to the right of current |np|
                if np.end < end {
                    arr.append(FreePos(pos: np.end, duration: end - np.end))
                }
            }
        }
        return arr
    }
}

struct NotePos {
    var pos: Rational
    let note: Note

    var start: Rational {
        return pos
    }

    var end: Rational {
        get {
            return pos + note.duration
        }
        set(newEnd) {
            pos = newEnd - note.duration
        }
    }

    var duration: Rational {
        return note.duration
    }

    func freespaceBetween(_ later: NotePos) -> FreePos? {
        if later.pos - end > 0 {
            return FreePos(pos: end, duration: later.pos - end)
        }
        return nil
    }

    func startsStrictlyAfter(_ position: Rational) -> Bool {
        return position < start
    }

    func startsAtOrAfter(_ position: Rational) -> Bool {
        return position <= start
    }

    func startsAtOrBefore(_ other: NotePos) -> Bool {
        return start <= other.start
    }

    func lengthOfOverlap(with other: NotePos) -> Rational {
        if !startsAtOrBefore(other) {
            return other.lengthOfOverlap(with: self)
        }
        // this starts before or at the same place as the other NotePos
        if other.end <= end {
            return other.duration
        }
        return max(end - other.start, 0)
    }

    func overlaps(with other: NotePos) -> Bool {
        return lengthOfOverlap(with: other) > 0
    }
}

struct FreePos {
    let pos: Rational
    let duration: Rational

    var start: Rational {
        return pos
    }

    var end: Rational {
        return pos + duration
    }

    func contains(_ position: Rational) -> Bool {
        return start <= position && position <= end
    }

    func freespaceRight(of position: Rational) -> Rational {
        return contains(position) ? end - position : 0
    }

    func freespaceLeft(of position: Rational) -> Rational {
        return contains(position) ? position - start : 0
    }

    func startsAfter(_ position: Rational) -> Bool {
        return position < start
    }

    func endsBefore(_ position: Rational) -> Bool {
        return end < position
    }
}
