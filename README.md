# Mint Classics Company: Warehouse Consolidation & Inventory Analysis

**Project by:** Pham Thu Trang
**Tools used:** MySQL Workbench, SQL (CTEs, joins, aggregation)
**Database:** `mintclassics` (9-table relational database, imported via `mintclassicsDB.sql`)

## Project Scenario

Mint Classics, a retailer of classic model cars and other vehicles, wants to close one storage warehouse. This project uses SQL exploration to recommend how inventory could be reorganized or reduced, while still being able to ship orders within 24 hours, backed by data.

## Summary

Mint Classics Company wants to close one of its four storage warehouses while continuing to ship customer orders within 24 hours. Using SQL exploration of the mintclassics database — covering warehouse capacity, product-line distribution, sales velocity, and current fulfillment speed — this analysis identifies **Warehouse C ("West")** as the strongest candidate for closure.

West is the only warehouse operating at just 50% capacity, is dedicated to a single product line (Vintage Cars), and carries a higher stock-to-sales ratio than the leanest-run facility in the network. The remaining three warehouses (East, North, South) have enough combined spare capacity (~185,600 units) to absorb West's entire inventory (~124,900 units) without approaching full capacity.

An alternative scenario — closing South instead, since its three smaller product lines could each be distributed individually — was tested and ruled out: South is actually the best-performing warehouse in the network (75% capacity, lowest stock-to-sales ratio), so closing it would remove the facility that's working, while leaving the genuinely underused one (West) still open.

Separately, the analysis found that inventory-wide "dead stock" is not a widespread problem — only one product across the entire catalog (1985 Toyota Supra, 7,733 units) has zero recorded sales. Most high stock-to-sales-ratio products are still selling steadily (25-28 distinct orders each); they are candidates for reduced reorder/safety-stock levels, not discontinuation.

**Recommendation:** Close Warehouse C (West). Relocate its Vintage Cars inventory primarily into East, right-size safety stock on the highest-ratio Classic Cars products in East, and discontinue the single confirmed non-mover. Because current average shipping time is already 3.76 days (not yet at the 24-hour target), warehouse consolidation should be paired with separate fulfillment-process improvements, not treated as a full solution to the shipping-speed goal on its own.

## Solution

### 1. Warehouse Profile

| Warehouse | Capacity Used | Product Lines Hosted | # Products | Total Stock | Stock-to-Sales Ratio |
|---|---|---|---|---|---|
| East (b) | 67% | 1 — Classic Cars | 38 | 219,183 | 6.16 |
| North (a) | 72% | 2 — Motorcycles, Planes | 25 | 131,688 | 5.34 |
| South (d) | 75% | 3 — Ships, Trains, Trucks and Buses | 23 | 79,380 | 3.55 (leanest) |
| West (c) | 50% (lowest) | 1 — Vintage Cars | 24 | 124,880 | 5.45 |

West stands out as the only warehouse combining low capacity utilization with a single dedicated product line — a pattern the data doesn't repeat anywhere else in the network. South and North both already run multiple product lines, more efficiently, in smaller buildings — proof that consolidating product lines into fewer warehouses is already normal practice at Mint Classics, not a new operating model this recommendation would require inventing.

### 2. Feasibility: Does the Network Have Room to Absorb West?

| Warehouse (remaining) | Current Stock | Est. Total Capacity | Est. Spare Capacity |
|---|---|---|---|
| East | 219,183 | 327,139 | 107,956 |
| North | 131,688 | 182,900 | 51,212 |
| South | 79,380 | 105,840 | 26,460 |
| **Total spare capacity** | | | **185,628** |

West's inventory to relocate: 124,880 units. Spare capacity across the remaining three warehouses (185,628) comfortably exceeds this, leaving roughly 60,700 units of buffer. East — with the most spare room and the highest existing sales volume — is the recommended primary destination for the Vintage Cars line, with North or South available as overflow if warehouse layout requires splitting the line.

### 3. Alternative Scenario Tested: Closing South Instead

Because South hosts three smaller product lines rather than one large one, an alternative hypothesis was tested: distributing each of South's lines individually (rather than moving one large line as with West) might reduce migration risk.

| South's Product Line | Stock to Relocate | Best-Fit Destination (spare capacity) |
|---|---|---|
| Trucks and Buses | 35,851 | West (124,880 spare) |
| Ships | 26,833 | East (107,956 spare) |
| Trains | 16,696 | North (51,212 spare) |

Each line does have a comfortable landing spot, confirming this scenario is physically feasible. However, it was ruled out because:

- South is the best-performing warehouse in the network — highest capacity utilization (75%) and the lowest stock-to-sales ratio (3.55) of all four. Closing it removes the facility that is working best, not the one that is underperforming.
- West would remain open under this scenario, still sitting at its current 50% capacity with a weaker stock-to-sales ratio than South — the core inefficiency the business is trying to solve would be left unaddressed.
- Migration complexity is genuinely lower for South's scenario (three smaller moves vs. one larger one), and this insight is retained in the recommendation below as a migration sequencing principle, even though South itself is not recommended for closure.

### 4. Inventory Reduction (Beyond Warehouse Closure)

Company-wide, the products with the highest stock-to-sales ratios (9-10x) are concentrated in Classic Cars (East), Motorcycles (North), and Vintage Cars (West) — but every one of these products still has 25-28 distinct orders on record. They are actively selling, just overstocked relative to that demand. These are candidates for reduced reorder quantities and safety stock, not discontinuation.

Only one product in the entire catalog has zero recorded sales: the **1985 Toyota Supra** (S18_3233, Classic Cars, East warehouse, 7,733 units in stock). This is the one clear, low-risk candidate for dropping from the product line entirely.

### 5. Current Shipping Performance (24-Hour Constraint Check)

| Order Status | # Orders | Avg Days to Ship | Min | Max |
|---|---|---|---|---|
| Shipped | 303 | 3.76 | 1 | 65 |
| Resolved | 4 | 3.50 | 2 | 5 |
| Cancelled | 6 | 1.50 | 1 | 2 |
| Disputed | 3 | 5.00 | 3 | 6 |

Mint Classics is not currently shipping within 24 hours on average (3.76 days), and some orders take as long as 65 days. This is an important caveat: the 24-hour target is a goal to design toward, not a baseline this recommendation is protecting. Warehouse consolidation reduces complexity and centralizes inventory, but reaching a 24-hour standard will likely also require separate improvements to order processing and carrier logistics that are outside the scope of this inventory-focused analysis.

## Final Recommendation

1. **Close Warehouse C (West).**
2. Relocate West's Vintage Cars inventory to East first (largest spare capacity, highest sales activity), with North/South as overflow only if needed.
3. Sequence the migration line-by-line: confirm each destination warehouse has sufficient actual spare shelf space before the physical move, and only close West once all inventory is confirmed relocated and receiving/picking is verified operational at the new location.
4. Discontinue the 1985 Toyota Supra (zero sales, 7,733 units) as an independent inventory reduction, unrelated to the warehouse closure.
5. Right-size (don't drop) the ~20 highest stock-to-sales-ratio products across Classic Cars, Motorcycles, and Vintage Cars — reduce reorder quantities rather than removing them from the line, since all are still actively selling.
6. Treat the 24-hour shipping goal as a separate initiative from warehouse closure — current fulfillment (3.76 days average) suggests process, not just inventory placement, needs attention to hit that target.

## Approach

### Methodology

The analysis proceeded in stages, each building on confirmed findings from the last, rather than jumping straight to a warehouse recommendation:

1. **Warehouse-level overview** — capacity utilization and product/stock counts per warehouse, to identify any warehouse that looked structurally different from the others.
2. **Sales velocity vs. stock** — joined in actual `orderdetails` data to compute a stock-to-sales ratio, since a warehouse could look "empty" either because it's underused or because it's lean and efficient.
3. **Product-line concentration** — checked whether product lines were mixed across warehouses or dedicated to one each, since this determines whether closing a warehouse means relocating an entire category or just redistributing overlapping stock.
4. **Capacity feasibility** — estimated total capacity and spare room in the remaining warehouses to confirm the move is physically possible, not just directionally sensible.
5. **Alternative scenario testing** — a second, independently plausible candidate (South) was tested on the same criteria rather than assumed away, to stress-test the primary recommendation.
6. **Company-wide reduction candidates** — ranked all products by stock-to-sales ratio and checked for zero-sales items, to distinguish "reduce stock levels" from "discontinue" candidates.
7. **Service-level check** — pulled actual current shipping times to confirm the 24-hour constraint's real starting point, rather than assuming it was already being met.

### Key Technical Decisions

- **CTEs (`WITH` clauses)** were used throughout instead of nested subqueries, to keep multi-step aggregations readable and self-documenting.
- **Careful handling of join grain:** an early version of the sales-velocity query joined `products` directly to `orderdetails` and summed `quantityInStock` in the same query, which silently inflated stock totals by the number of order lines per product (a classic "fan-out" error from a one-to-many join). This was caught by cross-checking totals against an earlier, simpler query, and corrected by aggregating stock and sales in separate CTEs at their correct grain before combining them.
- **Type casting:** `warehousePctCap` is stored as `VARCHAR` in the schema. Rather than altering the underlying table, the field was cast inline with `CAST(... AS UNSIGNED)` only where needed for calculation or sorting.
- **COALESCE/NULLIF** were used when computing per-product ratios so that products with no sales history show 0 sales and a `NULL` ratio, instead of causing divide-by-zero errors or being silently dropped from results.

### Assumptions & Limitations

- **Capacity is estimated, not directly given.** Total capacity was inferred as `current stock ÷ (pct_cap / 100)`, assuming `quantityInStock` and `warehousePctCap` are measured in comparable units across product lines — which the database does not explicitly document.
- **Sales history reflects the past, not future demand.** Stock-to-sales ratios are based on cumulative historical `orderdetails`, not a forecast.
- **Shipping-time analysis is at the order level, not the warehouse level.** The `orders` table doesn't attribute a shipment to a specific warehouse, so the 3.76-day average reflects overall company performance, not any single warehouse's fulfillment speed.
- **No cost or labor data available.** The database doesn't include real estate cost, staffing, or shipping-cost-by-route data, so this recommendation is based on inventory efficiency and capacity fit only.

## Repository Contents

| File | Description |
|---|---|
| [`mintclassics_analysis.sql`](./mintclassics_analysis.sql) | Full SQL script (Sections 0–8b), as developed and run in MySQL Workbench against the `mintclassics` schema |
| [`Mint_Classics_Inventory_Analysis_Report.docx`](./Mint_Classics_Inventory_Analysis_Report.docx) | Full write-up including summary, solution, approach, and appendix |

## How to Reproduce

1. Import the `mintclassics` sample database (`mintclassicsDB.sql`) into MySQL Workbench.
2. Run `mintclassics_analysis.sql` section by section — each section is commented with the question it answers.
3. Compare output against the tables in this README / the full report.
