import Flutter
import UIKit

struct SidebarItemModel: Hashable {
    let id: String
    let title: String
    let systemImage: String?
    let imageData: Data?
    let badge: String?

    init?(dict: [String: Any]) {
        guard let id = dict["id"] as? String,
              let title = dict["title"] as? String else { return nil }
        self.id = id
        self.title = title
        self.systemImage = dict["systemImage"] as? String
        self.badge = dict["badge"] as? String

        if let typedData = dict["imageData"] as? FlutterStandardTypedData {
            self.imageData = typedData.data
        } else {
            self.imageData = nil
        }
    }

    // systemImage takes priority; falls back to imageData bytes
    var resolvedIcon: UIImage? {
        if let name = systemImage {
            return UIImage(systemName: name)
        }
        if let data = imageData {
            return UIImage(data: data)
        }
        return nil
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SidebarItemModel, rhs: SidebarItemModel) -> Bool {
        lhs.id == rhs.id
    }
}
