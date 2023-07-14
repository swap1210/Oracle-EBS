-- Query 1
select
    QLH.NAME,
    QLH.DESCRIPTION,
    QLH.START_DATE_ACTIVE,
    QLL.OPERAND,
    QLL.ARITHMETIC_OPERATOR,
    OOLA.ordered_quantity,
    oola.order_quantity_uom,
    oola.ordered_item,
    ooha.order_number
from
    apps.qp_list_headers QLH,
    apps.qp_list_lines QLL,
    apps.qp_pricing_attributes qpa,
    apps.oe_order_lines_all oola,
    apps.oe_order_headers_all ooha
WHERE
    QLH.list_HEADER_ID = QLL.list_HEADER_ID
    and qpa.LIST_LINE_ID = qll.LIST_LINE_ID
    and qpa.list_HEADER_ID = qlh.list_HEADER_ID
    and to_char(oola.INVENTORY_ITEM_ID) = QPA.PRODUCT_ATTR_VALUE
    and oola.header_id = ooha.header_id
    and ooha.order_number = :P_ORDER_NUMBER -- Query 2
SELECT
    distinct ooh.order_number,
    ac.customer_name,
    ooh.org_id,
    ooh.ORDERED_DATE,
    ooh.FLOW_STATUS_CODE SO_Status,
    ool.line_number,
    msi.SEGMENT1 Item_Name,
    ool.ordered_quantity,
    wdd.shipped_quantity,
    rctl.QUANTITY_invoiced,
    wda.delivery_id shipment_number,
    rct.TRX_NUMBER Invoice_Num,
    rct.TRX_date Invoice_Date,
    rct.STATUS_TRX,
    decode(rct.COMPLETE_FLAG, 'Y', 'Completed', 'In Complete') Inv_Status,
    ool.UNIT_SELLING_price * ool.ordered_quantity line_total
from
    apps.oe_order_headers_all ooh,
    apps.ar_customers ac,
    apps.wsh_delivery_details wdd,
    apps.oe_order_lines_all ool,
    apps.wsh_delivery_assignments wda,
    apps.hz_cust_accounts hca,
    apps.ra_customer_trx_lines_all rctl,
    apps.ra_customer_trx_all rct,
    apps.mtl_system_items msi
where
    ooh.header_id = ool.header_id
    and ooh.sold_to_org_id = hca.cust_account_id
    and ooh.header_id = wdd.source_header_id
    and ool.line_id = wdd.source_line_id
    and hca.cust_account_id = ac.customer_id
    and msi.INVENTORY_ITEM_ID = ool.INVENTORY_ITEM_ID
    and msi.ORGANIZATION_ID = ool.SHIP_FROM_ORG_ID
    and wda.delivery_detail_id = wdd.delivery_detail_id
    and ooh.org_id = :P_ORG_ID
    and rct.CUSTOMER_TRX_ID = rctl.CUSTOMER_TRX_ID
    and rctl.LINE_TYPE = 'LINE'
    and rctl.interface_line_attribute1 = to_char(ooh.ORDER_NUMBER)
    and rctl.interface_line_attribute3 = to_char(wda.delivery_id) --and rctl.QUANTITY_invoiced = ool.ORDERED_QUANTITY
    and ooh.order_number = :P_order_number
order by
    ool.line_number