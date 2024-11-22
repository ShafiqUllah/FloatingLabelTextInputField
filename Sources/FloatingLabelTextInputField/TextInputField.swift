//
//  TextInputField.swift
//  TextInputFieldWithFloatingLabel
//
//  Created by test on 11/21/24.
//

import SwiftUI

public struct TextInputField: View {
    var title : String
    @Binding var text: String
    @Environment(\.clearButtonHidden) var clearButtonHidden
    @Environment(\.isMandatory) var isMandatory
    @Environment(\.validationHandler) var validationHandler
    
    @Binding private var isValidBinding: Bool
    @State private var isValid:Bool = true {
        didSet{
            isValidBinding = isValid
        }
    }
    @State var validationMessage : String = ""
    
    public init(_ title: String, text: Binding<String>, isValid isValidBinding: Binding<Bool>? = nil) {
        self.title = title
        self._text = text
        self._isValidBinding = isValidBinding ?? .constant(true)
    }
    
    var clearButton: some View{
        HStack {
            if !clearButtonHidden {
                Spacer()
                Button {
                    text = ""
                } label: {
                    Image(systemName: "multiply.circle.fill")
                        .foregroundStyle(Color(.systemGray))
                }
            }
            
            
        }
    }
    
    var clearButtonPadding: CGFloat{
        !clearButtonHidden ? 25 : 0
    }
    
    fileprivate func validate(_ newValue: String) {
        isValid = true
        if isMandatory{
            isValid = !newValue.isEmpty
            validationMessage = isValid ? "" : "This is a mandatory field"
        }
        
        if isValid{
            guard let validationHandler = self.validationHandler else { return }
            
            let validationResult = validationHandler(newValue)
            
            if case .failure(let error) = validationResult{
                isValid = false
                self.validationMessage = "\(error.localizedDescription)"
            }else if case .success(let isValid) = validationResult{
                self.isValid = true
                self.validationMessage = ""
            }
        }
    }
    
    public var body: some View {
        ZStack(alignment: .leading){
            
            if !isValid{
                Text(validationMessage)
                    .foregroundStyle(.red)
                    .offset(y: -25)
                    .scaleEffect(0.8, anchor: .leading)
            }
            
            if text.isEmpty || isValid{
                Text(title)
                    .foregroundStyle(text.isEmpty ? Color(.placeholderText) : .accentColor)
                    .offset(y: text.isEmpty ? 0 : -25)
                    .scaleEffect(text.isEmpty ? 1 : 0.8, anchor: .leading)
            }

            TextField("", text: $text)
                .onAppear(perform: {
                    validate(text)
                })
                .onChange(of: text, { oldValue, newValue in
                    validate(newValue)
                })
                
                .padding(.trailing, clearButtonPadding)
                .overlay {
                    clearButton
                }
        }
        .padding(.top, 15)
        .animation(.default, value: text)
    }
}




// Creating new Environment Key for ClearButton Hidden
private struct TextInputFiledClearButtonHidden: @preconcurrency EnvironmentKey{
    @MainActor static var defaultValue: Bool = false
}

extension EnvironmentValues{
    var clearButtonHidden: Bool{
        get{
            self[TextInputFiledClearButtonHidden.self]
        }
        set{
            self[TextInputFiledClearButtonHidden.self] = newValue
        }
    }
}

extension View{ // instead of doing TextInputField extension , we want to apply our envirment valriable to View to work in all trypes of variable
    public func clearButtonHidden(_ hiddenClearButton: Bool = true)-> some View{
        environment(\.clearButtonHidden, hiddenClearButton)
    }
}



// Creating new Environment Key for
private struct TextInputFieldMandatory: @preconcurrency EnvironmentKey{
    @MainActor static var defaultValue: Bool = false
}

extension EnvironmentValues{
    var isMandatory: Bool{
        get{
            self[TextInputFieldMandatory.self]
        }
        set{
            self[TextInputFieldMandatory.self] = newValue
        }
    }
}


extension View{
    public func isMandatory(_ value: Bool = true)->some View{
        environment(\.isMandatory, value)
    }
}

public struct ValidationError : Error{
    let message : String
    
    public init(message: String) {
        self.message = message
    }
}

extension ValidationError: LocalizedError{
    public var errorDescription: String? {
        return NSLocalizedString("\(message)", comment: "Message for generic validation errors.")
    }
}

private struct TextInputFieldValidationHandler : @preconcurrency EnvironmentKey{
    @MainActor static var defaultValue: ((String)->Result<Bool, ValidationError>)?
}

extension EnvironmentValues{
    var validationHandler : ((String) -> Result<Bool, ValidationError>)? {
        get{
            self[TextInputFieldValidationHandler.self]
        }
        
        set{
            self[TextInputFieldValidationHandler.self] = newValue
        }
    }
}

extension View{
    public func onValidate(validationHandler: @escaping (String)-> Result<Bool, ValidationError>) -> some View{
        environment(\.validationHandler, validationHandler)
    }
}


#Preview {
    TextInputField("First name", text: .constant("Shafiq"))
}
