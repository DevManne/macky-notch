//
//  ClipboardHistoryView.swift
//  boringNotch
//

import Defaults
import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject private var history = ClipboardHistoryManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Clipboard")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if history.entries.contains(where: { !$0.isPinned }) {
                    Button("Clear") { history.clearUnpinned() }
                        .buttonStyle(PlainButtonStyle())
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .padding(.horizontal, 4)

            if history.entries.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.title2)
                    Text("Copy some text and it will show up here")
                        .font(.caption)
                }
                .foregroundStyle(.gray)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 4) {
                        ForEach(history.entries) { entry in
                            ClipboardRow(entry: entry, isCopied: history.lastCopiedID == entry.id)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClipboardRow: View {
    let entry: ClipboardHistoryManager.Entry
    let isCopied: Bool
    @ObservedObject private var history = ClipboardHistoryManager.shared
    @State private var isHovering = false

    private var preview: String {
        entry.text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                history.copy(entry)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .foregroundStyle(isCopied ? Color.green : Color.gray)
                        .frame(width: 16)
                    Text(preview)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                history.togglePin(entry)
            } label: {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .foregroundStyle(entry.isPinned ? Color.effectiveAccent : Color.gray)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(entry.isPinned || isHovering ? 1 : 0)

            Button {
                history.remove(entry)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.gray)
            }
            .buttonStyle(PlainButtonStyle())
            .opacity(isHovering ? 1 : 0)
        }
        .font(.system(size: 12))
        .padding(.horizontal, 10)
        .frame(height: 26)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isHovering ? 0.14 : 0.08))
        )
        .onHover { isHovering = $0 }
    }
}
