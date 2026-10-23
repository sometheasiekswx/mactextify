import Foundation

/// Local OCR voting only: every output token must occur in an aligned OCR candidate.
/// Agreement is not an accuracy score. Never use evaluation references as inputs.
struct OCRConsensus {
    static func normalize(_ text: String) -> String { text.split(whereSeparator: \.isWhitespace).joined(separator: " ") }

    static func distance(_ a: [Character], _ b: [Character]) -> Int {
        var previous = Array(0...b.count)
        for (i, x) in a.enumerated() {
            var current = [i + 1] + Array(repeating: 0, count: b.count)
            for (j, y) in b.enumerated() {
                current[j + 1] = min(previous[j + 1] + 1, current[j] + 1, previous[j] + (x == y ? 0 : 2))
            }
            previous = current
        }
        return previous[b.count]
    }
    static func similarity(_ a: String, _ b: String) -> Double {
        let x = Array(a), y = Array(b)
        return 1 - Double(distance(x, y)) / Double(max(1, x.count + y.count))
    }

    static func resolve(_ blocks: [[String]]) -> [String] {
        let normalized = blocks.map { $0.map(normalize) }
        var frequency: [String: Int] = [:]
        for block in normalized { for candidate in block { for token in candidate.split(separator: " ") {
            frequency[String(token), default: 0] += 1
        } } }
        return normalized.map { resolveBlock($0, frequency: frequency) }
    }

    static func resolveBlock(_ candidates: [String], frequency: [String: Int]) -> String {
        let nonempty = candidates.filter { !$0.isEmpty }
        guard !nonempty.isEmpty else { return "" }
        // Bound the quadratic alignment; a huge/unusual block keeps a literal pass.
        guard nonempty.allSatisfy({ $0.count <= 2400 }) else { return nonempty[0] }
        var base = nonempty[0], best = -Double.infinity
        for candidate in nonempty {
            let score = nonempty.reduce(0) { $0 + similarity(candidate, $1) }
            if score > best { best = score; base = candidate }
        }
        let reliable = nonempty.filter { similarity(base, $0) >= 0.85 }
        let tokens = base.split(separator: " ").map(String.init)
        guard tokens.count <= 400 else { return base }
        var votes = Array(repeating: [String](), count: tokens.count)
        var insertions = Array(repeating: [String](), count: tokens.count + 1)
        for candidate in reliable {
            let aligned = align(tokens, candidate.split(separator: " ").map(String.init))
            for i in votes.indices { votes[i].append(aligned.words[i]) }
            for i in insertions.indices { insertions[i].append(aligned.insertions[i]) }
        }
        var output = [String]()
        for i in 0...tokens.count {
            let insertion = majority(insertions[i])
            if !insertion.isEmpty && insertions[i].filter({ $0 == insertion }).count * 2 >= reliable.count { output.append(insertion) }
            if i == tokens.count { break }
            var counts: [String: Int] = [:]
            for word in votes[i] { counts[word, default: 0] += 1 }
            // Local aligned votes take precedence. Image-wide frequency can only
            // break a tie, never replace a majority with an unrelated identifier.
            // Equal frequency retains the representative pass / stable candidate order.
            var selected = tokens[i]
            for word in votes[i] where !word.isEmpty {
                let count = counts[word, default: 0], selectedCount = counts[selected, default: 0]
                if count > selectedCount || (count == selectedCount &&
                    frequency[word, default: 0] > frequency[selected, default: 0]) {
                    selected = word
                }
            }
            output.append(selected)
        }
        return output.joined(separator: " ")
    }
    private static func majority(_ words: [String]) -> String {
        var counts: [String: Int] = [:], best = "", highest = 0
        for word in words { counts[word, default: 0] += 1 }
        for word in words where counts[word]! > highest { best = word; highest = counts[word]! }
        return best
    }
    static func align(_ a: [String], _ b: [String]) -> (words: [String], insertions: [String]) {
        let width = b.count + 1
        var costs = [Double](repeating: 0, count: (a.count + 1) * width)
        var directions = [UInt8](repeating: 0, count: costs.count)
        for i in 0...a.count { costs[i * width] = Double(i); directions[i * width] = 1 }
        for j in 0...b.count { costs[j] = Double(j); directions[j] = 2 }
        if !a.isEmpty && !b.isEmpty {
            var similarities: [String: Double] = [:]
            for i in 1...a.count { for j in 1...b.count {
                let key = a[i-1] + "\0" + b[j-1]
                let similarity = similarities[key] ?? Self.similarity(a[i-1], b[j-1])
                similarities[key] = similarity
                let p = i * width + j
                let diagonal = costs[p-width-1] + 1 - similarity
                let deletion = costs[p-width] + 1, insertion = costs[p-1] + 1
                costs[p] = diagonal; directions[p] = 0
                if deletion < costs[p] { costs[p] = deletion; directions[p] = 1 }
                if insertion < costs[p] { costs[p] = insertion; directions[p] = 2 }
            } }
        }
        var words = [String](repeating: "", count: a.count), inserted = [String](repeating: "", count: a.count + 1)
        var i = a.count, j = b.count
        while i > 0 || j > 0 {
            switch directions[i * width + j] {
            case 0: words[i-1] = b[j-1]; i -= 1; j -= 1
            case 1: i -= 1
            default: inserted[i] = b[j-1] + (inserted[i].isEmpty ? "" : " " + inserted[i]); j -= 1
            }
        }
        return (words, inserted)
    }
}
