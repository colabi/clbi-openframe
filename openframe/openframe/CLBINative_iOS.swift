import CoreMotion
import Speech
import Photos

struct UserDiaryEntry : Codable {
    var date:String;
    var steps:UInt32;
    var histogram:Array<Int>;
    var description:String;
    var photoid:String;
}

struct Diary : Codable {
    var entries: [UserDiaryEntry]
}


public class StepManager {
    static var updateui:(() -> Void)?
    static var instance:StepManager!
    public static var shared:StepManager {
        get {
            if instance == nil {
                instance = StepManager()
            }
            return instance
        }
    }
    
    var ped:CMPedometer!
    var entries:[String:UserDiaryEntry]
    var formatter = DateFormatter()
    var userid:String!
    public init() {
        ped = CMPedometer()
        entries = [String:UserDiaryEntry]()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "yyyy-MM-dd"
        
    }

    func doReal(day:Int, completion: @escaping (Int, Array<Int>, Date) -> Void) -> Void {
        let cal = Calendar.current
        let begin =  cal.startOfDay(for: Date() - TimeInterval(24*3600*(day - 1)))
        if day > -1 {
            var arrayofsteps = [Int]()
            let group = DispatchGroup()
            for i in 0..<24 {
                let start = begin + TimeInterval(i*3600)
                let finish = begin + TimeInterval((i+1)*3600)
                //                print(start, finish)
                group.enter()
                ped.queryPedometerData(from: start, to: finish) { (data, error) in
                    guard error == nil,
                        data != nil else {
                            return
                    }
                    let csteps = Int((data?.numberOfSteps)!)
                    arrayofsteps.append(csteps)
                    group.leave()
                    //                    completion(Int((data?.numberOfSteps)!), current)
                }
            }
            group.notify(queue: DispatchQueue.global(qos: .background)) {
                let totalsteps = arrayofsteps.reduce(0, +)
                print("total: \(totalsteps)")
                completion(totalsteps, arrayofsteps, begin)
            }
        }
        
    }
    
    func doSim(day:Int, completion: @escaping (Int, Array<Int>, Date) -> Void) -> Void {
        completion(Int(arc4random()), [], Date())
    }
    
    public func loadStepData(_ day:Int, completion: @escaping (Int, Array<Int>, Date) -> Void) -> Void {
        if CMPedometer.isStepCountingAvailable() {
            return doReal(day:day, completion:completion)
        } else {
            return doSim(day:day, completion:completion)
        }
    }
    
    subscript(day:Int, completion: @escaping (UserDiaryEntry?, Date) -> Void) -> Void {
        var date = Date() - TimeInterval(24*3600*(day))
        let keydate = self.formatter.string(from: date)
        var entry = entries[keydate]
        completion(entry, date)
    }
    

}


//
//enum SpeechStatus {
//    case ready
//    case recognizing
//    case unavailable
//}
//
//
//@available(iOS 10.0, *)
//class SpeechAnalysis: NSObject, SFSpeechRecognizerDelegate {
//
//    public var running:Bool = false;
//    let speechRecognizer:SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
//    var recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//    var recognitionTask: SFSpeechRecognitionTask?
//    let audioEngine = AVAudioEngine()
//    var audioSamples = [AVAudioPCMBuffer]()
//    var audioIdx:Int = 0;
//    var sethaudio:AVAudioFile?;
//    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("test2.aac")
//    override init() {
//
//
//    super.init()
//    speechRecognizer?.delegate = self
//    }
//
//
//    var isFinal:Bool = false;
//    var status = SpeechStatus.ready {
//    didSet {
//    print("status: ", status);
//    }
//    }
//
//    public func startRecording(cb:@escaping (String) ->Void ) throws {
//    running = true;
//    guard let node = audioEngine.inputNode else {
//    return
//    }
//
//    recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
//    let recordingFormat = node.outputFormat(forBus: 0)
//    node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
//    self.recognitionRequest.append(buffer)
//    }
//
//    // Prepare and start recording
//    audioEngine.prepare()
//    do {
//    try audioEngine.start()
//    self.status = .recognizing
//    } catch {
//    return print(error)
//    }
//
//    // Analyze the speech
//    recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { result, error in
//    if let result = result {
//    cb(result.bestTranscription.formattedString);
//    } else if let error = error {
//    //                enableAudio()
//    print(error)
//    }
//    })
//
//    }
//
//
//    public func stop() {
//    running = false;
//    defer {
//    print("done with stop")
//    }
//
//
//    recognitionTask?.cancel()
//    audioEngine.stop()
//
//    if let node = audioEngine.inputNode {
//    node.removeTap(onBus: 0)
//    }
//    }
//
//
//
//}

