# 🏭 Pollution Credit Marketplace

A transparent blockchain-based marketplace for trading pollution allowances between industries, built on the Stacks blockchain using Clarity smart contracts.

## 🌍 Overview

The Pollution Credit Marketplace enables companies to trade carbon credits and pollution allowances in a decentralized, transparent manner. Industries can buy and sell their allocated pollution credits, creating economic incentives for cleaner operations.

## ✨ Features

- 🏢 **Company Registration**: Industries can register with their name and industry type
- 💳 **Credit Management**: Track pollution credit balances for each company
- 🛒 **Credit Marketplace**: Create listings to sell credits with custom pricing
- 💰 **Secure Trading**: Buy credits from other companies using STX tokens
- 📊 **Transaction History**: Complete audit trail of all credit transfers
- ⏰ **Time-based Listings**: Listings expire automatically after specified duration
- 📈 **Market Statistics**: View total credits issued and traded

## 🚀 Getting Started

### Prerequisites

- Clarinet CLI installed
- Stacks wallet for testing

### Installation

```bash
clarinet new pollution-marketplace
cd pollution-marketplace
```

Copy the contract code into `contracts/pollution-credit-marketplace.clar`

### Testing

```bash
clarinet console
```

## 📖 Usage

### Register a Company

```clarity
(contract-call? .pollution-credit-marketplace register-company "Green Energy Corp" "Energy")
```

### Issue Credits (Owner Only)

```clarity
(contract-call? .pollution-credit-marketplace issue-credits 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE u1000)
```

### Create a Credit Listing

```clarity
(contract-call? .pollution-credit-marketplace create-listing u100 u50 u144)
```

### Buy Credits

```clarity
(contract-call? .pollution-credit-marketplace buy-credits u1 u50)
```

### View Company Information

```clarity
(contract-call? .pollution-credit-marketplace get-company 'ST1HTBVD3JG9C05J7HBJTHGR0GGW7KXW28M5JS8QE)
```

### Check Marketplace Statistics

```clarity
(contract-call? .pollution-credit-marketplace get-marketplace-stats)
```

## 🔧 Contract Functions

### Public Functions

- `register-company` - Register a new company in the marketplace
- `issue-credits` - Issue new pollution credits (owner only)
- `create-listing` - List credits for sale
- `buy-credits` - Purchase credits from a listing
- `cancel-listing` - Cancel an active listing

### Read-Only Functions

- `get-company` - Get company details and credit balance
- `get-listing` - Get listing information
- `get-transaction` - Get transaction details
- `get-marketplace-stats` - Get overall marketplace statistics
- `is-listing-active` - Check if a listing is still active

## 🛡️ Security Features

- Only registered companies can participate
- Sellers cannot buy their own listings
- Automatic expiration of listings
- Credit balance validation
- Owner-only credit issuance

## 🌱 Environmental Impact

This marketplace creates economic incentives for companies to:
- Reduce their pollution output
- Invest in cleaner technologies
- Trade excess credits efficiently
- Maintain transparent environmental records

## 📄 License

MIT License - Feel free to use this code for environmental good! 🌍
```

**Git commit message:**
```
feat: implement pollution credit marketplace MVP with trading functionality
```

**GitHub Pull Request title:**
```
🏭 Add Pollution Credit Marketplace Smart Contract
```

**GitHub Pull Request description:**
```
## Summary
Added a complete MVP implementation of a pollution credit marketplace smart contract that enables transparent trading of pollution allowances between industries.

## What's Added
- **Smart Contract**: Complete Clarity contract with company registration, credit issuance, marketplace listings, and secure trading
- **Company Management**: Registration system for industries with credit balance tracking  
- **Trading System**: Create/cancel listings, buy credits with STX payments, automatic expiration
- **Audit Trail**: Complete transaction history and marketplace statistics
- **Security**: Authorization checks, balance validation, and anti-self-trading protection

## Key Features
- 🏢 Company registration and management
- 💳 Pollution credit allocation and tracking
- 🛒 Decentralized marketplace for credit trading
- 📊 Transparent transaction history
- ⏰ Time-based listing expiration
- 🛡️ Comprehensive security validations

Ready for testing and deployment on Stacks blockchain.
