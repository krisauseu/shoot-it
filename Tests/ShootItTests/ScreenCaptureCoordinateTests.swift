import CoreGraphics
import Testing
@testable import ShootIt

struct ScreenCaptureCoordinateTests {
    @Test func appKitRectConvertsToCoreGraphicsCoordinates() {
        let mainHeight = CGDisplayBounds(CGMainDisplayID()).height
        let source = CGRect(x: 100, y: 200, width: 300, height: 150)
        let converted = ScreenCaptureService.coreGraphicsRect(from: source)

        #expect(converted == CGRect(x: 100, y: mainHeight - 350, width: 300, height: 150))
    }
}
