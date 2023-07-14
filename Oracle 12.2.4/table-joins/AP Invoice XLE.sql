SELECT
    SUM (xal.accounted_cr),
    SUM (xal.accounted_dr),
    aia.invoice_amount,
    invoice_num
FROM
    ap_invoices_all aia,
    xla.xla_transaction_entities xte,
    xla_ae_headers xah,
    xla_ae_lines xal,
    gl.gl_import_references gir,
    gl_je_lines gjl,
    gl_je_headers gjh
WHERE
    1 = 1
    AND aia.invoice_id = NVL ("SOURCE_ID_INT_1", (-99))
    AND xte.entity_code = 'AP_INVOICES'
    AND xte.application_id = 200
    AND xte.entity_id = xah.entity_id
    AND xah.ae_header_id = xal.ae_header_id
    AND xal.gl_sl_link_id = gir.gl_sl_link_id
    AND xal.gl_sl_link_table = gir.gl_sl_link_table
    AND gir.je_header_id = gjl.je_header_id
    AND gir.je_line_num = gjl.je_line_num
    AND gjl.je_header_id = gjh.je_header_id
    AND aia.invoice_num = 'XXXXXX' --Invoice Number
GROUP BY
    aia.invoice_num,
    aia.invoice_amount