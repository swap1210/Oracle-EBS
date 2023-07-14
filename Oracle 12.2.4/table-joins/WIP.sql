Select
    we.wip_entity_name wip_job_name "job created for Sale Order",
    wdj.scheduled_start_date wip_start_date,
    wdj.scheduled_completion_date wip_completion_date,
    ooh.order_number "Sales order number",
    msib.segment1 Item code "inventory item code",
    mr.reservation_quantity Quantity_reserved
FROM
    oe_order_headers_all ooh,
    oe_order_lines_all ool,
    mtl_reservations mr,
    wip_discrete_jobs wdj,
    wip_entities we,
    mtl_system_items_b msib
WHERE
    ooh.header_id = ool.header_id
    AND ooh.org_id = :p_org_id
    AND mr.demand_source_line_id = ool.line_id
    AND mr.supply_source_type_id = 5
    AND mr.supply_source_header_id = we.wip_entity_id
    AND we.wip_entity_id = wdj.wip_entity_id
    AND ool.ship_from_org_id = we.organization_id
    AND ool.ship_from_org_id = msib.organization_id
    AND mr.inventory_item_id = msib.inventory_item_id
    AND we.organization_id = wdj.organization_id