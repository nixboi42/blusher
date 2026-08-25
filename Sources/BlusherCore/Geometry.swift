import CoreGraphics
import Foundation

public struct Joint: Sendable {
    public var point: CGPoint
    public var confidence: Float
    public init(_ point: CGPoint, confidence: Float = 1) { self.point = point; self.confidence = confidence }
}

public struct HandPose: Sendable {
    public var wrist, indexMCP, indexPIP, indexTip, middleTip, ringTip, littleTip: Joint
    public init(wrist: Joint, indexMCP: Joint, indexPIP: Joint, indexTip: Joint, middleTip: Joint, ringTip: Joint, littleTip: Joint) {
        self.wrist=wrist; self.indexMCP=indexMCP; self.indexPIP=indexPIP; self.indexTip=indexTip; self.middleTip=middleTip; self.ringTip=ringTip; self.littleTip=littleTip
    }
}

public enum GestureScorer {
    public static func score(_ hands: [HandPose]) -> Double {
        guard hands.count >= 2 else { return 0 }
        let sorted = hands.sorted { $0.indexTip.point.x < $1.indexTip.point.x }, a=sorted[0], b=sorted[1]
        let joints=[a.wrist,a.indexMCP,a.indexPIP,a.indexTip,a.middleTip,a.ringTip,a.littleTip,b.wrist,b.indexMCP,b.indexPIP,b.indexTip,b.middleTip,b.ringTip,b.littleTip]
        guard joints.allSatisfy({$0.confidence >= 0.35}) else { return 0 }
        func d(_ p: CGPoint,_ q: CGPoint)->CGFloat { hypot(p.x-q.x,p.y-q.y) }
        let scale=max(0.02,(d(a.wrist.point,a.indexMCP.point)+d(b.wrist.point,b.indexMCP.point))/2)
        let gap=d(a.indexTip.point,b.indexTip.point)/scale
        let inwardA=(a.indexTip.point.x-a.indexMCP.point.x)/scale
        let inwardB=(b.indexMCP.point.x-b.indexTip.point.x)/scale
        let straightA=d(a.indexMCP.point,a.indexTip.point)/(d(a.indexMCP.point,a.indexPIP.point)+d(a.indexPIP.point,a.indexTip.point)+0.001)
        let straightB=d(b.indexMCP.point,b.indexTip.point)/(d(b.indexMCP.point,b.indexPIP.point)+d(b.indexPIP.point,b.indexTip.point)+0.001)
        let curl=[a,b].map { h in ([h.middleTip,h.ringTip,h.littleTip].map { d($0.point,h.wrist.point) }.reduce(0,+)/3)/scale }.reduce(0,+)/2
        let proximity=max(0, min(1, (2.2-gap)/1.5)); let inward=max(0,min(1,Double(min(inwardA,inwardB))/0.7)); let straight=max(0,min(1,Double(min(straightA,straightB)-0.65)/0.3)); let curled=max(0,min(1,Double(1.35-curl)/0.7))
        return proximity*0.35 + inward*0.3 + straight*0.2 + curled*0.15
    }
}

public struct GestureStateMachine: Sendable {
    public private(set) var active=false
    private var aboveSince: TimeInterval?; private var belowSince: TimeInterval?
    public var activationDelay=0.18; public var releaseDelay=0.28
    public init() {}
    public mutating func update(score: Double, time: TimeInterval) -> Bool {
        if score >= 0.68 { belowSince=nil; if aboveSince == nil { aboveSince=time }; if time-(aboveSince ?? time) >= activationDelay { active=true } }
        else if score < 0.42 { aboveSince=nil; if belowSince == nil { belowSince=time }; if time-(belowSince ?? time) >= releaseDelay { active=false } }
        return active
    }
}

public struct EffectAnimator: Sendable {
    private var value=0.0; private var last: TimeInterval?
    public init() {}
    public mutating func update(active: Bool, time: TimeInterval) -> Double {
        defer { last=time }; guard let last else { return value }; let dt=max(0,time-last)
        value += active ? dt/0.30 : -dt/0.50; value=max(0,min(1,value)); return value
    }
}

public struct FrameCoordinateMapper: Sendable {
    public enum ContentMode: Sendable { case fit, fill }
    public let extent: CGRect
    public init(extent: CGRect) { self.extent = extent }
    public init(size: CGSize) { self.extent = CGRect(origin: .zero, size: size) }

    /// Vision and Core Image both use a lower-left origin. No axis is flipped here.
    public func visionPointToCanonical(_ point: CGPoint) -> CGPoint {
        CGPoint(x: extent.minX + point.x * extent.width, y: extent.minY + point.y * extent.height)
    }
    public func visionRectToCanonical(_ rect: CGRect) -> CGRect {
        CGRect(x: extent.minX + rect.minX * extent.width, y: extent.minY + rect.minY * extent.height,
               width: rect.width * extent.width, height: rect.height * extent.height)
    }
    public func faceRelativeToVision(_ point: CGPoint, face: CGRect) -> CGPoint {
        CGPoint(x: face.minX + point.x * face.width, y: face.minY + point.y * face.height)
    }
    public func faceRelativeToCanonical(_ point: CGPoint, face: CGRect) -> CGPoint {
        visionPointToCanonical(faceRelativeToVision(point, face: face))
    }
    public func canonicalToDisplay(_ point: CGPoint, displaySize: CGSize, mode: ContentMode, mirrored: Bool) -> CGPoint {
        let sx = displaySize.width / extent.width, sy = displaySize.height / extent.height
        let scale = mode == .fit ? min(sx, sy) : max(sx, sy)
        let rendered = CGSize(width: extent.width * scale, height: extent.height * scale)
        let offset = CGPoint(x: (displaySize.width-rendered.width)/2, y: (displaySize.height-rendered.height)/2)
        let localX = (point.x-extent.minX)*scale
        return CGPoint(x: offset.x + (mirrored ? rendered.width-localX : localX),
                       y: displaySize.height - (offset.y + (point.y-extent.minY)*scale))
    }
}

public struct FaceModel: Sendable, Equatable {
    public var leftEye, rightEye, nose, mouth, leftCheek, rightCheek: CGPoint
    public var scale, angle: CGFloat
    public var faceRect: CGRect
    public init(leftEye: CGPoint, rightEye: CGPoint, nose: CGPoint, mouth: CGPoint, faceRect: CGRect) {
        var l=leftEye, r=rightEye
        if l.x > r.x { swap(&l,&r) }
        let dx=r.x-l.x, dy=r.y-l.y, distance=max(1,hypot(dx,dy))
        let h=CGPoint(x:dx/distance,y:dy/distance)
        var v=CGPoint(x:-h.y,y:h.x)
        let eyeMid=CGPoint(x:(l.x+r.x)/2,y:(l.y+r.y)/2)
        if (nose.x-eyeMid.x)*v.x + (nose.y-eyeMid.y)*v.y < 0 { v=CGPoint(x:-v.x,y:-v.y) }
        self.leftEye=l; self.rightEye=r; self.nose=nose; self.mouth=mouth; self.scale=distance
        self.leftCheek=CGPoint(x:l.x + v.x*distance*0.42 - h.x*distance*0.10, y:l.y + v.y*distance*0.42 - h.y*distance*0.10)
        self.rightCheek=CGPoint(x:r.x + v.x*distance*0.42 + h.x*distance*0.10, y:r.y + v.y*distance*0.42 + h.y*distance*0.10)
        self.angle=atan2(dy,dx); self.faceRect=faceRect
    }
    public func smoothed(toward target: FaceModel, deltaTime: TimeInterval, response: Double = 14) -> FaceModel {
        let a=CGFloat(1-exp(-response*max(0,deltaTime)))
        func p(_ x:CGPoint,_ y:CGPoint)->CGPoint { CGPoint(x:x.x+(y.x-x.x)*a,y:x.y+(y.y-x.y)*a) }
        var result=target; result.leftEye=p(leftEye,target.leftEye); result.rightEye=p(rightEye,target.rightEye); result.nose=p(nose,target.nose); result.mouth=p(mouth,target.mouth); result.leftCheek=p(leftCheek,target.leftCheek); result.rightCheek=p(rightCheek,target.rightCheek); result.scale=scale+(target.scale-scale)*a; result.angle=angle+(target.angle-angle)*a
        result.faceRect=CGRect(x:faceRect.minX+(target.faceRect.minX-faceRect.minX)*a,y:faceRect.minY+(target.faceRect.minY-faceRect.minY)*a,width:faceRect.width+(target.faceRect.width-faceRect.width)*a,height:faceRect.height+(target.faceRect.height-faceRect.height)*a); return result
    }
}
