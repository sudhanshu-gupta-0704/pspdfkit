import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';

export default class UploadTemplate extends LightningElement {

    @api recordId;

    handleUploadFinished(event) {
        console.log('E: '+JSON.stringify(event));
        const fields = {};
            fields['Id'] = this.recordId;
            fields['Template_Uploaded__c'] = true;
            fields['Salesforce_File_Id__c'] = event.detail.files[0].contentVersionId;

            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                   // Close the modal window and display a success toast
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Template Uploaded Successfully',
                variant: 'success'
            })
        );
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                });

        
   }

   handleCancel(){
    this.dispatchEvent(new CloseActionScreenEvent());

   }
}