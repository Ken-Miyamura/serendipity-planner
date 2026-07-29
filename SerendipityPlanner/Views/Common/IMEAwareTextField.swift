import SwiftUI
import UIKit

/// IME の変換中（未確定文字列）を検出できるテキストフィールド。
///
/// SwiftUI の `TextField` は未確定文字列でも変更を通知するため、
/// 「出雲大社」を入力する過程の「出雲大」のような中途半端な文字列で検索が走ってしまう。
/// `UITextField.markedTextRange` を見れば変換中かどうかが判定できるので、
/// 呼び出し側が確定前の検索を抑止できるよう `isComposing` を添えて通知する。
struct IMEAwareTextField: UIViewRepresentable {
    let placeholder: String
    /// クリアボタンなど、外側から文字列を差し替えるための双方向バインディング
    @Binding var text: String
    /// 入力変更の通知。`isComposing` が true の間は IME 変換中（未確定）。
    let onChange: (String, Bool) -> Void

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.autocorrectionType = .no
        field.returnKeyType = .search
        field.clearButtonMode = .never
        field.font = UIFont.preferredFont(forTextStyle: .body)
        field.adjustsFontForContentSizeCategory = true
        field.delegate = context.coordinator
        field.addTarget(
            context.coordinator,
            action: #selector(Coordinator.editingChanged(_:)),
            for: .editingChanged
        )
        // HStack 内で横に伸び、縦は内容ぶんに収める
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        context.coordinator.parent = self
        // 変換中に外から書き戻すと入力が壊れるため、確定済みのときだけ同期する
        if uiView.markedTextRange == nil, uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: IMEAwareTextField

        init(parent: IMEAwareTextField) {
            self.parent = parent
        }

        @objc func editingChanged(_ field: UITextField) {
            // markedTextRange が非 nil の間は未確定（変換中）
            parent.onChange(field.text ?? "", field.markedTextRange != nil)
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
