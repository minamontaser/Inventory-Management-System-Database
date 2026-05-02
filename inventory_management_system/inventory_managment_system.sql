USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'Inventory_management_system')
    CREATE DATABASE Inventory_management_system COLLATE SQL_Latin1_General_CP1_CI_AS;
GO

USE Inventory_management_system;
GO

CREATE TABLE Categories (
    CategoryID    INT           NOT NULL IDENTITY(1,1),
    CategoryCode  VARCHAR(20)   NOT NULL,
    CategoryName  NVARCHAR(100) NOT NULL,
    IsActive      BIT           NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt     DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Categories       PRIMARY KEY CLUSTERED (CategoryID),
    CONSTRAINT UQ_Categories_Code  UNIQUE (CategoryCode),
    CONSTRAINT UQ_Categories_Name  UNIQUE (CategoryName)
);
GO

CREATE TABLE Subcategories (
    SubcategoryID    INT           NOT NULL IDENTITY(1,1),
    CategoryID       INT           NOT NULL,
    SubcategoryCode  VARCHAR(20)   NOT NULL,
    SubcategoryName  NVARCHAR(100) NOT NULL,
    IsActive         BIT           NOT NULL DEFAULT 1,
    CreatedAt        DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Subcategories          PRIMARY KEY CLUSTERED (SubcategoryID),
    CONSTRAINT UQ_Subcategories_Code     UNIQUE (SubcategoryCode),
    CONSTRAINT FK_Subcategories_Category FOREIGN KEY (CategoryID)
        REFERENCES Categories (CategoryID)
        ON UPDATE CASCADE
        ON DELETE NO ACTION
);
GO

CREATE TABLE Products (
    ProductID       INT             NOT NULL IDENTITY(1,1),
    SerialNumber    VARCHAR(50)     NOT NULL,   -- e.g. "PRD-2024-00421"
    ProductName     NVARCHAR(200)   NOT NULL,
    CategoryID      INT             NOT NULL,
    SubcategoryID   INT             NOT NULL,
    BuyingPrice     DECIMAL(18,4)   NOT NULL CHECK (BuyingPrice  >= 0),
    SellingPrice    DECIMAL(18,4)   NOT NULL CHECK (SellingPrice >= 0),
    ImageURL        NVARCHAR(500)       NULL,   -- CDN path or relative URL
    Barcode         VARCHAR(100)        NULL,
    Unit            NVARCHAR(30)    NOT NULL DEFAULT N'Piece',
    ReorderLevel    INT             NOT NULL DEFAULT 0 CHECK (ReorderLevel >= 0),
    IsActive        BIT             NOT NULL DEFAULT 1,
    Notes           NVARCHAR(500)       NULL,
    CreatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt       DATETIME2(0)    NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Products              PRIMARY KEY CLUSTERED (ProductID),
    CONSTRAINT UQ_Products_Serial       UNIQUE (SerialNumber),
    CONSTRAINT UQ_Products_Barcode      UNIQUE (Barcode),
    CONSTRAINT FK_Products_Category     FOREIGN KEY (CategoryID)
        REFERENCES Categories    (CategoryID),
    CONSTRAINT FK_Products_Subcategory  FOREIGN KEY (SubcategoryID)
        REFERENCES Subcategories (SubcategoryID)
);
GO

CREATE TABLE StorageLocations (
    LocationID    INT           NOT NULL IDENTITY(1,1),
    --LocationCode  VARCHAR(30)   NOT NULL,   -- "B2-A1-11" create it in the backend
    Block         VARCHAR(10)       NULL,   -- "B2"
    Aisle         VARCHAR(10)       NULL,   -- "A1"
    Shelf         VARCHAR(10)       NULL,   -- "11"
    Description   NVARCHAR(200)     NULL,
    MaxCapacity   INT               NULL CHECK (MaxCapacity > 0),
    IsActive      BIT           NOT NULL DEFAULT 1,
    CreatedAt     DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_StorageLocations      PRIMARY KEY CLUSTERED (LocationID),

);
GO

CREATE TABLE StockLedger (
    LedgerID     BIGINT        NOT NULL IDENTITY(1,1),
    ProductID    INT           NOT NULL,
    LocationID   INT           NOT NULL,
    QtyOnHand    INT NOT NULL DEFAULT 0 CHECK (QtyOnHand >= 0),
    LastMovedAt  DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt    DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_StockLedger             PRIMARY KEY CLUSTERED (LedgerID),
    CONSTRAINT UQ_StockLedger_ProductLoc  UNIQUE (ProductID, LocationID),
    CONSTRAINT FK_StockLedger_Product     FOREIGN KEY (ProductID)
        REFERENCES Products        (ProductID),
    CONSTRAINT FK_StockLedger_Location    FOREIGN KEY (LocationID)
        REFERENCES StorageLocations (LocationID)
);
GO

CREATE TABLE Suppliers (
    SupplierID       INT           NOT NULL IDENTITY(1,1),
    SupplierCode     VARCHAR(20)   NOT NULL,
    SupplierName     NVARCHAR(200) NOT NULL,
    Phone            VARCHAR(30)       NULL,
    Email            VARCHAR(150)      NULL,
    Address          NVARCHAR(400)     NULL,
    TaxNumber        VARCHAR(50)       NULL,
    IsActive         BIT           NOT NULL DEFAULT 1,
    CreatedAt        DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt        DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_Suppliers        PRIMARY KEY CLUSTERED (SupplierID),
    CONSTRAINT UQ_Suppliers_Code   UNIQUE (SupplierCode),
    CONSTRAINT UQ_Suppliers_Email  UNIQUE (Email)
);
GO

CREATE TABLE PurchaseInvoices (
    PurchaseInvoiceID  BIGINT        NOT NULL IDENTITY(1,1),
    InvoiceNumber      VARCHAR(50)   NOT NULL,  -- "PI-20240315-0001"
    SupplierID         INT           NOT NULL,
    InvoiceDate        DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    SubTotal           DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (SubTotal   >= 0),
    DiscountAmount     DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (DiscountAmount >= 0),
    TaxAmount          DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (TaxAmount   >= 0),
    TotalAmount        DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (TotalAmount >= 0),
    Status             VARCHAR(20)   NOT NULL DEFAULT 'DRAFT',
    Notes              NVARCHAR(500)     NULL,
    CreatedBy          NVARCHAR(100)     NULL,
    CreatedAt          DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),
    UpdatedAt          DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_PurchaseInvoices           PRIMARY KEY CLUSTERED (PurchaseInvoiceID),
    CONSTRAINT UQ_PurchaseInvoices_Number    UNIQUE (InvoiceNumber),
    CONSTRAINT FK_PurchaseInvoices_Supplier  FOREIGN KEY (SupplierID)
        REFERENCES Suppliers (SupplierID),
    CONSTRAINT CK_PurchaseInvoices_Status    CHECK (Status IN
        ('DRAFT','CONFIRMED','PARTIALLY_PAID','PAID','CANCELLED'))
);
GO

CREATE TABLE PurchaseInvoiceLines (
    LineID              BIGINT        NOT NULL IDENTITY(1,1),
    PurchaseInvoiceID   BIGINT        NOT NULL,
    ProductID           INT           NOT NULL,
    LocationID          INT           NOT NULL,   -- Which bin receives this stock
    Quantity            DECIMAL(18,4) NOT NULL CHECK (Quantity > 0),
    UnitBuyingPrice     DECIMAL(18,4) NOT NULL CHECK (UnitBuyingPrice >= 0),  -- PRICE SNAPSHOT
    DiscountPercent     DECIMAL(5,2)  NOT NULL DEFAULT 0 CHECK (DiscountPercent BETWEEN 0 AND 100),
    LineSubTotal        AS (Quantity * UnitBuyingPrice) PERSISTED,
    LineDiscount        AS (Quantity * UnitBuyingPrice * DiscountPercent / 100) PERSISTED,
    LineTotal           AS (Quantity * UnitBuyingPrice * (1 - DiscountPercent / 100)) PERSISTED,
    Notes               NVARCHAR(200)     NULL,

    CONSTRAINT PK_PurchaseInvoiceLines             PRIMARY KEY CLUSTERED (LineID),
    CONSTRAINT FK_PurchaseInvoiceLines_Invoice     FOREIGN KEY (PurchaseInvoiceID)
        REFERENCES PurchaseInvoices (PurchaseInvoiceID) ON DELETE CASCADE,
    CONSTRAINT FK_PurchaseInvoiceLines_Product     FOREIGN KEY (ProductID)
        REFERENCES Products (ProductID),
    CONSTRAINT FK_PurchaseInvoiceLines_Location    FOREIGN KEY (LocationID)
        REFERENCES StorageLocations (LocationID)
);
GO

CREATE TABLE SalesInvoices (
    SalesInvoiceID   BIGINT        NOT NULL IDENTITY(1,1),
    InvoiceNumber    VARCHAR(50)   NOT NULL,   -- "SI-20240315-0042"
    InvoiceDate      DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),
    CustomerName     NVARCHAR(200)     NULL,
    CustomerPhone    VARCHAR(30)       NULL,
    SubTotal         DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (SubTotal      >= 0),
    DiscountAmount   DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (DiscountAmount >= 0),
    TaxAmount        DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (TaxAmount      >= 0),
    TotalAmount      DECIMAL(18,4) NOT NULL DEFAULT 0 CHECK (TotalAmount    >= 0),
    PaymentMethod    VARCHAR(30)   NOT NULL DEFAULT 'CASH',
    Status           VARCHAR(20)   NOT NULL DEFAULT 'COMPLETED',
    CashierName      NVARCHAR(100)     NULL,
    Notes            NVARCHAR(500)     NULL,
    CreatedAt        DATETIME2(3)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_SalesInvoices          PRIMARY KEY CLUSTERED (SalesInvoiceID),
    CONSTRAINT UQ_SalesInvoices_Number   UNIQUE (InvoiceNumber),
    CONSTRAINT CK_SalesInvoices_Payment  CHECK (PaymentMethod IN
        ('CASH','CARD','MOBILE','CREDIT','OTHER')),
    CONSTRAINT CK_SalesInvoices_Status   CHECK (Status IN
        ('COMPLETED','REFUNDED','VOIDED'))
);
GO

CREATE TABLE SalesInvoiceLines (
    LineID             BIGINT        NOT NULL IDENTITY(1,1),
    SalesInvoiceID     BIGINT        NOT NULL,
    ProductID          INT           NOT NULL,
    LocationID         INT           NOT NULL,   -- Stock deducted from this bin
    Quantity           DECIMAL(18,4) NOT NULL CHECK (Quantity > 0),
    UnitSellingPrice   DECIMAL(18,4) NOT NULL CHECK (UnitSellingPrice >= 0),  -- PRICE SNAPSHOT
    UnitCostSnapshot   DECIMAL(18,4)     NULL,   -- BuyingPrice at time of sale — for margin
    DiscountPercent    DECIMAL(5,2)  NOT NULL DEFAULT 0 CHECK (DiscountPercent BETWEEN 0 AND 100),
    LineSubTotal       AS (Quantity * UnitSellingPrice) PERSISTED,
    LineDiscount       AS (Quantity * UnitSellingPrice * DiscountPercent / 100) PERSISTED,
    LineTotal          AS (Quantity * UnitSellingPrice * (1 - DiscountPercent / 100)) PERSISTED,

    CONSTRAINT PK_SalesInvoiceLines            PRIMARY KEY CLUSTERED (LineID),
    CONSTRAINT FK_SalesInvoiceLines_Invoice    FOREIGN KEY (SalesInvoiceID)
        REFERENCES SalesInvoices (SalesInvoiceID) ON DELETE CASCADE,
    CONSTRAINT FK_SalesInvoiceLines_Product    FOREIGN KEY (ProductID)
        REFERENCES Products (ProductID),
    CONSTRAINT FK_SalesInvoiceLines_Location   FOREIGN KEY (LocationID)
        REFERENCES StorageLocations (LocationID)
);
GO

CREATE TABLE SupplierPayments (
    PaymentID           BIGINT        NOT NULL IDENTITY(1,1),
    SupplierID          INT           NOT NULL,
    PurchaseInvoiceID   BIGINT        NOT NULL,
    PaymentDate         DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    AmountPaid          DECIMAL(18,4) NOT NULL CHECK (AmountPaid > 0),
    PaymentMethod       VARCHAR(30)   NOT NULL DEFAULT 'BANK_TRANSFER',
    ReferenceNumber     VARCHAR(100)      NULL,   -- Bank ref / cheque number
    CreatedBy           NVARCHAR(100)     NULL,
    CreatedAt           DATETIME2(0)  NOT NULL DEFAULT SYSUTCDATETIME(),

    CONSTRAINT PK_SupplierPayments                 PRIMARY KEY CLUSTERED (PaymentID),
    CONSTRAINT FK_SupplierPayments_Supplier        FOREIGN KEY (SupplierID)
        REFERENCES Suppliers (SupplierID),
    CONSTRAINT FK_SupplierPayments_PurchaseInvoice FOREIGN KEY (PurchaseInvoiceID)
        REFERENCES PurchaseInvoices (PurchaseInvoiceID),
    CONSTRAINT CK_SupplierPayments_Method          CHECK (PaymentMethod IN
        ('CASH','BANK_TRANSFER','CHEQUE','CARD','OTHER'))
);
GO