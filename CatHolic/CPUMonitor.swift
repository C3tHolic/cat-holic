//
//  CPUMonitor.swift
//  CatHolic
//
//  Created by jaegool on 5/29/25.
//  Copyright © 2025 Tim Jarratt. All rights reserved.
//

import Foundation
import Darwin

@MainActor
@objc class CPUMonitor: NSObject {
    private static let loadInfoCount = UInt32(
        MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
    )

    private static var _loadPrevious = host_cpu_load_info()
    private static var usageHistory: [Double] = []
    private static let maxSamples = 200

    private static func hostCPULoadInfo() -> host_cpu_load_info {
        var size = loadInfoCount
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer in
            host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }

    /// 최근 샘플 평균(%)을 반환
    @objc static func usageValue() -> Double {
        let load = hostCPULoadInfo()

        let userDiff = Double(load.cpu_ticks.0 - _loadPrevious.cpu_ticks.0)
        let sysDiff  = Double(load.cpu_ticks.1 - _loadPrevious.cpu_ticks.1)
        let idleDiff = Double(load.cpu_ticks.2 - _loadPrevious.cpu_ticks.2)
        let niceDiff = Double(load.cpu_ticks.3 - _loadPrevious.cpu_ticks.3)
        _loadPrevious = load

        let total = sysDiff + userDiff + idleDiff + niceDiff
        var current: Double = 0
        if total > 0 {
            current = min(100.0 * (sysDiff + userDiff) / total, 100.0)
        }

        usageHistory.append(current)
        if usageHistory.count > maxSamples { usageHistory.removeFirst() }

        return usageHistory.reduce(0, +) / Double(usageHistory.count)
    }
}
