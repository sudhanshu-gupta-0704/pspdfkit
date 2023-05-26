public class DocumentViewer {
    
    @AuraEnabled
    public static Map<String, Object> getTemplates(Map<String, Object> mapInputParams){
        String sRecordId = (String)mapInputParams.get('recordId');
        Map<String, Object> mapOutputVar = new Map<String, Object>();
        mapOutputVar.put('isSuccess', true);
        try{
            if(sRecordId != NULL){
                List<Object> lstFields = new List<Object>(); 
                String sObjName = Id.valueOf(sRecordId).getSObjectType().getDescribe().getName();
                List<Document_Template__c> lstTemplates = [Select Id,Document_Title__c from Document_Template__c Where Template_Type__c =: sObjName];
                if(!lstTemplates.isEmpty()){
                    for(Document_Template__c objTemp : lstTemplates){
                        dropDownOptions ddOptions = new dropDownOptions();
                        ddOptions.label = objTemp.Document_Title__c;
                        ddOptions.value = objTemp.Id;
                        lstFields.add(JSON.serialize(ddOptions));
                    }
                    if(!lstFields.isEmpty()){
                        mapOutputVar.put('dropDownOptions', lstFields);
                    }
                }
            }
        } catch(Exception ex){
            mapOutputVar.put('isSuccess', false);
            mapOutputVar.put('errorMsg', ex.getMessage());
        }
        return mapOutputVar;
    }
    
    public static void getTemplateDetails(Map<String, Object> mapInputParams){
        String sTemplateId= (String)mapInputParams.get('TemplateId');
        String sRecordId = (String)mapInputParams.get('recordId');
        Map<String, String> mapFieldValue = new Map<String, String>();
        
        if(sTemplateId != NULL){
            List<Data_Mapping__c> lstMapping = [SELECT Id, Document_Template__c, Template_Field__c, Salesforce_Field_API_Name__c from Data_Mapping__c 
                                                Where isActive__c = true AND Document_Template__c =: sTemplateId];
            if(!lstMapping.isEmpty()){
                Set<String> setFields = new Set<String>();
                for(Data_Mapping__c objMap : lstMapping){
                    setFields.add(objMap.Salesforce_Field_API_Name__c);
                } 
                if(!setFields.isEmpty() && sRecordId != NULL && sRecordId != ''){
                    String sObjName = Id.valueOf(sRecordId).getSObjectType().getDescribe().getName();
                    String sQuery = 'Select Id,'+String.join(new List<String>(setFields),', ')+' FROM '+sObjName+' Where Id=\''+sRecordId+'\'';
                    sObject objData = Database.query(sQuery)[0];
                    system.debug('Data : '+objData);
                    Map<String, String> mapAPIValue = new Map<String, String>();
                    for(String sField :setFields){
                       mapAPIValue.put(sField, (String)objData.get(sField));
                    }
                    for(Data_Mapping__c objMap : lstMapping){
                    	 mapFieldValue.put(objMap.Template_Field__c, mapAPIValue.get(objMap.Salesforce_Field_API_Name__c));
                	}
                    
                }
                
            }
            
        }
        
    }
    
    public class dropDownOptions{
    	public string label;
    	public string value;
	}
    public class instanceJSON{
    	public string format;
    	public formFieldValue[] formFieldValues;
	}
    public class formFieldValue{
        public string v;
        public string stype;
        public string sname;
        public string value;
    }
}