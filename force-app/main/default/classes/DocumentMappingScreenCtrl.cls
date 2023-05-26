/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-20-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class DocumentMappingScreenCtrl {

    @AuraEnabled
    public static Map<String, Object> getTemplateData(Map<Object,Object> mapInputParams){
        //Variable Decleration
        Map<String, Object> mapOutputVar = new Map<String, Object>(); 
        String sBase64File = '';  
        Map<String, List<Object>> mapObjectField = new Map<String, List<Object>>(); 
        List<Object> lstFields = new List<Object>(); 
        
        try{
        //Reading Input Variables
        String sTemplateId = mapInputParams.containsKey('recordId')?(String)mapInputParams.get('recordId'):'';


        mapOutputVar.put('bIsSuccess', true);
        
        //Always 1 Record
        Document_Template__c objDocTemplate = [Select Id, Template_Type__c, Salesforce_File_Id__c, Template_Uploaded__c from Document_Template__c Where Id = :sTemplateId][0];
        
        if(objDocTemplate != Null ){
            if(objDocTemplate.Salesforce_File_Id__c != Null){
                ContentVersion objCV = [Select Id, Title, VersionData from ContentVersion Where Id =: objDocTemplate.Salesforce_File_Id__c][0];
                sBase64File = EncodingUtil.base64Encode(objCV.VersionData);
            }
            if(objDocTemplate.Template_Type__c != Null){
                
                Map<String, String> mapFieldAPIName = new Map<String, String>();
                List<FieldDefinition> lstDefinitions = [SELECT QualifiedApiName,DeveloperName,Label,DataType FROM FieldDefinition WHERE EntityDefinition.QualifiedApiName =: objDocTemplate.Template_Type__c];
                for(FieldDefinition objDef : lstDefinitions){
                    if(!String.valueOf(objDef.DataType).startsWithIgnoreCase('lookup(')){
                        system.debug('Map-->'+objDef.QualifiedAPINAme);
                        mapFieldAPIName.put(objDef.Label, objDef.QualifiedAPIName);
                        //lstFields.add(JSON.deserializeUntyped('{\'label\': '+objDef.Label+', \'apiName\': '+objDef.QualifiedAPINAme+'}'));
                        dropDownOptions ddOptions = new dropDownOptions();
                        ddOptions.label = objDocTemplate.Template_Type__c +' > '+objDef.Label;
                        ddOptions.value = objDef.QualifiedAPINAme;
                        system.debug('Opion:' +ddOptions);
                        lstFields.add(JSON.serialize(ddOptions));

                    }
                }
                mapObjectField.put(objDocTemplate.Template_Type__c, lstFields);
            }

        }
        //Prepare Output Var
        mapOutputVar.put('templateFile', sBase64File);
        mapOutputVar.put('templateRecord', objDocTemplate);
        //mapOutputVar.put('mappingStructure', new List<Map<String, List<Object>>>{mapObjectField});
        mapOutputVar.put('dropDownOptions', lstFields);
        } catch(Exception objEx){
            mapOutputVar.put('bIsSuccess', false);
            mapOutputVar.put('errorDetails', objEx.getMessage());
        }
        return mapOutputVar;
    }

    public class dropDownOptions{
        public string label;
        public string value;
    }

    @AuraEnabled
    public static Map<String, Object> saveDataMapping(Map<String, Object> mapInputParams){
        if(mapInputParams.containsKey('dataMapping')){
            String sTemplateId = mapInputParams.containsKey('templateId')?(String)mapInputParams.get('templateId'): null;
            //Boolean bIsRecNew = mapInputParams.containsKey('mapping')?(Boolean)mapInputParams.get('mapping'): false;
            Document_Template__c docTemp = [Select Id,Name,Salesforce_File_Id__c FROM Document_Template__c Where Id =: sTemplateId LIMIT 1][0];
            
            List<Data_Mapping__c> lstMapping = new List<Data_Mapping__c>();
            List<Object> lstDataMapping = (List<Object>)mapInputParams.get('dataMapping');
            system.debug('MAD: ' +lstDataMapping);
            for(Object obj : lstDataMapping){
                
                Data_Mapping__c objMap = new Data_Mapping__c();
				Map<String, Object> mapString = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(obj));
                for(String sKey : mapString.keySet()){       
                    system.debug('Map: ' +mapString);
                    Map<String, Object> mapValues1 = (Map<String, Object>)mapString.get(sKey);
                    Map<String, Object> mapValues = (Map<String, Object>)mapValues1.get(sKey);
                    system.debug('Values: ' +mapValues);
                    
                    String sTemplateField = sKey;
                    Boolean bRequiredOnGeneration = (Boolean)mapValues.get('generation');
                    Boolean bReadOnlySubmission = false;
                    String sOnSubmission = (String)mapValues.get('submission');
                    if(sOnSubmission == 'Read-only'){
                        bReadOnlySubmission = true;
                    }
                    String sField = (String)mapValues.get('salesforceField');
                    
                    objMap.Salesforce_Field_API_Name__c = sField;
                    objMap.Salesforce_Field__c = sField;    
                    objMap.Template_Field__c = sKey;
                    objMap.IsActive__c = true;
                    objMap.Document_Submission_Read_Only__c = bReadOnlySubmission;
                    objMap.Is_Required__c = bRequiredOnGeneration;
                	objMap.Document_Template__c = docTemp.Id;
                	objMap.Unique_Identifier__c = docTemp.Name+':'+sKey;
                	lstMapping.add(objMap);
                }
                
                
            }
            if(!lstMapping.isEmpty()){
                try{
                    //updateFile(new Map<String, Object> {'base64String' => (String)mapInputParams.get('updatedFile'), 'existingCVId' => docTemp.Salesforce_File_Id__c, 'templateId'=>docTemp.Id});
                    upsert lstMapping Unique_Identifier__c;
                    return new Map<String, Object> {'bIsSuccessFull' => true};
                        }
                catch(Exception ex){
                    return new Map<String, Object> {'bIsSuccessFull' => false, 'sErrMsg' => ex.getMessage()};
                        }
            }
            
            
        }
        return new Map<String, Object> {'bIsSuccessFull' => false, 'sErrMsg' => 'Please contact System Administrator'};
            }
}