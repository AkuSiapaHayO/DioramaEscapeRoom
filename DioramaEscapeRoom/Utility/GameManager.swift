//
//  GameManager.swift
//  DioramaEscapeRoom
//
//  Created by Daniel Fernando Herawan on 23/06/25.
//

import Foundation
import SwiftUI

enum GameProgressState {
    case puzzle1_done
    case puzzle3_done
    case puzzle4_done
    case puzzle5_done
    case gameFinished
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
            if currentState == .puzzle1_done {
                showingNumberInput = true
                inputTarget = .locker2
            }

        case "Locker_3":
            if currentState == .puzzle3_done {
                showingNumberInput = true
                inputTarget = .locker3
            }

        case "Cabiner_1", "Cabinet_2", "Cabinet_3":
            if currentState == .puzzle4_done {
                foundRiddle()
            }
            
        case "Passcode_Machine":
            if currentState == .puzzle5_done {
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
            if number == "1268" && currentState == .puzzle5_done {
                advanceTo(.gameFinished)
            }
        }
        showingNumberInput = false
        inputTarget = nil
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
