import Foundation

/// Parses LaTeX math strings into a ``MathList`` (abstract syntax tree).
///
/// The parser handles math delimiters (`$...$`, `$$...$$`, `\(...\)`, `\[...\]`),
/// commands (`\frac`, `\sqrt`, `\sum`, etc.), environments (`\begin{matrix}...\end{matrix}`),
/// and font-style switches (`\mathbf`, `\mathrm`, etc.).
///
/// ```swift
/// // Non-throwing — returns nil on parse error
/// let list = MathListBuilder.build(fromString: "x^2 + y^2 = z^2")
///
/// // Throwing — returns ParseError with details
/// let list = try MathListBuilder.buildChecked(fromString: "\\frac{1}{2}")
///
/// // Round-trip back to LaTeX
/// let latex = MathListBuilder.mathListToString(list)
/// ```
struct EnvProperties {
  var envName: String?
  var ended: Bool
  var numRows: Int
  var alignment: ColumnAlignment?  // Optional alignment for starred matrix environments

  init(name: String?, alignment: ColumnAlignment? = nil) {
    envName = name
    numRows = 0
    ended = false
    self.alignment = alignment
  }
}

/// An error encountered while parsing a LaTeX string with ``MathListBuilder``.
///
/// Each case carries a descriptive message string. Use `localizedDescription` to access it.
public enum ParseError: Error, Equatable {
  /// The braces { } do not match.
  case mismatchBraces(String)
  /// A command in the string is not recognized.
  case invalidCommand(String)
  /// An expected character such as ] was not found.
  case characterNotFound(String)
  /// The \left or \right command was not followed by a delimiter.
  case missingDelimiter(String)
  /// The delimiter following \left or \right was not a valid delimiter.
  case invalidDelimiter(String)
  /// There is no \right corresponding to the \left command.
  case missingRight(String)
  /// There is no \left corresponding to the \right command.
  case missingLeft(String)
  /// The environment given to the \begin command is not recognized
  case invalidEnv(String)
  /// A command is used which is only valid inside a \begin,\end environment
  case missingEnv(String)
  /// There is no \begin corresponding to the \end command.
  case missingBegin(String)
  /// There is no \end corresponding to the \begin command.
  case missingEnd(String)
  /// The number of columns do not match the environment
  case invalidNumColumns(String)
  /// Internal error, due to a programming mistake.
  case internalError(String)
  /// Limit control applied incorrectly
  case invalidLimits(String)

  public var localizedDescription: String {
    switch self {
    case .mismatchBraces(let message), .invalidCommand(let message),
      .characterNotFound(let message),
      .missingDelimiter(let message), .invalidDelimiter(let message), .missingRight(let message),
      .missingLeft(let message), .invalidEnv(let message), .missingEnv(let message),
      .missingBegin(let message), .missingEnd(let message), .invalidNumColumns(let message),
      .internalError(let message), .invalidLimits(let message):
      return message
    }
  }

  /// Bridge to NSError for backward compatibility.
  func asNSError() -> NSError {
    NSError(
      domain: "ParseError", code: 0,
      userInfo: [NSLocalizedDescriptionKey: localizedDescription],
    )
  }
}
