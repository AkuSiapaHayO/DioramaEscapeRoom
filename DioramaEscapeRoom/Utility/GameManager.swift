//
//  GameManager.swift
//  DioramaEscapeRoom
//
//  Created by Daniel Fernando Herawan on 23/06/25.
//

import Foundation
import SwiftUI

enum GameProgressState: Int {
    case puzzle1_done = 1
    case puzzle3_done = 2
    case puzzle4_done = 3
    case puzzle5_done = 4
    case gameFinished = 5
}

enum InputTarget {
    case locker1
    case locker2
    case locker3
    case door
}


class GameManager: ObservableObject {
    @Published var currentState: GameProgressState? = nil
    @Published var inventory: [String] = []
    @Published var showingNumberInput: Bool = false
    @Published var inputTarget: InputTarget? = nil
    @Published var foundRiddleCount: Int = 0
    @Published var hasInsertedKey: Bool = false

    func advanceTo(_ newState: GameProgressState) {
        print("\u{1F501} State berubah ke: \(newState)")
        currentState = newState
    }

    func handleNodeTapped(_ tappedNodeName: String) {
        switch tappedNodeName {
        case "Locker_1":
            if currentState == nil {
                showingNumberInput = true
                inputTarget = .locker1
            }

        case "Locker_2":
            if currentState == .puzzle1_done || currentState == .puzzle3_done || currentState == .puzzle4_done || currentState == .puzzle5_done || currentState == .gameFinished {
                showingNumberInput = true
                inputTarget = .locker2
            }

        case "Locker_3":
            if currentState == .puzzle3_done || currentState == .puzzle4_done || currentState == .puzzle5_done || currentState == .gameFinished {
                showingNumberInput = true
                inputTarget = .locker3
            }

        case "Cabinet_1", "Cabinet_2", "Cabinet_3":
            if currentState == .puzzle4_done || currentState == .puzzle5_done || currentState == .gameFinished {
                foundRiddle()
            }

        case "Passcode_Machine":
            if currentState == .puzzle5_done || currentState == .gameFinished {
                showingNumberInput = true
                inputTarget = .door
            }

        default:
            break
        }
    }

    func handleNumberInput(_ number: String) {
        guard let target = inputTarget else { return }
        switch target {
        case .locker1:
            if number.lowercased() == "coffe" && currentState == nil {
                advanceTo(.puzzle1_done)
            }
        case .locker2:
            if number == "2586" && currentState == .puzzle1_done {
                inventory.append("UV_Flashlight")
                inventory.append("Clue_color")
                advanceTo(.puzzle3_done)
            }
        case .locker3:
            if number == "357759" && currentState == .puzzle3_done {
                inventory.append("Golden_Key")
                advanceTo(.puzzle4_done)
            }
        case .door:
            if number == "2268" && currentState == .puzzle5_done {
                advanceTo(.gameFinished)
            }
        }
        showingNumberInput = false
        inputTarget = nil
    }
    
    func isPuzzleUnlocked(for requiredState: GameProgressState) -> Bool {
        guard let current = currentState else { return false }
        let order: [GameProgressState] = [.puzzle1_done, .puzzle3_done, .puzzle4_done, .puzzle5_done, .gameFinished]
        guard let requiredIndex = order.firstIndex(of: requiredState),
              let currentIndex = order.firstIndex(of: current) else { return false }
        return currentIndex >= requiredIndex
    }


    func foundRiddle() {
        if foundRiddleCount < 3 {
            foundRiddleCount += 1
        }

        // Cek hanya jika drawer sudah bisa dibuka (golden key sudah masuk)
        if foundRiddleCount == 3 && currentState == .puzzle5_done {
            advanceTo(.gameFinished)
        }
    }

}
