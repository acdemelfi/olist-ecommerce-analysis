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

## Data Preparation & Methodology

Before beginning the business analysis, I profiled the dataset to understand the grain, relationships, missing values, and potential duplication within each table. Several methodological decisions were made to ensure that category and review metrics were calculated consistently:

- **Review duplication:** Some orders contained multiple review records. For these orders, I retained the most recent review based on `review_answer_timestamp` as the best available representation of the customer's final recorded sentiment.
- **Multi-category orders:** A small number of orders contained products from multiple categories, making it difficult to attribute an order-level review to a single category. These orders were excluded from category-level customer experience analysis.
- **Poor reviews:** Reviews with scores of 1 or 2 stars were classified as poor reviews.
- **Sample size:** Category-level review comparisons were limited to categories with at least 100 recorded reviews to reduce distortion from very small samples.
- **Delivery performance:** Estimated delivery timestamps were recorded at midnight, so delivery performance was evaluated using calendar dates rather than exact timestamps.
- **Metric denominators:** Delivery metrics were calculated across all eligible delivered orders, while review metrics were calculated only across orders with a recorded review.

## Analysis & Key Findings

### 1. Product Category Performance

I compared product categories using both items sold and total sales value to identify categories that performed strongly across both metrics. An equally weighted average of their rankings was used as an exploratory measure of commercial importance.

- **Health & Beauty** ranked first in sales value and second in items sold.
- **Bed, Bath & Table** ranked first in items sold and third in sales value.
- **Watches & Gifts** ranked second in sales value despite ranking seventh in items sold.

These findings demonstrate why sales volume and sales value should be considered together when evaluating product-category performance.

### 2. Customer Reviews by Category

I calculated the percentage of poor reviews (1–2 stars) for each product category, restricting comparisons to categories with at least 100 reviews.

Categories such as Fashion Male Clothing, Office Furniture, and Audio exhibited particularly high poor-review rates. Some commercially important categories, including Bed, Bath & Table and Computers & Accessories, also showed elevated rates of negative feedback.

These findings helped identify categories where customer-experience improvements could be investigated.

### 3. Delivery Delays and Customer Satisfaction

I examined the relationship between delivery performance and customer reviews, comparing on-time deliveries with late deliveries and then investigating how the length of a delay affected review outcomes.

- Approximately **62% of late deliveries** received poor reviews, compared with **9% of on-time deliveries**.
- Poor-review rates increased substantially as delays grew, reaching approximately **82% for deliveries delayed by 15–30 days**.
- The poor-review rate declined to approximately **68% for delays exceeding 30 days**, although this group contained fewer observations.

These results reveal a strong association between delivery delays and negative customer feedback, although they do not establish that lateness caused the poor reviews.

### 4. Connecting Commercial Performance, Delivery, and Reviews

Finally, I combined category-level delivery performance and customer-review metrics to investigate whether differences in delivery delays aligned with differences in customer satisfaction.

Although categories with higher late-delivery rates generally tended to have higher poor-review rates, the relationship was not consistent across all categories.

Some categories exhibited relatively high poor-review rates despite having comparatively modest late-delivery rates. This suggests that delivery performance alone does not explain all differences in customer satisfaction and that additional factors warrant investigation.

## Business Recommendations

Based on these findings, I identified three areas for further investigation and potential operational improvement.

**1. Prioritize customer experience in commercially important categories.**

Categories such as Bed, Bath & Table and Computers & Accessories contribute substantial sales volume and value while exhibiting notable poor-review rates. Investigating customer-experience issues in these categories could help identify improvement opportunities affecting a relatively large number of orders.

**2. Investigate delivery delays and their impact on customer experience.**

The strong association between late deliveries and poor reviews suggests that delivery performance deserves operational attention. Monitoring delivery delays, particularly those exceeding three days, could help identify fulfillment problems and opportunities to improve delivery communication.

**3. Investigate additional causes of negative customer feedback.**

Categories such as Fashion Male Clothing and Office Furniture exhibited high poor-review rates without necessarily having the highest late-delivery rates. Further investigation into product quality, order accuracy, packaging, and other potential sources of dissatisfaction may help explain these differences.

These recommendations identify areas for investigation rather than establishing the underlying causes of negative reviews.

## Limitations

Several limitations should be considered when interpreting the results:

- **Historical data:** The dataset covers 2016–2018. Findings describe historical performance and should not be assumed to represent Olist's current operations.
- **Observational analysis:** Relationships between delivery performance and customer reviews are associations, not evidence of causation.
- **Commercial performance:** Sales value represents the sum of recorded product prices. The dataset does not contain the profit margins or operational costs required to determine profitability.
- **Category attribution:** Orders containing products from multiple categories were excluded from category-level customer-experience analysis because their reviews could not be reliably attributed to one category.
- **Review selection:** For orders with multiple reviews, the most recent review was retained based on its recorded answer timestamp. This does not guarantee that it represents a revised or final customer opinion.
- **Sample size:** Category-level comparisons were restricted to categories with at least 100 reviews. Categories with fewer reviews were excluded from these comparisons.
- **Review availability:** Review metrics include only orders with recorded reviews, while delivery metrics include all eligible delivered single-category orders. These populations are not identical.

## Repository Structure

```text
olist-ecommerce-analysis/
├── README.md
├── .gitignore
├── sql/
│   ├── 1_create_tables.sql
│   ├── 2_data_profiling.sql
│   ├── 3_business_analysis.sql
│   └── 4_create_powerbi_view.sql
├── powerbi/
│   └── olist_ecommerce_analysis.pbix
└── images/
    └── olist_ecommerce_dashboard.png
```

The original dataset is available through Kaggle and is not included in this repository. The SQL scripts document database creation, data profiling, business analysis, and the preparation of the Power BI customer-experience view.