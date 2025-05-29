//
//  CPUMonitor.swift
//  CatHolic
//
//  Created by jaegool on 5/29/25.
//  Copyright © 2025 Tim Jarratt. All rights reserved.
//

import Foundation
import Darwin

@objc class CPUMonitor: NSObject {
    private static let loadInfoCount = UInt32(MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size)

    private static let syncQueue = DispatchQueue(label: "CPUMonitor.syncQueue")

    nonisolated(unsafe) private static var _loadPrevious = host_cpu_load_info()

    private static func hostCPULoadInfo() -> host_cpu_load_info {
        var size = loadInfoCount
        let hostInfo = host_cpu_load_info_t.allocate(capacity: 1)
        let _ = hostInfo.withMemoryRebound(to: integer_t.self, capacity: Int(size)) { pointer -> kern_return_t in
            return host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, pointer, &size)
        }
        let data = hostInfo.move()
        hostInfo.deallocate()
        return data
    }

    @objc static func usageValue() -> Double {
        var result: Double = 0.0

        syncQueue.sync {
            let load = hostCPULoadInfo()
            let userDiff = Double(load.cpu_ticks.0 - _loadPrevious.cpu_ticks.0)
            let sysDiff  = Double(load.cpu_ticks.1 - _loadPrevious.cpu_ticks.1)
            let idleDiff = Double(load.cpu_ticks.2 - _loadPrevious.cpu_ticks.2)
            let niceDiff = Double(load.cpu_ticks.3 - _loadPrevious.cpu_ticks.3)
            _loadPrevious = load

            let totalTicks = sysDiff + userDiff + idleDiff + niceDiff
            if totalTicks > 0 {
                let usage = 100.0 * (sysDiff + userDiff) / totalTicks
                result = min(usage, 100.0)
            }
        }

        return result
    }
}
