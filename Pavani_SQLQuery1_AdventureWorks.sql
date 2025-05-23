USE AdventureWorks2022;
GO
SELECT p.FirstName, p.LastName, d.Name AS Department
FROM HumanResources.EmployeeDepartmentHistory edh
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
JOIN HumanResources.Employee e ON edh.BusinessEntityID = e.BusinessEntityID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE d.Name = 'Sales' AND edh.EndDate IS NULL;

SELECT sp.BusinessEntityID, p.FirstName, p.LastName, SUM(soh.TotalDue) AS TotalSales
FROM Sales.SalesPerson sp
JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
GROUP BY sp.BusinessEntityID, p.FirstName, p.LastName;
SELECT TOP 5 p.Name, SUM(sod.LineTotal) AS TotalRevenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TotalRevenue DESC;


SELECT d.Name AS Department, AVG(eph.Rate) AS AverageSalary
FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.EmployeeDepartmentHistory edh ON eph.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL
GROUP BY d.Name;
SELECT c.CustomerID, p.FirstName, p.LastName, SUM(soh.TotalDue) AS TotalSpent
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
GROUP BY c.CustomerID, p.FirstName, p.LastName
HAVING SUM(soh.TotalDue) > 10000;

SELECT p.Name, pi.Quantity
FROM Production.ProductInventory pi
JOIN Production.Product p ON pi.ProductID = p.ProductID
WHERE pi.Quantity = 0;
SELECT d.Name AS Department, MAX(e.HireDate) AS LatestHireDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL
GROUP BY d.Name;
SELECT c.CustomerID, COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID;
SELECT p.FirstName, p.LastName
FROM Sales.SalesPerson sp
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
WHERE sp.BusinessEntityID NOT IN (
    SELECT DISTINCT SalesPersonID FROM Sales.SalesOrderHeader
    WHERE SalesPersonID IS NOT NULL
);
SELECT p.Name
FROM Production.Product p
WHERE p.ProductID NOT IN (
    SELECT DISTINCT ProductID FROM Sales.SalesOrderDetail
);
WITH EmployeeHierarchy AS (
    SELECT 
        e.BusinessEntityID,
        p.FirstName,
        p.LastName,
        e.OrganizationNode,
        e.JobTitle,
        e.OrganizationLevel
    FROM HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    WHERE e.BusinessEntityID = 16  -- starting manager

    UNION ALL

    SELECT 
        e.BusinessEntityID,
        p.FirstName,
        p.LastName,
        e.OrganizationNode,
        e.JobTitle,
        e.OrganizationLevel
    FROM HumanResources.Employee e
    JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
    JOIN EmployeeHierarchy eh ON e.OrganizationNode.GetAncestor(1) = eh.OrganizationNode
)
SELECT * 
FROM EmployeeHierarchy
WHERE BusinessEntityID <> 16; -- exclude the manager themselves
SELECT JobTitle, COUNT(*) AS EmployeeCount
FROM HumanResources.Employee
GROUP BY JobTitle
ORDER BY EmployeeCount DESC;
SELECT DISTINCT c.CustomerID, p.FirstName, p.LastName, a.City, sp.Name AS StateProvince, cr.Name AS Country
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'United States';
SELECT v.Name AS VendorName, COUNT(pv.ProductID) AS ProductCount
FROM Purchasing.Vendor v
JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
GROUP BY v.Name
ORDER BY ProductCount DESC;
SELECT YEAR(OrderDate) AS SalesYear, SUM(TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;
SELECT c.CustomerID, p.FirstName, p.LastName, COUNT(soh.SalesOrderID) AS OrderCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID, p.FirstName, p.LastName
HAVING COUNT(soh.SalesOrderID) > 5;
SELECT ProductID, Name, StandardCost
FROM Production.Product
WHERE StandardCost > (
    SELECT AVG(StandardCost) FROM Production.Product
)
ORDER BY StandardCost DESC;
SELECT YEAR(HireDate) AS HireYear, COUNT(*) AS NumberOfHires
FROM HumanResources.Employee
GROUP BY YEAR(HireDate)
ORDER BY HireYear;
SELECT TOP 3 sp.Name AS StateProvince, COUNT(DISTINCT c.CustomerID) AS CustomerCount
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
GROUP BY sp.Name
ORDER BY CustomerCount DESC;
SELECT p.FirstName, p.LastName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE e.BusinessEntityID NOT IN (
    SELECT BusinessEntityID
    FROM HumanResources.EmployeePayHistory
    GROUP BY BusinessEntityID
    HAVING COUNT(DISTINCT RateChangeDate) > 1
);
SELECT c.CustomerID, AVG(soh.TotalDue) AS AvgOrderTotal
FROM Sales.Customer c
JOIN Sales.SalesOrderHeader soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID;
SELECT pc.Name AS Category, p.Name AS Product, p.ListPrice
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
WHERE p.ListPrice = (
    SELECT MAX(p2.ListPrice)
    FROM Production.Product p2
    JOIN Production.ProductSubcategory ps2 ON p2.ProductSubcategoryID = ps2.ProductSubcategoryID
    WHERE ps2.ProductCategoryID = pc.ProductCategoryID
);
SELECT d.Name AS Department, p.FirstName, p.LastName, eph.Rate
FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.Employee e ON eph.BusinessEntityID = e.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE edh.EndDate IS NULL
AND eph.Rate = (
    SELECT MAX(eph2.Rate)
    FROM HumanResources.EmployeePayHistory eph2
    JOIN HumanResources.EmployeeDepartmentHistory edh2 ON eph2.BusinessEntityID = edh2.BusinessEntityID
    WHERE edh2.DepartmentID = d.DepartmentID AND edh2.EndDate IS NULL
);
SELECT DISTINCT p.Name, pr.Rating
FROM Production.Product p
JOIN Production.ProductReview pr ON p.ProductID = pr.ProductID
WHERE pr.Rating = 5;
SELECT sp.BusinessEntityID, p.FirstName, p.LastName, sp.SalesQuota, SUM(soh.SubTotal) AS ActualSales
FROM Sales.SalesPerson sp
JOIN Sales.SalesOrderHeader soh ON sp.BusinessEntityID = soh.SalesPersonID
JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
GROUP BY sp.BusinessEntityID, p.FirstName, p.LastName, sp.SalesQuota
HAVING SUM(soh.SubTotal) > sp.SalesQuota;
SELECT TOP 1 d.Name AS Department, COUNT(*) AS EmployeeCount
FROM HumanResources.EmployeeDepartmentHistory edh
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL
GROUP BY d.Name
ORDER BY EmployeeCount DESC;
SELECT Name, SellStartDate
FROM Production.Product
WHERE SellStartDate = (SELECT MIN(SellStartDate) FROM Production.Product);
WITH ManagerInfo AS (
    SELECT e.BusinessEntityID, e.HireDate, e.OrganizationNode
    FROM HumanResources.Employee e
)
SELECT 
    emp.BusinessEntityID, p.FirstName, p.LastName,
    emp.HireDate AS EmployeeHireDate,
    mgr.BusinessEntityID AS ManagerID, mgr.HireDate AS ManagerHireDate
FROM HumanResources.Employee emp
JOIN Person.Person p ON emp.BusinessEntityID = p.BusinessEntityID
JOIN ManagerInfo mgr ON emp.OrganizationNode.GetAncestor(1) = mgr.OrganizationNode
WHERE YEAR(emp.HireDate) = YEAR(mgr.HireDate);
SELECT p.FirstName, p.LastName
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
WHERE c.CustomerID NOT IN (
    SELECT DISTINCT CustomerID FROM Sales.SalesOrderHeader
);
SELECT pc.Name AS Category, COUNT(p.ProductID) AS ProductCount
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name;
SELECT p.Name, SUM(sod.LineTotal) AS Revenue
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY Revenue DESC;

SELECT v.Name, a.City, a.StateProvinceID
FROM Purchasing.Vendor v
JOIN Person.BusinessEntityAddress bea ON v.BusinessEntityID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
JOIN Person.StateProvince sp ON a.StateProvinceID = sp.StateProvinceID
JOIN Person.CountryRegion cr ON sp.CountryRegionCode = cr.CountryRegionCode
WHERE cr.Name = 'United States';
SELECT p.FirstName, p.LastName, e.HireDate
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE DATEDIFF(YEAR, e.HireDate, GETDATE()) > 10;
SELECT TOP 1 p.Name, COUNT(*) AS TimesSold
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
ORDER BY TimesSold DESC;
SELECT YEAR(OrderDate) AS Year, SUM(Freight) AS TotalFreight
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate)
ORDER BY Year;
SELECT p.Name
FROM Production.Product p
WHERE p.ProductID NOT IN (
    SELECT DISTINCT ProductID FROM Production.ProductReview
);
SELECT p.FirstName, p.LastName, e.JobTitle
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE e.JobTitle LIKE '%Engineer%';
SELECT DISTINCT p.FirstName, p.LastName, a.City
FROM Sales.Customer c
JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
JOIN Person.BusinessEntityAddress bea ON p.BusinessEntityID = bea.BusinessEntityID
JOIN Person.Address a ON bea.AddressID = a.AddressID
WHERE a.City = 'Bothell';
SELECT p.Name, SUM(sod.OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY p.Name
HAVING SUM(sod.OrderQty) > (
    SELECT AVG(OrderQty) FROM Sales.SalesOrderDetail
);
SELECT AVG(ProductCount * 1.0) AS AvgProductsPerVendor
FROM (
    SELECT pv.BusinessEntityID, COUNT(*) AS ProductCount
    FROM Purchasing.ProductVendor pv
    GROUP BY pv.BusinessEntityID
) AS VendorProductCounts;


