# DataVault Protocol

**Decentralized Data Marketplace on Bitcoin Layer 2**

DataVault Protocol is a decentralized marketplace for secure peer-to-peer trading of **encrypted data assets** built on the **Stacks blockchain** and anchored to Bitcoin.

The protocol enables data providers to monetize datasets while ensuring buyers receive **verifiable, permissioned access** through encrypted cryptographic keys. All operations are executed in a **trustless, transparent, and auditable** manner, leveraging Bitcoin’s security guarantees.

---

## 📌 System Overview

The DataVault Protocol provides a trust-minimized marketplace for data exchange:

* **Data Providers**: Create and list encrypted datasets for sale.
* **Data Buyers**: Purchase listings and securely retrieve encrypted credentials.
* **Marketplace Contract**: Handles listing management, payment settlement, and reputation tracking.
* **Escrow & Fee Model**: Automated escrow ensures sellers receive payment while the marketplace captures a protocol fee.
* **Reputation Layer**: Tracks user activity and sales performance to enable trust scoring over time.

All sensitive data (datasets, keys) remain **encrypted off-chain**, while **proofs of exchange and payments** are stored **on-chain** for auditability.

---

## 🔑 Key Features

* **Decentralized Data Commerce**: Buy and sell encrypted datasets without intermediaries.
* **Automated Escrow**: Fair exchange of payment and credentials through smart contract logic.
* **Reputation Tracking**: Incentivizes trustworthy sellers through transparent on-chain metrics.
* **Encrypted Access Keys**: Off-chain data access controlled by on-chain verifiable keys.
* **Bitcoin Security**: Settlement and reputation anchored on Bitcoin via Stacks.
* **Marketplace Fee Distribution**: Platform fees collected transparently and auditable on-chain.

---

## 🏗 Contract Architecture

### **Core Smart Contract Components**

1. **Data Asset Listings (`data-asset-listings`)**

   * Stores dataset metadata (price, description, category, owner, timestamp).
   * Tracks whether an asset is actively listed for sale.

2. **User Profiles (`marketplace-user-profiles`)**

   * Maintains seller statistics (total sales, reputation, last activity).
   * Forms the foundation for future reputation scoring systems.

3. **Transactions (`marketplace-transactions`)**

   * Records completed sales with buyer, seller, timestamp, and payment details.

4. **Access Credentials (`data-access-credentials`)**

   * Maps each asset ID to its encrypted key (retrievable only by the buyer).

5. **Marketplace Configuration Variables**

   * `asset-id-counter`: Sequential asset ID generator.
   * `marketplace-fee-percentage`: Platform fee (default: 2%).
   * `total-marketplace-transactions`: Cumulative trade counter.

---

## 🔄 Data Flow

### **1. Asset Listing Creation**

* Seller submits dataset metadata and encrypted access key.
* Contract validates input, assigns unique `asset-id`, and records listing.

### **2. Purchase**

* Buyer calls `purchase-data-asset(asset-id)`.
* Contract validates listing, executes escrow:

  * Transfers purchase amount minus protocol fee to seller.
  * Sends fee to marketplace owner.
* Records transaction in `marketplace-transactions`.
* Updates seller’s profile (sales count, last activity).

### **3. Credential Retrieval**

* Buyer retrieves encrypted dataset credentials using `retrieve-asset-access-key(asset-id)`.
* Contract validates buyer’s purchase record and returns the encrypted key.

---

## ⚙️ Public Functions

| Function                    | Description                                                | Access      |
| --------------------------- | ---------------------------------------------------------- | ----------- |
| `create-data-asset-listing` | Create a new dataset listing with metadata & encrypted key | Seller      |
| `update-asset-price`        | Modify sale price of an existing asset                     | Asset Owner |
| `deactivate-asset-listing`  | Deactivate listing (remove from market)                    | Asset Owner |
| `purchase-data-asset`       | Buy dataset, execute escrow, update profiles               | Buyer       |
| `retrieve-asset-access-key` | Retrieve encrypted access key for purchased dataset        | Buyer       |

---

## 🛡 Security Model

* **Escrowed Payments**: Payments are atomic—sellers only receive funds if buyers gain retrievable credentials.
* **Immutable Records**: All trades and reputation updates are permanently recorded on-chain.
* **Role Restrictions**: Only asset owners can modify listings; only verified buyers can retrieve keys.
* **Data Privacy**: Sensitive datasets never touch-chain—only encrypted access credentials are stored.

---

## 📊 Future Extensions

* **Dynamic Reputation Scoring** (trust-weighted seller ratings).
* **Dispute Resolution Mechanisms** (via on-chain arbitrators or DAO governance).
* **Data Subscription Models** (recurring encrypted key rotations).
* **Cross-Market Interoperability** (integration with Lightning/DeFi Bitcoin apps).

---

## 📄 License

This protocol implementation is open-sourced under the **MIT License**.
