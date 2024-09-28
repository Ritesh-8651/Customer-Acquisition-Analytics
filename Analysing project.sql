use Project;
CREATE TABLE leads_basic_details (
  lead_id VARCHAR(20) PRIMARY KEY,
  age int DEFAULT NULL,
  gender VARCHAR(10),
  current_city VARCHAR(100),
  current_education VARCHAR(100),
  parent_occupation VARCHAR(100),
  lead_gen_source VARCHAR(100)
);

CREATE TABLE leads_demo_watched_details (
  lead_id VARCHAR(20),
  demo_watched_date VARCHAR(100),
  language VARCHAR(100),
  watched_percentage int DEFAULT NULL,
  FOREIGN KEY (lead_id) REFERENCES leads_basic_details(lead_id)
);

CREATE TABLE leads_interaction_details (
  jnr_sm_id VARCHAR(100) PRIMARY KEY,
  lead_id VARCHAR(100),
  lead_stage VARCHAR(100),
  call_done_date VARCHAR(100),
  call_status VARCHAR(100),
  call_reason VARCHAR(100),
  FOREIGN KEY (lead_id) REFERENCES leads_basic_details(lead_id)
);

CREATE TABLE leads_reasons_for_no_interest (
  lead_id VARCHAR(100),
  reasons_for_not_interested_in_demo VARCHAR(100),
  reasons_for_not_interested_to_consider VARCHAR(100),
  reasons_for_not_interested_to_convert VARCHAR(100),
  FOREIGN KEY (lead_id) REFERENCES leads_basic_details(lead_id)
);

CREATE TABLE sales_managers_assigned_leads_details (
  snr_sm_id VARCHAR(100) PRIMARY KEY,
  jnr_sm_id VARCHAR(100),
  assigned_date VARCHAR(100),
  cycle int DEFAULT NULL,
  lead_id VARCHAR(100),
  FOREIGN KEY (lead_id) REFERENCES leads_basic_details(lead_id),
  FOREIGN KEY (jnr_sm_id) REFERENCES leads_interaction_details(jnr_sm_id)
) ;

--   Lead Conversion Rate Analysis. --
SELECT 
    lead_stage, 
    COUNT(*) AS total_leads,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM leads_interaction_details WHERE lead_stage = 'lead')) AS conversion_rate
FROM 
    leads_interaction_details
GROUP BY 
    lead_stage
ORDER BY 
    FIELD(lead_stage, 'lead', 'awareness', 'consideration', 'conversion');
    
    
  --  Stage Drop-off Rate Analysis--
  SELECT 
    prev_stage.lead_stage AS prev_stage,
    COUNT(prev_stage.lead_id) AS total_leads_entered,
    COUNT(next_stage.lead_id) AS total_leads_exited,
    (COUNT(prev_stage.lead_id) - COUNT(next_stage.lead_id)) * 100.0 / COUNT(prev_stage.lead_id) AS drop_off_rate
FROM 
    leads_interaction_details prev_stage
LEFT JOIN 
    leads_interaction_details next_stage 
    ON prev_stage.lead_id = next_stage.lead_id AND prev_stage.lead_stage = 'lead' AND next_stage.lead_stage = 'awareness'
GROUP BY 
    prev_stage.lead_stage;
    
    
    --  Call Success Rate Analysis --
SELECT 
    jnr_sm_id,
    COUNT(*) AS total_calls,
    SUM(CASE WHEN call_status = 'successful' THEN 1 ELSE 0 END) AS successful_calls,
    SUM(CASE WHEN call_status = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS success_rate
FROM 
    leads_interaction_details
GROUP BY 
    jnr_sm_id
ORDER BY 
    success_rate DESC;
    
    
  --  Demo Session Engagement Analysis--
	SELECT   --  Demo Session Engagement Analysis--
    jnr_sm_id,
    COUNT(*) AS total_calls,
    SUM(CASE WHEN call_status = 'successful' THEN 1 ELSE 0 END) AS successful_calls,
    SUM(CASE WHEN call_status = 'successful' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS success_rate
FROM 
    leads_interaction_details
GROUP BY 
    jnr_sm_id
ORDER BY 
    success_rate DESC;

  
-- Reasons for Lack of Interest Analysis--
SELECT 
    reason,
    COUNT(*) AS total_leads
FROM (
    SELECT reasons_for_not_interested_in_demo AS reason FROM leads_reasons_for_no_interest
    UNION ALL
    SELECT 'reasons_for_not_interested_to_consider' AS reason FROM leads_reasons_for_no_interest
    UNION ALL
    SELECT 'reasons_for_not_interested_in_convert' AS reason FROM leads_reasons_for_no_interest
) AS combined_reasons
GROUP BY 
    reason
ORDER BY 
    total_leads DESC;


-- Sales Manager Performance Analysis--
SELECT -- Sales Manager Performance Analysis--
    smal.snr_sm_id,
    smal.jnr_sm_id,
    COUNT(lid.lead_id) AS total_leads_assigned,
    SUM(CASE WHEN lid.lead_stage = 'conversion' THEN 1 ELSE 0 END) AS total_conversions,
    SUM(CASE WHEN lid.lead_stage = 'conversion' THEN 1 ELSE 0 END) * 100.0 / COUNT(lid.lead_id) AS conversion_rate
FROM 
    sales_managers_assigned_leads_details smal
LEFT JOIN 
    leads_interaction_details lid 
    ON smal.lead_id = lid.lead_id
GROUP BY 
    smal.snr_sm_id, smal.jnr_sm_id
ORDER BY 
    conversion_rate DESC;


-- Identifying Outliers--
SELECT 
    dwd.lead_id,  -- specify the table alias here
    dwd.watched_percentage, 
    COUNT(*) AS total_interactions,
    SUM(CASE WHEN lid.lead_stage = 'conversion' THEN 1 ELSE 0 END) AS total_conversions
FROM 
    leads_demo_watched_details dwd
LEFT JOIN 
    leads_interaction_details lid 
    ON dwd.lead_id = lid.lead_id
GROUP BY 
    dwd.lead_id, dwd.watched_percentage
HAVING 
    dwd.watched_percentage < 20 AND total_conversions > 0;
    
    
    -- Final Recommendations Query--
   SELECT 
    lid.lead_stage,
    COUNT(*) AS total_leads,
    SUM(CASE WHEN lid.lead_stage = 'conversion' THEN 1 ELSE 0 END) AS total_conversions,
    SUM(CASE WHEN lid.call_status = 'successful' THEN 1 ELSE 0 END) AS successful_calls,
    AVG(dwd.watched_percentage) AS avg_demo_watched_percentage,
    GROUP_CONCAT(lrni.reasons_for_not_interested_in_demo, ', ', 
                 lrni.reasons_for_not_interested_to_consider, ', ', 
                 lrni.reasons_for_not_interested_to_convert) AS reasons_for_no_interest
FROM 
    leads_interaction_details lid
LEFT JOIN 
    leads_demo_watched_details dwd 
    ON lid.lead_id = dwd.lead_id
LEFT JOIN 
    leads_reasons_for_no_interest lrni 
    ON lid.lead_id = lrni.lead_id
GROUP BY 
    lid.lead_stage;

    
