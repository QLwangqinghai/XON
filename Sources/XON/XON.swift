
import Foundation

public struct XON {
    public static let domain = String(cString: XONErrorDomain)
    public static let countMax: UInt64 = UInt64.max >> 8
    
    public static let objectError: NSError = error(code: XONErrorContent)
    public static let countError: NSError = error(code: XONErrorCount)
    public static let contentError: NSError = error(code: XONErrorContent)
    public static let typeError: NSError = error(code: XONErrorType)
    public static let notEnoughError: NSError = error(code: XONErrorNotEnough)
    public static let stringContentError: NSError = error(code: XONErrorStringContent)
    public static let numberOutOfBoundsError: NSError = error(code: XONErrorNumberOutOfBounds)
    
    public static let fieldNotFound: NSError = error(code: XONErrorFieldNotFound)

    public static func error(code: XONError_e) -> NSError {
        return NSError(domain: domain, code: Int(code.rawValue))
    }
}

