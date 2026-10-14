USE SalesAnalytics;
GO

/*
===============================================================================
PROJECT: SALES ANALYTICS CASE STUDY
PLATFORM: Microsoft SQL Server / T-SQL

BUSINESS RULES
1. Include Orders with OrderStatus = 'Completed'.
2. Exclude returned order details (not necessarily the entire order).
3. GrossSales = UnitPrice * Quantity.
4. DiscountAmount = GrossSales * DiscountPercent / 100.
5. NetRevenue = GrossSales - DiscountAmount.
6. Cost = UnitCost * Quantity.
7. GrossProfit = NetRevenue - Cost.

===============================================================================
*/

-- Shared detail-level sales dataset: one row per eligible, non-returned line.
SELECT
    o.OrderID,
    o.OrderDate,
    o.CustomerID,
    c.CustomerName,
    od.OrderDetailID,
    od.ProductID,
    p.ProductName,
    od.Quantity,
    CAST(p.UnitPrice AS DECIMAL(18,2)) AS UnitPrice,
    CAST(p.UnitCost AS DECIMAL(18,2)) AS UnitCost,
    CAST(od.DiscountPercent AS DECIMAL(9,4)) AS DiscountPercent,
    CAST(od.Quantity * p.UnitPrice AS DECIMAL(18,2)) AS GrossSales,
    CAST((od.Quantity * p.UnitPrice) * od.DiscountPercent / 100.0 AS DECIMAL(18,2)) AS DiscountAmount,
    CAST((od.Quantity * p.UnitPrice) -
         ((od.Quantity * p.UnitPrice) * od.DiscountPercent / 100.0) AS DECIMAL(18,2)) AS NetRevenue,
    CAST(od.Quantity * p.UnitCost AS DECIMAL(18,2)) AS Cost,
    CAST(((od.Quantity * p.UnitPrice) -
         ((od.Quantity * p.UnitPrice) * od.DiscountPercent / 100.0)) -
         (od.Quantity * p.UnitCost) AS DECIMAL(18,2)) AS GrossProfit
INTO #SalesLines
FROM Orders AS o
JOIN OrderDetails AS od ON od.OrderID = o.OrderID
JOIN Products AS p ON p.ProductID = od.ProductID
JOIN Customers AS c ON c.CustomerID = o.CustomerID
LEFT JOIN [Returns] AS r ON r.OrderDetailID = od.OrderDetailID
WHERE o.OrderStatus = 'Completed'
  AND r.ReturnID IS NULL;

-- Shared order-level dataset: one row per customer/order.
SELECT
    CustomerID,
    CustomerName,
    OrderID,
    OrderDate,
    SUM(Quantity) AS TotalQuantity,
    SUM(NetRevenue) AS OrderValue,
    SUM(Cost) AS OrderCost,
    SUM(GrossProfit) AS OrderGrossProfit
INTO #CustomerOrders
FROM #SalesLines
GROUP BY CustomerID, CustomerName, OrderID, OrderDate;
GO

/*=============================================================================
Q1. What are the company's total net revenue, cost, and gross profit?
=============================================================================*/
SELECT
    SUM(NetRevenue) AS TotalNetRevenue,
    SUM(Cost) AS TotalCost,
    SUM(GrossProfit) AS GrossProfit,
    CAST(100.0 * SUM(GrossProfit) / NULLIF(SUM(NetRevenue), 0) AS DECIMAL(10,2)) AS GrossProfitMarginPct
FROM #SalesLines;
GO

/*=============================================================================
Q2. Which products generate the highest revenue?
=============================================================================*/
SELECT
    ProductID,
    ProductName,
    SUM(Quantity) AS TotalQuantity,
    SUM(NetRevenue) AS NetRevenue,
    SUM(Cost) AS TotalCost,
    SUM(GrossProfit) AS GrossProfit,
    CAST(100.0 * SUM(GrossProfit) / NULLIF(SUM(NetRevenue), 0) AS DECIMAL(10,2)) AS GrossProfitMarginPct
FROM #SalesLines
GROUP BY ProductID, ProductName
ORDER BY NetRevenue DESC;
GO

/*=============================================================================
Q3. Which customers generate the most revenue, and how many orders did they place?
=============================================================================*/
SELECT
    CustomerID,
    CustomerName,
    COUNT(DISTINCT OrderID) AS TotalOrders,
    SUM(NetRevenue) AS NetRevenue,
    SUM(Cost) AS TotalCost,
    SUM(GrossProfit) AS GrossProfit
FROM #SalesLines
GROUP BY CustomerID, CustomerName
ORDER BY NetRevenue DESC;
GO

/*=============================================================================
Q4. What is the average number of days between each customer's purchases?
=============================================================================*/
;WITH OrderGaps AS
(
    SELECT
        CustomerID,
        CustomerName,
        OrderID,
        OrderDate,
        LAG(OrderDate) OVER
            (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS PreviousOrderDate
    FROM #CustomerOrders
)
SELECT
    CustomerID,
    CustomerName,
    COUNT(*) AS RepeatPurchaseCount,
    CAST(AVG(CAST(DATEDIFF(DAY, PreviousOrderDate, OrderDate) AS DECIMAL(10,2))) AS DECIMAL(10,2))
        AS AverageDaysBetweenOrders
FROM OrderGaps
WHERE PreviousOrderDate IS NOT NULL
GROUP BY CustomerID, CustomerName
ORDER BY AverageDaysBetweenOrders;
GO

/*=============================================================================
Q5. Which customers may be inactive for more than 90 days?
Reference date = latest completed, eligible order date in the analysis dataset.
=============================================================================*/
DECLARE @ReferenceDate DATE = (SELECT MAX(OrderDate) FROM #CustomerOrders);

;WITH RankedCustomerOrders AS
(
    SELECT
        CustomerID,
        CustomerName,
        OrderDate,
        ROW_NUMBER() OVER
            (PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS rn
    FROM #CustomerOrders
)
SELECT
    CustomerID,
    CustomerName,
    OrderDate AS LastOrderDate,
    DATEDIFF(DAY, OrderDate, @ReferenceDate) AS DaysSinceLastOrder
FROM RankedCustomerOrders
WHERE rn = 1
  AND DATEDIFF(DAY, OrderDate, @ReferenceDate) > 90
ORDER BY DaysSinceLastOrder DESC;
GO

/*=============================================================================
Q6. Which products have negative gross profit?
=============================================================================*/
SELECT
    ProductID,
    ProductName,
    SUM(Quantity) AS TotalQuantity,
    SUM(NetRevenue) AS TotalRevenue,
    SUM(Cost) AS TotalCost,
    SUM(GrossProfit) AS GrossProfit
FROM #SalesLines
GROUP BY ProductID, ProductName
HAVING SUM(GrossProfit) < 0
ORDER BY GrossProfit;
GO

/*=============================================================================
Q7. How does each customer's latest order value compare with their first order?
=============================================================================*/
;WITH RankedOrders AS
(
    SELECT
        CustomerID,
        CustomerName,
        OrderID,
        OrderDate,
        OrderValue,
        ROW_NUMBER() OVER
            (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS FirstRank,
        ROW_NUMBER() OVER
            (PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS LatestRank
    FROM #CustomerOrders
),
FirstOrders AS
(
    SELECT CustomerID, CustomerName, OrderDate AS FirstOrderDate,
           OrderValue AS FirstOrderValue
    FROM RankedOrders
    WHERE FirstRank = 1
),
LatestOrders AS
(
    SELECT CustomerID, OrderDate AS LatestOrderDate,
           OrderValue AS LatestOrderValue
    FROM RankedOrders
    WHERE LatestRank = 1
)
SELECT
    f.CustomerID,
    f.CustomerName,
    f.FirstOrderDate,
    l.LatestOrderDate,
    f.FirstOrderValue,
    l.LatestOrderValue,
    l.LatestOrderValue - f.FirstOrderValue AS ValueChange,
    CAST(100.0 * (l.LatestOrderValue - f.FirstOrderValue) /
         NULLIF(f.FirstOrderValue, 0) AS DECIMAL(10,2)) AS PercentageChange
FROM FirstOrders AS f
JOIN LatestOrders AS l ON l.CustomerID = f.CustomerID
WHERE f.FirstOrderDate <> l.LatestOrderDate OR f.FirstOrderValue <> l.LatestOrderValue
ORDER BY PercentageChange;
GO

/*=============================================================================
Q8. Which customers spent less on their latest order than on their previous order?
=============================================================================*/
;WITH OrderComparisons AS
(
    SELECT
        CustomerID,
        CustomerName,
        OrderID,
        OrderDate,
        OrderValue AS LatestOrderValue,
        LAG(OrderValue) OVER
            (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS PreviousOrderValue,
        ROW_NUMBER() OVER
            (PARTITION BY CustomerID ORDER BY OrderDate DESC, OrderID DESC) AS LatestRank
    FROM #CustomerOrders
)
SELECT
    CustomerID,
    CustomerName,
    PreviousOrderValue,
    LatestOrderValue,
    PreviousOrderValue - LatestOrderValue AS DecreaseAmount,
    CAST(100.0 * (PreviousOrderValue - LatestOrderValue) /
         NULLIF(PreviousOrderValue, 0) AS DECIMAL(10,2)) AS DecreasePercentage
FROM OrderComparisons
WHERE LatestRank = 1
  AND PreviousOrderValue > LatestOrderValue
ORDER BY DecreaseAmount DESC;
GO

/*=============================================================================
Q9. How many days passed between each repeat customer's consecutive purchases?
=============================================================================*/
SELECT
    CustomerID,
    CustomerName,
    OrderID,
    OrderDate,
    PreviousOrderDate,
    DATEDIFF(DAY, PreviousOrderDate, OrderDate) AS DaysSincePreviousOrder
FROM
(
    SELECT
        CustomerID,
        CustomerName,
        OrderID,
        OrderDate,
        LAG(OrderDate) OVER
            (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS PreviousOrderDate
    FROM #CustomerOrders
) AS PurchaseHistory
WHERE PreviousOrderDate IS NOT NULL
ORDER BY CustomerID, OrderDate, OrderID;
GO

/*=============================================================================
Q10. How quickly do customers make a second purchase, and how does its value
     compare with the first purchase?
=============================================================================*/
;WITH RankedOrders AS
(
    SELECT
        CustomerID,
        CustomerName,
        OrderID,
        OrderDate,
        OrderValue,
        ROW_NUMBER() OVER
            (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS PurchaseNumber
    FROM #CustomerOrders
),
FirstAndSecond AS
(
    SELECT
        CustomerID,
        CustomerName,
        MAX(CASE WHEN PurchaseNumber = 1 THEN OrderDate END) AS FirstOrderDate,
        MAX(CASE WHEN PurchaseNumber = 2 THEN OrderDate END) AS SecondOrderDate,
        MAX(CASE WHEN PurchaseNumber = 1 THEN OrderValue END) AS FirstOrderValue,
        MAX(CASE WHEN PurchaseNumber = 2 THEN OrderValue END) AS SecondOrderValue
    FROM RankedOrders
    WHERE PurchaseNumber IN (1, 2)
    GROUP BY CustomerID, CustomerName
)
SELECT
    CustomerID,
    CustomerName,
    FirstOrderDate,
    SecondOrderDate,
    DATEDIFF(DAY, FirstOrderDate, SecondOrderDate) AS DaysToSecondPurchase,
    FirstOrderValue,
    SecondOrderValue,
    CAST(100.0 * (SecondOrderValue - FirstOrderValue) /
         NULLIF(FirstOrderValue, 0) AS DECIMAL(10,2)) AS ChangePercentage
FROM FirstAndSecond
WHERE SecondOrderDate IS NOT NULL
ORDER BY DaysToSecondPurchase;
GO

/*=============================================================================
Q11. Which customers' order values have decreased over consecutive purchases?
This complements Q8 by returning every consecutive decrease, not only the latest.
=============================================================================*/
;WITH OrderComparisons AS
(
    SELECT
        CustomerID,
        CustomerName,
        OrderID,
        OrderDate,
        OrderValue,
        LAG(OrderValue) OVER
            (PARTITION BY CustomerID ORDER BY OrderDate, OrderID) AS PreviousOrderValue
    FROM #CustomerOrders
)
SELECT
    CustomerID,
    CustomerName,
    OrderID,
    OrderDate,
    PreviousOrderValue,
    OrderValue AS CurrentOrderValue,
    PreviousOrderValue - OrderValue AS DecreaseAmount,
    CAST(100.0 * (PreviousOrderValue - OrderValue) /
         NULLIF(PreviousOrderValue, 0) AS DECIMAL(10,2)) AS DecreasePercentage
FROM OrderComparisons
WHERE PreviousOrderValue > OrderValue
ORDER BY CustomerID, OrderDate, OrderID;
GO

/*=============================================================================
Q12. Are customers' later orders generating less revenue than their earlier orders?
Split order history into two halves. For odd counts, the earlier half receives
the extra order; customers must have at least four orders.
=============================================================================*/
;WITH EligibleCustomers AS
(
    SELECT CustomerID, COUNT(*) AS OrderCount
    FROM #CustomerOrders
    GROUP BY CustomerID
    HAVING COUNT(*) >= 4
),
RankedOrders AS
(
    SELECT
        co.CustomerID,
        co.CustomerName,
        co.OrderID,
        co.OrderDate,
        co.OrderValue,
        ec.OrderCount,
        (ec.OrderCount + 1) / 2 AS FirstHalfCount,
        ROW_NUMBER() OVER
            (PARTITION BY co.CustomerID ORDER BY co.OrderDate, co.OrderID) AS PurchaseNumber
    FROM #CustomerOrders AS co
    JOIN EligibleCustomers AS ec ON ec.CustomerID = co.CustomerID
),
HalfTotals AS
(
    SELECT
        CustomerID,
        CustomerName,
        SUM(CASE WHEN PurchaseNumber <= FirstHalfCount THEN OrderValue ELSE 0 END) AS FirstHalfRevenue,
        SUM(CASE WHEN PurchaseNumber > FirstHalfCount THEN OrderValue ELSE 0 END) AS SecondHalfRevenue
    FROM RankedOrders
    GROUP BY CustomerID, CustomerName
)
SELECT
    CustomerID,
    CustomerName,
    FirstHalfRevenue,
    SecondHalfRevenue,
    SecondHalfRevenue - FirstHalfRevenue AS RevenueChange,
    CAST(100.0 * (SecondHalfRevenue - FirstHalfRevenue) /
         NULLIF(FirstHalfRevenue, 0) AS DECIMAL(10,2)) AS RevenueChangePercentage
FROM HalfTotals
WHERE SecondHalfRevenue < FirstHalfRevenue
ORDER BY RevenueChange;
GO

