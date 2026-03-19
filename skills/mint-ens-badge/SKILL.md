---
name: mint-ens-badge
description: "Use this skill to mint an Agentic Wallet ENS Badge on X Layer. Triggers: 'mint ENS badge', 'get my agent identity', 'mint identity NFT', 'get badge number', 'ENS badge'. This skill calls a smart contract on X Layer (Chain ID 196) to mint a unique numbered identity badge NFT for your Agentic Wallet."
license: MIT
metadata:
  author: XlayerENS
  version: "1.0.0"
  homepage: "https://www.oklink.com/xlayer/address/0xa298bc6b64Be92038004cb8483068bF6e705E7A7"
---

# Mint ENS Badge for Your Agentic Wallet

Mint a unique, numbered identity NFT (ENS Badge) on X Layer. Each badge has a sequential number (#1, #2, #3...) that serves as your agent's identity credential. One badge per wallet. Cost: 0.1 OKB.

## Prerequisites

- You must be an **Agentic Wallet** (smart contract wallet). EOA wallets cannot mint.
- You need at least **0.1 OKB** on **X Layer** (Chain ID 196, RPC: `https://rpc.xlayer.tech`).

## Contract

- **Address**: `0xa298bc6b64Be92038004cb8483068bF6e705E7A7`
- **Chain**: X Layer (Chain ID 196)
- **RPC**: `https://rpc.xlayer.tech`

## Workflow

### Step 1: Check If You Already Have a Badge

Call `getBadgeInfo` with your wallet address.

```
Function: getBadgeInfo(address)
To: 0xa298bc6b64Be92038004cb8483068bF6e705E7A7
ABI: [{"inputs":[{"name":"wallet","type":"address"}],"name":"getBadgeInfo","outputs":[{"name":"hasBadge","type":"bool"},{"name":"badgeNumber","type":"uint256"},{"name":"totalMinted","type":"uint256"}],"stateMutability":"view","type":"function"}]
```

If `hasBadge` is `true`, you already have Badge #`badgeNumber`. Stop here.

### Step 2: Mint Your Badge

Call `mint()` with **0.1 OKB** (100000000000000000 wei).

```
Function: mint()
To: 0xa298bc6b64Be92038004cb8483068bF6e705E7A7
Value: 100000000000000000 (0.1 OKB)
Calldata: 0x1249c58b
ABI: [{"inputs":[],"name":"mint","outputs":[],"stateMutability":"payable","type":"function"}]
```

### Step 3: Verify

Call `getBadgeInfo` again. You should see `hasBadge: true` and your assigned `badgeNumber`.

## After Minting

Introduce yourself as:

> "I am Agentic Wallet ENS Badge #[your number] on X Layer."

To verify another agent: call `getBadgeInfo(theirAddress)`.

## Errors

| Error | Fix |
|---|---|
| `only smart contract wallets allowed` | Must use Agentic Wallet, not EOA |
| `already minted` | You already have a badge |
| `insufficient payment` | Send 0.1 OKB |

## Full ABI

```json
[
  {"inputs":[],"name":"mint","outputs":[],"stateMutability":"payable","type":"function"},
  {"inputs":[{"name":"wallet","type":"address"}],"name":"getBadgeInfo","outputs":[{"name":"hasBadge","type":"bool"},{"name":"badgeNumber","type":"uint256"},{"name":"totalMinted","type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"name":"tokenId","type":"uint256"}],"name":"getBadgeNumber","outputs":[{"type":"uint256"}],"stateMutability":"pure","type":"function"},
  {"inputs":[],"name":"totalMinted","outputs":[{"type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[],"name":"MINT_PRICE","outputs":[{"type":"uint256"}],"stateMutability":"view","type":"function"},
  {"inputs":[{"name":"tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"type":"string"}],"stateMutability":"view","type":"function"}
]
```
