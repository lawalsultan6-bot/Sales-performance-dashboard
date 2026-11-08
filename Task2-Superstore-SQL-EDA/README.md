# Superstore Sales: Exploratory Data Analysis in SQL

Task 2 of my data analytics internship. An SQL-based exploratory data analysis of the Superstore global sales dataset (51,290 order lines, 2011 to 2014, 7 markets).

## What is in this repo
| File | Purpose |
|---|---|
| `superstore_eda.sql` | The full SQL script: questions, data structure, data-quality checks, trends and anomalies, hypothesis tests, clean view |
| `superstore.db` | SQLite database with the `superstore` table and `superstore_clean` view, ready to query |
| `query_results.xlsx` | Output of every query, one sheet per query |
| `findings_report.docx` | Written findings, hypothesis results, data issues, recommendations |

## How to run
1. Open `superstore.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) (free).
2. Go to **Execute SQL**, paste in `superstore_eda.sql`, and run it.

## Approach
1. Asked meaningful questions before analysing.
2. Explored structure, variables and data types.
3. Identified trends, patterns and anomalies.
4. Tested 8 hypotheses with SQL aggregates and statistical tests.
5. Detected data issues to address in later analysis.

## Key findings
- Sales grew from $2.26M (2011) to $4.30M (2014), but margin stayed flat at about 11 to 12%.
- **Discounts drive losses.** Lines with no discount are always profitable; about 90% of lines discounted over 20% lose money (correlation between discount and profit margin: -0.85).
- **Tables** is the only sub-category losing money (-$64K), and the loss is growing each year.
- **EMEA** earns a 5.4% margin, about half the other markets.
- Faster shipping costs up to twice as much as Standard Class.
- The top 20% of customers generate about 51% of sales.

## Data issues found
Constant helper column (`记录数`), redundant `Market2`, 4,873 Customer IDs for only 795 distinct names, 457 Product IDs with more than one name, inconsistent region mapping for some states, whole-number sales values, and a meaningless time part in the date fields.

## Tools
SQL (SQLite). Significance tests (t-test, ANOVA, Mann-Whitney) were run in Python with SciPy on the same data.
