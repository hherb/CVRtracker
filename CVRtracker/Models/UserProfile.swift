import Foundation
import SwiftData

enum Sex: String, Codable, CaseIterable {
    case male = "Male"
    case female = "Female"
}

@Model
final class UserProfile {
    var id: UUID
    var age: Int
    var sex: Sex
    var totalCholesterol: Double  // mg/dL
    var hdlCholesterol: Double    // mg/dL
    var onHypertensionTreatment: Bool
    var isSmoker: Bool
    var hasDiabetes: Bool

    init(
        age: Int = 50,
        sex: Sex = .male,
        totalCholesterol: Double = 200,
        hdlCholesterol: Double = 50,
        onHypertensionTreatment: Bool = false,
        isSmoker: Bool = false,
        hasDiabetes: Bool = false
    ) {
        self.id = UUID()
        self.age = age
        self.sex = sex
        self.totalCholesterol = totalCholesterol
        self.hdlCholesterol = hdlCholesterol
        self.onHypertensionTreatment = onHypertensionTreatment
        self.isSmoker = isSmoker
        self.hasDiabetes = hasDiabetes
    }

    var isComplete: Bool {
        age >= 30 && age <= 79 &&
        totalCholesterol > 0 &&
        hdlCholesterol > 0
    }
}
