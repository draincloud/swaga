# Project in progress (not prod ready)

# Swaga - Elixir Bitcoin Library

## Overview

Swaga appears to be an Elixir library for interacting with the Bitcoin protocol. It provides tools and modules for
handling various aspects of Bitcoin, including cryptographic operations, network communication, and data structures.
Inspired by book `Programming Bitcoin: Learn How to Program Bitcoin from Scratch`

## Features

* **Cryptographic Primitives:**
    * Elliptic curve cryptography (e.g., `Secp256Field`, `Secp256Point`, `PrivateKey`, `Signature`)
    * Hashing utilities (`CryptoUtils`)
    * Base58 encoding/decoding (`Base58`)
* **Bitcoin Data Structures:**
    * Transactions (`Tx`, `TxIn`, `TxOut`, `TxFetcher`)
    * Blocks (`Block`, `MerkleBlock`, `HeadersMessage`)
    * Merkle Trees (`MerkleTree`)
    * Scripts (`Script`, `VM`)
    * Bloom Filters (`BloomFilter`)
* **BIP (Bitcoin Improvement Proposal) Support:**
    * BIP32: Hierarchical Deterministic Wallets (`BIP32.Xprv`, `BIP32.Xpub`, `BIP32.Seed`, `BIP32.DerivationPath`)
    * BIP39: Mnemonic code for generating deterministic keys (`BIP39.Wordlist`)
* **Networking:**
    * P2P communication with Bitcoin nodes (`BitcoinNode`, `NetworkEnvelope`, `VersionMessage`, `VerAckMessage`,
      `PingMessage`, `PongMessage`, `GetHeadersMessage`, `GetDataMessage`)
    * Socket handling (`Socket`)
* **Wallet Functionality (Implied):**
    * Address generation
    * Transaction creation and signing

## Docs

* Run the docs

```bash
cd doc
python3 -m http.server 4040
```

## Tests

* Examples (some of the tests are skipped by default look for: @moduletag :skip)

```bash
# Run with debugger
iex -S mix test --trace test/bloom_filter/bloom_filter_test.exs
mix test --only in_progress
mix test --exclude in_progress
```