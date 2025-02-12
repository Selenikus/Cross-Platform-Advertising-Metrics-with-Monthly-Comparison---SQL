WITH combined_ads_data as( SELECT 
    	fabd.campaign_id,
    	fc.campaign_name,
   		fabd.ad_date, 
    	fa.adset_name, 
    	fabd.url_parameters , 
    	coalesce (fabd.spend , 0) as spend,
    	coalesce (fabd.impressions , 0) as impressions,
    	coalesce (fabd.reach , 0) as reach,
    	coalesce (fabd.clicks ,0) as clicks,
    	coalesce (fabd.leads , 0) as leads,
    	coalesce (fabd.value ,0) as value
    
    FROM facebook_ads_basic_daily fabd
    INNER JOIN 
        facebook_adset fa ON fa.adset_id = fabd.adset_id
    INNER JOIN 
    	facebook_campaign fc on fc.campaign_id = fabd.campaign_id 
        
    UNION
    
 SELECT 
        fc.campaign_id, 
        gabd.campaign_name,
        gabd.ad_date,
        gabd.adset_name ,
        gabd.url_parameters ,
        coalesce (gabd.spend,0) as spend, 
        coalesce (gabd.impressions ,0) as impressions,
        coalesce (gabd.reach ,0) as reach,
        coalesce (gabd.clicks,0) as clicks,
        coalesce (gabd.leads,0) as leads,
        coalesce (gabd.value,0) as value
       
    FROM 
        google_ads_basic_daily gabd 
    INNER JOIN 
        facebook_campaign fc ON fc.campaign_name = gabd.campaign_name),

  monthly_aggregated_data as (select 
  
  
  
  TO_CHAR(DATE_TRUNC('month', ad_date), 'YYYY-MM-DD') AS ad_month,
   
   CASE 
     WHEN LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&#$]+)'))  = 'nan' 
     THEN NULL
     ELSE LOWER(SUBSTRING(url_parameters, 'utm_campaign=([^&#$]+)')) 
     end as utm_campaign,
   

    SUM(spend) AS total_spend,
    SUM (impressions) AS total_impressions,
    SUM(clicks)  AS total_clicks, 
    SUM(value)  AS total_value,
   
  CASE 
	WHEN sum(cast(impressions as decimal)) =0 THEN NULL 
	ELSE 
	round(sum(cast(clicks as decimal )) /sum(cast(impressions
	AS decimal )) * 100,2)
	END AS CTR,
	
  CASE WHEN
	sum(cast(clicks as decimal)) =0  THEN NULL
	ELSE
	ROUND(SUM(cast(spend as decimal))/ SUM(cast(clicks as decimal)),2)
	END AS CPC,
	
  CASE WHEN
	sum(cast(impressions as decimal))= 0 THEN NULL
	ELSE
	Round((Sum(cast(spend as decimal)) / sum(cast(impressions as decimal)))*1000,2) 
	END AS CPM,
	
	ROUND(((SUM(cast(value as decimal)) - sum(cast(spend as decimal))) / nullif(sum(cast(spend as decimal)),0))*100,2)
    AS ROMI
    
    FROM  combined_ads_data  
    
    GROUP BY 
    
  	ad_month, utm_campaign)
  	
  	 SELECT 
   
   		ad_month,
   		utm_campaign,
   		total_spend,
   		total_impressions,
   		total_clicks,
   		total_value,
   		CTR,
   
   LAG (CTR) OVER(PARTITION BY utm_campaign ORDER BY ad_month) as prev_month_CTR ,
  
      	CONCAT(ROUND(((CTR - lag(CTR,1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / nullif(LAG (CTR,1) over(PARTITION BY utm_campaign ORDER BY ad_month),0) * 100),2),'%')
  
  		AS CTR_change_percent,
  		
   		CPC,
   
   LAG(CPC) OVER (PARTITION BY utm_campaign ORDER BY ad_month) AS prev_month_CPC,
   
   		CONCAT(ROUND(((CPC - LAG(CPC,1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / nullif(LAG(CPC,1) OVER (PARTITION BY utm_campaign ORDER BY ad_month),0)* 100),2),'%') 
   	
  		 AS CPC_change_percent,
   
   		CPM,
   
   LAG(CPM) OVER (PARTITION BY utm_campaign ORDER BY ad_month) AS prev_month_CPM,
   
   		CONCAT(ROUND(((CPM - LAG(CPM,1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / nullif(LAG(CPM) OVER (PARTITION BY utm_campaign ORDER BY ad_month),0) * 100),2),'%') 
   	
  		AS CPM_change_percent,
  		 
   		ROMI,
   
   LAG(ROMI) OVER (PARTITION BY utm_campaign ORDER BY ad_month) AS prev_month_ROMI,
   
    	CONCAT(ROUND(((ROMI - LAG(ROMI,1) OVER (PARTITION BY utm_campaign ORDER BY ad_month)) / nullif(LAG(ROMI) OVER (PARTITION BY utm_campaign ORDER BY ad_month),0) * 100),2),'%')
   	
  		AS ROMI_change_percent
  		 
  
   FROM  monthly_aggregated_data
  
   ORDER BY ad_month, utm_campaign;