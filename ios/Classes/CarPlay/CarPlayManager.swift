import Foundation
import UIKit
import CarPlay

@available(iOS 14.0, *)
public class GMNSCarPlayManager: NSObject {
  public static func makeRootTemplate() -> CPTemplate {
    let item = CPListItem(text: "Configurar credenciais do Navigation SDK", detailText: "Este é um scaffold para CarPlay.")
    let section = CPListSection(items: [item])
    let list = CPListTemplate(title: "Google Maps Native SDK", sections: [section])
    return list
  }
}

