#if os(watchOS)

import SwiftUI

/// Option set that determines the displayed components of a date picker.
@available(watchOS 8, *)
public struct DatePickerComponents: OptionSet {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  
  /// Displays day, month, and year based on the locale.
  public static let date = Self(rawValue: 1 << 0)
  
  /// Displays hour and minute components based on the locale.
  public static let hourAndMinute = Self(rawValue: 1 << 1)
}

/// Enum that determines the interaction style of a date picker.
@available(watchOS 8, *)
public enum DatePickerInteractionStyle {
  /// Displays the date picking interface in a sheet.
  case sheet

  /// Pushes the date picking interface onto the navigation stack.
  case navigationLink
}

/// A control for the inputting of date and time values.
///
/// The `DatePicker` view displays a button with a title and the selected value. When pressed, it presents a user interface for selecting date, time, or both. The view binds to a `Date` instance.
///
/// ![](DatePicker.png)
@available(watchOS 8, *)
public struct DatePicker<Label: View>: View {
  public typealias Components = DatePickerComponents

  @ViewBuilder var label: Label
  @Binding var selection: Date?
  let displayedComponents: Components

  @State private var newSelection: Date?
  private let selectionIsOptional: Bool
  private var minimumDate: Date?
  private var maximumDate: Date?

  @State private var isPresented = false
  @State private var secondViewIsPresented = false

  @Environment(\.locale) private var locale

  @Environment(\.datePickerFlipsLabelAndValue) private var flipsLabelAndValue
  @Environment(\.datePickerInteractionStyle) private var interactionStyle
  @Environment(\.datePickerConfirmationTitleKey) private var confirmationTitleKey
  @Environment(\.datePickerConfirmationTint) private var confirmationTint
  @Environment(\.datePickerDefaultSelection) private var _defaultSelection

  private var defaultSelection: Date {
    _defaultSelection ?? (displayedComponents == .date ? Calendar.current.startOfDay(for: .now) : .nextHour)
  }

  @ViewBuilder private var formattedButtonTitle: some View {
    if let selection = selection {
      switch displayedComponents {
      case [.date, .hourAndMinute]:
        Text(selection, format: Date.FormatStyle(date: .numeric, time: .shortened).hour(.twoDigits(amPM: .abbreviated)))
      case .date:
        Text(selection, format: Date.FormatStyle(date: .abbreviated).weekday(.abbreviated))
      case .hourAndMinute:
        Text(selection, format: Date.FormatStyle(time: .shortened).hour(.twoDigits(amPM: .abbreviated)))
      default:
        fatalError()
      }
    } else {
      Text("None", bundle: .module)
    }
  }

  private var confirmationButton: some View {
    Button(action: {
      if displayedComponents == [.date, .hourAndMinute] {
        secondViewIsPresented = true
      } else {
        submit()
      }
    }) {
      if let confirmationTitleKey = confirmationTitleKey {
        Text(confirmationTitleKey).bold()
      } else if displayedComponents == [.date, .hourAndMinute] {
        Text("Continue", bundle: .module).bold()
      } else {
        Text("Set", bundle: .module).bold()
      }
    }
    .accessibilityIdentifier("DoneButton")
    .buttonStyle(.borderedProminent)
    .foregroundStyle(.background)
    .tint(confirmationTint ?? .green)
    .padding(.horizontal, 0.5)
    .padding(.vertical)
  }
  
  private var circularButtons: some View {
    HStack {
      cancelOrBackButton
      
      Spacer()
      
      submitButton
    }
    .padding(.horizontal, 12)
  }
  
  @ViewBuilder private var cancelOrBackButton: some View {
    if displayedComponents == [.date, .hourAndMinute], !isWatchOS10 {
      Button(action: { secondViewIsPresented = false }) {
        Image(systemName: "chevron.backward")
      }
      .accessibilityLabel(Text("Back", bundle: .module))
      .accessibilityIdentifier("BackButton")
      .buttonStyle(.circular())
    } 
    else {
      Button(action: { isPresented = false }) {
        Image(systemName: "xmark")
      }
      .accessibilityLabel(Text("Cancel", bundle: .module))
      .accessibilityIdentifier("CancelButton")
      .buttonStyle(.circular())
    }
  }
  
  @ViewBuilder private var submitButton: some View {
    Button(action: submit) {
      Image(systemName: "checkmark")
    }
    .accessibilityLabel(Text("Done", bundle: .module))
    .accessibilityIdentifier("DoneButton")
    .accessibilityRemoveTraits(.isSelected)
    .buttonStyle(.circular(confirmationTint ?? .green))
  }

  private func submit() {
    isPresented = false
    selection = newSelection

    if secondViewIsPresented {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        secondViewIsPresented = false
      }
    }
  }

  private func clear() {
    newSelection = nil
    submit()
  }

  private var buttonBody: some View {
    VStack(alignment: .leading) {
      if flipsLabelAndValue != true {
        label
        
        formattedButtonTitle
          .font(.footnote)
          .foregroundStyle(.secondary)
      } else {
        formattedButtonTitle
        
        label
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
  }
  
  private var isWatchOS10: Bool {
    if #available(watchOS 10, *) {
		return true
	}

	return false
	}

 	private var dateInput: some View {
    VStack(spacing: 10) {
      DateInputView(selection: $newSelection, minimumDate: minimumDate, maximumDate: maximumDate)
        .padding(.top, 20)

      if displayedComponents == [.date] {
        confirmationButton
      }
    }
    .edgesIgnoringSafeArea([.bottom, .horizontal])
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        if selectionIsOptional {
          Button(action: clear) { Text("Clear", bundle: .module) }
            .accessibilityIdentifier("ClearButton")
            .foregroundColor(.red)
        }
      }
    }
  }

  private var timeInput: some View {
    ZStack(alignment: .bottom) {
      TimeInputView(selection: $newSelection)

      if #unavailable(watchOS 10) {
        circularButtons
          .padding(.bottom, 16)
          .padding(.horizontal, -24)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationBarHidden( !isWatchOS10)
    .watchStatusBar(hidden: !isWatchOS10)
    .edgesIgnoringSafeArea(.all)
    .padding(.bottom, -40)
    .padding(.horizontal, 20)
    //.offset(y: -45)
    .overlay(alignment: .topTrailing) {
      if selectionIsOptional, displayedComponents == .hourAndMinute {
        Button(action: clear) { Image(systemName: "trash.fill") }
          .accessibilityIdentifier("ClearButton")
          .accessibilityLabel(Text("Clear", bundle: .module))
          .buttonStyle(.smallCircular(.red))
          .offset(y: -30)
          .padding(8)
      }
    }
    .toolbar {
      #if compiler(>=5.9)
      if #available(watchOS 10, *) {
        if !displayedComponents.contains(.date) {
          ToolbarItem(placement: .topBarLeading) {
            cancelOrBackButton
          }
        }
        
        ToolbarItem(placement: .topBarTrailing) {
          submitButton
        }
      }
      #endif
    }
  }

  @ViewBuilder private var mainBody: some View {
    switch displayedComponents {
    case [.date, .hourAndMinute]:
      NavigationView {
        dateInput
          .overlay {
            NavigationLink(isActive: $secondViewIsPresented) {
              timeInput
            } label: {
              EmptyView()
            }
            .hidden()
          }
        
        confirmationButton
      }
      .edgesIgnoringSafeArea(.bottom)
      .scenePadding(.bottom)
      
    case .date:
      dateInput
      
    case .hourAndMinute:
      timeInput
      
    default:
      fatalError()
    }
  }

  /// The content and behavior of the view.
  public var body: some View {
    Group {
      switch interactionStyle {
      case .sheet:
        Button(action: { isPresented = true }) {
          buttonBody
        }
        .sheet(isPresented: $isPresented) {
          mainBody
        }

      case .navigationLink:
        NavigationLink(isActive: $isPresented) {
          mainBody
        } label: {
          buttonBody
        }
      }
    }
    .onChange(of: isPresented) {
      if !$0 { secondViewIsPresented = false }
      newSelection = selection ?? defaultSelection
    }
    .onChange(of: selection) { newValue in
      if newSelection != newValue {
        newSelection = newValue ?? defaultSelection
      }
    }
  }
}

// MARK: - Initializers

@available(watchOS 8, *)
extension DatePicker {
  /// Creates an instance that selects a `Date` with an unbounded range.
  ///
  /// - Parameters:
  ///   - selection: The date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    self.displayedComponents = displayedComponents
    self.label = label()
  }

  /// Creates an instance that selects a `Date` in a closed range.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - selection: The date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
    self.label = label()
  }

  /// Creates an instance that selects a `Date` on or after some start date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
    self.label = label()
  }

  /// Creates an instance that selects a `Date` on or before some end date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
    self.label = label()
  }
}

@available(watchOS 8, *)
extension DatePicker where Label == Text {
  /// Creates an instance that selects a `Date` with an unbounded range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects a `Date` in a closed range.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects a `Date` on or after some start date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects a `Date` on or before some end date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }
}

@available(watchOS 8, *)
extension DatePicker where Label == Text {
  /// Creates an instance that selects a `Date` with an unbounded range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects a `Date` in a closed range.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects a `Date` on or after some start date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects a `Date` on or before some end date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = Binding(selection)
    _newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = false
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }
}

@available(watchOS 8, *)
extension DatePicker {
  /// Creates an instance that selects an optional `Date` with an unbounded range.
  ///
  /// - Parameters:
  ///   - selection: The optional date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date?>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    self.displayedComponents = displayedComponents
    self.label = label()
  }

  /// Creates an instance that selects an optional `Date` in a closed range.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date?>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
    self.label = label()
  }

  /// Creates an instance that selects an optional `Date` on or after some start date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date?>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
    self.label = label()
  }

  /// Creates an instance that selects an optional `Date` on or before some end date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  ///   - label: A view that describes the use of the date.
  public init(
    selection: Binding<Date?>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.date, .hourAndMinute],
    label: () -> Label
  ) {
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
    self.label = label()
  }
}

@available(watchOS 8, *)
extension DatePicker where Label == Text {
  /// Creates an instance that selects an optional `Date` with an unbounded range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date?>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects an optional `Date` in a closed range.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date?>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects an optional `Date` on or after some start date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date?>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects an optional `Date` on or before some end date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The key for the localized title of `self`, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  public init(
    _ titleKey: LocalizedStringKey,
    selection: Binding<Date?>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(titleKey)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }
}

@available(watchOS 8, *)
extension DatePicker where Label == Text {
  /// Creates an instance that selects an optional `Date` with an unbounded range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date?>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects an optional `Date` in a closed range.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The inclusive range of selectable dates.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date?>,
    in range: ClosedRange<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    minimumDate = range.lowerBound
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects an optional `Date` on or after some start date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The open range from some selectable start date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date?>,
    in range: PartialRangeFrom<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    minimumDate = range.lowerBound
    self.displayedComponents = displayedComponents
  }

  /// Creates an instance that selects an optional `Date` on or before some end date.
  ///
  /// Only selection of day, month, and year, not hour and minute, will adhere to the range.
  ///
  /// - Parameters:
  ///   - label: The title of self, describing its purpose.
  ///   - selection: The optional date value being displayed and selected.
  ///   - range: The open range before some selectable end date.
  ///   - displayedComponents: The date components that user is able to view and edit. Defaults to `[.date, .hourAndMinute]`.
  @_disfavoredOverload public init<S: StringProtocol>(
    _ title: S,
    selection: Binding<Date?>,
    in range: PartialRangeThrough<Date>,
    displayedComponents: Components = [.date, .hourAndMinute]
  ) {
    label = Text(title)
    _selection = selection
    //_newSelection = State(initialValue: selection.wrappedValue)
    selectionIsOptional = true
    maximumDate = range.upperBound
    self.displayedComponents = displayedComponents
  }
}

// MARK: -

struct DatePicker_Previews: PreviewProvider {
  struct Example: View {
    @State var value = Calendar.current.date(bySettingHour: 10, minute: 09, second: 0, of: Date())!
    
    var body: some View {
      Form {
        DatePicker("Select Date & Time", selection: $value)
        DatePicker("Select Date", selection: $value, displayedComponents: .date)
        DatePicker("Select Time", selection: $value, displayedComponents: .hourAndMinute)

        DatePicker(selection: $value) {
          Label("Select Date & Time", systemImage: "clock")
        }

        DatePicker(String("Select Date & Time"), selection: $value)
      }
      .tint(.orange)
    }
  }

  static var previews: some View {
    NavigationView {
      Example()
    }
  }
}

#endif
