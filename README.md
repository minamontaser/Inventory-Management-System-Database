# 📦 Inventory Management System (Database)

A robust and scalable **SQL Server database schema** designed for managing inventory, suppliers, purchases, sales, and stock movements efficiently.

---

## 🚀 Features

- 📂 Category & Subcategory management
- 📦 Product catalog with pricing and barcode support
- 🏬 Multi-location storage (warehouse/bin system)
- 📊 Real-time stock tracking via ledger
- 🧾 Purchase & Sales invoice management
- 🤝 Supplier management & payments tracking
- 💰 Discount, tax, and pricing calculations (computed columns)
- 🔒 Data integrity using constraints, foreign keys, and checks

---

## 🧱 Database Structure

### 1. Categories & Subcategories
- **Categories**
  - Unique category code and name
- **Subcategories**
  - Linked to categories via foreign key

---

### 2. Products
- Stores product details:
  - Serial number (unique)
  - Buying & selling prices
  - Barcode support
  - Reorder level
  - Category & subcategory relationships

---

### 3. Storage Locations
- Represents warehouse structure:
  - Block (e.g., B2)
  - Aisle (e.g., A1)
  - Shelf (e.g., 11)
- Optional max capacity per location

---

### 4. Stock Ledger
- Tracks inventory per product per location
- Ensures:
  - One record per product-location pair
- Stores:
  - Quantity on hand
  - Last movement timestamp

---

### 5. Suppliers
- Supplier information:
  - Contact details
  - Tax number
  - Unique email & code

---

### 6. Purchase Module

#### PurchaseInvoices
- Tracks supplier invoices
- Includes:
  - Subtotal, discount, tax, total
  - Status:
    - `DRAFT`
    - `CONFIRMED`
    - `PARTIALLY_PAID`
    - `PAID`
    - `CANCELLED`

#### PurchaseInvoiceLines
- Line items per invoice
- Includes:
  - Quantity & unit price
  - Discount %
  - Computed fields:
    - LineSubTotal
    - LineDiscount
    - LineTotal
- Linked to storage location (where stock is stored)

---

### 7. Sales Module

#### SalesInvoices
- Customer sales transactions
- Supports:
  - Multiple payment methods (`CASH`, `CARD`, etc.)
  - Invoice statuses (`COMPLETED`, `REFUNDED`, `VOIDED`)

#### SalesInvoiceLines
- Items sold per invoice
- Includes:
  - Selling price snapshot
  - Cost snapshot (for profit analysis)
  - Discount calculations

---

### 8. Supplier Payments
- Tracks payments made to suppliers
- Linked to:
  - Supplier
  - Purchase Invoice
- Supports multiple payment methods

---

## 🔗 Relationships Overview

- Category → Subcategory → Product
- Product → StockLedger → StorageLocations
- Supplier → PurchaseInvoices → PurchaseInvoiceLines
- SalesInvoices → SalesInvoiceLines
- SupplierPayments → PurchaseInvoices

---

## ⚙️ Setup Instructions

1. Open SQL Server Management Studio (SSMS)
2. Run the provided SQL script:
   ```sql
   USE master;
   GO
   CREATE DATABASE Inventory_management_system;
