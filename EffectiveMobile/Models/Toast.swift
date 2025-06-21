import Foundation
import SimpleToast
import SwiftUI

@MainActor
public extension SimpleToastOptions {
    static var defaultOptions: SimpleToastOptions = {
        SimpleToastOptions(
            alignment: .top,
            hideAfter: 3,
            animation: .snappy,
            modifierType: .slide
        )
    }()
    static var defaultBottomOptions: SimpleToastOptions = {
        SimpleToastOptions(
            alignment: .bottom,
            hideAfter: 3,
            animation: .snappy,
            modifierType: .slide
        )
    }()
}


public struct ToastState: Equatable, Identifiable, Sendable {
    public var id: String {
        "\(title)_\(subtitle)_\(type.rawValue)"
    }
    
    public var title: String
    public var subtitle: String
    public var type: ToastView.ToastType
        
    public init(title: String, subtitle: String, type: ToastView.ToastType) {
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
}

public struct ToastView: View {
    public enum ToastType: Int, Equatable, Sendable {
        case error
        case success
        case `default`

        var systemImageName: String {
            switch self {
            case .error:
                return "exclamationmark.circle"
            case .success:
                return "checkmark.circle"
            case .default:
                return ""
            }
        }
        
        var iconColor: Color {
            switch self {
            case .error:
                return .red
            case .success:
                return .green
            case .default:
                return .clear
            }
        }
    }
    
    public var title: String?
    public var subtitle: String?
    public var type: ToastType?
    
    public init(title: String?, subtitle: String?, type: ToastType?) {
        self.title = title
        self.subtitle = subtitle
        self.type = type
    }
    
    public var body: some View {
        if let title, let subtitle, let type {
            HStack {
                Image(systemName: type.systemImageName)
                    .fontWeight(.semibold)
                    .foregroundStyle(type.iconColor)
                VStack(alignment: .leading) {
                    if !title.isEmpty {
                        Text(title)
                            .font(.body.weight(.semibold))
                    }
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(10)
            .background(Color(.black.withAlphaComponent(0.5)))
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal)
        }
        EmptyView()
    }
}

#Preview {
    VStack {
        Spacer()
        HStack {
            Spacer()
            Text("Test")
            Spacer()
        }
        Spacer()
    }
    .background(Color.red)
    .simpleToast(
        isPresented: .constant(true),
        options: .defaultOptions
    ) {
        ToastView(title: "Error", subtitle: "Error message, Error message, Error message Error message, Error message, Error message Error message, Error message, Error message Error message, Error message, Error message", type: .error)
    }
}
