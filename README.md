# Sales Performance Analytics

## 1. Project Objective and Business Problem

### Project Objective
The objective of this project is to analyze sales performance, revenue, profitability, customer purchasing behavior, and product performance using SQL Server, Python (Pandas), and Power BI.

The project transforms raw sales data into meaningful business insights through data extraction, cleaning, transformation, analysis, and interactive dashboard visualization.

### Business Problem
Businesses need to understand which products and categories generate the most revenue and profit, identify loss-making products, track monthly sales trends, and understand customer purchasing patterns.

This project addresses these challenges by analyzing sales transactions and developing an interactive Power BI dashboard to support data-driven business decisions.

## 2. Tools and Technologies

- **SQL Server:** Data extraction, joins, CTEs, temporary tables, window functions, aggregations, and business analysis.
- **Python:** Data processing, calculations, validation, and exploratory data analysis.
- **Pandas:** Data cleaning, merging tables, handling dates, grouping, aggregations, and profitability analysis.
- **NumPy:** Numerical operations and analytical calculations.
- **Power BI:** Interactive dashboard development, KPI cards, charts, slicers, DAX measures, and revenue forecasting.

## 3. Project Workflow

### Step 1: SQL Server Analysis
- Worked with Orders, OrderDetails, Products, Customers, and Returns tables.
- Joined multiple tables to create a consolidated sales dataset.
- Analyzed revenue, gross profit, product performance, and customer behavior.
- Identified loss-making products and customers with declining purchasing activity.
- Used window functions and date calculations to analyze repeat purchases and order gaps.
- Excluded orders that were not completed and sales details associated with returns from the core sales analysis.

### Step 2: Python and Pandas Analysis
- Connected to SQL Server to retrieve data for analysis.
- Inspected data types, missing values, duplicate records, and table relationships.
- Converted date columns to appropriate datetime formats.
- Merged relevant tables to build a consolidated sales dataset.
- Calculated gross sales, discount amount, net revenue, cost, gross profit, and profit margin.
- Performed product-level and category-level analysis to identify performance trends.

### Step 3: Power BI Dashboard
- Developed an interactive sales performance dashboard.
- Created KPI cards to summarize key business metrics.
- Built charts to analyze revenue, profit, and product/category performance.
- Developed a monthly revenue trend visualization.
- Added slicers for interactive data exploration.
- Incorporated revenue forecasting to explore potential future sales trends.

## 4. KPI Definitions

| KPI | Definition |
|---|---|
| Gross Sales | Unit Price × Quantity before discounts |
| Discount Amount | Gross Sales × Discount Rate |
| Net Revenue | Gross Sales − Discount Amount |
| Cost | Unit Cost × Quantity |
| Gross Profit | Net Revenue − Cost |
| Profit Margin (%) | (Gross Profit ÷ Net Revenue) × 100 |
| Total Orders | Count of distinct completed orders included in the analysis |
| Total Quantity Sold | Sum of quantities for included sales transactions |

**Note:** Returned order details and non-completed orders are excluded from the core sales calculations. Discount percentages are treated as decimal rates in the formulas above; if the source stores percentages as whole numbers, divide by 100 before calculating discounts.

## 5. Business Questions Addressed

The analysis explores the following business questions:

1. What is the total net revenue and gross profit?
2. Which products generate the highest revenue and profit?
3. Which product categories contribute most to overall sales?
4. Which products generate negative gross profit?
5. Which customers contribute most to revenue?
6. How does revenue change month over month?
7. Which customers have not purchased recently?
8. How frequently do customers place repeat orders?
9. Which customers show a decline in order value?
10. What does the revenue forecast suggest about potential future sales trends?

## 6. Key Findings and Recommendations

### Key Findings
- Evaluated revenue and profitability across products and categories.
- Compared product-level and category-level sales performance.
- Examined customer purchasing patterns and repeat-order behavior.
- Analyzed monthly revenue trends and incorporated forecasting into the dashboard.
- Identified analytical approaches for investigating loss-making products and declining customer activity.

### Business Recommendations
- Prioritize products and categories that demonstrate strong revenue and profitability.
- Investigate loss-making products and review their pricing, discounting, and costs.
- Use customer purchasing patterns to support retention campaigns and repeat purchases.
- Monitor monthly revenue trends to identify changes in sales performance.
- Use forecasts as planning inputs while considering historical trends, seasonality, and uncertainty.

*Specific numerical findings and recommendations should be added after validating the final SQL outputs and Power BI dashboard.*

## 7. Dashboard Preview

The Power BI dashboard provides an interactive view of sales performance, profitability, product/category comparisons, monthly revenue trends, and forecasting.

![Sales Performance Analytics Dashboard](screenshots/SalesAnalyticsDashboard.png)

### Dashboard Features
- KPI cards for key sales and profitability metrics.
- Revenue and gross profit analysis.
- Product and category performance comparisons.
- Monthly revenue trend analysis.
- Interactive slicers for filtering data.
- Revenue forecasting visualization.

## 8. How to Run the Project

### Prerequisites
- Microsoft SQL Server.
- SQL Server Management Studio (SSMS).
- Python with Pandas and NumPy.
- Jupyter Notebook.
- Microsoft Power BI Desktop.

### Steps
1. Clone or download this repository.
2. Create or restore the `SalesAnalytics` database and load the required source tables.
3. Open `Sales_Analytics.sql` in SSMS and execute the queries against the configured database.
4. Open `Sales_Analytics.ipynb` in Jupyter Notebook and configure the database connection for your local SQL Server instance.
5. Execute the notebook cells in order to reproduce the data preparation and analysis.
6. Open the Power BI `.pbix` file in Power BI Desktop.
7. Configure the appropriate data source connection and refresh the data if the source database is available.

**Important:** The SQL database and connection settings are environment-specific. The project files do not automatically provide access to the original local database. The notebook and dashboard may require connection updates before they can run on another computer.

## 9. Project Structure

```text
Sales-Performance-Analytics/
├── README.md
├── Sales_Analytics.sql
├── Sales_Analytics.ipynb
├── Sales_Performance_Dashboard.pbix
└── screenshots/
    └── SalesAnalyticsDashboard.png
```

## 10. Skills Demonstrated

- SQL querying and business analysis
- Relational data joins and data transformation
- Window functions and customer behavior analysis
- Python and Pandas data manipulation
- Data quality validation
- Revenue and profitability analysis
- Power BI dashboard development
- DAX measures and interactive reporting
- Business insight generation and data storytelling

---

**Author:** Tejus R.

**Project:** Sales Performance Analytics

**Tools:** SQL Server | Python | Pandas | NumPy | Power BI
