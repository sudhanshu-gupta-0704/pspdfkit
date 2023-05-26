/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 05-08-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
global with sharing class PSPDFKitController {
    public static contentVersion contVersion{get;set;}
    public static String conbase{get;set;}
    public static String base64String{get;set;}
    public static String licensekey{get;set;}

    @AuraEnabled
    public static list<ContentDocument> getAttachmentDetails(string record_Id){
        if(record_Id == null || record_Id == ''){
            return [SELECT Title, FileExtension, OwnerId FROM ContentDocument];
        }else{
            list<ContentDocumentLink> doccontList = [SELECT contentDocumentId FROM ContentDocumentLink where LinkedEntityId=:record_Id];
            set<Id> idSet = new set<Id>();
            for(ContentDocumentLink cd :doccontList ){
                idSet.add(cd.contentDocumentId);
            }
            list<ContentDocument> contentDocList = [SELECT Title, FileExtension, OwnerId FROM ContentDocument where id in:idSet];
            return contentDocList;
        }
    }

    public string getFileDetail(){
        try {
            String recId = ApexPages.currentPage().getParameters().get('id');
            Map<String,String> filedNameVsValue = new Map<String,String>();
            if(recId != null){
                contVersion = [SELECT Id, Title, contentDocumentId, PathOnClient, FileExtension, VersionData, IsMajorVersion FROM contentVersion WHERE IsLatest = true AND contentDocumentId =: ApexPages.currentPage().getParameters().get('id')];
                conbase = EncodingUtil.Base64Encode(contVersion.VersionData);
                return 'Success';
            }else{
                return null;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String,String> getbase64Data(String strId){
        try {
            Map<String,String> filedNameVsValue = new Map<String,String>();
            ContentVersion newList = [SELECT Id, VersionData, FileType, Title, FileExtension, ContentDocumentId, PathOnClient FROM ContentVersion WHERE ContentDocumentId = :strId AND IsLatest = true];
            filedNameVsValue.put('ContentDocumentId',newList.ContentDocumentId);
            filedNameVsValue.put('PathOnClient',newList.PathOnClient);
            filedNameVsValue.put('VersionData',EncodingUtil.Base64Encode(newList.VersionData));
            return filedNameVsValue;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());

        }
    }


    //Custom Methods
    public string getTemplateData(){
        try{
        String sContext = ApexPages.currentPage().getParameters().get('context');
        if(sContext == 'Mapping'){
            String sFileId = ApexPages.currentPage().getParameters().get('sFileId');
            System.debug('File: '+sFileId);
            ContentVersion objCV = [SELECT Id, VersionData FROM contentVersion WHERE Id = :sFileId][0];
            base64String = EncodingUtil.Base64Encode(objCV.VersionData);
            if(System.Label.pspdfKit_LicenseKey == 'demo'){
                licensekey = '';
            } else {
                licensekey = System.Label.pspdfKit_LicenseKey;

            }
            return 'Success';
        } else {
            return null;
        }
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

}