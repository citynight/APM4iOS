//
//  PerformanceMonitor.swift
//  APM
//
//  Created by 李小争 on 2021/3/19.
//

import Foundation

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
     
    /// 信号
    var semaphore: DispatchSemaphore?
    /// 当前状态
    var activity:CFRunLoopActivity = .allActivities
    
    /// 观察者
    private var observer:CFRunLoopObserver?
    /// 耗时次数
    private var timeoutCount = 0
    /// 时间格式
    private static let format: DateFormatter = {
        let format = DateFormatter()
        format.dateFormat = "YYYY/MM/dd hh:mm:ss:SSS"
        return format
    }()
    
//    private init() {
//        addRunloopObserver()
//    }
}

extension PerformanceMonitor {
    
    func stop() {
        guard let observer = observer else {
            return
        }
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, CFRunLoopMode.commonModes)
        self.observer = nil
    }
    
    func start() {
        if let _ = observer {
            return
        }
        
        semaphore = DispatchSemaphore(value: 0)
        guard let semaphore = self.semaphore else { return }
        
        print("dispatch_semaphore_create: \(getCurTime())")
        addRunloopObserver()
        
        DispatchQueue.global().async { [self] in
            
            while(true) {
                // 有信号的话 就查询当前runloop的状态
                // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)
                // 因为下面 runloop 状态改变回调方法runLoopObserverCallBack中会将信号量递增 1,所以每次 runloop 状态改变后,下面的语句都会执行一次
                // dispatch_semaphore_wait:Returns zero on success, or non-zero if the timeout occurred.
                let st = semaphore.wait(timeout: DispatchTime.now() + .microseconds(50))
                if st == .timedOut {
                    //超时处理
                    guard let _ = self.observer else {
                        self.timeoutCount = 0
                        self.semaphore = DispatchSemaphore(value: 0)
                        self.activity = CFRunLoopActivity(rawValue: 0)
                        return
                    }
//                    print("st = \(st), activity = \(activity),timeoutCount = \(self.timeoutCount),time = \(self.getCurTime())")
                    
                    if self.activity == .beforeSources || self.activity == .afterWaiting {
                        self.timeoutCount += 1
                        if self.timeoutCount < 5 {
                            continue
                        }
                        print("------------\n卡顿\n------------")
//                        for stackSymbol in Thread.callStackSymbols {
//                            print(stackSymbol)
//                        }
                        
                        
                    }
                }
                timeoutCount = 0;
            }
        }
    }
    private
    func addRunloopObserver() {
        autoreleasepool {
            guard let runloop = CFRunLoopGetMain() else {return}
            let unmanaged = Unmanaged.passRetained(self)
            let uptr = unmanaged.toOpaque()
            let vptr = UnsafeMutableRawPointer(uptr)
            
            // 注册RunLoop状态观察, 设置Run Loop observer的运行环境
            var content = CFRunLoopObserverContext(version: 0, info: vptr, retain: nil, release: nil, copyDescription: nil)
            
            /*
                 创建Run loop observer对象
                 第一个参数用于分配该observer对象的内存
                 第二个参数用以设置该observer所要关注的的事件，详见回调函数myRunLoopObserver中注释
                 第三个参数用于标识该observer是在第一次进入run loop时执行还是每次进入run loop处理时均执行
                 第四个参数用于设置该observer的优先级
                 第五个参数用于设置该observer的回调函数
                 第六个参数用于设置该observer的运行环境
                 */
            guard let observer = CFRunLoopObserverCreate(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, observerCallbackFunc(), &content) else {return}
            self.observer = observer
            // 将新建的observer加入到当前thread的runloop
            CFRunLoopAddObserver(runloop, observer, CFRunLoopMode.defaultMode)
        }
    }
        
        
    func observerCallbackFunc() -> CFRunLoopObserverCallBack {
        
        return { (observer, activity, context) -> Void in
            guard let context = context else {
                return
            }
            let moniotr = Unmanaged<PerformanceMonitor>.fromOpaque(context).takeUnretainedValue()
            moniotr.activity = activity
//            guard let semaphore = moniotr.semaphore else {
//                return
//            }
            
//            let st = DispatchSemaphore.signal(semaphore)()
//            print("dispatch_semaphore_signal:st=\(String(describing: st)),time:\(PerformanceMonitor.getCurTime())");
            
//            switch activity {
//            case .entry:
//                print("runLoopObserverCallBack - ","entry")
//            case .beforeTimers:
//                print("runLoopObserverCallBack - ","beforeTimers")
//            case .beforeSources:
//                print("runLoopObserverCallBack - ","beforeSources")
//            case .beforeWaiting:
//                print("runLoopObserverCallBack - ","beforeWaiting")
//            case .afterWaiting:
//                print("runLoopObserverCallBack - ","afterWaiting")
//            case .exit:
//                print("runLoopObserverCallBack - ","exit")
//            case .allActivities:
//                print("runLoopObserverCallBack - ","allActivities")
//            default:
//                print("runLoopObserverCallBack - ","other activity")
//            }
        }
    }
}


extension PerformanceMonitor {
    func getCurTime() -> String {
        return PerformanceMonitor.format.string(from: Date())
    }
    
    class func getCurTime() -> String {
        return format.string(from: Date())
    }
}
