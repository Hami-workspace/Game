import Foundation
import SceneKit

public class RoadManager {
    private let scene: SCNScene
    private var roadSegments: [SCNNode] = []
    
    // Configs
    private let segmentLength: Float = 100.0
    private let totalSegments = 6
    private var nextZPosition: Float = 0.0
    
    public init(scene: SCNScene) {
        self.scene = scene
    }
    
    // MARK: - Initial Road Builder
    
    public func buildInitialRoad(location: Location) {
        // Clear any old segments
        for segment in roadSegments {
            segment.removeFromParentNode()
        }
        roadSegments.removeAll()
        
        nextZPosition = 0.0
        
        // Spawn 6 segments consecutively
        for _ in 0..<totalSegments {
            spawnSegment(location: location)
        }
    }
    
    // MARK: - Spawner Logic
    
    private func spawnSegment(location: Location) {
        let segmentNode = SCNNode()
        segmentNode.name = "road_segment"
        segmentNode.position = SCNVector3(0, 0, nextZPosition)
        
        // 1. Asphalt Road Base (Width = 15m, Height = 0.2m, Length = 100m)
        let asphaltGeo = SCNBox(width: 15.0, height: 0.2, length: CGFloat(segmentLength), chamferRadius: 0.0)
        let asphaltMat = SCNMaterial()
        asphaltMat.diffuse.contents = UIColor(hex: "#1A1A1A") // Charcoal asphalt
        asphaltMat.roughness.contents = 0.95
        asphaltGeo.materials = [asphaltMat]
        
        let asphaltNode = SCNNode(geometry: asphaltGeo)
        asphaltNode.position = SCNVector3(0, -0.1, 0)
        segmentNode.addChildNode(asphaltNode)
        
        // 2. Side Concrete Guard Rails
        let barrierGeo = SCNBox(width: 0.6, height: 0.8, length: CGFloat(segmentLength), chamferRadius: 0.05)
        let barrierMat = SCNMaterial()
        barrierMat.diffuse.contents = UIColor(hex: "#444444")
        barrierGeo.materials = [barrierMat]
        
        let leftBarrier = SCNNode(geometry: barrierGeo)
        leftBarrier.position = SCNVector3(-7.8, 0.3, 0)
        segmentNode.addChildNode(leftBarrier)
        
        let rightBarrier = SCNNode(geometry: barrierGeo)
        rightBarrier.position = SCNVector3(7.8, 0.3, 0)
        segmentNode.addChildNode(rightBarrier)
        
        // Glowing Neon Stripe indicator on guard rails
        let neonStripGeo = SCNBox(width: 0.05, height: 0.1, length: CGFloat(segmentLength), chamferRadius: 0.0)
        let neonStripMat = SCNMaterial()
        let themeColor = UIColor(hex: location.skyboxColorHex)
        neonStripMat.diffuse.contents = themeColor
        neonStripMat.emission.contents = themeColor.withAlphaComponent(0.6)
        neonStripGeo.materials = [neonStripMat]
        
        let leftNeon = SCNNode(geometry: neonStripGeo)
        leftNeon.position = SCNVector3(-7.48, 0.4, 0)
        segmentNode.addChildNode(leftNeon)
        
        let rightNeon = SCNNode(geometry: neonStripGeo)
        rightNeon.position = SCNVector3(7.48, 0.4, 0)
        segmentNode.addChildNode(rightNeon)
        
        // 3. Lane Dash Lines
        // Lanes are 3.5m wide: X positions are -5.25m, -1.75m, +1.75m, +5.25m
        // White dashes go down X = -3.5m, X = 0m, X = 3.5m
        let dashCount = 10
        let dashSpacing = segmentLength / Float(dashCount)
        
        for i in 0..<dashCount {
            let zPos = -segmentLength / 2.0 + Float(i) * dashSpacing + dashSpacing / 2.0
            
            // White dashes for lane dividers
            let dashGeo = SCNBox(width: 0.15, height: 0.01, length: 3.0, chamferRadius: 0.0)
            dashGeo.firstMaterial?.diffuse.contents = UIColor.white
            dashGeo.firstMaterial?.emission.contents = UIColor.white.withAlphaComponent(0.2)
            
            // Lane dividing lines (Left and Right)
            let leftDash = SCNNode(geometry: dashGeo)
            leftDash.position = SCNVector3(-3.5, 0.01, zPos)
            segmentNode.addChildNode(leftDash)
            
            let rightDash = SCNNode(geometry: dashGeo)
            rightDash.position = SCNVector3(3.5, 0.01, zPos)
            segmentNode.addChildNode(rightDash)
            
            // Center Divider Dash (Yellow for Two-Way, White for One-Way)
            let centerDashGeo = SCNBox(width: 0.15, height: 0.01, length: 3.0, chamferRadius: 0.0)
            centerDashGeo.firstMaterial?.diffuse.contents = location.isTwoWay ? UIColor.yellow : UIColor.white
            centerDashGeo.firstMaterial?.emission.contents = (location.isTwoWay ? UIColor.yellow : UIColor.white).withAlphaComponent(0.2)
            
            let centerDash = SCNNode(geometry: centerDashGeo)
            centerDash.position = SCNVector3(0, 0.01, zPos)
            segmentNode.addChildNode(centerDash)
        }
        
        // 4. Procedural Side Scenery Spawning
        spawnSideScenery(node: segmentNode, location: location)
        
        scene.rootNode.addChildNode(segmentNode)
        roadSegments.append(segmentNode)
        
        // Advance negative Z direction (moving forward)
        nextZPosition -= segmentLength
    }
    
    // MARK: - Scenery Generators
    
    private func spawnSideScenery(node: SCNNode, location: Location) {
        let type = location.groundSceneryType
        let isNight = location.isNight
        
        // Spawn ~8 assets per segment (4 on left, 4 on right)
        let count = 4
        let spawnOffsetsZ: [Float] = [-37.5, -12.5, 12.5, 37.5]
        
        for i in 0..<count {
            let zOffset = spawnOffsetsZ[i]
            
            // Generate Left Asset (X ranges from -15m to -30m)
            let leftAsset = buildSceneryAsset(type: type, isNight: isNight)
            let lDist = Float.random(in: 14.0...25.0)
            leftAsset.position = SCNVector3(-lDist, 0, zOffset)
            node.addChildNode(leftAsset)
            
            // Generate Right Asset (X ranges from 15m to 30m)
            let rightAsset = buildSceneryAsset(type: type, isNight: isNight)
            let rDist = Float.random(in: 14.0...25.0)
            rightAsset.position = SCNVector3(rDist, 0, zOffset)
            node.addChildNode(rightAsset)
        }
    }
    
    private func buildSceneryAsset(type: String, isNight: Bool) -> SCNNode {
        let assetNode = SCNNode()
        
        switch type {
        case "city":
            // 3D Neon Skyscrapers!
            let height = CGFloat.random(in: 15.0...40.0)
            let width = CGFloat.random(in: 6.0...12.0)
            let blockGeo = SCNBox(width: width, height: height, length: width, chamferRadius: 0.2)
            
            let blockMat = SCNMaterial()
            blockMat.diffuse.contents = UIColor(hex: "#100B1A") // Slate building base
            blockMat.roughness.contents = 0.5
            blockMat.metalness.contents = 0.8
            
            // Glowing Synthwave Window grid grids
            let lightsColors = [UIColor(hex: "#00FFFF"), UIColor(hex: "#FF007F"), UIColor(hex: "#FFBE0B")]
            blockMat.emission.contents = lightsColors.randomElement()?.withAlphaComponent(0.2)
            blockGeo.materials = [blockMat]
            
            let building = SCNNode(geometry: blockGeo)
            building.position = SCNVector3(0, height / 2.0, 0)
            assetNode.addChildNode(building)
            
        case "mountain":
            // Autumn Pine Trees
            let trunkGeo = SCNCylinder(radius: 0.15, height: 1.5)
            trunkGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#5C4033") // Brown wood
            let trunk = SCNNode(geometry: trunkGeo)
            trunk.position = SCNVector3(0, 0.75, 0)
            assetNode.addChildNode(trunk)
            
            // Conical foliage pyramid
            let coneGeo = SCNCone(topRadius: 0.0, bottomRadius: 1.2, height: 3.5)
            // Orange, Crimson, Amber foliage colors
            let foliageColors = [UIColor(hex: "#D62828"), UIColor(hex: "#F77F00"), UIColor(hex: "#E9C46A")]
            coneGeo.firstMaterial?.diffuse.contents = foliageColors.randomElement()
            coneGeo.firstMaterial?.roughness.contents = 0.9
            let foliage = SCNNode(geometry: coneGeo)
            foliage.position = SCNVector3(0, 2.5, 0)
            assetNode.addChildNode(foliage)
            
        case "snow":
            // Squashed snowy hills mounds
            if Float.random(in: 0...1) > 0.5 {
                let hillGeo = SCNSphere(radius: CGFloat.random(in: 6.0...12.0))
                hillGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#EBF3F5") // White snow
                let hill = SCNNode(geometry: hillGeo)
                hill.scale = SCNVector3(1.5, 0.4, 1.5)
                hill.position = SCNVector3(0, 0.2, 0)
                assetNode.addChildNode(hill)
            } else {
                // Frost pine tree
                let trunkGeo = SCNCylinder(radius: 0.12, height: 1.2)
                trunkGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#4A3525")
                let trunk = SCNNode(geometry: trunkGeo)
                trunk.position = SCNVector3(0, 0.6, 0)
                assetNode.addChildNode(trunk)
                
                let coneGeo = SCNCone(topRadius: 0.0, bottomRadius: 0.9, height: 2.8)
                coneGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#F4FAFD") // White frosted blue
                let foliage = SCNNode(geometry: coneGeo)
                foliage.position = SCNVector3(0, 2.0, 0)
                assetNode.addChildNode(foliage)
            }
            
        default: // "farmland"
            // Green grass domes
            let domeGeo = SCNSphere(radius: CGFloat.random(in: 5.0...10.0))
            domeGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#38B000") // Lush green
            let dome = SCNNode(geometry: domeGeo)
            dome.scale = SCNVector3(2.0, 0.35, 1.5)
            dome.position = SCNVector3(0, -0.2, 0)
            assetNode.addChildNode(dome)
            
            // Random simple low-poly farm barn (a simple red box with white roof)
            if Float.random(in: 0...1) > 0.8 {
                let barnGeo = SCNBox(width: 4, height: 3, length: 5, chamferRadius: 0)
                barnGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#E63946") // Barn Red
                let barn = SCNNode(geometry: barnGeo)
                barn.position = SCNVector3(0, 1.5, 0)
                assetNode.addChildNode(barn)
                
                let roofGeo = SCNPyramid(width: 4.5, height: 1.5, length: 5.5)
                roofGeo.firstMaterial?.diffuse.contents = UIColor.white
                let roof = SCNNode(geometry: roofGeo)
                roof.position = SCNVector3(0, 3.0, 0)
                assetNode.addChildNode(roof)
            }
        }
        
        return assetNode
    }
    
    // MARK: - Frame Recycler Updates
    
    public func updateRecycling(playerPositionZ: Float, location: Location) {
        // Iterate segments: if segment is 100m BEHIND the player, recycle it!
        // Remember, driving forward means moving along the NEGATIVE Z axis.
        // Therefore, if segment.z > playerPositionZ + 100, the segment is behind!
        
        for idx in 0..<roadSegments.count {
            let segment = roadSegments[idx]
            
            if segment.position.z > playerPositionZ + 100.0 {
                // Recycle! Move it to the front of the queue
                segment.position.z = nextZPosition
                
                // Clear old scenery nodes (keep asphalt road, guard rails, and dashes)
                let sceneryNodes = segment.childNodes.filter { $0.name != nil && $0.name != "road_segment" && $0.geometry is SCNBox == false && $0.geometry is SCNCylinder == false }
                // Let's explicitly clear out everything that is NOT the road body
                // To be safe, we can just rebuild the entire segment!
                segment.removeFromParentNode()
                
                // Spawn a new clean segment at the front
                let newSegmentNode = SCNNode()
                newSegmentNode.name = "road_segment"
                newSegmentNode.position = SCNVector3(0, 0, nextZPosition)
                
                // Asphalt Road Base
                let asphaltGeo = SCNBox(width: 15.0, height: 0.2, length: CGFloat(segmentLength), chamferRadius: 0.0)
                asphaltGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#1A1A1A")
                asphaltGeo.firstMaterial?.roughness.contents = 0.95
                let asphaltNode = SCNNode(geometry: asphaltGeo)
                asphaltNode.position = SCNVector3(0, -0.1, 0)
                newSegmentNode.addChildNode(asphaltNode)
                
                // Side Guard Rails
                let barrierGeo = SCNBox(width: 0.6, height: 0.8, length: CGFloat(segmentLength), chamferRadius: 0.05)
                barrierGeo.firstMaterial?.diffuse.contents = UIColor(hex: "#444444")
                let leftBarrier = SCNNode(geometry: barrierGeo)
                leftBarrier.position = SCNVector3(-7.8, 0.3, 0)
                newSegmentNode.addChildNode(leftBarrier)
                
                let rightBarrier = SCNNode(geometry: barrierGeo)
                rightBarrier.position = SCNVector3(7.8, 0.3, 0)
                newSegmentNode.addChildNode(rightBarrier)
                
                // Neon Stripes
                let neonStripGeo = SCNBox(width: 0.05, height: 0.1, length: CGFloat(segmentLength), chamferRadius: 0.0)
                let themeColor = UIColor(hex: location.skyboxColorHex)
                neonStripGeo.firstMaterial?.diffuse.contents = themeColor
                neonStripGeo.firstMaterial?.emission.contents = themeColor.withAlphaComponent(0.6)
                
                let leftNeon = SCNNode(geometry: neonStripGeo)
                leftNeon.position = SCNVector3(-7.48, 0.4, 0)
                newSegmentNode.addChildNode(leftNeon)
                
                let rightNeon = SCNNode(geometry: neonStripGeo)
                rightNeon.position = SCNVector3(7.48, 0.4, 0)
                newSegmentNode.addChildNode(rightNeon)
                
                // Lane dividers
                let dashCount = 10
                let dashSpacing = segmentLength / Float(dashCount)
                for i in 0..<dashCount {
                    let zPos = -segmentLength / 2.0 + Float(i) * dashSpacing + dashSpacing / 2.0
                    
                    let dashGeo = SCNBox(width: 0.15, height: 0.01, length: 3.0, chamferRadius: 0.0)
                    dashGeo.firstMaterial?.diffuse.contents = UIColor.white
                    
                    let leftDash = SCNNode(geometry: dashGeo)
                    leftDash.position = SCNVector3(-3.5, 0.01, zPos)
                    newSegmentNode.addChildNode(leftDash)
                    
                    let rightDash = SCNNode(geometry: dashGeo)
                    rightDash.position = SCNVector3(3.5, 0.01, zPos)
                    newSegmentNode.addChildNode(rightDash)
                    
                    let centerDashGeo = SCNBox(width: 0.15, height: 0.01, length: 3.0, chamferRadius: 0.0)
                    centerDashGeo.firstMaterial?.diffuse.contents = location.isTwoWay ? UIColor.yellow : UIColor.white
                    
                    let centerDash = SCNNode(geometry: centerDashGeo)
                    centerDash.position = SCNVector3(0, 0.01, zPos)
                    newSegmentNode.addChildNode(centerDash)
                }
                
                // Scenery
                spawnSideScenery(node: newSegmentNode, location: location)
                
                scene.rootNode.addChildNode(newSegmentNode)
                roadSegments[idx] = newSegmentNode
                
                // Advance next spawn marker down negative Z
                nextZPosition -= segmentLength
                break // Only recycle one segment per loop cycle for frame rate stability!
            }
        }
    }
}
