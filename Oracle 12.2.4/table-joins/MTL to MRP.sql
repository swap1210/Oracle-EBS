select
    c.category_set_name,
    d.segment1
from
    inv.mtl_item_categories b,
    inv.mtl_categories_b d,
    apps.MTL_CATEGORY_SETS_V c,
    apps.mtl_system_items_b msi
where
    1 = 1
    and B.CATEGORY_SET_ID = C.CATEGORY_SET_ID
    and c.category_set_name = 'GE WHS LOCATION' --'GE Product Hierarchy'
    and B.CATEGORY_ID = D.CATEGORY_ID
    and B.INVENTORY_ITEM_ID = msi.inventory_item_id
    and b.organization_id = msi.organization_id
    and msi.segment1 = '30308526'
    and msi.organization_id = 804;

Item Attachment
SELECT
    fad.pk1_value,
    fad.pk2_value,
    msib.segment1,
    fdst.short_text attachment -- nvl(listagg(fdst.short_text, ' | ')  --within GROUP (ORDER BY fad.seq_num),' ') AS attachment
FROM
    apps.fnd_attached_documents fad,
    apps.fnd_documents fd,
    apps.fnd_documents_short_text fdst,
    apps.fnd_document_categories_tl fdct --,wms.WMS_LABEL_REQUESTS wlr
,
    apps.mtl_system_items_b msib
WHERE
    fad.pk1_value = '545'
    and fad.pk2_value = msib.inventory_item_id
    and fad.pk1_value = msib.organization_id --AND fad.pk2_value = wlr.inventory_item_id
    AND fd.document_id = fad.document_id
    AND fdst.media_id = fd.media_id
    AND fdct.category_id = fd.category_id
    AND fdct.user_name = 'To Receiver';

---ITEM SQLS-----
--Item Frequency
select
    Mac.Abc_Class_Name,
    count(*) --To_Number(SUBSTR(Mac.Abc_Class_Name,4)) FRQ
from
    Apps.Mtl_System_Items Msi,
    Apps.Mtl_Abc_Assignment_Groups Maag,
    Apps.Mtl_Abc_Assignments Maa,
    Apps.Mtl_Abc_Classes Mac
where
    Maag.Assignment_Group_Name = 'HKD_Freq_Assignment_group'
    AND Maag.Assignment_Group_Id = Maa.Assignment_Group_Id
    AND Maa.Abc_Class_Id = Mac.Abc_Class_Id
    AND Mac.Organization_Id = msi.organization_id
    AND Maag.Organization_Id = msi.organization_id
    AND Maa.Inventory_Item_Id = msi.Inventory_Item_Id
    and msi.organization_id = 1533 --1872
    --and msi.segment1 = '29032003'
group by
    Mac.Abc_Class_Name
order by
    1;

-- Item Lot / Serial Control / Temp / Cost
select
    mp.organization_code org,
    msib_sgd.segment1 "Item",
    msib_sgd.inventory_item_id Id,
    (
        select
            c_ext_attr11 || '/' || c_ext_attr12
        from
            apps.ego_mtl_sy_items_ext_b
        where
            organization_id = 89
            and inventory_item_id = msib_sgd.inventory_item_id
            and attr_group_id = 42
    ) "Item Temperature",
    decode(msib_sgd.serial_number_control_code, 1, 'No', 'Yes') "Serial Item SGD",
    decode(msib_upd.serial_number_control_code, 1, 'No', 'Yes') "Serial Item UPD",
    decode(msib_sgd.lot_control_code, 1, 'No', 'Yes') "Lot Item SGD",
    decode(msib_upd.lot_control_code, 1, 'No', 'Yes') "Lot Item UPD",
    cic.item_cost --msib_sgd.UNIT_LENGTH, msib_sgd.UNIT_WIDTH, msib_sgd.UNIT_HEIGHT, msib_sgd.UNIT_WEIGHT, msib_sgd.UNIT_VOLUME
from
    apps.mtl_system_items_b msib_upd,
    apps.mtl_system_items_b msib_sgd,
    apps.cst_item_costs cic,
    apps.mtl_parameters mp
where
    1 = 1
    AND cic.inventory_item_id(+) = msib_sgd.inventory_item_id
    AND cic.organization_id(+) = msib_sgd.organization_id
    AND msib_sgd.inventory_item_id = msib_upd.inventory_item_id
    AND msib_upd.organization_id = 84
    AND cic.cost_type_id(+) = 1
    and msib_sgd.organization_id = mp.organization_id
    and mp.organization_code = 'SGD' --and msib.segment1 = 'BR100669'
    and (
        msib_sgd.lot_control_code <> msib_upd.lot_control_code
        or msib_sgd.serial_number_control_code <> msib_upd.serial_number_control_code
    )
    and msib_sgd.segment1 in ('28978245', '28954215')
order by
    2,
    1;

Item with No Onhands -- Query to get item details for those IQM items which do not have onhand quantity
select
    msib.inventory_item_id,
    msib.segment1,
    msib.description,
    msib.PLANNING_MAKE_BUY_CODE,
    msib.INVENTORY_ITEM_STATUS_CODE
from
    apps.mtl_system_items_b msib
where
    msib.organization_id = 1571 -- Code for IQM
    and msib.PLANNING_MAKE_BUY_CODE = 2 -- All Buy Items
    and msib.INVENTORY_ITEM_STATUS_CODE <> 'Inactive' -- Dont include Inactive items
    and inventory_item_id not in (
        select
            moq.inventory_item_id
        from
            apps.mtl_onhand_quantities moq
        where
            1 = 1
            and moq.organization_id = 1571
    );

Item Onhands Report
SELECT
    ood.organization_code "Organization",
    ood.organization_name "Org Name",
    milk.subinventory_code "Subinventory",
    (
        select
            status_code
        from
            apps.mtl_material_statuses
        where
            status_id = mss.status_id
    ) "Subinv Status",
    hl.location_code "Location",
    mss.attribute_category "Subinv Context",
    mss.attribute2 "Subinv Type",
    mss.attribute3 "Storage Temp",
    milk.concatenated_segments "Locator",
    (
        select
            status_code
        from
            apps.mtl_material_statuses
        where
            status_id = milk.status_id
    ) "Loc Status",
    Zones.zones "Loc Zones",
    milk.alias "Loc Alias",
    msib.segment1 "Item",
    (
        select
            c_ext_attr12
        from
            apps.ego_mtl_sy_items_ext_b
        where
            organization_id = 89
            and inventory_item_id = msib.inventory_item_id
            and attr_group_id = 42
    ) "Storage Condition",
    (
        select
            c_ext_attr11
        from
            apps.ego_mtl_sy_items_ext_b
        where
            organization_id = 89
            and inventory_item_id = msib.inventory_item_id
            and attr_group_id = 42
    ) "Shipping Condition",
    (
        select
            DECODE(c_ext_attr9, 'N', 'No', 'Y', 'Yes')
        from
            apps.ego_mtl_sy_items_ext_b
        where
            organization_id = msib.organization_id
            and inventory_item_id = msib.inventory_item_id
            and attr_group_id = 43
    ) "Back to Back",
    ItemFreq.abc_class "Item Frequency",
    moq.transaction_quantity "Quantity",
    moq.serial_number "Serial",
    moq.lot_number "Lot",
    (
        select
            status_code
        from
            apps.mtl_material_statuses
        where
            status_id = mln.status_id
    ) "Lot Status",
    to_char(mln.expiration_date, 'YYYY-MM-DD') "Sell Until Date",
    to_char(
        to_date(substr(mln.c_attribute1, 0, 10), 'YYYY/MM/DD'),
        'YYYY-MM-DD'
    ) "Expiry Date",
    moq.orig_date_received "Date Received",
    moq.last_update_date "Last Transaction",
    (cic.item_cost * moq.transaction_quantity) "SPC Total",
    gsob.currency_code "Currency",
    mic.modality "Modality",
    mic.prodcenter "Product Center",
    mic.prodgroup "Product Group"
from
    apps.mtl_item_locations_kfv milk,
    apps.mtl_secondary_inventories mss,
    apps.hr_locations hl,
    apps.mtl_system_items_b msib,
    apps.org_organization_definitions ood,
    apps.gl_sets_of_books gsob,
    apps.cst_item_costs cic,
    apps.mtl_lot_numbers mln,
    (
        SELECT
            maag.organization_id,
            maa.inventory_item_id,
            max(mac.abc_class_name) abc_class
        FROM
            apps.mtl_abc_classes mac,
            apps.mtl_abc_assignments maa,
            apps.mtl_abc_assignment_groups maag
        WHERE
            1 = 1
            AND maa.abc_class_id = mac.abc_class_id
            AND maag.assignment_group_id = maa.assignment_group_id
            AND upper(maag.assignment_group_name) LIKE '%FREQ_ASSIGNMENT_GROUP%'
        group by
            maag.organization_id,
            maa.inventory_item_id
    ) ItemFreq,
    (
        select
            wzl.inventory_location_id,
            listagg(wzt.zone_name, ', ') within group (
                order by
                    wzt.zone_name
            ) zones
        from
            apps.wms_zone_locators wzl,
            apps.wms_zones_tl wzt
        where
            1 = 1
            and wzt.zone_id = wzl.zone_id
        group by
            wzl.inventory_location_id
    ) Zones,
    (
        select
            moq.organization_id,
            moq.locator_id,
            moq.inventory_item_id,
            moq.lot_number,
            msn.serial_number,
            min(moq.orig_date_received) orig_date_received,
            max(moq.last_update_date) last_update_date,
            case
                when msn.serial_number is not null then 1
                else sum(moq.transaction_quantity)
            end transaction_quantity
        from
            apps.mtl_onhand_quantities moq,
            apps.mtl_serial_numbers msn
        where
            1 = 1
            and msn.inventory_item_id(+) = moq.inventory_item_id
            and msn.current_locator_id(+) = moq.locator_id
            and msn.current_organization_id(+) = moq.organization_id
        group by
            moq.organization_id,
            moq.locator_id,
            moq.inventory_item_id,
            moq.lot_number,
            msn.serial_number
    ) moq,
    (
        SELECT
            mic.organization_id,
            mic.inventory_item_id,
            mcb.segment4 || ' - ' || ffvv1.description modality,
            mcb.segment6 || ' - ' || ffvv2.description prodcenter,
            mcb.segment8 || ' - ' || ffvv3.description prodgroup
        FROM
            apps.mtl_item_categories mic,
            apps.mtl_categories_b mcb,
            apps.fnd_flex_values_vl ffvv1,
            apps.fnd_flex_values_vl ffvv2,
            apps.fnd_flex_values_vl ffvv3
        WHERE
            1 = 1
            AND mic.category_set_id = '1100000021'
            AND mcb.category_id = mic.category_id
            AND ffvv1.flex_value = mcb.segment4
            AND ffvv2.flex_value = mcb.segment6
            AND ffvv3.flex_value = mcb.segment8
            AND ffvv1.flex_value_set_id = '1009484'
            AND ffvv2.flex_value_set_id = '1009488'
            AND ffvv3.flex_value_set_id = '1009490'
    ) mic
where
    1 = 1
    and ood.organization_id = milk.organization_id
    and gsob.set_of_books_id = ood.set_of_books_id
    and mss.secondary_inventory_name = milk.subinventory_code
    and mss.organization_id = milk.organization_id
    and cic.organization_id(+) = moq.organization_id
    and cic.inventory_item_id(+) = moq.inventory_item_id
    and cic.cost_type_id(+) = 1
    and hl.location_id(+) = mss.location_id
    and moq.locator_id(+) = milk.inventory_location_id
    and msib.inventory_item_id(+) = moq.inventory_item_id
    and msib.organization_id(+) = moq.organization_id
    and mic.organization_id(+) = moq.organization_id
    and mic.inventory_item_id(+) = moq.inventory_item_id
    and mln.organization_id(+) = moq.organization_id
    and mln.inventory_item_id(+) = moq.inventory_item_id
    and mln.lot_number(+) = moq.lot_number
    and ItemFreq.organization_id(+) = msib.organization_id
    and ItemFreq.inventory_item_id(+) = msib.inventory_item_id
    and Zones.inventory_location_id(+) = milk.inventory_location_id
    and ood.organization_code = 'HKD';

Onhand Cost Group
select
    item_type,
    cost_group,
    count(*)
from
    (
        select
            moq.inventory_item_id,
            msib.segment1,
            msib.item_type,
            moq.date_received,
            moq.transaction_quantity,
            moq.subinventory_code,
            moq.lot_number,
            moq.cost_group_id,
            cg.cost_group
        from
            apps.mtl_onhand_quantities moq,
            apps.mtl_system_items_b msib,
            apps.cst_cost_groups cg
        where
            moq.organization_id = 1872
            and moq.inventory_item_id = msib.inventory_item_id
            and msib.organization_id = moq.organization_id
            and cg.organization_id = moq.organization_id
            and cg.cost_group_id = moq.cost_group_id
    )
group by
    item_type,
    cost_group;

select
    moq.inventory_item_id,
    msib.segment1,
    decode(msib.lot_control_code, 2, 'Yes', 'No') Lot,
    decode(msib.SERIAL_NUMBER_CONTROL_CODE, 1, 'No', 'Yes') Serial --, msib.item_type
,
    moq.date_received,
    moq.transaction_quantity Qty,
    moq.subinventory_code,
    (
        select
            mil.SEGMENT1 || '.' || mil.SEGMENT2 || '.' || mil.SEGMENT3 || '.' || mil.SEGMENT4 || '.' || mil.SEGMENT5
        from
            apps.mtl_item_locations mil
        where
            organization_id = moq.organization_id
            and mil.INVENTORY_LOCATION_ID = moq.locator_id
    ) loc,
    moq.lot_number --, moq.cost_group_id
,
    cg.cost_group,
    D.SEGMENT4,
    b.last_update_date
from
    apps.mtl_onhand_quantities moq,
    apps.mtl_system_items_b msib,
    apps.cst_cost_groups cg,
    inv.mtl_item_categories b,
    inv.mtl_categories_b d
where
    moq.organization_id = 1538 --(1872, 1533)  --1533  --1872
    and moq.inventory_item_id = msib.inventory_item_id
    and msib.organization_id = moq.organization_id
    and cg.organization_id = moq.organization_id
    and cg.cost_group_id = moq.cost_group_id --and msib.segment1 = 'BR100213'
    and B.CATEGORY_SET_ID = '1100000021'
    and B.CATEGORY_ID = D.CATEGORY_ID
    and B.INVENTORY_ITEM_ID = moq.inventory_item_id
    and b.organization_id = msib.organization_id
    and substr(cg.cost_group, 3, 3) <> D.SEGMENT4;

Cost Groups
select
    cg.cost_group_id,
    cg.cost_group,
    cg.organization_id,
    cg.multi_org_flag,
    cg.description,
    cg.disable_date,
    cg.cost_group_type,
    cga.material_account,
    (
        select
            (
                segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11
            )
        from
            apps.gl_code_combinations
        where
            code_combination_id = cga.material_account
    ) MATERIAL_ACCOUNT_STR,
    cga.material_overhead_account,
    (
        select
            (
                segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11
            )
        from
            apps.gl_code_combinations
        where
            code_combination_id = cga.material_overhead_account
    ) MATERIAL_OVERHEAD_ACCOUNT_STR,
    cga.resource_account,
    (
        select
            (
                segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11
            )
        from
            apps.gl_code_combinations
        where
            code_combination_id = cga.resource_account
    ) RESOURCE_ACCOUNT_STR,
    cga.overhead_account,
    (
        select
            (
                segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11
            )
        from
            apps.gl_code_combinations
        where
            code_combination_id = cga.overhead_account
    ) OVERHEAD_ACCOUNT_STR,
    cga.outside_processing_account,
    (
        select
            (
                segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11
            )
        from
            apps.gl_code_combinations
        where
            code_combination_id = cga.outside_processing_account
    ) OUTSIDE_PROCESSING_ACCOUNT_STR,
    cga.expense_account,
    (
        select
            (
                segment1 || '.' || segment2 || '.' || segment3 || '.' || segment4 || '.' || segment5 || '.' || segment6 || '.' || segment7 || '.' || segment8 || '.' || segment9 || '.' || segment10 || '.' || segment11
            )
        from
            apps.gl_code_combinations
        where
            code_combination_id = cga.expense_account
    ) EXPENSE_ACCOUNT_STR
from
    apps.CST_COST_GROUPS_V cg,
    apps.CST_COST_GROUP_ACCOUNTS cga
where
    --cost_group = 'CG-LGM' and
    cg.organization_id = (
        select
            organization_id
        from
            apps.mtl_parameters
        where
            organization_code = 'PAM'
            and rownum = 1
    )
    and cg.cost_group_id = cga.cost_group_id
order by
    2;

Material Status Check:
SELECT
    --ms.status_id "Id",ms.status_code, ms.enabled_flag,
    ms.reservable_type,
    ms.inventory_atp_code,
    ms.AVAILABILITY_TYPE,
    ms.zone_control,
    ms.locator_control,
    ms.lot_control,
    ms.serial_control,
    ms.onhand_control,
    msc.transaction_source_type_id "Id1",
    msc.transaction_type_id "Id2",
    msc.transaction_description,
    msc.is_allowed,
    count(*)
FROM
    mtl_material_statuses_vl ms,
    apps.MTL_STATUS_CONTROL_V msc
where
    1 = 1
    and msc.status_id = ms.status_id --and ms.status_id =74
group by
    --ms.status_id ,ms.status_code,
    --ms.enabled_flag,
    ms.reservable_type,
    ms.inventory_atp_code,
    ms.AVAILABILITY_TYPE,
    ms.zone_control,
    ms.locator_control,
    ms.lot_control,
    ms.serial_control,
    ms.onhand_control,
    msc.transaction_source_type_id,
    msc.transaction_type_id,
    msc.transaction_description,
    msc.is_allowed;

Sourcing Rules: ------SR Setup ----
select
    sr.sourcing_rule_id,
    sr.SOURCING_RULE_NAME,
    sr.ORGANIZATION_ID,
    sr.DESCRIPTION,
    sr.STATUS,
    sr.SOURCING_RULE_TYPE,
    sr.PLANNING_ACTIVE,
    sro.sr_receipt_id,
    sro.receipt_organization_id,
    sro.effective_date,
    msso.source_type,
    msso.source_organization_id,
    msso.vendor_id,
    msso.vendor_site_id,
    msso.allocation_percent,
    msso.rank,
    msso.ship_method
from
    mrp.mrp_sourcing_rules sr,
    APPS.mrp_sr_receipt_org sro,
    APPS.mrp_sr_source_org msso
where
    1 = 1 --and sr.creation_date > sysdate - 1
    and sro.sourcing_rule_id = sr.sourcing_rule_id
    and msso.sr_receipt_id = sro.sr_receipt_id
    and sr.SOURCING_RULE_NAME like '%CDM%';

----- SR Assignment-----
SELECT
    count(*) --  sr.sourcing_rule_name
FROM
    MRP.MRP_SR_ASSIGNMENTS a,
    mrp.mrp_sourcing_rules sr,
    apps.mtl_system_items_b msib9
where
    a.organization_id = MSIB9.organization_id
    and a.inventory_item_id = MSIB9.inventory_item_id
    and a.sourcing_rule_id = sr.sourcing_rule_id
    and a.assignment_set_id = 10
    and msib9.organization_id = 84
    and sourcing_rule_name like '%CDM%FT%';

MTL Transaction Records:
select
    --*
    mmt.ORGANIZATION_ID,
    msib.segment1,
    --(select mln.lot_number from apps.mtl_transaction_lot_numbers mln where mln.transaction_id = mmt.transaction_id) lot_number,
    mmt.subinventory_code,
    --mmt.locator_id,
    (
        select
            mil.SEGMENT1 || '.' || mil.SEGMENT2 || '.' || mil.SEGMENT3 || '.' || mil.SEGMENT4 || '.' || mil.SEGMENT5
        from
            apps.mtl_item_locations mil
        where
            mil.organization_id = mmt.ORGANIZATION_ID
            and mil.inventory_location_id = mmt.locator_id
    ) FROM_LOC,
    --(select location_code from apps.hr_locations where location_id = mmt.SHIP_TO_LOCATION_ID) Ship_Location,
    mmt.transaction_quantity,
    mmt.transaction_date,
    mmt.transfer_subinventory,
    --mmt.transfer_locator_id,
    --(select mil.SEGMENT1||'.'||mil.SEGMENT2||'.'||mil.SEGMENT3||'.'||mil.SEGMENT4||'.'||mil.SEGMENT5 from apps.mtl_item_locations mil where mil.inventory_location_id = mmt.transfer_locator_id) TO_LOC,
    mmt.TRANSFER_ORGANIZATION_ID,
    mmt.transaction_id,
    mtst.transaction_source_type_name,
    mtt.transaction_type_name,
    flv.meaning trx_action,
    mmt.creation_date,
    mmt.created_by,
    (
        select
            user_name || ' / ' || description
        from
            apps.fnd_user
        where
            user_id = mmt.created_by
    ) cre_by
from
    apps.MTL_MATERIAL_TRANSACTIONS mmt,
    apps.mtl_system_items_b msib,
    apps.MTL_TXN_SOURCE_TYPES mtst,
    apps.MTL_TRANSACTION_TYPES mtt,
    apps.fnd_lookup_values flv
where
    1 = 1 --mmt.transaction_id = 487011033
    and mmt.ORGANIZATION_ID in (84)
    and msib.inventory_item_id = mmt.inventory_item_id
    and msib.organization_id = mmt.organization_id
    and mtst.transaction_source_type_id = mmt.TRANSACTION_SOURCE_TYPE_ID
    and mtt.transaction_type_id = mmt.TRANSACTION_TYPE_ID
    and flv.lookup_type = 'MTL_TRANSACTION_ACTION'
    and flv.lookup_code = mmt.TRANSACTION_ACTION_ID --and mmt.INVENTORY_ITEM_ID = 178915
    --and mmt.created_by = 10298
    and msib.segment1 = '29027743'
    and trunc(mmt.creation_date) = to_date('15-OCT-2013', 'DD-MON-YYYY') -- > sysdate -.5
order by
    mmt.transaction_id desc;