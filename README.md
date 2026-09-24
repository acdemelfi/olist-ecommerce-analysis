# Olist E-Commerce Performance & Customer Experience Analysis

![Olist E-Commerce Dashboard](images/olist_ecommerce_dashboard.png)

## Project Overview

The Olist dataset contains real-world e-commerce data covering nearly 100,000 orders, including product categories, customer reviews, order fulfillment, and delivery performance. Using PostgreSQL and Power BI, I analyzed the data to identify patterns in commercial performance and customer experience and determine where potential business issues were concentrated. The analysis focuses on product-category performance, poor customer reviews, and the relationship between delivery delays and customer satisfaction, with the goal of turning these findings into actionable business insights.

## Business Questions

This project was guided by four main analytical questions:

1. Which product categories are most commercially important when considering both sales volume and sales value?
2. Which product categories have the highest rates of poor customer reviews?
3. How is delivery performance associated with customer satisfaction, and does the severity of a delivery delay matter?
4. Do differences in delivery performance help explain differences in customer satisfaction across product categories?

## Dataset & Tools

### Dataset

The analysis uses the Brazilian E-Commerce Public Dataset by Olist, an anonymized commercial dataset containing approximately 100,000 orders placed between 2016 and 2018. The dataset is relational and includes information on orders, order items, products, payments, customer reviews, sellers, customers, and delivery timestamps.

For this analysis, the primary tables used were:
- Orders
- Order Items
- Products
- Product Category Translation
- Order Reviews

The original dataset is available on Kaggle: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

### Tools

- **PostgreSQL** — data storage, profiling, cleaning, and SQL analysis
- **Power BI** — data modeling, DAX measures, visualization, and dashboard development
- **VS Code / Git / GitHub** — project organization, version control, and documentation
