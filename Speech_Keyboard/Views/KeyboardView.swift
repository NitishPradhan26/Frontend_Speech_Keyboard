//
//  KeyboardView.swift
//  Speech_Keyboard
//
//  Created by Claude on 2025-09-12.
//

import SwiftUI

struct KeyboardView: View {
    @StateObject private var viewModel = KeyboardViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            // Status indicator
            StatusIndicatorView(status: viewModel.recordingStatus)
                .padding(.horizontal)
            
            // Recording controls
            HStack(spacing: 16) {
                RecordButton(
                    isRecording: viewModel.recordingStatus == .recording,
                    isEnabled: viewModel.hasFullAccess && viewModel.recordingStatus != .processing,
                    action: viewModel.handleRecordAction
                )
                
                if viewModel.recordingStatus == .recording {
                    PauseButton(
                        isPaused: viewModel.recordingStatus == .paused,
                        isEnabled: true,
                        action: viewModel.handlePauseAction
                    )
                    
                    StopButton(
                        isEnabled: true,
                        action: viewModel.handleStopAction
                    )
                }
            }
            .padding(.horizontal)
            
            // Full Access warning if needed
            if !viewModel.hasFullAccess {
                FullAccessWarningView()
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .onAppear {
            viewModel.checkFullAccess()
        }
    }
}

struct RecordButton: View {
    let isRecording: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                
                Text(isRecording ? "Recording..." : "Record")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(isEnabled ? .white : .gray)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(buttonBackgroundColor)
            )
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isRecording)
    }
    
    private var buttonBackgroundColor: Color {
        if !isEnabled {
            return Color.gray.opacity(0.3)
        }
        return isRecording ? Color.red : Color.blue
    }
}

struct PauseButton: View {
    let isPaused: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isPaused ? "play.circle.fill" : "pause.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(isEnabled ? .orange : .gray)
        }
        .disabled(!isEnabled)
        .scaleEffect(isPaused ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPaused)
    }
}

struct StopButton: View {
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "stop.circle.fill")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(isEnabled ? .red : .gray)
        }
        .disabled(!isEnabled)
    }
}

struct StatusIndicatorView: View {
    let status: RecordingStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .opacity(status == .recording ? 1.0 : 0.7)
                .scaleEffect(status == .recording ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: status == .recording)
            
            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private var statusColor: Color {
        switch status {
        case .idle:
            return .gray
        case .recording:
            return .red
        case .paused:
            return .orange
        case .processing:
            return .blue
        case .completed:
            return .green
        case .error:
            return .red
        }
    }
    
    private var statusText: String {
        switch status {
        case .idle:
            return "Ready to record"
        case .recording:
            return "Recording..."
        case .paused:
            return "Paused"
        case .processing:
            return "Processing..."
        case .completed:
            return "Completed"
        case .error:
            return "Error occurred"
        }
    }
}

struct FullAccessWarningView: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text("Full Access Required")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Text("Enable 'Allow Full Access' in Settings > General > Keyboard to use voice recording.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    KeyboardView()
        .frame(height: 150)
}