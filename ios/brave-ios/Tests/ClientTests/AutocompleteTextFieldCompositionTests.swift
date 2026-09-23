// Copyright 2026 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

import UIKit
import XCTest

@testable import Brave

@MainActor
final class AutocompleteTextFieldCompositionTests: XCTestCase {
  private var window: UIWindow!
  private var field: AutocompleteTextField!
  private var delegate: CompositionDelegate!

  override func setUp() {
    super.setUp()
    window = UIWindow(frame: CGRect(x: 0, y: 0, width: 600, height: 400))
    window.rootViewController = UIViewController()
    field = AutocompleteTextField(privateBrowsingManager: PrivateBrowsingManager())
    field.frame = CGRect(x: 20, y: 20, width: 500, height: 44)
    delegate = CompositionDelegate()
    field.autocompleteDelegate = delegate
    window.rootViewController?.view.addSubview(field)
    window.makeKeyAndVisible()
    XCTAssertTrue(field.becomeFirstResponder())
  }

  override func tearDown() {
    field.resignFirstResponder()
    window.isHidden = true
    field = nil
    delegate = nil
    window = nil
    super.tearDown()
  }

  private func beginComposition() {
    field.setMarkedText("nihao", selectedRange: NSRange(location: 5, length: 0))
    XCTAssertNotNil(field.markedTextRange)
  }

  func testCompositionDoesNotSubmitOrCancelAddressBar() {
    beginComposition()
    XCTAssertFalse(field.textFieldShouldReturn(field))
    field.handleKeyCommand(
      sender: UIKeyCommand(
        input: UIKeyCommand.inputEscape,
        modifierFlags: [],
        action: #selector(noop)
      )
    )
    XCTAssertEqual(delegate.returnCount, 0)
    XCTAssertEqual(delegate.cancelCount, 0)
    XCTAssertNotNil(field.markedTextRange)
    XCTAssertEqual(field.text, "nihao")
  }

  func testCompositionDoesNotRegisterAddressBarArrowKeys() {
    beginComposition()
    let inputs = (field.keyCommands ?? []).compactMap(\.input)
    XCTAssertFalse(inputs.contains(UIKeyCommand.inputLeftArrow))
    XCTAssertFalse(inputs.contains(UIKeyCommand.inputRightArrow))
    XCTAssertFalse(inputs.contains(UIKeyCommand.inputEscape))
    field.unmarkText()
    XCTAssertTrue(
      (field.keyCommands ?? []).compactMap(\.input).contains(UIKeyCommand.inputLeftArrow)
    )
  }

  func testPendingSearchDoesNotRunDuringComposition() async {
    let search = expectation(description: "No search for uncommitted pinyin")
    search.isInverted = true
    delegate.onSearch = { _ in search.fulfill() }
    field.lastReplacement = "n"
    field.text = "n"
    beginComposition()
    await fulfillment(of: [search], timeout: 0.3)
  }

  func testCommittedTextResumesSearch() async {
    beginComposition()
    field.setMarkedText("你好", selectedRange: NSRange(location: 2, length: 0))
    let search = expectation(description: "Search committed Chinese text")
    delegate.onSearch = { text in
      XCTAssertEqual(text, "你好")
      search.fulfill()
    }
    field.unmarkText()
    XCTAssertNil(field.markedTextRange)
    await fulfillment(of: [search], timeout: 1)
    XCTAssertTrue(field.textFieldShouldReturn(field))
    XCTAssertEqual(delegate.returnCount, 1)
  }

  func testSuggestionDoesNotReplaceMarkedText() {
    beginComposition()
    field.setAutocompleteSuggestion("nihao.example")
    XCTAssertFalse(field.isSelectionActive)
    XCTAssertEqual(field.text, "nihao")
    XCTAssertNotNil(field.markedTextRange)
  }

  @objc private func noop() {}
}

@MainActor
private final class CompositionDelegate: AutocompleteTextFieldDelegate {
  var returnCount = 0
  var cancelCount = 0
  var onSearch: ((String) -> Void)?

  func autocompleteTextField(_ field: AutocompleteTextField, didEnterText text: String) {
    onSearch?(text)
  }
  func autocompleteTextField(_ field: AutocompleteTextField, didDeleteAutoSelectedText text: String)
  {}
  func autocompleteTextFieldShouldReturn(_ field: AutocompleteTextField) -> Bool {
    returnCount += 1
    return true
  }
  func autocompleteTextFieldShouldClear(_ field: AutocompleteTextField) -> Bool { true }
  func autocompleteTextFieldDidBeginEditing(_ field: AutocompleteTextField) {}
  func autocompleteTextFieldDidCancel(_ field: AutocompleteTextField) {
    cancelCount += 1
  }
}
