//Base Imports
import pSPDFKitLWC_Base from "c/pSPDFKitLWC_Base";
import { wire, track } from 'lwc';

import { CurrentPageReference } from 'lightning/navigation';
import getListOfTemplate from '@salesforce/apex/documentGeneratorCtrl.getListOfTemplate';
import generateDocument from '@salesforce/apex/documentGeneratorCtrl.generateDocument';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class DocGeneratorLWC extends pSPDFKitLWC_Base {
    @track bFirstLoad = true;
    @track recordId;
    @track templateOptions = [];
    @track templateNotSelected = true;
    @track selectedTemplate = '';
    @track instantJSON = [];
    @track documentGenerated = false;
    @track generatedDocumentURL = '';
    @track isModalOpen = false;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
       if (currentPageReference) {
          console.log(currentPageReference);
          this.recordId = currentPageReference.state.recordId;
       }
    }
    
    renderedCallback(){
        if(this.bFirstLoad){
            getListOfTemplate({ mapInputParams: { recordId: this.recordId } }).then((result) => {
                if (result.isSuccess) {
                    if(result.templateDetails){
                        this.templateOptions = [];
                        let templates = result.templateDetails;
                        for(let key in templates){
                            this.templateOptions.push({label: key, value: templates[key] });
                        }
                    }
                } else {
                    this.showToast("Something Went Wrong", error, "error");
                }
            }).catch((error) => {
                console.log
                this.showToast("Something Went Wrong", error, "error");
            });
    }
    this.bFirstLoad = false;
       
    }

    templateChanged(event){
        this.selectedTemplate =event.target.value;
        this.templateNotSelected = false;
    }

    generateDocument(){
        let url = '/apex/'+this.label.pspdfKit_FramePageName_Preview+'?context=Generation&sTemplateId='+this.selectedTemplate+'&sRecordId='+this.recordId;
        this.generatedDocumentURL = url;
        this.documentGenerated = true;
        
        //window.open(url, '_blank');
    }
    closeModal() {
        // to close modal set isModalOpen tarck value as false
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    saveDocument(){
        this.template.querySelector('iframe').contentWindow.postMessage('message', 'https://developer95--pspdfkit--c.sandbox.vf.force.com');
        console.log('Save Clicked');
    }

    
}