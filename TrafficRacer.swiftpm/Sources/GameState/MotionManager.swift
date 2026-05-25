import Foundation
import CoreMotion

public class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    
    @Published public var tiltSteerValue: Double = 0.0 // Ranges from -1.0 (full left) to +1.0 (full right)
    
    public init() {}
    
    public func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("CoreMotion: Device motion is not available on this device/simulator.")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0 // 60Hz update rate
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
            guard let self = self, let data = data else { return }
            
            // In Landscape Right orientation:
            // Tilting the top towards the player = negative pitch/roll?
            // Let's use the roll angle as steering:
            // Roll will be 0 when held upright in Landscape, rotating will give -90 to +90 degrees.
            
            let roll = data.attitude.roll
            let pitch = data.attitude.pitch
            
            // Landscape orientation: standard steering uses device roll or gravity components.
            // Let's normalize it so roughly 30 degrees tilt gives full steering output (-1.0 to 1.0)
            let maxTiltAngle = 0.5 // approx 30 degrees in radians
            
            // Depending on landscape orientation (Left vs Right), we map gravity:
            // Standard approach: use attitude roll or pitch depending on reference frame.
            // Let's grab attitude.pitch for steering in standard landscape:
            let steer = pitch / maxTiltAngle
            
            // Clamp between -1.0 and 1.0
            DispatchQueue.main.async {
                self.tiltSteerValue = min(1.0, max(-1.0, steer))
            }
        }
    }
    
    public func stopUpdates() {
        if motionManager.isDeviceMotionActive {
            motionManager.stopDeviceMotionUpdates()
        }
        tiltSteerValue = 0.0
    }
}
