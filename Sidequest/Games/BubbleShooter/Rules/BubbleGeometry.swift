import Foundation

struct BubblePoint: Equatable, Sendable {
  let x: Double
  let y: Double

  func distanceSquared(to other: Self) -> Double {
    (x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)
  }
}

struct BubbleSlot: Hashable, Sendable {
  let row: Int
  let column: Int
}

enum BubbleContact: Equatable, Sendable {
  case ceiling
  case bubble(BubbleSlot)
}

struct BubbleTrajectory: Equatable, Sendable {
  let points: [BubblePoint]
  let contact: BubbleContact
  let incomingDirection: BubblePoint
}

enum BubbleGeometry {
  static let radius = 1.0
  static let width = 10.0
  static let rows = 5
  static let launcher = BubblePoint(x: 5, y: 11)
  static let maximumAngle = Double.pi / 3
  static let epsilon = 0.000_001

  static let slots = (0..<rows).flatMap { row in
    (0..<(row.isMultiple(of: 2) ? 5 : 4)).map { BubbleSlot(row: row, column: $0) }
  }

  static func center(of slot: BubbleSlot) -> BubblePoint {
    BubblePoint(
      x: 1 + Double(slot.column) * 2 + (slot.row.isMultiple(of: 2) ? 0 : 1),
      y: 1 + Double(slot.row) * sqrt(3))
  }

  static func neighbors(of slot: BubbleSlot) -> [BubbleSlot] {
    slots.filter { abs(center(of: slot).distanceSquared(to: center(of: $0)) - 4) < epsilon }
  }

  /// The moving center touches a stationary bubble at the sum of their radii.
  /// Testing the whole ray segment prevents tunneling even with long animation steps.
  static func trace(angleRadians: Double, occupied: [BubbleSlot: BubbleColor]) throws
    -> BubbleTrajectory
  {
    guard angleRadians.isFinite, abs(angleRadians) <= maximumAngle else {
      throw BubbleShotError.invalidAngle
    }
    var direction = BubblePoint(x: sin(angleRadians), y: -cos(angleRadians))
    var origin = launcher
    var points = [origin]
    for _ in 0..<16 {
      let roofDistance = (radius - origin.y) / direction.y
      let wallDistance: Double
      if abs(direction.x) < epsilon {
        wallDistance = .infinity
      } else {
        let wall = direction.x > 0 ? width - radius : radius
        wallDistance = max(0, (wall - origin.x) / direction.x)
      }
      let boundaryDistance = min(roofDistance, wallDistance)
      var first: (slot: BubbleSlot, distance: Double)?
      // Stable slot order also makes exact-contact ties reproducible.
      for slot in slots where occupied[slot] != nil {
        let center = center(of: slot)
        let dx = origin.x - center.x
        let dy = origin.y - center.y
        let projection = dx * direction.x + dy * direction.y
        let discriminant = projection * projection - (dx * dx + dy * dy - 4)
        guard discriminant >= -epsilon else { continue }
        let distance = -projection - sqrt(max(0, discriminant))
        guard distance >= -epsilon, distance <= boundaryDistance + epsilon else { continue }
        if let previous = first, distance >= previous.distance - epsilon { continue }
        first = (slot, max(0, distance))
      }
      if let first {
        points.append(
          BubblePoint(
            x: origin.x + direction.x * first.distance,
            y: origin.y + direction.y * first.distance))
        return BubbleTrajectory(
          points: points, contact: .bubble(first.slot), incomingDirection: direction)
      }
      let end = BubblePoint(
        x: origin.x + direction.x * boundaryDistance,
        y: origin.y + direction.y * boundaryDistance)
      points.append(end)
      if roofDistance <= wallDistance + epsilon {
        return BubbleTrajectory(points: points, contact: .ceiling, incomingDirection: direction)
      }
      origin = end
      direction = BubblePoint(x: -direction.x, y: direction.y)
    }
    throw BubbleShotError.invalidTrajectory
  }

  static func attachment(
    for trajectory: BubbleTrajectory, occupied: [BubbleSlot: BubbleColor]
  ) -> BubbleSlot? {
    guard let contactPoint = trajectory.points.last else { return nil }
    let candidates: [BubbleSlot]
    switch trajectory.contact {
    case .ceiling:
      candidates = slots.filter { $0.row == 0 }
    case .bubble(let hit):
      let hitCenter = center(of: hit)
      candidates = neighbors(of: hit).filter {
        let candidate = center(of: $0)
        // A shot cannot pass through the first hit into a slot on its far side.
        return (candidate.x - hitCenter.x) * trajectory.incomingDirection.x
          + (candidate.y - hitCenter.y) * trajectory.incomingDirection.y <= epsilon
      }
    }
    return candidates.filter {
      occupied[$0] == nil && center(of: $0).distanceSquared(to: contactPoint) <= 4 + epsilon
    }.min {
      center(of: $0).distanceSquared(to: contactPoint)
        < center(of: $1).distanceSquared(to: contactPoint) - epsilon
    }
  }
}
