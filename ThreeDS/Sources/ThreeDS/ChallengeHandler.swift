//
//  ChallengeHandler.swift
//  ThreeDS
//
//  Created by kevin on 9/10/24.
//
import Ravelin3DS

class ChallengeHandler: ChallengeStatusReceiver {
    let sessionId: String
    let authenticationResponse: AuthenticationResponse
    let transactionStatusMap = [
        "Y": "successful",
        "A": "attempted",
        "N": "failed",
        "U": "unavailable",
        "R": "rejected",
    ]
    let onCompleted: (ChallengeResponse) -> Void
    let onFailure: (ChallengeResponse) -> Void
    let transaction: Transaction

    init(
        sessionId: String,
        authenticationResponse: AuthenticationResponse,
        onCompleted: @escaping (ChallengeResponse) -> Void,
        onFailure: @escaping (ChallengeResponse) -> Void,
        transaction: Transaction
    ) {
        self.sessionId = sessionId
        self.authenticationResponse = authenticationResponse
        self.onCompleted = onCompleted
        self.onFailure = onFailure
        self.transaction = transaction
    }

    func completed(completionEvent: CompletionEvent) {
        if let transactionStatus = transactionStatusMap[completionEvent.getTransactionStatus()] {
            Logger.log("challenge completed with status: \(transactionStatus)")
            onCompleted(
                ChallengeResponse(
                    id: sessionId,
                    status: transactionStatus,
                    details: authenticationResponse.authenticationStatusReason
                )
            )
        } else {
            Logger.log("challenge failed successfully")
        }
        closeTransaction()
    }

    func cancelled() {
        closeTransaction()
        Logger.log("challenge cancelled")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "Challenge cancelled"))
    }

    func timedout() {
        closeTransaction()
        Logger.log("challenge timed out")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "Challenge timed out"))
    }

    func protocolError(protocolErrorEvent: ProtocolErrorEvent) {
        closeTransaction()
        Logger.log("challenge protocol error: \(protocolErrorEvent.getErrorMessage())")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "ProtocolError \(protocolErrorEvent.getErrorMessage())"
            )
        )
    }

    func runtimeError(runtimeErrorEvent: RuntimeErrorEvent) {
        closeTransaction()
        Logger.log("challenge runtime error: \(runtimeErrorEvent.getErrorMessage())")
        onFailure(
            ChallengeResponse(
                id: sessionId,
                status: "N",
                details: "RuntimeError \(runtimeErrorEvent.getErrorMessage())"
            )
        )
    }

    func closeTransaction() {
        do {
            try transaction.close()
        } catch {
            Logger.log("Unable to close transaction \(error.localizedDescription)")
        }
    }
}
