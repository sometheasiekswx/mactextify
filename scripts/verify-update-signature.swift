import Foundation
import CryptoKit

// All arguments are public. Private signing material never reaches this verifier.
guard CommandLine.arguments.count == 4,
      let key = Data(base64Encoded: CommandLine.arguments[1]),
      let signature = Data(base64Encoded: CommandLine.arguments[2]) else {
    fputs("Expected public key, signature and archive path\n", stderr)
    exit(1)
}
do {
    let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: key)
    let data = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[3]))
    guard publicKey.isValidSignature(signature, for: data) else {
        fputs("Update signature does not match the embedded public key\n", stderr)
        exit(1)
    }
} catch {
    fputs("Could not verify update signature\n", stderr)
    exit(1)
}
