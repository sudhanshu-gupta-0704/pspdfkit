public class docGenLogTriggerHandler {
    public static boolean bByPassTrigger = false;
    public static void beforeInsert(List<Document_Generation_Log__c> lstNewRecords){
        //generateLog(lstNewRecords);
    }
    public static void afterInsert(List<Document_Generation_Log__c> lstNewRecords, Map<Id, Document_Generation_Log__c> mapOldRecords){
        //if(!bByPassTrigger)
        //initiateLifeCycle(lstNewRecords);
        generateLog(lstNewRecords);
    }
    public static void beforeUpdate(List<Document_Generation_Log__c> lstNewRecords, Map<Id, Document_Generation_Log__c> mapOldRecords){
        
    }
    public static void afterUpdate(List<Document_Generation_Log__c> lstNewRecords, Map<Id, Document_Generation_Log__c> mapOldRecords){
        if(!bByPassTrigger){
        	calculateNextSigner(lstNewRecords);
        }
    }
    
    public static void initiateLifeCycle(List<Document_Generation_Log__c> lstNewRecords){
        List<Document_Generation_Log__c> lstSigningDocuments = new List<Document_Generation_Log__c>();
        List<Document_Generation_Log__c> lstCompletionDocuments = new List<Document_Generation_Log__c>();
        
        for(Document_Generation_Log__c objLog : lstNewRecords){
            //If Document has Signer, Add to Signing Documents
            if(objLog.Document_Require_E_Signature__c){
               lstSigningDocuments.add(objLog);
            } else {
               lstCompletionDocuments.add(objLog);
            }
            
        }
        if(!lstSigningDocuments.isEmpty()){
            calculateNextSigner(lstSigningDocuments);
        } 
        if(!lstCompletionDocuments.isEmpty()){
           documentCompletion(lstCompletionDocuments);
        }
    }
    
    public static void calculateNextSigner(List<Document_Generation_Log__c> lstRecords){  
        //Get Template ID
        List<Id> lstTemplateId = new List<Id>();
        for(Document_Generation_Log__c objLog : lstRecords){
            lstTemplateId.add(objLog.Template_Record__c);
        }
        List<Document_Generation_Log__c> lstSigningDocuments = new List<Document_Generation_Log__c>();
        List<Document_Generation_Log__c> lstCompletionDocuments = new List<Document_Generation_Log__c>();
        //Get Template Details
        Map<Id, Document_Template__c> mapTemplates = new Map<Id, Document_Template__c>([Select Id, (Select Id,Name, Signer_Email__c from Document_Signers__r) From Document_Template__c WHERE Id IN :lstTemplateId]);      
        
        for(Document_Generation_Log__c objLog : lstRecords){
            Document_Template__c objTemplate = mapTemplates.containsKey(objLog.Template_Record__c)?mapTemplates.get(objLog.Template_Record__c):null;
            if(objTemplate != null){
                List<Document_Signer__c> lstSigners = objTemplate.Document_Signers__r;
                //If More Signing Exist
                if(Integer.valueOf(objLog.Current_Signer_Count__c) < lstSigners.size()){
                    Document_Signer__c objCurrentSigner = lstSigners[Integer.valueOf(objLog.Current_Signer_Count__c)];
                    //Clone Existing record
                    Document_Generation_Log__c objNewLog = new Document_Generation_Log__c();
                    objNewLog.Id = objLog.Id;
                    objNewLog.Signer_Name__c = objCurrentSigner.Name;
                    objNewLog.Signer_Email__c = objCurrentSigner.Signer_Email__c;
                    lstSigningDocuments.add(objNewLog);
                } else { //Signing Done
                    lstCompletionDocuments.add(objLog);
                }
                
            }
        }
        if(!lstSigningDocuments.isEmpty()){
            sendDocumentForSignature(lstSigningDocuments);
        } 
        if(!lstCompletionDocuments.isEmpty()){
           documentCompletion(lstCompletionDocuments);
        }
    }
    
     
    public static void sendDocumentForSignature(List<Document_Generation_Log__c> lstRecords){ 
        List<Messaging.SingleEmailMessage> lstEmailsToSend = new List<Messaging.SingleEmailMessage>();  
        List<Document_Generation_Log__c> lstLogToUpdate = new List<Document_Generation_Log__c>(); 
        List<Log_Records__c> lstLog = new List<Log_Records__c>(); 
        Document_Generation_Log__c objNewLog = new Document_Generation_Log__c();
        for(Document_Generation_Log__c objLog: lstRecords){
            //Change the Status of Log Record: 
            objNewLog.Id = objLog.Id;
            objNewLog.Status__c = 'Document Signing Pending';
            objNewLog.Complete_Log__c = 'Document Sent for Signature at: '+System.now()+' to '+objLog.Signer_Name__c+' at '+objLog.Signer_Email__c+'\n'+objLog.Complete_Log__c;
            objNewLog.Signer_Email__c = objLog.Signer_Email__c;
            objNewLog.Signer_Name__c = objLog.Signer_Name__c;
            lstLogToUpdate.add(objNewLog); 
            
            Log_Records__c objLogRecord = new Log_Records__c();
           	objLogRecord.Type__c = 'Document Sent for Signature';
            objLogRecord.Salesforce_Record_Id__c = objNewLog.Salesforce_Record_Id__c;
            objLogRecord.Document_Generation_Log__c = objLog.Id;
            objLogRecord.Additional_Information__c ='Email: '+objLog.Signer_Email__c+'\n Name:'+objLog.Signer_Name__c;
            
            lstLog.add(objLogRecord);
            
            String sToEmail = objLog.Signer_Email__c;
            String sUserName = objLog.Signer_Name__c;             
            String sLink = '';
            
            EmailTemplate emTemp = [Select Id, HTMLValue, Subject from EmailTemplate Where Name = 'Document Generation- Template for e-signature'][0];
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new List<String>{sToEmail});
			String sHTMLBody = emTemp.HTMLValue;
            String sURLParam = (String)documentGeneratorCtrl.encodeDecodeURL(new Map<String, Object>{'operation'=> 'encode', 'recordId'=> objLog.Id}).get('param');
            String sURL = System.Label.pspdfKit_ExternalPublicLink+'?document='+sURLParam;
            sHTMLBody = sHTMLBody.replaceAll('Document_Link', sURL);
            sHTMLBody = sHTMLBody.replaceAll('Signer_Name', sUserName);
            mail.setHtmlBody(sHTMLBody);
            //mail.setSubject(emTemp.Subject);
            mail.setSubject('Request for Document Validation and Signature');
            lstEmailsToSend.add(mail);   
            
        }
        if(!lstEmailsToSend.isEmpty()){
            Messaging.sendEmail(lstEmailsToSend);
        }
        if(!lstLogToUpdate.isEmpty()){
            bByPassTrigger = true;
			update lstLogToUpdate;            
        }
        if(!lstLog.isEmpty()){
            insert lstLog;
        }
    }
    
    public static void documentCompletion(List<Document_Generation_Log__c> lstRecords){ 
        Boolean bUpdateLog= false;
        List<Messaging.SingleEmailMessage> lstEmailsToSend = new List<Messaging.SingleEmailMessage>();  
        List<ContentDocumentLink> lstLinksToCreate = new List<ContentDocumentLink>();
        List<Document_Generation_Log__c> lstLogToUpdate = new List<Document_Generation_Log__c>(); 
        Document_Generation_Log__c objNewLog = new Document_Generation_Log__c();
        List<Log_Records__c> lstLog = new List<Log_Records__c>();
        for(Document_Generation_Log__c objLog: lstRecords){
            if(objLog.Post_Signature_Processing__c == 'Create Salesforce file record' || objLog.Post_Signature_Processing__c == 'Both'){
                //Change the Status of Log Record: 
                objNewLog.Id = objLog.Id;
            	objNewLog.Status__c = 'Completed';
            	objNewLog.Complete_Log__c = 'Document Linked to Record: '+objLog.Salesforce_Record_Id__c+' at '+System.now()+'\n'+objLog.Complete_Log__c;
	            bUpdateLog = true;
                
                Log_Records__c objLogRecord = new Log_Records__c();
            	objLogRecord.Type__c = 'Document Linked to Salesforce Record';
                objLogRecord.Salesforce_Record_Id__c = objNewLog.Salesforce_Record_Id__c;
            	objLogRecord.Document_Generation_Log__c = objLog.Id;
                objLogRecord.Additional_Information__c ='Record: '+objNewLog.Salesforce_Record_Id__c;
            	lstLog.add(objLogRecord);
                
                ContentVersion objCV = [Select Id,ContentDocumentId from ContentVersion Where Id =: objLog.Latest_ContentVersion_Id__c][0];
                
                ContentDocumentLink objnewCDL = new ContentDocumentLink();
                objnewCDL.ContentDocumentId = objCV.ContentDocumentId;
                objnewCDL.LinkedEntityId = objLog.Salesforce_Record_Id__c;
                objnewCDL.ShareType = 'V';
                objnewCDL.Visibility = 'AllUsers';
                lstLinksToCreate.add(objnewCDL);
                
            }
            if(objLog.Post_Signature_Processing__c == 'Send file as email attachment' || objLog.Post_Signature_Processing__c == 'Both'){
                //Change the Status of Log Record: 
                objNewLog.Id = objLog.Id;
            	objNewLog.Status__c = 'Completed';
                
                Log_Records__c objLogRecord = new Log_Records__c();
            	objLogRecord.Type__c = 'Document sent on email';
                objLogRecord.Document_Generation_Log__c = objNewLog.Id;
                objLogRecord.Additional_Information__c ='Email: '+objLog.Post_Processing_Email__c;
            	lstLog.add(objLogRecord);
	            objNewLog.Complete_Log__c = 'Document Sent at: '+System.now()+' to '+objLog.Post_Processing_Email__c+'\n'+objLog.Complete_Log__c;
                bUpdateLog = true;
            
                String sToEmail = objLog.Post_Processing_Email__c;
                String sUserName = objLog.Signer_Name__c;             
                String sLink = '';
                
                
                EmailTemplate emTemp = [Select Id, HTMLValue, Subject from EmailTemplate Where Name = 'Document Generation- Template for document completion'][0];
				
                ContentVersion objCV = [Select Id,ContentDocument.LatestPublishedVersionId,VersionData from ContentVersion Where Id =: objLog.Latest_ContentVersion_Id__c][0];
            
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new List<String>{sToEmail});
                //mail.setHtmlBody(emTemp.HTMLValue+'\n\n\n'+EncodingUtil.base64Encode(objCV.VersionData));
                mail.setHtmlBody(emTemp.HTMLValue);
                mail.setSubject(emTemp.Subject);
                
                mail.setEntityAttachments(new List<String> {objLog.Latest_ContentVersion_Id__c});
                
                
                lstEmailsToSend.add(mail);   
            }
            if(bUpdateLog){
                Log_Records__c objLogRecord = new Log_Records__c();
            	objLogRecord.Type__c = 'Document completed';
                objLogRecord.Document_Generation_Log__c = objNewLog.Id;
                objLogRecord.Additional_Information__c ='Completed on '+System.now();
            	lstLog.add(objLogRecord);
                
                bUpdateLog = true;
                
               lstLogToUpdate.add(objNewLog); 
            }
            
            
        }
        if(!lstEmailsToSend.isEmpty()){
            Messaging.sendEmail(lstEmailsToSend);
        }
        if(!lstLinksToCreate.isEmpty()){
            insert lstLinksToCreate;
        }
        if(!lstLogToUpdate.isEmpty()){
            bByPassTrigger = true;
			update lstLogToUpdate;            
        }
        if(!lstLog.isEmpty()){
            insert lstLog;
        }
        
    }
    
    public static void generateLog(List<Document_Generation_Log__c> lstRecords){
        List<Log_Records__c> lstLog = new List<Log_Records__c>();
        for(Document_Generation_Log__c objLog: lstRecords){
            Log_Records__c objLogRecord = new Log_Records__c();
           	objLogRecord.Type__c = 'Initiation';
            objLogRecord.Document_Generation_Log__c = objLog.Id;
            lstLog.add(objLogRecord);
            //objLog.Complete_Log__c = 'Document Generated by '+UserInfo.getName()+' at '+System.now();
        }
        if(!lstLog.isEmpty()){
            insert lstLog;
        }
    }
    
    

}