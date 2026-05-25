import Foundation
import SceneKit

public class VehicleNodeFactory {
    
    // MARK: - Core Player Vehicle Builder
    
    public static func createPlayerVehicle(car: Car) -> SCNNode {
        let rootNode = SCNNode()
        rootNode.name = "player_car"
        
        // Convert hex colors
        let paintColor = UIColor(hex: car.paintColorHex)
        let neonColor = UIColor(hex: car.lightColorHex)
        
        // 1. Chassis Main Body
        // Sizing: Length=4.2, Width=1.8, Height=0.8
        let chassisGeo = SCNBox(width: 1.8, height: 0.6, length: 4.2, chamferRadius: 0.15)
        let chassisMat = SCNMaterial()
        chassisMat.diffuse.contents = paintColor
        chassisMat.roughness.contents = 0.15   // Sleek polished gloss
        chassisMat.metalness.contents = 0.85   // Metallic paint shine
        chassisMat.specular.contents = UIColor.white
        chassisGeo.materials = [chassisMat]
        
        let chassisNode = SCNNode(geometry: chassisGeo)
        chassisNode.position = SCNVector3(0, 0.45, 0) // elevated off ground
        rootNode.addChildNode(chassisNode)
        
        // 2. Cabin / Windshields
        let cabinGeo = SCNBox(width: 1.4, height: 0.5, length: 2.2, chamferRadius: 0.1)
        let cabinMat = SCNMaterial()
        cabinMat.diffuse.contents = UIColor.black
        cabinMat.roughness.contents = 0.05
        cabinMat.specular.contents = UIColor.white
        cabinGeo.materials = [cabinMat]
        
        let cabinNode = SCNNode(geometry: cabinGeo)
        cabinNode.position = SCNVector3(0, 0.45, -0.3) // offset on top of chassis towards back
        chassisNode.addChildNode(cabinNode)
        
        // 3. Sports Spoiler (if price or stats indicate a sporty vehicle)
        if car.price >= 50000 || car.name == "Phantom" || car.name == "Valkyrie" || car.name == "Apex" {
            let spoilerWingGeo = SCNBox(width: 1.7, height: 0.08, length: 0.4, chamferRadius: 0.02)
            let wingMat = SCNMaterial()
            wingMat.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0) // Carbon black spoiler
            spoilerWingGeo.materials = [wingMat]
            let wingNode = SCNNode(geometry: spoilerWingGeo)
            wingNode.position = SCNVector3(0, 0.45, 1.9)
            chassisNode.addChildNode(wingNode)
            
            // Spoiler Struts
            let strutGeo = SCNBox(width: 0.08, height: 0.25, length: 0.08, chamferRadius: 0.0)
            strutGeo.firstMaterial?.diffuse.contents = UIColor.black
            
            let leftStrut = SCNNode(geometry: strutGeo)
            leftStrut.position = SCNVector3(-0.6, 0.2, 1.9)
            chassisNode.addChildNode(leftStrut)
            
            let rightStrut = SCNNode(geometry: strutGeo)
            rightStrut.position = SCNVector3(0.6, 0.2, 1.9)
            chassisNode.addChildNode(rightStrut)
        }
        
        // 4. Wheels Assembly
        // standard wheel coordinates relative to chassis
        let wheelOffsets: [(x: Float, z: Float)] = [
            (-0.95, -1.3),  // Front Left
            (0.95, -1.3),   // Front Right
            (-0.95, 1.3),   // Rear Left
            (0.95, 1.3)     // Rear Right
        ]
        
        for offset in wheelOffsets {
            let wheelNode = createWheelNode(style: car.wheelStyle)
            wheelNode.position = SCNVector3(offset.x, 0.25, offset.z)
            rootNode.addChildNode(wheelNode)
        }
        
        // 5. Headlights
        let headlightGeo = SCNCylinder(radius: 0.12, height: 0.1)
        let headlightMat = SCNMaterial()
        headlightMat.diffuse.contents = UIColor.white
        headlightMat.emission.contents = neonColor
        headlightGeo.materials = [headlightMat]
        
        // Left Headlight
        let leftHL = SCNNode(geometry: headlightGeo)
        leftHL.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        leftHL.position = SCNVector3(-0.6, 0.0, -2.1)
        chassisNode.addChildNode(leftHL)
        
        // Right Headlight
        let rightHL = SCNNode(geometry: headlightGeo)
        rightHL.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        rightHL.position = SCNVector3(0.6, 0.0, -2.1)
        chassisNode.addChildNode(rightHL)
        
        // Dynamic Headlight Spotlights (Dynamic real lights)
        let spotLight = SCNLight()
        spotLight.type = .spot
        spotLight.color = neonColor
        spotLight.intensity = 1800
        spotLight.spotInnerAngle = 30
        spotLight.spotOuterAngle = 60
        spotLight.castsShadow = true
        spotLight.shadowRadius = 4.0
        spotLight.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let lightPivot = SCNNode()
        lightPivot.light = spotLight
        lightPivot.position = SCNVector3(0, 0, -2.2)
        // Point forward down the road
        lightPivot.rotation = SCNVector4(1, 0, 0, -Float.pi / 16)
        chassisNode.addChildNode(lightPivot)
        
        // 6. Taillights (Red)
        let tailGeo = SCNBox(width: 0.25, height: 0.08, length: 0.05, chamferRadius: 0.0)
        let tailMat = SCNMaterial()
        tailMat.diffuse.contents = UIColor.red
        tailMat.emission.contents = UIColor.red.withAlphaComponent(0.8)
        tailGeo.materials = [tailMat]
        
        let leftTL = SCNNode(geometry: tailGeo)
        leftTL.position = SCNVector3(-0.6, 0.0, 2.1)
        chassisNode.addChildNode(leftTL)
        
        let rightTL = SCNNode(geometry: tailGeo)
        rightTL.position = SCNVector3(0.6, 0.0, 2.1)
        chassisNode.addChildNode(rightTL)
        
        // 7. Dynamic Underglow Light
        let underglow = SCNLight()
        underglow.type = .omni
        underglow.color = neonColor
        underglow.intensity = 800
        underglow.attenuationStartDistance = 0.5
        underglow.attenuationEndDistance = 2.5
        
        let underglowNode = SCNNode()
        underglowNode.light = underglow
        underglowNode.position = SCNVector3(0, -0.4, 0)
        chassisNode.addChildNode(underglowNode)
        
        // 8. Customizable License Plate with 3D SCNText!
        let plateFrameGeo = SCNBox(width: 0.45, height: 0.18, length: 0.04, chamferRadius: 0.01)
        plateFrameGeo.firstMaterial?.diffuse.contents = UIColor.white
        let plateFrameNode = SCNNode(geometry: plateFrameGeo)
        plateFrameNode.position = SCNVector3(0, -0.15, 2.1)
        chassisNode.addChildNode(plateFrameNode)
        
        let plateTextGeo = SCNText(string: car.plateText, extrusionDepth: 0.05)
        plateTextGeo.font = UIFont.systemFont(ofSize: 0.08, weight: .bold)
        plateTextGeo.flatness = 0.1
        plateTextGeo.firstMaterial?.diffuse.contents = UIColor.black
        
        // Center text on the plate
        let textNode = SCNNode(geometry: plateTextGeo)
        // Center alignment bounds calculation
        let (minBounds, maxBounds) = plateTextGeo.boundingBox
        let dx = (maxBounds.x - minBounds.x) / 2.0
        let dy = (maxBounds.y - minBounds.y) / 2.0
        
        textNode.position = SCNVector3(-dx, -dy, 0.03) // offset slightly in front of frame
        plateFrameNode.addChildNode(textNode)
        
        return rootNode
    }
    
    // MARK: - Wheel Generation
    
    private static func createWheelNode(style: String) -> SCNNode {
        let wheelRoot = SCNNode()
        
        // Outer Tire (Black Rubber)
        let tireGeo = SCNCylinder(radius: 0.35, height: 0.3)
        let tireMat = SCNMaterial()
        tireMat.diffuse.contents = UIColor(white: 0.15, alpha: 1.0)
        tireMat.roughness.contents = 0.8
        tireGeo.materials = [tireMat]
        
        let tireNode = SCNNode(geometry: tireGeo)
        tireNode.rotation = SCNVector4(0, 0, 1, Float.pi / 2) // rotate along X axis
        wheelRoot.addChildNode(tireNode)
        
        // Inner Rims (Custom styles)
        let rimGeo = SCNCylinder(radius: 0.22, height: 0.31)
        let rimMat = SCNMaterial()
        rimMat.roughness.contents = 0.15
        rimMat.metalness.contents = 0.95
        
        switch style {
        case "sport":
            rimMat.diffuse.contents = UIColor(white: 0.3, alpha: 1.0) // Dark Titanium rims
            rimMat.specular.contents = UIColor.white
        case "deepdish":
            rimMat.diffuse.contents = UIColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0) // Deep Gold rims
            rimMat.specular.contents = UIColor.white
        default:
            rimMat.diffuse.contents = UIColor(white: 0.8, alpha: 1.0) // Standard Chrome silver
            rimMat.specular.contents = UIColor.white
        }
        rimGeo.materials = [rimMat]
        
        let rimNode = SCNNode(geometry: rimGeo)
        rimNode.rotation = SCNVector4(0, 0, 1, Float.pi / 2)
        wheelRoot.addChildNode(rimNode)
        
        return wheelRoot
    }
    
    // MARK: - Procedural Traffic Vehicles Builder
    
    public static func createTrafficVehicle(type: String) -> SCNNode {
        let rootNode = SCNNode()
        rootNode.name = "traffic_vehicle"
        
        // Base randomized colors for traffic (classic but vibrant)
        let trafficColors: [UIColor] = [
            UIColor(hex: "#2B2D42"), // Slate blue
            UIColor(hex: "#8D99AE"), // Silver gray
            UIColor(hex: "#EF233C"), // Solid red
            UIColor(hex: "#FFB703"), // Cab yellow
            UIColor(hex: "#006400"), // Dark forest green
            UIColor(hex: "#4A148C")  // Dark violet
        ]
        let color = trafficColors.randomElement() ?? UIColor.lightGray
        
        let bodyNode: SCNNode
        
        switch type {
        case "sports":
            // Low sports vehicle
            let chassisGeo = SCNBox(width: 1.8, height: 0.55, length: 4.2, chamferRadius: 0.1)
            chassisGeo.firstMaterial?.diffuse.contents = color
            chassisGeo.firstMaterial?.metalness.contents = 0.8
            bodyNode = SCNNode(geometry: chassisGeo)
            bodyNode.position = SCNVector3(0, 0.45, 0)
            
            // Spoiler
            let spoilerGeo = SCNBox(width: 1.6, height: 0.05, length: 0.3, chamferRadius: 0.0)
            spoilerGeo.firstMaterial?.diffuse.contents = UIColor.black
            let spoiler = SCNNode(geometry: spoilerGeo)
            spoiler.position = SCNVector3(0, 0.4, 1.8)
            bodyNode.addChildNode(spoiler)
            
            // Low cabin
            let cabinGeo = SCNBox(width: 1.4, height: 0.4, length: 2.0, chamferRadius: 0.05)
            cabinGeo.firstMaterial?.diffuse.contents = UIColor.black
            let cabin = SCNNode(geometry: cabinGeo)
            cabin.position = SCNVector3(0, 0.4, -0.4)
            bodyNode.addChildNode(cabin)
            
        case "pickup":
            // Raised pickup truck
            let chassisGeo = SCNBox(width: 1.9, height: 0.7, length: 4.5, chamferRadius: 0.1)
            chassisGeo.firstMaterial?.diffuse.contents = color
            bodyNode = SCNNode(geometry: chassisGeo)
            bodyNode.position = SCNVector3(0, 0.6, 0)
            
            // Cab (Front half)
            let cabGeo = SCNBox(width: 1.6, height: 0.7, length: 2.2, chamferRadius: 0.05)
            cabGeo.firstMaterial?.diffuse.contents = UIColor.black
            let cabNode = SCNNode(geometry: cabGeo)
            cabNode.position = SCNVector3(0, 0.6, -1.0)
            bodyNode.addChildNode(cabNode)
            
            // Flat bed walls (Rear half hollow look using thin boxes)
            let bedGeo = SCNBox(width: 1.7, height: 0.5, length: 2.0, chamferRadius: 0.0)
            bedGeo.firstMaterial?.diffuse.contents = color
            let bedNode = SCNNode(geometry: bedGeo)
            bedNode.position = SCNVector3(0, 0.4, 1.1)
            bodyNode.addChildNode(bedNode)
            
        case "truck":
            // Heavy Semi-Truck
            let chassisGeo = SCNBox(width: 2.0, height: 0.8, length: 4.0, chamferRadius: 0.05)
            chassisGeo.firstMaterial?.diffuse.contents = UIColor.darkGray
            bodyNode = SCNNode(geometry: chassisGeo)
            bodyNode.position = SCNVector3(0, 0.65, 0)
            
            // Cab (Tall front box)
            let cabGeo = SCNBox(width: 2.0, height: 1.8, length: 2.2, chamferRadius: 0.05)
            cabGeo.firstMaterial?.diffuse.contents = color
            let cabNode = SCNNode(geometry: cabGeo)
            cabNode.position = SCNVector3(0, 1.2, -0.9)
            bodyNode.addChildNode(cabNode)
            
            // Cargo Box Container (Large metal back)
            let cargoGeo = SCNBox(width: 2.2, height: 2.4, length: 5.5, chamferRadius: 0.05)
            let cargoMat = SCNMaterial()
            cargoMat.diffuse.contents = UIColor(white: 0.85, alpha: 1.0)
            cargoMat.metalness.contents = 0.5
            cargoGeo.materials = [cargoMat]
            let cargoNode = SCNNode(geometry: cargoGeo)
            cargoNode.position = SCNVector3(0, 1.3, 3.4)
            bodyNode.addChildNode(cargoNode)
            
        case "tanker":
            // Oil fuel tanker
            let chassisGeo = SCNBox(width: 2.0, height: 0.8, length: 4.0, chamferRadius: 0.05)
            chassisGeo.firstMaterial?.diffuse.contents = UIColor.black
            bodyNode = SCNNode(geometry: chassisGeo)
            bodyNode.position = SCNVector3(0, 0.65, 0)
            
            // Cab
            let cabGeo = SCNBox(width: 2.0, height: 1.8, length: 2.2, chamferRadius: 0.05)
            cabGeo.firstMaterial?.diffuse.contents = UIColor.orange
            let cabNode = SCNNode(geometry: cabGeo)
            cabNode.position = SCNVector3(0, 1.2, -0.9)
            bodyNode.addChildNode(cabNode)
            
            // Large cylindrical Tanker at the back
            let tankGeo = SCNCylinder(radius: 1.1, height: 5.8)
            let tankMat = SCNMaterial()
            tankMat.diffuse.contents = UIColor.lightGray
            tankMat.metalness.contents = 0.9
            tankMat.roughness.contents = 0.1
            tankGeo.materials = [tankMat]
            let tankNode = SCNNode(geometry: tankGeo)
            tankNode.rotation = SCNVector4(1, 0, 0, Float.pi / 2) // orient horizontally
            tankNode.position = SCNVector3(0, 1.2, 3.4)
            bodyNode.addChildNode(tankNode)
            
        default: // "sedan"
            // Classic 3-box commuter sedan
            let chassisGeo = SCNBox(width: 1.8, height: 0.6, length: 4.2, chamferRadius: 0.12)
            chassisGeo.firstMaterial?.diffuse.contents = color
            bodyNode = SCNNode(geometry: chassisGeo)
            bodyNode.position = SCNVector3(0, 0.48, 0)
            
            let cabinGeo = SCNBox(width: 1.4, height: 0.55, length: 2.4, chamferRadius: 0.1)
            cabinGeo.firstMaterial?.diffuse.contents = UIColor.black
            let cabinNode = SCNNode(geometry: cabinGeo)
            cabinNode.position = SCNVector3(0, 0.55, -0.2)
            bodyNode.addChildNode(cabinNode)
        }
        
        rootNode.addChildNode(bodyNode)
        
        // Install appropriate wheels
        let wheelOffsets: [(x: Float, z: Float)] = [
            (-0.95, -1.3),
            (0.95, -1.3),
            (-0.95, 1.3),
            (0.95, 1.3)
        ]
        
        for offset in wheelOffsets {
            let wheelNode = createWheelNode(style: "standard")
            // Elevate cargo truck wheels slightly differently
            if type == "truck" || type == "tanker" {
                wheelNode.position = SCNVector3(offset.x * 1.05, 0.35, offset.z * 1.2)
                wheelNode.scale = SCNVector3(1.2, 1.2, 1.2) // slightly bigger wheels
            } else {
                wheelNode.position = SCNVector3(offset.x, 0.25, offset.z)
            }
            rootNode.addChildNode(wheelNode)
        }
        
        // Spawn standard white front lights
        let lightGeo = SCNCylinder(radius: 0.1, height: 0.05)
        lightGeo.firstMaterial?.diffuse.contents = UIColor.white
        lightGeo.firstMaterial?.emission.contents = UIColor.yellow.withAlphaComponent(0.8)
        
        let leftHL = SCNNode(geometry: lightGeo)
        leftHL.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        leftHL.position = SCNVector3(-0.6, 0.0, -2.1)
        bodyNode.addChildNode(leftHL)
        
        let rightHL = SCNNode(geometry: lightGeo)
        rightHL.rotation = SCNVector4(1, 0, 0, Float.pi / 2)
        rightHL.position = SCNVector3(0.6, 0.0, -2.1)
        bodyNode.addChildNode(rightHL)
        
        return rootNode
    }
}

// UI Color extension for hexadecimal strings
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 255, 255)
        }
        
        self.init(
            red: CGFloat(r) / 255.0,
            green: CGFloat(g) / 255.0,
            blue: CGFloat(b) / 255.0,
            alpha: CGFloat(a) / 255.0
        )
    }
}
