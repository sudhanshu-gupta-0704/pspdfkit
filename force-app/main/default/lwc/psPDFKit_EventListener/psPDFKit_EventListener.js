import { api } from 'lwc';
import pSPDFKitLWC_Base from "c/pSPDFKitLWC_Base";
import insertRecord from '@salesforce/apex/documentGeneratorCtrl.insertRecord';
import createDocument from '@salesforce/apex/documentGeneratorCtrl.createDocument';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';


export default class PsPDFKit_EventListener extends pSPDFKitLWC_Base {
    @api base64String;
    @api templateId;
    @api recordId;
    @api fields;
    @api context;
    @api title;
    @api message;
    @api type;
    @api logId;

    connectedCallback(){
       /*console.log('Values 1: '+this.base64String);
        console.log('Values 2: '+this.templateId);
        console.log('Values 3: '+this.recordId); 
        console.log('Values 4: '+this.context); */
        if(this.context == 'processData'){
            insertRecord({ mapInputParams: { templateId: this.templateId, recordId: this.recordId, base64String: this.base64String, fieldMap: this.fields, logId: this.logId } }).then((result) => {
                console.log('Result: '+JSON.stringify(result));
                if(result.Success){
                    alert('Changes have been saved. Please close this window');
                } else {
                     alert('There is some error while saving your changes. Please contact your GS representative.');
                }               
                
            }).catch((error) => {
                console.log('Error: '+error)
            });
        }
        else if(this.context == 'createDocument'){
            createDocument({ mapInputParams: { templateId: this.templateId, recordId: this.recordId, base64String: this.base64String} }).then((result) => {
                console.log('Result: '+JSON.stringify(result));
                if(result.Success){
                    alert('Document Generated Succesfully, Please close the preview window');
                    this.dispatchEvent(new CloseActionScreenEvent());
                } else {
                    alert('Document Generated Failed,  Please close the preview window and try again later\n'+result.ErrorMessage);
                    //this.dispatchEvent(new CloseActionScreenEvent());
                }
            }).catch((error) => {
                console.log('Error: '+error)
            });
        }
        else if(this.context == 'showMessage'){
            alert(this.message);
        }
        
    }

    showNotification(title, message, variant) {
        console.log('Here2');
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}