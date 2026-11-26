---
name: pies-aces-data-classes
description: What classes of data an automotive aftermarket part needs for a PIM (PIES and ACES), and what could not be confirmed, as read on 2026-11-10
metadata:
  type: reference
---

Summary of a sub-agent read on 2026-11-10. Full notes: `/Users/alcatraz627/Code/Versable/aep-scrape/.claude/output/20261110-1530-pies/pies-aces-minimum.md`.

The public "PIES Reference Manual v6.0" PDF is Advance Auto Parts' supplier manual, not the Auto Care standard. Its required marks are that one retailer's. The standard's own manual and schema sit behind an Auto Care login.

Data classes a PIES file carries, with the retailer's mark:

- Item: part number, brand ID, part type ID from PCdb, GTIN, quantity per application. Required.
- Descriptions: coded short and long text. Required. Marketing copy is optional.
- Price. Required.
- Extended information: country of origin, tariff code, life cycle status. Required.
- Attributes: attribute ID and value, from PAdb or free. Required as a segment.
- Package: dimensions and weight at each level. Required.
- Interchange: OE and competitor numbers. Optional.
- Digital assets: one primary image is needed in practice.
- Hazardous material and kits. Not required.

ACES carries fitment. An application needs a base vehicle (year, make, model) from VCdb, a part type from PCdb and a quantity. Engine detail, position and coded qualifiers are added on top. These points come from search snippets only.

Not confirmed: the standard's own mandatory fields, the warehouse distributors' minimum field list (the count of 60 is unverified), and any ACES element list.

Owner's stance for the Asian Engine Parts work: OE numbers and validated fitment matter most. The other classes are best effort.
