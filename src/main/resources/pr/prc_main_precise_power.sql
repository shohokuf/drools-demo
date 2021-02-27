CREATE DEFINER=`root`@`%` PROCEDURE `prc_main_precise_power`(
    IN `i_form_inst_id` int,
    IN `i_ins_proc_id` int,
    IN `i_ins_node_id` int,
    IN `i_proc_id` int,
    IN `i_decision` int
)
label:BEGIN
    declare v_ins_cnt        int default 0;
    declare v_ins_proc_id    varchar(40);
    declare v_json           JSON; 
    declare v_json1           JSON; 
    declare vItemKey         varchar(200);
    declare vData            text;
    declare vRecLen          int default 0;
    declare i                int;
    declare vKeyTmp          varchar(128);
    declare vRecData,recTmp  varchar(4000);
    declare v_ins_node_id    varchar(40);
    declare v_cur_time       datetime;
    declare v_send_year      varchar(4);
    declare v_send_month     varchar(2);
    declare v_send_day       varchar(2); 
    declare is_auto          varchar(12) default "false"; 
    
    declare v_keys              json;
    declare v_extract_k         varchar(20);
    declare v_extract_v         varchar(100);
    declare v_element_key       varchar(100);
    declare v_element_value     varchar(1000);
    declare v_element_json      varchar(1000);
    declare v_num               int;
    declare v_count             int;
    
    declare v_auto_tile            varchar(1000); 
    declare v_auto_specialty       varchar(500);  
    declare v_auto_city            varchar(500);  
    declare v_auto_county          varchar(500);  
    declare v_auto_urgent_level    varchar(500);  
    declare v_auto_region_feat     varchar(500);  
    declare v_auto_sheet_tile1     varchar(500); 
    declare v_ne_id                varchar(500);
    declare v_city_name            varchar(100);
    declare v_county_name          varchar(100);
    declare v_special_name         varchar(100);

    declare v_archive_flag         int default 0;

    
    
    declare flag_resignal       tinyint default 1;       
    declare CONTINUE handler for SQLWARNING, SQLEXCEPTION
        begin
            if flag_resignal then
                resignal;
            end if;
        end;

    select count(*) into v_archive_flag from bpm_ins_node_t a ,bpm_def_node_t b
	where a.proc_id=b.proc_id and a.node_id=b.node_id and a.proc_id=82  and a.ins_proc_id=i_ins_proc_id 
	and a.ins_node_id= i_ins_node_id and b.node_name like '%归档' ;
     
    set v_ins_proc_id =  convert(i_ins_proc_id , CHAR);    
    select count(*) into v_ins_cnt from bp_precise_power_main a where a.id=v_ins_proc_id;   
    if v_ins_cnt = 0 then
        set flag_resignal = 0;
        insert into bp_precise_power_main(id,status,end_statisfact,is_deleted,ins_proc_id,is_template,
         send_year,send_month,send_day,is_upload_files,is_overtime,is_chargeing,is_fault_sheet,room_direct_load) 
        values( v_ins_proc_id, 0, 0, 0, v_ins_proc_id, 0, 0, 0, 0, 0, 0, '1', 0, 0);
        set flag_resignal = 1;

        set v_json1 = null;
        
        select count(*) into v_num from bpm_ins_proc_ext_t t where t.ins_proc_id = i_ins_proc_id;
        if v_num > 0 then       
            select data_json into v_json1 from bpm_ins_proc_ext_t where ins_proc_id = i_ins_proc_id;        
            if v_json1 is not null and LENGTH(trim(v_json1))>0 then
                set v_json = JSON_EXTRACT(v_json1, '$.data_transform');
                set v_num = JSON_LENGTH(v_json);
                set v_keys = JSON_KEYS(v_json);

                set i = 0;     
                set v_auto_tile="";
                set is_auto=true;
                while i < v_num do
                    set v_extract_k = concat('$[', i, ']');
                    set v_element_key = JSON_UNQUOTE(JSON_EXTRACT(v_keys, v_extract_k)); 
                    set v_extract_v = concat('$.', v_element_key);
                    set v_element_value = JSON_UNQUOTE(JSON_EXTRACT(v_json, v_extract_v)); 

                    if v_element_key = 'alarmDesc' then
                        update bp_precise_power_main 
                        set task_remark=case when length(v_element_value)>=2000 then substring(v_element_value,1,2000) else v_element_value end
                        where id=v_ins_proc_id; 
                    end if;
					if v_element_key = 'alarmRegion' then
                        update bp_precise_power_main
						set city_id1  = case when length(v_element_value)>=4 then substring(v_element_value,1,4) else null end
						where id=v_ins_proc_id; 
					end if;
					if v_element_key = 'alarmCounty' then 
                        update bp_precise_power_main
						set city_id1  = case when length(v_element_value)>=4 then substring(v_element_value,1,4) else null end,
						    county_id1= case when length(v_element_value)>=6 then substring(v_element_value,1,6) else null end
						where id=v_ins_proc_id; 
					end if;
                    if v_element_key = 'MaintenanceUnit' then
                        update bp_precise_power_main set assign_group_id=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'alarmSerialNum' then
                        update bp_precise_power_main set alarm_id=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'neId' then
                        set v_ne_id=v_element_value;
                        update bp_precise_power_main set resources_id=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'neName' then
                        update bp_precise_power_main set resources_name=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'alarmDetectTime' and v_element_value is not null and length(v_element_value)>=10 then
                        update bp_precise_power_main set power_cut_time=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'urgentLevel' then
                        update bp_precise_power_main set urgent_level=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'isFaultSheet' then
                        update bp_precise_power_main set is_fault_sheet=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'eoms_id' then
                        update bp_precise_power_main set eoms_id=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'eoms_title'  then
                        update bp_precise_power_main set eoms_title=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'title' then
                        update bp_precise_power_main set eoms_title=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'eoms_sheet_id' then
                        update bp_precise_power_main set eoms_sheet_id=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'eomsTitle' then
                        update bp_precise_power_main set eoms_title=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if v_element_key = 'sheetId' then
                        update bp_precise_power_main set sheet_no=v_element_value where id=v_ins_proc_id; 
                    end if;
                    if vItemKey = 'sendTime'  and v_element_value is not null and length(v_element_value) >= 10 then
                        set v_send_year = substring(v_element_value,1,4);
                        set v_send_month = substring(v_element_value,6,2);
                        set v_send_day = substring(v_element_value,9,2);
                        update bp_precise_power_main set send_year=v_send_year,send_month=v_send_month,send_day=v_send_day where id = v_ins_proc_id;
                    end if;
                    if vItemKey = 'acceptLimit' and v_element_value is not null and length(v_element_value) >= 10 then
                        update bp_precise_power_main set accept_limit=v_element_value where id = v_ins_proc_id;
                    end if;
                    if vItemKey = 'finishLimit' and v_element_value is not null and length(v_element_value) >= 10 then
                        update bp_precise_power_main set finish_limit=v_element_value where id = v_ins_proc_id;
                    end if;
                    if vItemKey = 'alarmId' then
                        update bp_precise_power_main set alarm_id=v_element_value where id = v_ins_proc_id;
                    end if;

                    set i = i + 1;
                end while;
                select date_format(now(), '%Y'),date_format(now(), '%m'),date_format(now(), '%d') into v_send_year,v_send_month,v_send_day;
                update bp_precise_power_main 
                set send_year=v_send_year,send_month=v_send_month,send_day=v_send_day,send_time=now()
                where id = v_ins_proc_id and send_time is null;
				update bp_precise_power_main set is_auto="true" where id = v_ins_proc_id and is_auto is null;
                
                if v_ne_id is not null  then 
                    update bp_precise_power_main a, bs_basicres_cfg b
                    set a.specialty1=b.specialty,  a.longitude=b.longitude, a.latitude=b.latitude,
                        a.city_id1  = case when a.city_id1 is null then b.city else a.city_id1 end,
						a.county_id1= case when a.county_id1 is null then b.county else a.county_id1 end,
						a.region_features1=b.area_type, a.res_power_flag=b.power
                    where a.resources_id=b.id and b.id=v_ne_id and a.id = v_ins_proc_id;
                end if;
                    
				
				update  bp_precise_power_main a, sys_busi_dict b 
				set a.specialty = concat('{\"value\":\"',a.specialty1,'\",\"label\":\"',b.dict_name,'\",\"key\":\"',a.specialty1,'\"}')
				where a.specialty1=b.dict_id and b.parent_dictid='11225' and a.id = v_ins_proc_id;
				
				
				
				update  bp_precise_power_main a, sys_busi_area b,sys_busi_area c
				set a.city = concat('{\"label\":\"',b.area_name,'\",\"value\":\"',a.city_id1,'\",\"key\":\"',a.city_id1,'\"}'),
					a.county = concat('{\"label\":\"',c.area_name,'\",\"value\":\"',a.county_id1,'\",\"key\":\"',a.county_id1,'\"}')
				where a.city_id1=b.area_id and a.county_id1=c.area_id  and a.id = v_ins_proc_id;
				
				
				update  bp_precise_power_main a, sys_busi_dict b 
				set a.specialty = concat('{\"value\":\"',a.region_features1,'\",\"label\":\"',b.dict_name,'\",\"key\":\"',a.region_features1,'\"}')
				where a.region_features1=b.dict_id and b.parent_dictid='11230' and a.id = v_ins_proc_id;
                select a.area_name into v_city_name   from sys_busi_area a,bp_precise_power_main b where b.city_id1=a.area_id   and b.id = v_ins_proc_id;
                select a.area_name into v_county_name from sys_busi_area a,bp_precise_power_main b where b.county_id1=a.area_id and b.id = v_ins_proc_id;
                select b.dict_name into v_special_name from bp_precise_power_main a, sys_busi_dict b 
				where a.specialty1=b.dict_id and b.parent_dictid='11225' and a.id=v_ins_proc_id;

                
                update bp_precise_power_main a
                set title  =  concat('{\"templateValue\":\"', DATE_FORMAT(send_time, '%Y%m%d'), v_city_name,v_county_name,
                            v_special_name, ', \"customValue\":\"', a.resources_name,'\"}'),
                    sheet_title1 = concat(DATE_FORMAT(send_time, '%Y%m%d'),v_city_name,v_county_name,v_special_name, a.resources_name)
                where id = v_ins_proc_id ;              
            else
                set is_auto="false";
            end if;
        
        end if;
        
        if exists(select 1 from bp_precise_power_main a where id = v_ins_proc_id and accept_limit is null and send_time is not null) then
            update bp_precise_power_main set accept_limit = date_add(send_time, interval 1 day), finish_limit = date_add(send_time, interval 3 day) 
            where id = v_ins_proc_id  ;
        end if;
    end if;
       
    set v_json = null;
    select form_items_data into v_json from frm_form_inst where id = i_form_inst_id;
    if v_json = null then 
        LEAVE label;
    end if;
    
    set vRecLen = JSON_LENGTH(v_json);  
		
		select vRecLen;
		
    set i = 0;
    while i < vRecLen do 
        set vKeyTmp = concat('$[',i,']'); 
        select JSON_EXTRACT(v_json, vKeyTmp) into recTmp;
        set vItemKey = recTmp->>'$.itemKey';
        set vData = recTmp->>'$.data';
				
				select vItemKey;
				select vData;
        
        if(ISNULL(vData)=1) or (LENGTH(trim(vData))=0) then 
            select vItemKey as '无数据';
        else
            if vItemKey = 'sheetId' then
                update bp_precise_power_main set sheet_no=vData where id = v_ins_proc_id;
            end if;
            if (vItemKey = 'sheetTitle' or vItemKey = 'title') and vData is not null then
                if is_auto='false' then
                    update bp_precise_power_main set title=vData, sheet_title1 = concat(vData->>'$.templateValue',vData->>'$.customValue') where id = v_ins_proc_id;
                end if;
            end if;
            if vItemKey = 'acceptLimit' then
                update bp_precise_power_main set accept_limit=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'finishLimit' then
                update bp_precise_power_main set finish_limit=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendOrgKind' then
                update bp_precise_power_main set send_org_kind=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendUserid' then
                update bp_precise_power_main set send_userid=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendPhone' then
                update bp_precise_power_main set send_phone=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sheetAttach' then
            update bp_precise_power_main set sheet_attach=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'endTime' then
                update bp_precise_power_main set end_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'endOpinion' then
                update bp_precise_power_main set end_opinion=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'status' then
                update bp_precise_power_main set status=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'endStatisfact' then
                update bp_precise_power_main set end_statisfact=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'endUserId' then
                update bp_precise_power_main set end_userId=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isDeleted' then
                update bp_precise_power_main set is_deleted=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'insProcId' then
                update bp_precise_power_main set ins_proc_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'templateName' then
                update bp_precise_power_main set template_name=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'parentSheetName' then
                update bp_precise_power_main set parent_sheet_name=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'parentSheetNo' then
                update bp_precise_power_main set parent_sheet_no=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'correlationKey' then
                update bp_precise_power_main set correlation_key=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'parentCorrelation' then
                update bp_precise_power_main set parent_correlation=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'toDeptid' then
                update bp_precise_power_main set to_deptid=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendDeptid' then
                update bp_precise_power_main set send_deptid=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendRoleid' then
                update bp_precise_power_main set send_roleid=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'endRoleid' then
                update bp_precise_power_main set end_roleid=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'endDeptid' then
                update bp_precise_power_main set end_deptid=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isTemplate' then
                update bp_precise_power_main set is_template=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'cancleReason' then
                update bp_precise_power_main set cancle_reason=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendYear' then
                update bp_precise_power_main set send_year=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendMonth' then
                update bp_precise_power_main set send_month=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendDay' then
                update bp_precise_power_main set send_day=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'parentTaskName' then
                update bp_precise_power_main set parent_task_name=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'invokeKind' then
                update bp_precise_power_main set invoke_kind=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendObjectJson' then
                update bp_precise_power_main set send_object_json=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'specialty' and vData is not null then
				if is_auto = 'false' then
                update bp_precise_power_main set specialty=vData,specialty1=vData->>'$.key' where id = v_ins_proc_id;
				end if;
            end if;
            if vItemKey = 'taskKind' and vData is not null then
				if is_auto = 'false' then
                update bp_precise_power_main set task_kind=vData,task_kind1 = vData->>'$.key' where id = v_ins_proc_id;
				end if;
            end if;
            if vItemKey = 'city' and vData is not null then
				if is_auto = 'false' then
                update bp_precise_power_main set city=vData,city_id1 = vData->>'$.key' where id = v_ins_proc_id;
				end if;
            end if;
            if vItemKey = 'county' and vData is not null then
				if is_auto = 'false' then
					update bp_precise_power_main set county=vData,county_id1 = vData->>'$.key' where id = v_ins_proc_id;
				end if;
            end if;
            if vItemKey = 'alarmCounty' then
                update bp_precise_power_main set county=vData,city = case when vData is null then null else substring(vData,1,4) end where id = v_ins_proc_id;
            end if;
            if vItemKey = 'resourceData' and vData is not null and  JSON_LENGTH(v_json) > 0 then
            update bp_precise_power_main set resource_data=vData where id = v_ins_proc_id;
                set recTmp = JSON_UNQUOTE(JSON_EXTRACT(vData, "$[0]"));
                update bp_precise_power_main set resources_id=recTmp->>'$.id'        where id = v_ins_proc_id;
                update bp_precise_power_main set resources_code=recTmp->>'$.id'      where id = v_ins_proc_id;
                update bp_precise_power_main set resources_name=recTmp->>'$.resName' where id = v_ins_proc_id;
                update bp_precise_power_main set task_location=recTmp->>'$.resName'  where id = v_ins_proc_id;
                update bp_precise_power_main set city_id1 =recTmp->>'$.city'         where id = v_ins_proc_id;
                update bp_precise_power_main set county_id1 =recTmp->>'$.county'     where id = v_ins_proc_id;
                update bp_precise_power_main set specialty1 =recTmp->>'$.specialty'  where id = v_ins_proc_id;
                update bp_precise_power_main set res_power_flag=recTmp->>'$.power'   where id = v_ins_proc_id;
                update bp_precise_power_main set region_features1=recTmp->>'$.areaType'  where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isUploadFiles' then
                update bp_precise_power_main set is_upload_files=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'taskRemark' then
                update bp_precise_power_main set task_remark=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'longitude' then
                update bp_precise_power_main set longitude=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'latitude' then
                update bp_precise_power_main set latitude=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'sendObject' then
                update bp_precise_power_main set send_object=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'singleTimeTotal' then
                update bp_precise_power_main set single_time_total=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'multiTimeTotal' then
                update bp_precise_power_main set multi_time_total=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'timeout' then
                update bp_precise_power_main set timeout=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isOvertime' then
                update bp_precise_power_main set is_overtime=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'backtime' then
                update bp_precise_power_main set backtime=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'powerCutTime' and vData is not null and length(vData)>0 then
                update bp_precise_power_main set power_cut_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isChargeing' then
                update bp_precise_power_main set is_chargeing=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'regionFeatures' and vData is not null then
				if is_auto = 'false' then
					update bp_precise_power_main set region_features=vData,region_features1=vData->>'$.key' where id = v_ins_proc_id;
				end if;
            end if;
            if vItemKey = 'urgentLevel' then
                update bp_precise_power_main set urgent_level=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'batteryLoad' then
                update bp_precise_power_main set battery_load=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'batteryVoltage' then
                update bp_precise_power_main set battery_voltage=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'batteryLife' then
                update bp_precise_power_main set battery_life=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'distanceTime' then
                update bp_precise_power_main set distance_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'readyTime' then
                update bp_precise_power_main set ready_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'safeTime' then
                update bp_precise_power_main set safe_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isFaultSheet' then
                update bp_precise_power_main set is_fault_sheet=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'faultSheetId' then
                update bp_precise_power_main set fault_sheet_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'resSiteKind' then
                update bp_precise_power_main set res_site_kind=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'eomsId' then
                update bp_precise_power_main set eoms_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'eomsSheetId' then
                update bp_precise_power_main set eoms_sheet_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'eomsTitle' then
                update bp_precise_power_main set eoms_title=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'cleanTime' then
                update bp_precise_power_main set clean_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fakeGenerdependency' then
                update bp_precise_power_main set fake_generdependency=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'generateStartTime' then
                update bp_precise_power_main set generate_start_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'generateEndTime' then
                update bp_precise_power_main set generate_end_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fgdStartCt' then
                update bp_precise_power_main set fgd_start_ct=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fgdNoCt' then
                update bp_precise_power_main set fgd_no_ct=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fgdStartAlarm8' then
                update bp_precise_power_main set fgd_start_alarm8=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fgdStartBfPowerCut' then
                update bp_precise_power_main set fgd_start_bf_power_cut=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fgdStartNoAlarm' then
                update bp_precise_power_main set fgd_start_no_alarm=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fgdEndNoAlarm' then
                update bp_precise_power_main set fgd_end_no_alarm=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'efficientGenericelec' then
                update bp_precise_power_main set efficient_genericelec=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'manualAuditResults' then
                update bp_precise_power_main set manual_audit_results=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isManualAudit' then
                update bp_precise_power_main set is_manual_audit=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isAutoAudit' then
                update bp_precise_power_main set is_auto_audit=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'autoAuditResults' then
                update bp_precise_power_main set auto_audit_results=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'autoAuditFailedReason' then
                update bp_precise_power_main set auto_audit_failed_reason=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'notAutoAuditReason' then
                update bp_precise_power_main set not_auto_audit_reason=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'recommendOilPowerful' then
                update bp_precise_power_main set recommend_oil_powerful=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'recommendOilPhase' then
                update bp_precise_power_main set recommend_oil_phase=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'gatingAlarmEtime' then
                update bp_precise_power_main set gating_alarm_etime=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilAlarmEtime' then
                update bp_precise_power_main set oil_alarm_etime=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilCleanTime' then
                update bp_precise_power_main set oil_clean_time=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilCode' then
                update bp_precise_power_main set oil_code=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilKind' then
                update bp_precise_power_main set oil_kind=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilCast' then
                update bp_precise_power_main set oil_cast=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'alarmId' then
                update bp_precise_power_main set alarm_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilStartAlarm20' then
                update bp_precise_power_main set oil_start_alarm20=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilEndAlarm20' then
                update bp_precise_power_main set oil_end_alarm20=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'auditSignMethod' then
                update bp_precise_power_main set audit_sign_method=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilAffiliatedUnit' then
                update bp_precise_power_main set oil_affiliated_unit=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'oilEnginePowerful' then
                update bp_precise_power_main set oil_engine_powerful=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'powerGeneratDuration' then
                update bp_precise_power_main set power_generat_duration=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'times' then
                update bp_precise_power_main set times=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'fee' then
                update bp_precise_power_main set fee=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'roomDirectLoad' then
                update bp_precise_power_main set room_direct_load=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'unitOilConsumption' then
                update bp_precise_power_main set unit_oil_consumption=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'settleOilConsumption' then
                update bp_precise_power_main set settle_oil_consumption=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'deptId' then
                update bp_precise_power_main set dept_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'deptName' then
                update bp_precise_power_main set dept_name=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'assignGroupId' then
                update bp_precise_power_main set assign_group_id=vData where id = v_ins_proc_id;
            end if;
            if vItemKey = 'isAuto' then
                update bp_precise_power_main set is_auto=vData where id = v_ins_proc_id;
            end if;
						if vItemKey = 'startSignTime' then
                update bp_precise_power_main set start_sign_time=vData where id = v_ins_proc_id;
            end if;
						if vItemKey = 'endSignTime' then
                update bp_precise_power_main set end_sign_time=vData where id = v_ins_proc_id;
            end if;
			if v_archive_flag>0 then
				if vItemKey = 'operationUser' then
					update bp_precise_power_main set end_user_id=vData where id = v_ins_proc_id;
				end if;
				if vItemKey = 'department' then
					update bp_precise_power_main set end_deptid=vData where id = v_ins_proc_id;
				end if;
				if vItemKey = 'role' then
					update bp_precise_power_main set end_roleid=vData where id = v_ins_proc_id;
				end if;
			end if;
        end if;
        set i = i + 1;
    end while;  
    update bp_precise_power_main a,bpm_ins_proc_t b
    set a.sheet_no=case when a.sheet_no is null then b.sheet_id else a.sheet_no end,
        a.send_userid=b.opt_person_id, a.send_deptid=b.opt_organization_id,
		a.send_time=case when a.send_time is null then b.create_time else a.send_time end,        
        a.accept_limit=case when a.accept_limit is null then date_add(b.create_time,INTERVAL 1 DAY) else a.accept_limit end,
        a.finish_limit=case when a.finish_limit is null then date_add(b.create_time,INTERVAL 3 DAY) else a.finish_limit end
    where a.ins_proc_id=b.ins_proc_id and a.id=v_ins_proc_id;

END