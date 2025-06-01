--HackerRank Profile https://www.hackerrank.com/profile/pavaniideep14



USE AdventureWorks2022;
GO
--STORED PROCEDURES
--2.1 InsertOrderDetails function
GO
CREATE OR ALTER PROCEDURE dbo.InsertOrderDetails
    @SalesOrderID      INT,
    @ProductID         INT,
    @UnitPrice         MONEY = NULL,
    @OrderQty          SMALLINT,
    @UnitPriceDiscount MONEY = 0
AS
BEGIN
    SET NOCOUNT ON;

    IF @UnitPrice IS NULL
    BEGIN
        SELECT @UnitPrice = ListPrice
        FROM Production.Product
        WHERE ProductID = @ProductID;
    END

    INSERT INTO Sales.SalesOrderDetail
        (SalesOrderID, ProductID, OrderQty, UnitPrice, UnitPriceDiscount, SpecialOfferID)
    VALUES
        (@SalesOrderID, @ProductID, @OrderQty, @UnitPrice, @UnitPriceDiscount, 1);

    IF @@ROWCOUNT = 0
        PRINT 'Failed to place the order. Please try again.';
    ELSE
        PRINT 'Order placed successfully.';
END
GO




--2.2 UpdateOrderDetails function
GO
CREATE OR ALTER PROCEDURE dbo.UpdateOrderDetails
    @SalesOrderDetailID INT,
    @UnitPrice          MONEY = NULL,
    @OrderQty           SMALLINT = NULL,
    @UnitPriceDiscount  MONEY = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Sales.SalesOrderDetail
    SET
        UnitPrice = ISNULL(@UnitPrice, UnitPrice),
        OrderQty = ISNULL(@OrderQty, OrderQty),
        UnitPriceDiscount = ISNULL(@UnitPriceDiscount, UnitPriceDiscount)
    WHERE SalesOrderDetailID = @SalesOrderDetailID;

    IF @@ROWCOUNT = 0
        PRINT 'No such order found to update.';
    ELSE
        PRINT 'Order updated successfully.';
END
GO





--2.3 GetOrderDetails function
GO
CREATE OR ALTER PROCEDURE dbo.GetOrderDetails
    @SalesOrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 FROM Sales.SalesOrderDetail
        WHERE SalesOrderID = @SalesOrderID
    )
    BEGIN
        PRINT 'The OrderID ' + CAST(@SalesOrderID AS VARCHAR) + ' does not exist';
        RETURN;
    END

    SELECT *
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @SalesOrderID;
END
GO





--2.4 DeleteOrderDetails function
GO
CREATE OR ALTER PROCEDURE dbo.DeleteOrderDetails
    @SalesOrderDetailID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderDetail
        WHERE SalesOrderDetailID = @SalesOrderDetailID
    )
    BEGIN
        PRINT 'Invalid parameters – record not found.';
        RETURN;
    END

    DELETE FROM Sales.SalesOrderDetail
    WHERE SalesOrderDetailID = @SalesOrderDetailID;

    PRINT 'Order deleted successfully.';
END
GO


--FUNCTIONS
--function1 fn_DateOnlyISO
GO
CREATE OR ALTER FUNCTION dbo.fn_DateOnlyISO (@In DATETIME)
RETURNS CHAR(10)
AS
BEGIN
    RETURN RIGHT('0' + CAST(DAY(@In) AS VARCHAR), 2) + '-' +
           RIGHT('0' + CAST(MONTH(@In) AS VARCHAR), 2) + '-' +
           CAST(YEAR(@In) AS VARCHAR)
END
GO
--example usage
SELECT dbo.fn_DateOnlyISO(GETDATE()) AS FormattedDate;





--function2 fn_TimeOnly24Hr
GO
CREATE OR ALTER FUNCTION dbo.fn_TimeOnly24Hr (@In DATETIME)
RETURNS CHAR(8)
AS
BEGIN
    RETURN CONVERT(CHAR(8), @In, 108);  -- Format 108 = hh:mm:ss (24hr)
END
GO
--example usage
SELECT dbo.fn_TimeOnly24Hr(GETDATE()) AS CurrentTime;






--VIEW
--view vwCustomerOrders
GO
CREATE OR ALTER VIEW dbo.vwCustomerOrders
AS
SELECT
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue AS TotalAmount
FROM
    Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID;
GO
--testing the view
SELECT TOP 10 * FROM dbo.vwCustomerOrders;





--copy of vwCustomerOrders
GO
CREATE OR ALTER VIEW dbo.vwHighValueCustomerOrders
AS
SELECT
    c.CustomerID,
    p.FirstName + ' ' + p.LastName AS CustomerName,
    soh.SalesOrderID,
    soh.OrderDate,
    soh.TotalDue AS TotalAmount
FROM
    Sales.SalesOrderHeader AS soh
JOIN Sales.Customer AS c
    ON soh.CustomerID = c.CustomerID
JOIN Person.Person AS p
    ON c.PersonID = p.BusinessEntityID
WHERE
    soh.TotalDue > 10000;
GO
--testing the view
SELECT TOP 10 * FROM dbo.vwHighValueCustomerOrders;





--Myproducts view
GO
CREATE OR ALTER VIEW dbo.MyProducts
AS
SELECT
    p.ProductID,
    p.Name AS ProductName,
    p.ProductNumber AS QuantityPerUnit,
    p.ListPrice AS UnitPrice,
    NULL AS CompanyName,  -- ProductVendor table not present
    pc.Name AS CategoryName
FROM
    Production.Product AS p
LEFT JOIN Production.ProductSubcategory AS psc
    ON p.ProductSubcategoryID = psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory AS pc
    ON psc.ProductCategoryID = pc.ProductCategoryID;
GO
--to view this
SELECT TOP 10 * FROM dbo.MyProducts;






--TRIGGERS
-- trigger1 trg_DeleteSalesOrder 
IF OBJECT_ID('Sales.trg_DeleteSalesOrder', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_DeleteSalesOrder;
GO
CREATE TRIGGER Sales.trg_DeleteSalesOrder
ON Sales.SalesOrderHeader
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DELETE d
    FROM Sales.SalesOrderDetail d
    JOIN deleted del ON del.SalesOrderID = d.SalesOrderID;

    DELETE FROM Sales.SalesOrderHeader
    WHERE SalesOrderID IN (SELECT SalesOrderID FROM deleted);
END
GO





--trigger2 trg_CheckStockBeforeInsert
CREATE TRIGGER Sales.trg_CheckStockBeforeInsert
ON Sales.SalesOrderDetail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT, @OrderQty INT, @TotalStock INT;

    SELECT 
        @ProductID = i.ProductID,
        @OrderQty = i.OrderQty
    FROM inserted i;

    SELECT @TotalStock = SUM(Quantity)
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID;

    IF @TotalStock IS NULL SET @TotalStock = 0;

    -- Debug messages to help you trace what’s wrong
    PRINT 'DEBUG: ProductID = ' + CAST(@ProductID AS VARCHAR);
    PRINT 'DEBUG: OrderQty = ' + CAST(@OrderQty AS VARCHAR);
    PRINT 'DEBUG: TotalStock = ' + CAST(@TotalStock AS VARCHAR);

    IF @OrderQty > @TotalStock
    BEGIN
        RAISERROR('Insufficient stock. Order rejected.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO





--SAMPLE DATA

IF OBJECT_ID('Sales.trg_CheckStockBeforeInsert', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_CheckStockBeforeInsert;
GO
CREATE TRIGGER Sales.trg_CheckStockBeforeInsert
ON Sales.SalesOrderDetail
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT, @OrderQty INT, @TotalStock INT;

    SELECT 
        @ProductID = i.ProductID,
        @OrderQty = i.OrderQty
    FROM inserted i;

    SELECT @TotalStock = SUM(Quantity)
    FROM Production.ProductInventory
    WHERE ProductID = @ProductID;

    IF @TotalStock IS NULL SET @TotalStock = 0;

    PRINT 'DEBUG: ProductID = ' + CAST(@ProductID AS VARCHAR);
    PRINT 'DEBUG: OrderQty = ' + CAST(@OrderQty AS VARCHAR);
    PRINT 'DEBUG: TotalStock = ' + CAST(@TotalStock AS VARCHAR);

    IF @OrderQty > @TotalStock
    BEGIN
        RAISERROR('Insufficient stock. Order rejected.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
INSERT INTO Sales.SpecialOfferProduct
    (SpecialOfferID, ProductID, rowguid, ModifiedDate)
VALUES
    (1, 1, NEWID(), GETDATE());
EXEC dbo.InsertOrderDetails
    @SalesOrderID = 75123,
    @ProductID = 1,
    @OrderQty = 5;




-- View 1
SELECT * FROM vwCustomerOrders;
-- View 2
SELECT * FROM vwHighValueCustomerOrders;
-- View 3
SELECT * FROM MyProducts;

--final test
-- Insert test
EXEC dbo.InsertOrderDetails @SalesOrderID = 75123, @ProductID = 1, @OrderQty = 5;


-- Function test
SELECT dbo.fn_DateOnlyISO(GETDATE()), dbo.fn_TimeOnly24Hr(GETDATE());

-- View test
SELECT * FROM vwCustomerOrders;


SELECT TOP 5 SalesOrderDetailID, SalesOrderID, ProductID
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = 75123;

EXEC dbo.UpdateOrderDetails
    @SalesOrderDetailID = 121321,  -- Replace with a valid ID from the query
    @UnitPrice = 180.00;           -- Or any field you want to update




-- Confirm update works
EXEC dbo.UpdateOrderDetails
    @SalesOrderDetailID = 121321,  
    @OrderQty = 10,
    @UnitPrice = 150.00;

-- Confirm get works
EXEC dbo.GetOrderDetails
    @SalesOrderID = 75123;

-- Confirm delete works
EXEC dbo.DeleteOrderDetails
    @SalesOrderDetailID = 121321;

-- Re-insert to restore data for testing
EXEC dbo.InsertOrderDetails
    @SalesOrderID = 75123,
    @ProductID = 1,
    @OrderQty = 5;

