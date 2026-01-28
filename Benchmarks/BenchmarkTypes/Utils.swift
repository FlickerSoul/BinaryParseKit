import Benchmark

public extension Benchmark {
    @inlinable
    func context(_ body: () -> Void) {
        startMeasurement()
        body()
        stopMeasurement()
    }
}
