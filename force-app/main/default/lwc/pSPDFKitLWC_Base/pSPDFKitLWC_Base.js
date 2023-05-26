import { LightningElement, api } from 'lwc';
import PSPDFKit_JS from '@salesforce/resourceUrl/PSPDFKit';
import PSPDFKit_Core from '@salesforce/resourceUrl/PSPDFKit_core';
import PSPDFKit_Lib from '@salesforce/resourceUrl/PSPDFKit_lib';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import pspdfKit_FramePageName from '@salesforce/label/c.pspdfKit_FramePageName'
import pspdfKit_FramePageName_Generate from '@salesforce/label/c.pspdfKit_FramePageName_Generate'
import pspdfKit_FramePageName_Preview from '@salesforce/label/c.pspdfKit_FramePageName_Preview'
import pspdfKit_VF_Origin from '@salesforce/label/c.pspdfKit_VF_Origin'


export default class PSPDFKitLWC_Base extends LightningElement {
    @api get coreURL(){
        return PSPDFKit_Core;
    }
    @api get libURL(){
        return PSPDFKit_Lib;
    } 
    @api get label(){
        return {pspdfKit_FramePageName, pspdfKit_FramePageName_Generate, pspdfKit_VF_Origin, pspdfKit_FramePageName_Preview};
    }
    @api loadScripts(){
        loadScript(this, PSPDFKit_JS).then(() => {
            console.log('Script Loaded');
        }).catch((e) => {
            console.log('error');
            console.log(JSON.stringify(e));
        });               
    }
    @api showToast(title, message, variant){
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}