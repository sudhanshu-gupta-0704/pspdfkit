import { LightningElement, track } from 'lwc';
import getTemplateList from '@salesforce/apex/DocumentViewer.getTemplates';

export default class ViewDocument extends LightningElement {
    @track disableSubmitButton = true;
    @track contactId;
    @track showAvailableTemplates = false;
    @track templateList = [];
    @track selectedTemplateId = '';
    @track url;

    connectedCallback(){

    }

    readTemplates(){
        if(this.contactId != null && this.contactId != ''){
            getTemplateList({ mapInputParams: { recordId: this.contactId } })
          .then((result) => {
            console.log('Data:'+JSON.stringify(result));
            this.templateList = [];
            result.dropDownOptions.forEach((field) =>{
              console.log('Field: '+JSON.stringify(field));
              this.templateList.push(JSON.parse(field));
            });
            this.showAvailableTemplates = true;
          });
        }
        
    }
    readContactId(event){
        if(event.target.value != null && event.target.value != ''){
            this.disableSubmitButton = false;
            this.contactId = event.target.value;
            console.log('Update Document')
        } else {
            this.disableSubmitButton = true;
        }
        
    }

    handleTemplateSelection(event){
        this.showDocument = false;
        this.selectedTemplateId = event.target.value;
        this.showDocument = true;
    }




    getTemplateDetails() {
        getTemplateData({ mapInputParams: { recordId: this.recordId } })
          .then((result) => {
            if (result.bIsSuccess) {
              //If Salesforce File is returned set base64Data
              if (result.templateFile != null && result.templateFile != '') {
                this.base64Data = result.templateFile;
              }
              if(result.dropDownOptions != null && result.dropDownOptions != ''){
                this.dropdownOptions = [];
                result.dropDownOptions.forEach((field) =>{
                  console.log('Field: '+JSON.stringify(field));
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
}