import Foundation

/// A bounded inert tokenizer for feed text and image attributes, not a browser renderer.
enum NewsHTML {
  struct Content {
    let text: String
    let imageAttributes: [String: String]?
  }

  static func parse(_ html: String) -> Content {
    let chars = Array(html.prefix(65_536))
    var index = 0
    var text = ""
    var image: [String: String]?
    var hidden: String?
    while index < chars.count {
      guard chars[index] == "<" else {
        if hidden == nil { text.append(chars[index]) }
        index += 1
        continue
      }
      if index + 3 < chars.count, String(chars[index...index + 3]) == "<!--" {
        index += 4
        while index + 2 < chars.count && String(chars[index...index + 2]) != "-->" { index += 1 }
        index = min(index + 3, chars.count)
        continue
      }
      let start = index + 1
      index = start
      var quote: Character?
      while index < chars.count {
        let character = chars[index]
        if let current = quote {
          if character == current { quote = nil }
        } else if character == "\"" || character == "'" {
          quote = character
        } else if character == ">" {
          break
        }
        index += 1
      }
      guard index < chars.count else { break }
      let tag = String(chars[start..<index])
      index += 1
      let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
      let closing = trimmed.hasPrefix("/")
      let body = closing ? String(trimmed.dropFirst()) : trimmed
      let name = String(body.prefix { $0.isLetter || $0.isNumber }).lowercased()
      if let current = hidden {
        if closing && name == current { hidden = nil }
        continue
      }
      if name == "script" || name == "style" {
        if !closing { hidden = name }
        continue
      }
      if name == "img", !closing, image == nil {
        image = attributes(String(body.dropFirst(name.count)))
      }
      if ["p", "br", "div", "li"].contains(name) { text.append(" ") }
    }
    return Content(
      text: entities(text).split(whereSeparator: \.isWhitespace).joined(separator: " "),
      imageAttributes: image)
  }

  private static func attributes(_ input: String) -> [String: String] {
    let chars = Array(input)
    var index = 0
    var result: [String: String] = [:]
    while index < chars.count {
      while index < chars.count && (chars[index].isWhitespace || chars[index] == "/") { index += 1 }
      let start = index
      while index < chars.count && !chars[index].isWhitespace && chars[index] != "=" { index += 1 }
      let name = String(chars[start..<index]).lowercased()
      while index < chars.count && chars[index].isWhitespace { index += 1 }
      guard index < chars.count, chars[index] == "=" else { continue }
      index += 1
      while index < chars.count && chars[index].isWhitespace { index += 1 }
      guard index < chars.count else { break }
      let quote: Character? = ["\"", "'"].contains(chars[index]) ? chars[index] : nil
      if quote != nil { index += 1 }
      let valueStart = index
      while index < chars.count
        && (quote != nil ? chars[index] != quote : !chars[index].isWhitespace)
      { index += 1 }
      if result[name] == nil { result[name] = entities(String(chars[valueStart..<index])) }
      if quote != nil && index < chars.count { index += 1 }
    }
    return result
  }

  static func entities(_ input: String) -> String {
    let names = [
      "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ", "copy": "©",
      "ndash": "–", "mdash": "—", "hellip": "…", "ouml": "ö", "auml": "ä", "uuml": "ü", "Ouml": "Ö",
      "Auml": "Ä", "Uuml": "Ü", "szlig": "ß",
    ]
    var result = ""
    var index = input.startIndex
    while index < input.endIndex {
      if input[index] == "&", let end = input[index...].prefix(16).firstIndex(of: ";") {
        let token = String(input[input.index(after: index)..<end])
        var replacement = names[token]
        if token.hasPrefix("#") {
          let hex = token.hasPrefix("#x") || token.hasPrefix("#X")
          let digits = String(token.dropFirst(hex ? 2 : 1))
          if let number = UInt32(digits, radix: hex ? 16 : 10), number != 0,
            let scalar = UnicodeScalar(number)
          {
            replacement = String(scalar)
          }
        }
        if let replacement {
          result += replacement
          index = input.index(after: end)
          continue
        }
      }
      result.append(input[index])
      index = input.index(after: index)
    }
    return result
  }
}
