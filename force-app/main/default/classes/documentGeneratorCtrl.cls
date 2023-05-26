/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-08-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class documentGeneratorCtrl {
    public static String base64String{get;set;}
    public static String instantValues{get;set;}
    public static String templateId{get;set;}
    public static String record{get;set;}
    public static List<String> readOnlyFields{get;set;}
    public static List<String> requiredFields{get;set;}
    public static String logId{get;set;}
    public static String licensekey{get;set;}

    @AuraEnabled(cacheable = true)
    public static Map<String, Object> getListOfTemplate(Map<String, Object> mapInputParams){
        Map<String, Object> mapOutputParams = new Map<String,Object>();
        try {
            Id iRecordId = mapInputParams.containsKey('recordId')?(Id)mapInputParams.get('recordId'):null;
            if(iRecordId != NULL){
                mapOutputParams.put('isSuccess', true);
                String sObjectName = String.valueOf(iRecordId.getSobjectType());
                List<Document_Template__c> lstDocumentTemplate = new List<Document_Template__c>();
                lstDocumentTemplate = [Select Id, Document_Title__c from Document_Template__c Where Template_Type__c =: sObjectName];
                Map<String, String> mapTemplateId = new Map<String, String>();
                if(!lstDocumentTemplate.isEmpty() && lstDocumentTemplate != null){
                    for(Document_Template__c objTemp : lstDocumentTemplate){
                        mapTemplateId.put(objTemp.Document_Title__c, objTemp.Id);
                    }
                    mapOutputParams.put('templateDetails', mapTemplateId);
                }
            }
            
        } catch (Exception e) {
            mapOutputParams.put('isSuccess', false);
            mapOutputParams.put('errorMessage', e.getMessage());
        }
        return mapOutputParams;
    }
    @AuraEnabled
    public static Map<String, Object> generateDocument(Map<String, Object> mapInputParams){
        String sTemplateId= (String)mapInputParams.get('templateId');
        String sRecordId = (String)mapInputParams.get('recordId');
        Boolean bViewScreen = (Boolean)mapInputParams.get('isViewScreen');
        Map<String, String> mapFieldValue = new Map<String, String>();
        Map<String, Object> mapOutputParams = new Map<String, Object>();
        List<String> lstReadOnlyFields = new List<String>();
        List<String> lstRequiredFields = new List<String>();
        List<String> lstGenerationRequiredFields = new List<String>();
        mapOutputParams.put('isSuccess', true);
        try{
        if(sTemplateId != NULL){
            
            List<Data_Mapping__c> lstMapping = [SELECT Id, Document_Template__c, Document_Template__r.Salesforce_File_Id__c, Template_Field__c, Salesforce_Field_API_Name__c,
                                                Document_Submission_Read_Only__c,Document_Submission_Required__c,Is_Required__c  from Data_Mapping__c 
                                                Where isActive__c = true AND Document_Template__c =: sTemplateId];
            if(!lstMapping.isEmpty()){
                Set<String> setFields = new Set<String>();
                for(Data_Mapping__c objMap : lstMapping){
                    if(objMap != NULL){
                    if(objMap.Document_Submission_Read_Only__c){
                        lstReadOnlyFields.add(objMap.Template_Field__c);
                    }
                    if(objMap.Document_Submission_Required__c){
                        lstRequiredFields.add(objMap.Template_Field__c);
                    }
                    if(objMap.Is_Required__c){
                        lstGenerationRequiredFields.add(objMap.Salesforce_Field_API_Name__c);
                    }
                    setFields.add(objMap.Salesforce_Field_API_Name__c);
                    mapOutputParams.put('sFileId', objMap.Document_Template__r.Salesforce_File_Id__c);
                    }
                } 
                if(bViewScreen){
                    String sLogId = (String)mapInputParams.get('logId');
                    Document_Generation_Log__c objLog = [Select Id, Latest_ContentVersion_Id__c from Document_Generation_Log__c Where Id =: sLogId][0];
                    mapOutputParams.put('sFileId', objLog.Latest_ContentVersion_Id__c);
                }
                mapOutputParams.put('readOnlyField', lstReadOnlyFields);
                mapOutputParams.put('requiredField', lstRequiredFields);
                if(!setFields.isEmpty() && sRecordId != NULL && sRecordId != ''){
                    Boolean bRequiredValuesPresent = true;
                    String sObjName = Id.valueOf(sRecordId).getSObjectType().getDescribe().getName();
                    String sQuery = 'Select Id,'+String.join(new List<String>(setFields),', ')+' FROM '+sObjName+' Where Id=\''+sRecordId+'\'';
                    sObject objData = Database.query(sQuery)[0];
                    List<String> lstNullFields = new List<String>();
                    system.debug('Data : '+objData);
                    Map<String, String> mapAPIValue = new Map<String, String>();
                    for(String sField :setFields){
                        if(lstGenerationRequiredFields.contains(sField)){
                            system.debug('Field : '+sField);
                            system.debug('Field : '+objData.get(sField));
                            if(objData.get(sField) != NULL){
                                
                                mapAPIValue.put(sField, String.valueOf(objData.get(sField))); 
                            } else {
                               String sFieldLabel = getFieldLabel(sObjName, sField);
                               lstNullFields.add(sFieldLabel);
                            }                           
                        } else {
                            if(objData.get(sField) != NULL){
                                mapAPIValue.put(sField, String.valueOf(objData.get(sField))); 
                            } else {    
                                mapAPIValue.put(sField, ''); 
                            }

                        }
                       
                    }
                    for(Data_Mapping__c objMap : lstMapping){
                    	 mapFieldValue.put(objMap.Template_Field__c, mapAPIValue.get(objMap.Salesforce_Field_API_Name__c));
                	}

                    mapOutputParams.put('dataMap', mapFieldValue);  
                    if(!lstNullFields.isEmpty()){
                        String sFieldList = String.join(lstNullFields, ',');
                        mapOutputParams.put('isSuccess', false);
                        mapOutputParams.put('errorMessage', sFieldList +' Fields are not populated, We will not be able to generate form.');
                    }
                }                
            }
        }
        } catch(Exception ex){
            mapOutputParams.put('isSuccess', false);
            mapOutputParams.put('errorMessage', ex.getMessage());
        }
        return mapOutputParams;
    }
    
    
    //Custom Methods
    public String getTemplateData(){
        try{
        String sContext = ApexPages.currentPage().getParameters().get('context');
        if(sContext == 'Generation'){
            String sTemplateId = '';
            String sRecordId = ApexPages.currentPage().getParameters().get('sRecordId');

            String sObj = Id.valueOf(sRecordId).getSobjectType().getDescribe().getName();
            Map<String, Object> mapData = new Map<String, Object>();

            if(sObj != 'Document_Generation_Log__c'){                
                sTemplateId = ApexPages.currentPage().getParameters().get('sTemplateId');
                templateId = sTemplateId;
                record = sRecordId;
                mapData = generateDocument(new Map<String, Object>{'templateId'=> sTemplateId, 'recordId'=> sRecordId, 'isViewScreen' => false});
            } else {
                Document_Generation_Log__c objLog = [Select Id, Template_Record__c, Salesforce_Record_Id__c from Document_Generation_Log__c Where ID =: sRecordId][0];
                templateId = objLog.Template_Record__c;
                record = objLog.Salesforce_Record_Id__c;
                logId = sRecordId;
                mapData = generateDocument(new Map<String, Object>{'templateId'=> templateId, 'recordId'=> record, 'logId'=> sRecordId, 'isViewScreen' => true});
            }
            
            if((Boolean)mapData.get('isSuccess')) {
                //Get File Record
                ContentVersion objCV = [SELECT Id, VersionData FROM contentVersion WHERE Id = :(Id)mapData.get('sFileId')][0];
            	base64String = EncodingUtil.Base64Encode(objCV.VersionData);
                String sJSONString = JSON.serialize(getInstantJSON((Map<String, String>)mapData.get('dataMap')));
                sJSONString = sJSONString.replaceAll('"', '\'');
                instantValues = sJSONString;
                readOnlyFields = (List<String>)mapData.get('readOnlyField');
                requiredFields = (List<String>)mapData.get('requiredField');
                if(System.Label.pspdfKit_LicenseKey == 'demo'){
                    licensekey = '';
                } else {
                    licensekey = System.Label.pspdfKit_LicenseKey;

                }
                
            } else {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,(String)mapData.get('errorMessage')));
                return 'Error:'+(String)mapData.get('errorMessage');
            }        
            
        } else {
            return 'Error:Not a valid Context';
        }
        } catch(Exception e){
            return 'Error:'+e.getMessage();
        }
        return 'Success'; 
    }
    
    public static Map<String,String>  getInstantJSON(Map<String, String> mapData){
        Map<String,String> fields = new Map<String,String>();
        for(String sKey : mapData.keySet()){
            if(mapData.get(sKey) != NULL){
                fields.put(sKey, mapData.get(sKey));
            }            
        }        
        return fields;
    }
    
    public class fieldWrapper {
        public string name;
        public string type;
        public integer v;
        public string value;
    }

    @AuraEnabled
    public static Map<String, Object> insertRecord(Map<String, Object> mapInputParams){
        Map<String, Object> mapOutputParams = new Map<String, Object>();
        try{
        String sLogId = (String)mapInputParams.get('logId');   
        String sTemplateId = (String)mapInputParams.get('templateId');
        String sRecordId = (String)mapInputParams.get('recordId');
        String sBase64String = (String)mapInputParams.get('base64String');
       	Map<Object, Object> mapFieldData = (Map<Object, Object>)mapInputParams.get('fieldMap');

		Map<String, String> mapFieldAPI = new Map<String, String>();
        Map<String, String> mapFieldValues = new Map<String, String>();
        Set<String> sFormValues = new Set<String>();
            
        for(Object obj : mapFieldData.keySet()){
            system.debug('obj: '+obj);
            mapFieldValues.put((String)obj, (String)mapFieldData.get(obj));
            
        } 
        List<Data_Mapping__c> lstMapping = [SELECT Id, Template_Field__c, Salesforce_Field_API_Name__c FROM Data_Mapping__c WHERE Document_Template__c =: sTemplateId AND Template_Field__c IN: mapFieldValues.keySet()];

        for(Data_Mapping__c objMap :lstMapping){
            mapFieldAPI.put(objMap.Template_Field__c, objMap.Salesforce_Field_API_Name__c);
        }
            
        sObject sObj = Id.valueOf(sRecordId).getSobjectType().newSObject(sRecordId);
        sObj.put('Id', sRecordId);
            
        for(Object sKey : mapFieldValues.keySet()){
            if(mapFieldAPI.get((String)sKey) != NULL){
                sObj.put(mapFieldAPI.get((String)sKey), mapFieldValues.get((String)sKey));
            }            
        } 
        update sObj;

        Document_Generation_Log__c objLog = [Select Id, Complete_Log__c, Current_Signer_Count__c, Template_Record__c, Latest_ContentVersion_Id__c FROM Document_Generation_Log__c WHERE Id =: sLogId][0];
        objLog.Complete_Log__c = 'Document Signed by '+UserInfo.getName()+' at '+System.now()+'.\n'+objLog.Complete_Log__c;
        objLog.Current_Signer_Count__c = objLog.Current_Signer_Count__c+1;
        update objLog;
            
            
       	Document_Template__c objTemplate = [Select Id, Document_Title__c from Document_Template__c Where Id =: objLog.Template_Record__c][0];
        ContentVersion objCV = [Select Id, ContentDocumentId from ContentVersion Where Id =: objLog.Latest_ContentVersion_Id__c][0];

        ContentVersion cv = new ContentVersion();
        cv.Title = objTemplate.Document_Title__c+'.pdf';
        cv.PathOnClient = objTemplate.Document_Title__c+'.pdf';
        cv.VersionData = EncodingUtil.base64Decode(sBase64String);
        cv.IsMajorVersion = true;
        cv.ContentDocumentId = objCV.ContentDocumentId;
        Insert cv;
            
        docGenLogTriggerHandler.bByPassTrigger = true;
        objLog.Latest_ContentVersion_Id__c = cv.Id;
        update objLog;
        docGenLogTriggerHandler.bByPassTrigger = false;

        mapOutputParams.put('Success', true);
        mapOutputParams.put('LogId', objLog.ID);


    } catch(Exception ex){
        mapOutputParams.put('Success', false);
        mapOutputParams.put('ErrorMessage', ex.getMessage());
    }


    return mapOutputParams;
    }
    
    @AuraEnabled
    public static Map<String, Object> createDocument(Map<String, Object> mapInputParams){
        Map<String, Object> mapOutputParams = new Map<String, Object>();
        try{
        	String sTemplateId = (String)mapInputParams.get('templateId');
        	String sRecordId = (String)mapInputParams.get('recordId');
        	String sBase64String = (String)mapInputParams.get('base64String');
       		Document_Template__c objTemplate = [Select Id, Document_Title__c, Document_Require_E_Signature__c, Salesforce_File_Id__c, (Select Id,Signer_Email__c from Document_Signers__r) from Document_Template__c Where Id =: sTemplateId][0];
            
        	Document_Generation_Log__c objLog = new Document_Generation_Log__c();
        	objLog.Salesforce_Record_Id__c = sRecordId;
        	objLog.Status__c = 'Initiated';
        	objLog.Template_Record__c = sTemplateId;
        	insert objLog; 

        	ContentVersion cv = new ContentVersion();
        	cv.Title = objTemplate.Document_Title__c+'.pdf';
        	cv.PathOnClient = objTemplate.Document_Title__c+'.pdf';
        	cv.VersionData = EncodingUtil.base64Decode(sBase64String);
        	cv.IsMajorVersion = true;
        	cv.firstPublishLocationId = objLog.ID; 
        	Insert cv;
            
        	docGenLogTriggerHandler.bByPassTrigger = true;
        	objLog.Latest_ContentVersion_Id__c = cv.Id;
        	update objLog;        
        	docGenLogTriggerHandler.bByPassTrigger = false;
            
        	Document_Generation_Log__c objUpdatedLog = [Select Salesforce_Record_Id__c,Status__c,Template_Record__c,
                                                    	Document_Require_E_Signature__c,Current_Signer_Count__c,
                                                    	Post_Processing_Email__c,Signer_Name__c,Signer_Email__c,
                                                    	Latest_ContentVersion_Id__c ,Post_Signature_Processing__c,Complete_Log__c  
                                                    	FROM Document_Generation_Log__c WHERE ID =: objLog.Id LIMIT 1][0];
        	docGenLogTriggerHandler.initiateLifeCycle(new List<Document_Generation_Log__c>{objUpdatedLog});
        
        	mapOutputParams.put('Success', true);
        	mapOutputParams.put('LogId', objLog.Id);

    	} catch(Exception ex){
        	mapOutputParams.put('Success', false);
        	mapOutputParams.put('ErrorMessage', ex.getMessage());
    	}

	    return mapOutputParams;
    }

    public static String getFieldLabel(String objectName, String fieldName) {
    	String fieldLabel = '';
    	Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
    	Schema.SObjectType objectType = gd.get(objectName);
    	if (objectType != null) {
        	Schema.DescribeSObjectResult objDescribe = objectType.getDescribe();
        	Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();
        	Schema.SObjectField field = fields.get(fieldName);
        	if (field != null) {
            	fieldLabel = field.getDescribe().getLabel();
        	}
    	}
    	return fieldLabel;
	}
    
    public static Map<String, Object> encodeDecodeURL(Map<String, Object> mapInputParams) {
    	Map<String, Object> mapOutputParam = new Map<String, Object>();
    	String sOperation = mapInputParams.containsKey('operation')? (String)mapInputParams.get('operation'):null;
    		if(sOperation == 'encode'){
            	String sRecordId = mapInputParams.containsKey('recordId')? (String)mapInputParams.get('recordId'):null;
            	mapOutputParam.put('param', EncodingUtil.convertToHex(Blob.valueOf(sRecordId)));
        	} else if (sOperation == 'decode'){
            	String param = mapInputParams.containsKey('param')? (String)mapInputParams.get('param'):null;
            	Blob blobData = EncodingUtil.convertFromHex(param);
            	String sRecordId = blobData.toString();
            	mapOutputParam.put('recordid', sRecordId); 
        	} 
        return mapOutputParam;
	}

    @AuraEnabled(cacheable=true)
    public static string viewDocument(Map<String, Object> mapInputParams){
        try {
            String sParam = mapInputParams.containsKey('urlParam')?(String)mapInputParams.get('urlParam'):null;
            Map<String, Object> mapOutputParams = encodeDecodeURL(new Map<String, Object>{'operation' => 'decode', 'param' => sParam});
            return (String)mapOutputParams.get('recordid');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());            
        }        
    }
    
    @AuraEnabled
    public static Boolean generateOTP(Map<String, Object> mapInputParams){
        try {
            String sParam = mapInputParams.containsKey('urlParam')?(String)mapInputParams.get('urlParam'):null;
            Object sIPAdr = mapInputParams.containsKey('devDetails')?(Object)mapInputParams.get('devDetails'):null;
            
            Map<String, Object> mapOutputParams = encodeDecodeURL(new Map<String, Object>{'operation' => 'decode', 'param' => sParam});
            Id iRecordId = (Id)mapOutputParams.get('recordid');
            String iPIN = generateRandomNumber(6);
            Document_Generation_Log__c objLog = [Select Id, One_Time_Password__c, OTP_Request_Time__c, Signer_Name__c, Complete_Log__c from Document_Generation_Log__c WHERE Id=: iRecordId][0];
            objLog.Id = iRecordId;
            objLog.One_Time_Password__c = iPIN;
            objLog.OTP_Request_Time__c = System.now();
            objLog.Complete_Log__c = 'OTP Requested by '+objLog.Signer_Name__c+' from '+JSON.serialize(sIPAdr)+' at '+system.now()+'.\n'+objLog.Complete_Log__c ;
            
            Log_Records__c objLogRecord = new Log_Records__c();
           	objLogRecord.Type__c = 'OTP Requested';
            objLogRecord.Document_Generation_Log__c = iRecordId;
            objLogRecord.Additional_Information__c ='Signer Name: '+objLog.Signer_Name__c+'\n Device Details:'+JSON.serialize(sIPAdr);
            insert objLogRecord;
            
            docGenLogTriggerHandler.bByPassTrigger = true;
            update objLog;
            docGenLogTriggerHandler.bByPassTrigger = false;
            sendOTP(iRecordId, iPIN);
            return true;       
        } catch (Exception e) {
            system.debug('Error: '+e.getMessage());
            return false;
        }        
    }
    
    public static void sendOTP(Id iRecordId, String sOTP){             
            List<Messaging.SingleEmailMessage> lstEmailsToSend = new List<Messaging.SingleEmailMessage>();  
         	EmailTemplate emTemp = [Select Id, HTMLValue, Subject from EmailTemplate Where Name = 'Document Generation- Template for Sending OTP'][0];
            Document_Generation_Log__c objLog =[Select Id,Signer_Email__c From Document_Generation_Log__c WHERE Id =:iRecordId][0];
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{objLog.Signer_Email__c});
			String sHTMLBody = emTemp.HTMLValue;
            sHTMLBody = sHTMLBody.replaceAll('One_Time_Password', sOTP);
            mail.setHtmlBody(sHTMLBody);
            mail.setSubject(emTemp.Subject);
            mail.setSubject('Your One-Time Password is here.');
        	lstEmailsToSend.add(mail);
        	if(!lstEmailsToSend.isEmpty()){
            	Messaging.sendEmail(lstEmailsToSend);
        	}
    }
    
    @AuraEnabled
    public static Map<String, Object> validateOTP(Map<String, Object> mapInputParams){
        Map<String, Object> mapOutputParams = new Map<String, Object>(); 
        
        String sParam = mapInputParams.containsKey('urlParam')?(String)mapInputParams.get('urlParam'):null;
        String sPIN = mapInputParams.containsKey('sPIN')?(String)mapInputParams.get('sPIN'):null;
        Object sIPAdr = mapInputParams.containsKey('devDetails')?(Object)mapInputParams.get('devDetails'):null;
        Map<String, Object> mapURLParams = encodeDecodeURL(new Map<String, Object>{'operation' => 'decode', 'param' => sParam});
        Id iRecordId = (Id)mapURLParams.get('recordid');
        
        if(iRecordId != NULL){
            Document_Generation_Log__c objLog =[Select Id,One_Time_Password__c,OTP_Request_Time__c, Complete_Log__c,Signer_Name__c,Signer_Email__c From Document_Generation_Log__c WHERE Id =:iRecordId][0];            
            
            Boolean timeDifference = isWithinTimeLimit(objLog.OTP_Request_Time__c, system.now());
            if(!timeDifference){
               objLog.Complete_Log__c = 'OTP Verification failed for '+objLog.Signer_Name__c+' at '+system.now()+' using device '+JSON.serialize(sIPAdr)+'.\n'+objLog.Complete_Log__c;
                Log_Records__c objLogRecord = new Log_Records__c();
           		objLogRecord.Type__c = 'OTP Verification Failed';
            	objLogRecord.Document_Generation_Log__c = iRecordId;
            	objLogRecord.Additional_Information__c ='Signer Name: '+objLog.Signer_Name__c+'\nSigner Email: '+objLog.Signer_Email__c+'\n Device Details:'+JSON.serialize(sIPAdr)+'\nReason: OTP Expired \nOTP Requested at: '+objLog.OTP_Request_Time__c+'\nOTP Entered at: '+System.now();
            	insert objLogRecord;
               mapOutputParams.put('verification', false);
               mapOutputParams.put('error', 'Your last OTP is expired, Please request new OTP.');
            } else if(objLog.One_Time_Password__c != sPIN){
                objLog.Complete_Log__c = 'OTP Verification failed for '+objLog.Signer_Name__c+' at '+system.now()+' using device '+JSON.serialize(sIPAdr)+'.\n'+objLog.Complete_Log__c;
                Log_Records__c objLogRecord = new Log_Records__c();
           		objLogRecord.Type__c = 'OTP Verification Failed';
            	objLogRecord.Document_Generation_Log__c = iRecordId;
            	objLogRecord.Additional_Information__c ='Signer Name: '+objLog.Signer_Name__c+'\nSigner Email: '+objLog.Signer_Email__c+'\n Device Details:'+JSON.serialize(sIPAdr)+'\nReason: Wrong OTP Entered \nOTP Requested at: '+objLog.OTP_Request_Time__c+'\nOTP Entered at: '+System.now();
            	insert objLogRecord;
                mapOutputParams.put('verification', false);
               	mapOutputParams.put('error', 'OTP didnot matched.');
            } else if(objLog.One_Time_Password__c == sPIN) {
                Log_Records__c objLogRecord = new Log_Records__c();
           		objLogRecord.Type__c = 'OTP Verified';
            	objLogRecord.Document_Generation_Log__c = iRecordId;
            	objLogRecord.Additional_Information__c ='Signer Name: '+objLog.Signer_Name__c+'\nSigner Email: '+objLog.Signer_Email__c+'\n Device Details:'+JSON.serialize(sIPAdr);
            	insert objLogRecord;
                objLog.Complete_Log__c = 'OTP Verified by '+objLog.Signer_Name__c+' at '+system.now()+' using device '+JSON.serialize(sIPAdr)+'.\n'+objLog.Complete_Log__c;
                mapOutputParams.put('verification', true);
            }
            docGenLogTriggerHandler.bByPassTrigger = true;
            update objLog;
            docGenLogTriggerHandler.bByPassTrigger = false;
        }
          return mapOutputParams;          
    }
    
    public static String generateRandomNumber(Integer length) {
        String result = '';
        while(result.length() < length) {
           result += String.valueOf(Math.abs(Crypto.getRandomLong()));
        }
        return result.substring(0,length);
    }
    
    public static Boolean isWithinTimeLimit(DateTime dateTime1, DateTime dateTime2) {
    	Long diffInMilliseconds = Math.abs(dateTime1.getTime() - dateTime2.getTime());
    	Long diffInMinutes = (diffInMilliseconds / 1000) / 60;
    	return diffInMinutes <= 1;
	}

}