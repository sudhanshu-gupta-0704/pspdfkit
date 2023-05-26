//Base Imports
import pSPDFKitLWC_Base from "c/pSPDFKitLWC_Base";
import { track, api } from "lwc";

//Apex Methods Import
import getTemplateData from "@salesforce/apex/DocumentMappingScreenCtrl.getTemplateData";
import saveDataMapping from "@salesforce/apex/DocumentMappingScreenCtrl.saveDataMapping";
import PSPDFKit_JS from "@salesforce/resourceUrl/PSPDFKit";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class DocumentTemplateMapping extends pSPDFKitLWC_Base {
  //Constant Variables
  fullWidth = 'width : 100%;';
  halfWidth = 'width : 70%;';

  //Track Variables
  @track url;
  @track bFirstLoad = true;
  @track loadTemplate = false;
  @track base64Data = "";
  @track libURL = this.libURL;
  @track showMapping = false;
  @track formFields = [];
  @track dropdownOptions = [];
  @track templateMapping =[];
  @track fileId = '';
  @track templateUploaded = false;

  //CSSTrack Variables
  @track pdfWidth = 'width : 100%;';
  @track mappingTableWidth = 'width : 30%;'

  //Api Variables
  @api recordId;

  connectedCallback(){
    var VfOrigin = this.label.pspdfKit_VF_Origin;
    window.addEventListener("message", (message) => {
      if (message.origin !== VfOrigin) {
        //Not the expected origin
        console.log('Here: ')
        return;
      }
      console.log('Data: '+JSON.stringify(message.data));
      //handle the message
      if (message.data.name === "fieldDetails") {
        this.prepareMappingOptions(message.data.payload);
      }
      if(message.data.name === "selectedField"){
        
        let fieldName = message.data.payload;
        this.template.querySelectorAll('c-document-mapping_-field').forEach((row) => {
          if(row.labelValue == fieldName){
            row.focus();
            row.scrollIntoView();
          } else {
            row.unfocus();
          }
          console.log('row'+row.labelValue);
        });
        if(field){
          field.focus();
          console.log('Selected Field: ');
        }
        
      }
      
    });

  }

  renderedCallback() {
    //For First Load
    if (this.bFirstLoad) {
      this.getTemplateDetails();
      //Load Tempalate

      //First Load Completed
      //Load Static Resouces


        //this.handleTemplateLoad();
        this.bFirstLoad = false;
    }
  }

  getTemplateDetails() {
    getTemplateData({ mapInputParams: { recordId: this.recordId } })
      .then((result) => {
        if (result.bIsSuccess) {
          
          if(result.templateRecord.Template_Uploaded__c){          
            this.fileId = result.templateRecord.Salesforce_File_Id__c;
            this.url = '/apex/'+this.label.pspdfKit_FramePageName+'?context=Mapping&sFileId='+this.fileId;            
            this.templateUploaded = result.templateRecord.Template_Uploaded__c;  
          }
          console.log('Salesforce: '+JSON.stringify(result));
          // //If Salesforce File is returned set base64Data
          // if (result.templateFile != null && result.templateFile != '') {
          //   this.base64Data = result.templateFile;
          // }
          if(result.dropDownOptions != null && result.dropDownOptions != ''){
            this.dropdownOptions = [];
            result.dropDownOptions.forEach((field) =>{
              this.dropdownOptions.push(JSON.parse(field));
            });
          }
        } else {
          this.showToast("Something Went Wrong", result.errorDetails, "error");
        }
      })
      .catch((error) => {
        this.showToast("Something Went Wrong", error, "error");
      });
  }

  handleTemplateLoad() {
    if (this.base64Data !== "") {
      let baseURL = this.libURL;
      PSPDFKit_JS.load({
        baseURL,
        container: "#pspdfkit",
        document: "data:application/pdf;base64" + this.base64Data
      })
        .then((instance) => {
          console.log("PSPDFKit loaded", instance);
        })
        .catch((error) => {
          console.error(error.message);
        });
    }
  }

  prepareMappingOptions(fields){
    this.formFields = fields;
  }
  handleFocus(event){
    let fieldName = event.target.dataset.fieldname;
    console.log('On Focus:'+event.target.dataset.fieldname);
    this.template.querySelector('iframe').contentWindow.postMessage(fieldName, 'https://developer95--pspdfkit--c.sandbox.vf.force.com');
  }



  handleMappingVisibility(){
    if(this.showMapping){
      this.pdfWidth = this.halfWidth;
    } else {
      this.pdfWidth = this.fullWidth;
    }

    this.showMapping = !this.showMapping;
    
  }
  handleValueChange(event){
      let templateField = event.target.dataset.fieldname;
      let value = event.target.value;
      let selectedLabel = event.target.options.find(opt => opt.value === event.detail.value).label;
      this.templateMapping[templateField]= selectedLabel+':'+value;
      console.log('Mapping: '+this.templateMapping) 
  }
  saveMapping(){
     this.templateMapping = [];
    this.template.querySelectorAll('c-document-mapping_-field').forEach((field)=>{
      field.click();
      if(field.valueSelected){
        let obj= {};
        obj[field.selectedField] = field.mapParamValue;
        this.templateMapping.push(obj);
        
      }
    });
    console.log('Template: '+JSON.stringify(this.templateMapping));
    
    saveDataMapping({mapInputParams : {'templateId': this.recordId, 'dataMapping' : this.templateMapping}}).then(result => {
        if(result.bIsSuccessFull == true){
            const evt = new ShowToastEvent({
                message: 'Template Mapped Successfully',
                variant: "success",
                mode: "dismissable"
            }); 
            this.dispatchEvent(evt);
            this.handleMappingVisibility();
        } else {
            const evt = new ShowToastEvent({
                message: 'Error:'+result.sErrMsg,
                variant: "error",
                mode: "dismissable"
            });
            this.dispatchEvent(evt);
        }
    });
}

  
}