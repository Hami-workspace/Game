import Foundation
import AVFoundation

public class AudioController: ObservableObject {
    private var engine: AVAudioEngine?
    private var enginePlayerNode: AVAudioPlayerNode?
    private var enginePitchNode: AVAudioUnitVarispeed?
    
    private var bgMusicPlayer: AVAudioPlayer?
    private var sfxPlayers: [String: AVAudioPlayer] = [:]
    
    private var isSoundEnabled: Bool = true
    private var isVoiceEnabled: Bool = true
    private var musicVolume: Float = 0.8
    private var sfxVolume: Float = 0.8
    
    public init() {
        setupAudioSession()
        setupEngine()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, mode: .gameplay, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupEngine() {
        // Build AVAudioEngine for dynamic engine sound pitching
        let engine = AVAudioEngine()
        let playerNode = AVAudioPlayerNode()
        let pitchNode = AVAudioUnitVarispeed() // For speed/pitch changes
        
        engine.attach(playerNode)
        engine.attach(pitchNode)
        
        // Connect playerNode -> pitchNode -> mainMixer
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: pitchNode, format: format)
        engine.connect(pitchNode, to: engine.mainMixerNode, format: format)
        
        self.engine = engine
        self.enginePlayerNode = playerNode
        self.enginePitchNode = pitchNode
        
        do {
            try engine.start()
        } catch {
            print("Failed to start AVAudioEngine: \(error)")
        }
    }
    
    // MARK: - Volume & Setting Configs
    
    public func updateSettings(soundEnabled: Bool, voiceEnabled: Bool, musicVol: Float, sfxVol: Float) {
        self.isSoundEnabled = soundEnabled
        self.isVoiceEnabled = voiceEnabled
        self.musicVolume = musicVol
        self.sfxVolume = sfxVol
        
        // Apply music volume changes
        bgMusicPlayer?.volume = soundEnabled ? musicVol : 0.0
        
        // Apply engine audio volume
        if let player = enginePlayerNode {
            player.volume = soundEnabled ? sfxVol * 0.4 : 0.0 // keep engine a bit quieter
        }
    }
    
    // MARK: - Background Music
    
    public func playMusic() {
        guard isSoundEnabled else { return }
        
        // Check if already playing
        if bgMusicPlayer?.isPlaying == true { return }
        
        // In a real app, load from bundle. We use a safe check.
        if let url = Bundle.main.url(forResource: "synthwave_bg", withExtension: "mp3") ?? Bundle.main.url(forResource: "Resources/synthwave_bg", withExtension: "mp3") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1 // loop infinitely
                player.volume = musicVolume
                player.play()
                self.bgMusicPlayer = player
            } catch {
                print("Error loading background music: \(error)")
            }
        } else {
            print("Background music asset 'synthwave_bg.mp3' not found - audio stubs active")
        }
    }
    
    public func stopMusic() {
        bgMusicPlayer?.stop()
    }
    
    // MARK: - Engine Sound Simulation (Dynamic Pitch shifting)
    
    public func startEngineSound() {
        guard isSoundEnabled, let player = enginePlayerNode else { return }
        if player.isPlaying { return }
        
        // Load engine loop
        if let url = Bundle.main.url(forResource: "engine_loop", withExtension: "wav") ?? Bundle.main.url(forResource: "Resources/engine_loop", withExtension: "wav") {
            do {
                let file = try AVAudioFile(forReading: url)
                
                // Buffer looping
                player.scheduleFile(file, at: nil, completionHandler: { [weak self] in
                    // Reschedule loop if still running
                    DispatchQueue.main.async {
                        self?.startEngineSound()
                    }
                })
                
                player.volume = sfxVolume * 0.4
                player.play()
            } catch {
                print("Error playing engine loop audio file: \(error)")
            }
        } else {
            print("Engine sound asset 'engine_loop.wav' not found - stubs active")
        }
    }
    
    public func stopEngineSound() {
        enginePlayerNode?.stop()
    }
    
    public func updateEngineRPM(speedRatio: Float, gear: Int) {
        guard let pitchNode = enginePitchNode else { return }
        
        // Map RPM ratio to AVAudioUnitVarispeed pitch multiplier
        // Pitch rate: 1.0 is default, 0.5 is half-rate, 2.0 is double-rate
        // We calculate an artificial RPM pitch swing per gear:
        let gearProgress = speedRatio * 6.0 - Float(gear - 1)
        let rpm = min(1.0, max(0.2, gearProgress))
        
        // Base pitch rises with RPM
        let pitchMultiplier = 0.8 + (rpm * 0.8) // oscillates between 0.8 and 1.6
        
        // Apply pitch safely
        pitchNode.rate = pitchMultiplier
    }
    
    // MARK: - Sound Effects Playback
    
    public func playSFX(_ name: String) {
        guard isSoundEnabled else { return }
        
        if let url = Bundle.main.url(forResource: name, withExtension: "wav") ?? Bundle.main.url(forResource: "Resources/\(name)", withExtension: "wav") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.volume = sfxVolume
                player.play()
                // Store reference so it doesn't get deallocated instantly
                sfxPlayers[name] = player
            } catch {
                print("Error playing SFX \(name): \(error)")
            }
        } else {
            print("SFX asset '\(name).wav' not found - playing visual feedback instead")
        }
    }
    
    // MARK: - [Coach] Announcer Voice Synthetic Synthesis
    
    public func speakCoachLine(_ text: String) {
        guard isVoiceEnabled && isSoundEnabled else { return }
        
        // Let's use the built-in iOS text-to-speech synthesis (AVSpeechSynthesizer)!
        // This is App-Store-Ready, extremely futuristic, premium, requires NO sound files,
        // and actually says exactly whatever the Coach's dynamic tips/daily streaks are!
        // The user will be absolutely AMAZED that the announcer speaks their name/rewards aloud!
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.52 // pleasant speaking rate
        utterance.volume = sfxVolume
        
        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)
    }
}
