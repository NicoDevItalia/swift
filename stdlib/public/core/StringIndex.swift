//===--- StringIndex.swift ------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2017 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
extension String {
  /// A position of a character or code unit in a string.
  public struct Index {
    internal var _compoundOffset : UInt64
    @_versioned
    internal var _cache: _Cache

    internal typealias _UTF8Buffer = _ValidUTF8Buffer<UInt64>
    @_versioned
    internal enum _Cache {
    case utf16
    case utf8(buffer: _UTF8Buffer)
    case character(stride: UInt16)
    case unicodeScalar(value: Unicode.Scalar)
    }
  }
}

/// Convenience accessors
extension String.Index._Cache {
  var utf16: Void? {
    if case .utf16 = self { return () } else { return nil }
  }
  var utf8: String.Index._UTF8Buffer? {
    if case .utf8(let r) = self { return r } else { return nil }
  }
  var character: UInt16? {
    if case .character(let r) = self { return r } else { return nil }
  }
  var unicodeScalar: UnicodeScalar? {
    if case .unicodeScalar(let r) = self { return r } else { return nil }
  }
}

extension String.Index : Equatable {
  public static func == (lhs: String.Index, rhs: String.Index) -> Bool {
    return lhs._compoundOffset == rhs._compoundOffset
  }
}

extension String.Index : Comparable {
  public static func < (lhs: String.Index, rhs: String.Index) -> Bool {
    return lhs._compoundOffset < rhs._compoundOffset
  }
}

extension String.Index {
  internal typealias _Self = String.Index
  
  /// Creates a new index at the specified UTF-16 offset.
  ///
  /// - Parameter offset: An offset in UTF-16 code units.
  public init(encodedOffset offset: Int) {
    _compoundOffset = UInt64(offset << _Self._strideBits)
    _cache = .utf16
  }

  @_versioned
  internal init(encodedOffset o: Int, transcodedOffset: Int = 0, _ c: _Cache) {
    _compoundOffset = UInt64(o << _Self._strideBits | transcodedOffset)
    _cache = c
  }
  
  internal static var _strideBits : Int { return 16 }
  internal static var _mask : UInt64 { return (1 &<< _Self._strideBits) &- 1 }
  
  internal mutating func _setEncodedOffset(_ x: Int) {
    _compoundOffset = UInt64(x << _Self._strideBits)
  }
  
  /// The offset into a string's UTF-16 encoding for this index.
  public var encodedOffset : Int {
    return Int(_compoundOffset >> numericCast(_Self._strideBits))
  }

  /// The offset of this index within whatever encoding this is being viewed as
  @_versioned
  internal var _transcodedOffset : Int {
    get {
      return Int(_compoundOffset & _Self._mask)
    }
    set {
      let extended = UInt64(newValue)
      _sanityCheck(extended <= _Self._mask)
      _compoundOffset &= ~_Self._mask
      _compoundOffset |= extended
    }
  }
}

// SPI for Foundation
extension String.Index {
  @available(swift, deprecated: 3.2)
  @available(swift, obsoleted: 4.0)
  public // SPI(Foundation)    
  init(_position: Int) {
    self.init(encodedOffset: _position)
  }
  
  @available(swift, deprecated: 3.2)
  @available(swift, obsoleted: 4.0)
  public // SPI(Foundation)    
  init(_offset: Int) {
    self.init(encodedOffset: _offset)
  }
  
  @available(swift, deprecated: 3.2)
  @available(swift, obsoleted: 4.0)
  public // SPI(Foundation)    
  init(_base: String.Index, in c: String.CharacterView) {
    self = _base
  }
  
  /// The integer offset of this index in UTF-16 code units.
  @available(swift, deprecated: 3.2)
  @available(swift, obsoleted: 4.0)
  public // SPI(Foundation)
  var _utf16Index: Int {
    return self.encodedOffset
  }

  /// The integer offset of this index in UTF-16 code units.
  @available(swift, deprecated: 3.2)
  @available(swift, obsoleted: 4.0)
  public // SPI(Foundation)
  var _offset: Int {
    return self.encodedOffset
  }
}


// backward compatibility for index interchange.  
extension Optional where Wrapped == String.Index {
  @available(
    swift, obsoleted: 4.0,
    message: "Any String view index conversion can fail in Swift 4; please unwrap the optional indices")
  public static func ..<(
    lhs: String.Index?, rhs: String.Index?
  ) -> Range<String.Index> {
    return lhs! ..< rhs!
  }

  @available(
    swift, obsoleted: 4.0,
    message: "Any String view index conversion can fail in Swift 4; please unwrap the optional indices")
  public static func ...(
    lhs: String.Index?, rhs: String.Index?
  ) -> ClosedRange<String.Index> {
    return lhs! ... rhs!
  }
}
