SELECT
    mp.organization_code "Warehouse",
    wda.delivery_id "Delivery",
    wt.name "Trip",
    (
        SELECT
            MEANING
        FROM
            apps.FND_LOOKUP_VALUES_VL
        WHERE
            lookup_type = 'PICK_STATUS'
            AND LOOKUP_CODE = wdd.released_status
    ) "Delivery Status",
    CASE
        WHEN wdt_extra.move_order_line_id IS NOT NULL THEN (
            SELECT
                MEANING
            FROM
                apps.FND_LOOKUP_VALUES_VL
            WHERE
                lookup_type = 'WMS_TASK_STATUS'
                AND LOOKUP_CODE = wdt_extra.status
        )
        WHEN mmtt.wms_task_status IS NOT NULL THEN (
            SELECT
                MEANING
            FROM
                apps.FND_LOOKUP_VALUES_VL
            WHERE
                lookup_type = 'WMS_TASK_STATUS'
                AND LOOKUP_CODE = mmtt.wms_task_status
        )
        WHEN wdth.move_order_line_id IS NOT NULL THEN (
            SELECT
                MEANING
            FROM
                apps.FND_LOOKUP_VALUES_VL
            WHERE
                lookup_type = 'WMS_TASK_STATUS'
                AND LOOKUP_CODE = wdth.status
        )
        WHEN wdt.move_order_line_id IS NOT NULL THEN (
            SELECT
                MEANING
            FROM
                apps.FND_LOOKUP_VALUES_VL
            WHERE
                lookup_type = 'WMS_TASK_STATUS'
                AND LOOKUP_CODE = wdt.status
        )
    END AS "Task Status",
    CASE
        WHEN wdd.released_status = 'S' THEN 'Awaiting Picking'
        WHEN wdd.released_status = 'Y'
        AND wdd_outermost.delivery_detail_id IS NULL THEN 'Awaiting Packing'
        WHEN wdd.released_status = 'Y'
        AND wdd_outermost.delivery_detail_id IS NOT NULL
        AND wnd.planned_flag != 'Y' THEN 'Awaiting Delivery Completion'
        WHEN wdd.released_status = 'Y'
        AND wdd_outermost.delivery_detail_id IS NOT NULL
        AND wnd.planned_flag = 'Y' THEN 'Awaiting Ship Confirm'
        WHEN wdd.released_status = 'C' THEN 'Shipped'
        ELSE 'Unknown'
    END "Current Status",
    haou.name "Selling Org",
    hp.party_name "Customer",
    hcsu.site_use_id "Ship To",
    hl.country "Country",
    hl.state "State",
    hl.city "City",
    NVL(mmtt.pick_slip_number, mmt.pick_slip_number) "Pick Slip",
    wdd.source_header_number "Order",
    ooha.ship_to_org_id,
    ooha.invoice_to_org_id,
    ooha.deliver_to_org_id,
    ooha.cust_po_number "Customer PO",
    wdd.source_header_type_name "Order Type",
    wdd.source_line_number "Line",
    ottt.name "Line Type",
    nvl(mmtt.subinventory_code, mmt.subinventory_code) "From Subinventory",
    (
        select
            milk.concatenated_segments
        from
            apps.mtl_item_locations_kfv milk
        where
            milk.inventory_location_id = nvl(mmtt.locator_id, mmt.locator_id)
    ) "From Locator",
    msib.segment1 "Item",
    (
        select
            c_ext_attr11 || '/' || c_ext_attr12
        from
            apps.ego_mtl_sy_items_ext_b
        where
            organization_id = 89
            and inventory_item_id = msib.inventory_item_id
            and attr_group_id = 42
    ) "Item Temperature",
    CASE
        WHEN wdd.shipped_quantity IS NOT NULL THEN wdd.shipped_quantity
        WHEN mmtt.transaction_quantity IS NOT NULL THEN mmtt.transaction_quantity
        ELSE mtrl.quantity
    END "Quantity",
    decode(msib.serial_number_control_code, 1, 'No', 'Yes') "Serial Item",
    CASE
        WHEN wdd.shipped_quantity IS NOT NULL THEN (wdd.shipped_quantity * oola.unit_selling_price)
        WHEN mmtt.transaction_quantity IS NOT NULL THEN (
            mmtt.transaction_quantity * oola.unit_selling_price
        )
        ELSE (mtrl.quantity * oola.unit_selling_price)
    END "Shipment Total Price",
    ooha.transactional_curr_code "Currency",
    wdd_parent.container_name "Parent LPN",
    wdd_outermost.container_name "Outermost LPN",
    flvv.meaning "Ship Method",
    CASE
        WHEN regexp_like(
            nvl(
                wdd_outermost.tracking_number,
                wdd_parent.tracking_number
            ),
            '^-?[[:digit:],.]*$'
        ) THEN '''' || nvl(
            wdd_outermost.tracking_number,
            wdd_parent.tracking_number
        )
        ELSE nvl(
            wdd_outermost.tracking_number,
            wdd_parent.tracking_number
        )
    END "Tracking Number",
    (
        SELECT
            ffvl.description
        FROM
            apps.mtl_item_categories mic,
            apps.mtl_categories_b mcb,
            apps.fnd_flex_values_vl ffvl
        WHERE
            mic.organization_id = msib.organization_id
            AND mic.inventory_item_id = msib.inventory_item_id
            AND mic.category_set_id = '1100000155'
            AND mcb.category_id = mic.category_id
            AND ffvl.flex_value_meaning = mcb.segment2
            AND ffvl.flex_value_set_id = 1018149
    ) "Distribution Planner",
    wdd.ship_set_id "Ship Set ID",
    trunc(oola.schedule_ship_date) "Scheduled Ship Date",
    /*
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(nvl(mtrl.pick_slip_date,mtrl.creation_date), 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Released Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(nvl(wdt.dispatched_time,wdth.dispatched_time), 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Dispatched Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(nvl(wdt.loaded_time,wdth.loaded_time), 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Loaded Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wdth.drop_off_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Drop Off Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wdd_outermost.creation_date, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Packed Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wnd.confirm_date, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Ship Confirm Timestamp",
     */
    round(
        (
            nvl(wdth.drop_off_time, sysdate) - mtrl.pick_slip_date
        ) * 24 * 60,
        2
    ) "Picking Leadtime (m)",
    round(
        (
            nvl(wdd_outermost.creation_date, sysdate) - nvl(wdth.drop_off_time, mtrl.pick_slip_date)
        ) * 24 * 60,
        2
    ) "Packing Leadtime (m)",
    round(
        (
            nvl(wdd_outermost.creation_date, sysdate) - mtrl.pick_slip_date
        ) * 24 * 60,
        2
    ) "Total Leadtime (m)",
    ooha.header_id as "header_id",
    oola.line_id as "line_id",
    wdd.delivery_detail_id as "delivery_detail_id",
    msib.inventory_item_id as "inventory_item_id",
    hcsu.site_use_id as "site_use_id",
    hcsu.site_use_code || '|' || hcsu.site_use_id as "%KeyShipTo",
    (
        select
            max(
                fad.last_update_date || ': ' || fdst.short_text || ' [' || fu.description || ']'
            )
        from
            apps.fnd_attached_documents fad,
            apps.fnd_documents fd,
            apps.fnd_documents_short_text fdst,
            apps.fnd_document_categories_tl fdct,
            apps.fnd_user fu
        where
            1 = 1
            and fu.user_id = fad.last_updated_by
            and fd.document_id = fad.document_id
            and fdst.media_id = fd.media_id
            and fdct.category_id = fd.category_id
            and (
                fad.entity_name = 'WSH_NEW_DELIVERIES'
                and fad.pk1_value = wnd.delivery_id
            )
            and fdct.user_name = 'Warehouse Comment'
    ) "Header Comment",
    (
        select
            max(
                fad.last_update_date || ': ' || fdst.short_text || ' [' || fu.description || ']'
            )
        from
            apps.fnd_attached_documents fad,
            apps.fnd_documents fd,
            apps.fnd_documents_short_text fdst,
            apps.fnd_document_categories_tl fdct,
            apps.fnd_user fu
        where
            1 = 1
            and fu.user_id = fad.last_updated_by
            and fd.document_id = fad.document_id
            and fdst.media_id = fd.media_id
            and fdct.category_id = fd.category_id
            and (
                fad.entity_name = 'WSH_DELIVERY_DETAILS'
                and fad.pk1_value = wdd.delivery_detail_id
            )
            and fdct.user_name = 'Warehouse Comment'
    ) "Line Comment"
FROM
    -- Delivery detail and assignment
    apps.wsh_delivery_details wdd,
    apps.wsh_delivery_assignments wda,
    apps.wsh_delivery_details wdd_parent,
    apps.wsh_delivery_assignments wda_parent,
    apps.wsh_delivery_details wdd_outermost,
    apps.wsh_new_deliveries wnd,
    apps.wsh_delivery_legs wdl,
    apps.wsh_trip_stops wts,
    apps.wsh_trips wt,
    -- WMS Tasks
    apps.mtl_material_transactions mmt,
    apps.mtl_material_transactions_temp mmtt,
    apps.wms_dispatched_tasks wdt,
    apps.wms_dispatched_tasks_history wdth,
    apps.mtl_txn_request_lines mtrl,
    apps.wms_dispatched_tasks wdt_extra,
    apps.wsh_delivery_details wdd_extra,
    -- Order and Address
    apps.oe_order_lines_all oola,
    apps.oe_order_headers_all ooha,
    apps.oe_transaction_types_tl ottt,
    apps.hz_cust_site_uses_all hcsu,
    apps.hz_cust_acct_sites_all hcasa,
    apps.hz_party_sites hps,
    apps.hz_locations hl,
    apps.hz_parties hp,
    -- Others
    apps.mtl_parameters mp,
    apps.hr_all_organization_units haou,
    apps.mtl_system_items_b msib,
    apps.fnd_lookup_values_vl flvv
WHERE
    1 = 1
    AND mp.organization_id = mtrl.organization_id
    AND haou.organization_id = wdd.org_id
    AND msib.inventory_item_id = wdd.inventory_item_id
    AND msib.organization_id = wdd.organization_id
    AND ottt.transaction_type_id = oola.line_type_id
    AND flvv.lookup_type(+) = 'SHIP_METHOD'
    AND flvv.lookup_code(+) = wnd.ship_method_code -- Order and Address
    AND oola.line_id = wdd.source_line_id
    AND ooha.header_id = oola.header_id
    AND hcsu.site_use_id = ooha.ship_to_org_id
    AND hcasa.cust_acct_site_id = hcsu.cust_acct_site_id
    AND hps.party_site_id = hcasa.party_site_id
    AND hl.location_id = hps.location_id
    AND hp.party_id = hps.party_id -- Delivery detail and assignment joins
    AND wda.delivery_detail_id = wdd.delivery_detail_id
    AND wdd_parent.delivery_detail_id(+) = wda.parent_delivery_detail_id
    AND wda_parent.delivery_detail_id(+) = wdd_parent.delivery_detail_id
    AND wdd_outermost.delivery_detail_id(+) = wda_parent.parent_delivery_detail_id
    AND wnd.delivery_id(+) = wda.delivery_id
    AND wdl.delivery_id(+) = wnd.delivery_id
    AND wts.stop_id(+) = wdl.drop_off_stop_id
    AND wt.trip_id(+) = wts.trip_id -- Task Joins
    AND wdt.move_order_line_id(+) = wdd.move_order_line_id
    AND wdt.status(+) NOT IN (2, 3, 4) -- Filter loaded and queued duplicates that will be found in wdt_extra
    AND wdt_extra.transaction_temp_id(+) = mmtt.transaction_temp_id -- Join this table to get correct WMS task status as records exist in both mmtt and wdd
    AND wdt_extra.status(+) IN (2, 3, 4) -- Restrict to not get duplicates
    AND wdd_extra.delivery_detail_id(+) = wdd.delivery_detail_id -- re-join delivery details table
    AND wdd_extra.released_status(+) = 'S' -- restrict to S to counter nasty duplication bug in mmtt table
    AND mmtt.move_order_line_id(+) = wdd_extra.move_order_line_id -- only join this against wdd_extra
    AND mmt.move_order_line_id(+) = wdd.move_order_line_id
    AND mmt.transaction_id(+) = wdd.transaction_id
    AND wdth.move_order_line_id(+) = mmt.move_order_line_id
    AND wdth.transaction_id(+) = mmt.transaction_set_id
    AND wdth.transaction_batch_seq(+) = mmt.transaction_batch_seq
    AND wdth.source_locator_id(+) = mmt.locator_id -- Bugfix for UPD/Clearorbit. Not sure if still needed.
    AND wdth.status(+) != '11' -- Filter Aborted tasks
    AND mtrl.line_id = wdd.move_order_line_id -- Filters
    AND wdd.container_flag = 'N' -- Do not include containers in result
    --AND mp.organization_code IN ('CNS') -- Specific Warehouses
    -- Delivery lines with status "Released to Warehouse" and "Staged/Pick Confirmed"
    AND wdd.released_status IN ('S', 'Y') -- Filter out SVC orders
    AND wdd.source_header_type_name NOT LIKE 'SVC_ORDER_%'
    and wda.delivery_id = '84519487';

/*  ************************************************************************************************************
 
 OUTBOUND METRICS 
 
 Shipped/Interfaced - restrict how far back to look at the end
 
 ************************************************************************************************************  */
SELECT
    mp.organization_code "Warehouse",
    wda.delivery_id "Delivery",
    wt.name "Trip",
    (
        SELECT
            MEANING
        FROM
            apps.FND_LOOKUP_VALUES_VL
        WHERE
            lookup_type = 'PICK_STATUS'
            AND LOOKUP_CODE = wdd.released_status
    ) "Delivery Status",
    (
        SELECT
            MEANING
        FROM
            apps.FND_LOOKUP_VALUES_VL
        WHERE
            lookup_type = 'WMS_TASK_STATUS'
            AND LOOKUP_CODE = wdth.status
    ) "Task Status",
    CASE
        WHEN wdd.released_status = 'S' THEN 'Awaiting Picking'
        WHEN wdd.released_status = 'Y'
        AND wdd_outermost.delivery_detail_id IS NULL THEN 'Awaiting Packing'
        WHEN wdd.released_status = 'Y'
        AND wdd_outermost.delivery_detail_id IS NOT NULL
        AND wnd.planned_flag != 'Y' THEN 'Awaiting Delivery Completion'
        WHEN wdd.released_status = 'Y'
        AND wdd_outermost.delivery_detail_id IS NOT NULL
        AND wnd.planned_flag = 'Y' THEN 'Awaiting Ship Confirm'
        WHEN wdd.released_status = 'C' THEN 'Shipped'
        ELSE 'Unknown'
    END "Current Status",
    haou.name "Selling Org",
    hp.party_name "Customer",
    hcsu.site_use_id "Ship To",
    hl.country "Country",
    hl.state "State",
    hl.city "City",
    mmt.pick_slip_number "Pick Slip",
    wdd.source_header_number "Order",
    ooha.cust_po_number "Customer PO",
    wdd.source_header_type_name "Order Type",
    wdd.source_line_number "Line",
    ottt.name "Line Type",
    mmt.subinventory_code "From Subinventory",
    (
        select
            milk.concatenated_segments
        from
            apps.mtl_item_locations_kfv milk
        where
            milk.inventory_location_id = mmt.locator_id
    ) "From Locator",
    msib.segment1 "Item",
    decode(msib.lot_control_code, 1, 'No', 'Yes') "Lot",
    (
        select
            c_ext_attr11 || '/' || c_ext_attr12
        from
            apps.ego_mtl_sy_items_ext_b
        where
            organization_id = 89
            and inventory_item_id = msib.inventory_item_id
            and attr_group_id = 42
    ) "Item Temperature",
    NVL(wdd.shipped_quantity, mtrl.quantity) "Quantity",
    decode(msib.serial_number_control_code, 1, 'No', 'Yes') "Serial Item",
    (
        NVL(wdd.shipped_quantity, mtrl.quantity) * oola.unit_selling_price
    ) "Shipment Total Price",
    ooha.transactional_curr_code "Currency",
    wdd_parent.container_name "Parent LPN",
    wdd_outermost.container_name "Outermost LPN",
    flvv.meaning "Ship Method",
    CASE
        WHEN regexp_like(
            nvl(
                wdd_outermost.tracking_number,
                wdd_parent.tracking_number
            ),
            '^-?[[:digit:],.]*$'
        ) THEN '''' || nvl(
            wdd_outermost.tracking_number,
            wdd_parent.tracking_number
        )
        ELSE nvl(
            wdd_outermost.tracking_number,
            wdd_parent.tracking_number
        )
    END "Tracking Number",
    (
        SELECT
            ffvl.description
        FROM
            apps.mtl_item_categories mic,
            apps.mtl_categories_b mcb,
            apps.fnd_flex_values_vl ffvl
        WHERE
            mic.organization_id = msib.organization_id
            AND mic.inventory_item_id = msib.inventory_item_id
            AND mic.category_set_id = '1100000155'
            AND mcb.category_id = mic.category_id
            AND ffvl.flex_value_meaning = mcb.segment2
            AND ffvl.flex_value_set_id = 1018149
    ) "Distribution Planner",
    wdd.ship_set_id "Ship Set ID",
    trunc(oola.schedule_ship_date) "Scheduled Ship Date",
    /*
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(nvl(mtrl.pick_slip_date,mtrl.creation_date), 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Released Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wdth.dispatched_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Dispatched Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wdth.loaded_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Loaded Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wdth.drop_off_time, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Drop Off Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wdd_outermost.creation_date, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Packed Timestamp",
     CASE
     WHEN mp.organization_code = 'PYD' THEN TO_CHAR(FROM_TZ(CAST(TO_CHAR(wnd.confirm_date, 'YYYY-MM-DD HH24:MI:SS') AS TIMESTAMP), 'UTC') AT TIME ZONE 'America/New_York', 'YYYY-MM-DD HH24:MI:SS')
     END "Ship Confirm Timestamp",
     */
    round(
        (
            nvl(wdth.drop_off_time, sysdate) - mtrl.pick_slip_date
        ) * 24 * 60,
        2
    ) "Picking Leadtime (m)",
    round(
        (
            nvl(wdd_outermost.creation_date, sysdate) - nvl(wdth.drop_off_time, mtrl.pick_slip_date)
        ) * 24 * 60,
        2
    ) "Packing Leadtime (m)",
    round(
        (
            nvl(wdd_outermost.creation_date, sysdate) - mtrl.pick_slip_date
        ) * 24 * 60,
        2
    ) "Total Leadtime (m)",
    ooha.header_id as "header_id",
    oola.line_id as "line_id",
    wdd.delivery_detail_id as "delivery_detail_id",
    msib.inventory_item_id as "inventory_item_id",
    hcsu.site_use_id as "site_use_id",
    hcsu.site_use_code || '|' || hcsu.site_use_id as "%KeyShipTo",
    (
        select
            max(
                fad.last_update_date || ': ' || fdst.short_text || ' [' || fu.description || ']'
            )
        from
            apps.fnd_attached_documents fad,
            apps.fnd_documents fd,
            apps.fnd_documents_short_text fdst,
            apps.fnd_document_categories_tl fdct,
            apps.fnd_user fu
        where
            1 = 1
            and fu.user_id = fad.last_updated_by
            and fd.document_id = fad.document_id
            and fdst.media_id = fd.media_id
            and fdct.category_id = fd.category_id
            and (
                fad.entity_name = 'WSH_NEW_DELIVERIES'
                and fad.pk1_value = wnd.delivery_id
            )
            and fdct.user_name = 'Warehouse Comment'
    ) "Header Comment",
    (
        select
            max(
                fad.last_update_date || ': ' || fdst.short_text || ' [' || fu.description || ']'
            )
        from
            apps.fnd_attached_documents fad,
            apps.fnd_documents fd,
            apps.fnd_documents_short_text fdst,
            apps.fnd_document_categories_tl fdct,
            apps.fnd_user fu
        where
            1 = 1
            and fu.user_id = fad.last_updated_by
            and fd.document_id = fad.document_id
            and fdst.media_id = fd.media_id
            and fdct.category_id = fd.category_id
            and (
                fad.entity_name = 'WSH_DELIVERY_DETAILS'
                and fad.pk1_value = wdd.delivery_detail_id
            )
            and fdct.user_name = 'Warehouse Comment'
    ) "Line Comment"
FROM
    -- Delivery detail and assignment joins
    apps.wsh_delivery_details wdd,
    apps.wsh_delivery_assignments wda,
    apps.wsh_delivery_details wdd_parent,
    apps.wsh_delivery_assignments wda_parent,
    apps.wsh_delivery_details wdd_outermost,
    apps.wsh_new_deliveries wnd,
    apps.wsh_delivery_legs wdl,
    apps.wsh_trip_stops wts,
    apps.wsh_trips wt,
    -- WMS Tasks
    apps.mtl_material_transactions mmt,
    apps.wms_dispatched_tasks_history wdth,
    apps.mtl_txn_request_lines mtrl,
    -- Order and Address
    apps.oe_order_lines_all oola,
    apps.oe_order_headers_all ooha,
    apps.oe_transaction_types_tl ottt,
    apps.hz_cust_site_uses_all hcsu,
    apps.hz_cust_acct_sites_all hcasa,
    apps.hz_cust_site_uses_all hcsua,
    apps.hz_party_sites hps,
    apps.hz_locations hl,
    apps.hz_parties hp,
    -- Others
    apps.mtl_parameters mp,
    apps.hr_all_organization_units haou,
    apps.mtl_system_items_b msib,
    apps.fnd_lookup_values_vl flvv
WHERE
    1 = 1
    AND mp.organization_id = mtrl.organization_id
    AND haou.organization_id = wdd.org_id
    AND msib.inventory_item_id = wdd.inventory_item_id
    AND msib.organization_id = wdd.organization_id
    AND ottt.transaction_type_id = oola.line_type_id
    AND flvv.lookup_type(+) = 'SHIP_METHOD'
    AND flvv.lookup_code(+) = wnd.ship_method_code -- Order and Address
    AND oola.line_id = wdd.source_line_id
    AND ooha.header_id = oola.header_id
    AND hcsu.site_use_id = ooha.ship_to_org_id
    AND hcasa.cust_acct_site_id = hcsu.cust_acct_site_id
    AND hps.party_site_id = hcasa.party_site_id
    AND hl.location_id = hps.location_id
    AND hp.party_id = hps.party_id
    and hcsua.site_use_id = ooha.ship_to_org_id -- Delivery detail and assignment joins
    AND wda.delivery_detail_id = wdd.delivery_detail_id
    AND wdd_parent.delivery_detail_id(+) = wda.parent_delivery_detail_id
    AND wda_parent.delivery_detail_id(+) = wdd_parent.delivery_detail_id
    AND wdd_outermost.delivery_detail_id(+) = wda_parent.parent_delivery_detail_id
    AND wnd.delivery_id(+) = wda.delivery_id
    AND wdl.delivery_id(+) = wnd.delivery_id
    AND wts.stop_id(+) = wdl.drop_off_stop_id
    AND wt.trip_id(+) = wts.trip_id -- Task Joins
    AND mmt.move_order_line_id(+) = wdd.move_order_line_id
    AND mmt.transaction_id(+) = wdd.transaction_id
    AND wdth.move_order_line_id(+) = mmt.move_order_line_id
    AND wdth.transaction_id(+) = mmt.transaction_set_id
    AND wdth.transaction_batch_seq(+) = mmt.transaction_batch_seq
    AND wdth.source_locator_id(+) = mmt.locator_id -- Bugfix for UPD/Clearorbit. Not sure if still needed.
    AND mtrl.line_id = wdd.move_order_line_id -- Filters
    AND wdd.container_flag = 'N' -- Do not include containers in result
    AND wdth.status(+) != '11' -- Filter Aborted tasks
    AND mp.organization_code in ('UPD') -- Specific Warehouses
    -- Filter out SVC orders
    AND wdd.source_header_type_name NOT LIKE 'SVC_ORDER_%' -- All Ship Confirm transactions during specific time
    AND wda.delivery_id IN (
        SELECT
            trx_source_delivery_id
        FROM
            apps.mtl_material_transactions mmt,
            apps.mtl_transaction_types mtt
        WHERE
            1 = 1
            AND mmt.transaction_type_id = mtt.transaction_type_id
            AND mtt.transaction_type_name IN (
                'Sales order issue',
                'Int Order Intr Ship',
                'Internal Order Xfer'
            )
            AND mmt.transaction_date > sysdate -1 -- CHANGE HERE TO LOOK FURTHER BACK
        UNION
        ALL -- This union allows you to capture lines that are stuck in the transactions interface as well
        SELECT
            wnd.delivery_id
        FROM
            apps.wsh_new_deliveries wnd,
            apps.wsh_delivery_assignments wda,
            apps.wsh_delivery_details wdd,
            apps.mtl_transactions_interface mti
        WHERE
            1 = 1
            AND wnd.delivery_id = wda.delivery_id
            AND wda.delivery_detail_id = wdd.delivery_detail_id
            AND wnd.delivery_id = mti.trx_source_delivery_id
            AND wdd.source_line_id = mti.trx_source_line_id
            AND wdd.inv_interfaced_flag = 'P'
            AND wnd.status_code = 'CL'
            AND mti.creation_date > sysdate -1 -- CHANGE HERE TO LOOK FURTHER BACK
    );