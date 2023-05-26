import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord,deleteRecord } from 'lightning/uiRecordApi';
import SalesforceFileId from "@salesforce/schema/Document_Template__c.Salesforce_File_Id__c";

const fields =[SalesforceFileId];

export default class RemoveTemplate extends LightningElement {
    @api recordId;
    @track retrievedRecordId = false;

      renderedCallback(){
        if (!this.retrievedRecordId && this.recordId) {
            
            this.retrievedRecordId = true; // Escape case from recursion
            console.log('Found recordId: ' + this.recordId);

            // Execute some function or backend controller call that needs the recordId
        }
        
      }

    handleCancel(){
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    handleRemoveTemplate(){
        const fields = {};
            fields['Id'] = this.recordId;
            fields['Template_Uploaded__c'] = false;
            fields['Salesforce_File_Id__c'] = '';

            const recordInput = { fields };
            updateRecord(recordInput)
                .then(() => {
                   // Close the modal window and display a success toast
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Template Removed Successfully',
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
    
}