import { api, track } from 'lwc';
import pSPDFKitLWC_Base from "c/pSPDFKitLWC_Base";
import viewDocument from '@salesforce/apex/documentGeneratorCtrl.viewDocument';
import generateOTP from '@salesforce/apex/documentGeneratorCtrl.generateOTP';
import validateOTP from '@salesforce/apex/documentGeneratorCtrl.validateOTP';

export default class PsPDFKit_ViewDocument extends pSPDFKitLWC_Base {
    @api urlParam;
    @track generatedDocumentURL;
    @track documentGenerated = false;
    @track otpPIN;
		@track isSubmitDisabled = true;

    connectedCallback() {
        console.log('Param: '+this.urlParam);
        
    }

    requestOTP(event){
        this.getDeviceInfoAndIPAddress().then(deviceInfo => {
            generateOTP({ mapInputParams: { urlParam: this.urlParam, devDetails: deviceInfo }}).then((result) => {
                if(result){
                    alert('OTP has been sent to registered email address.');
										this.isSubmitDisabled = false;
                    //this.showToast("Success", 'OTP has been sent to registered email address.', "success");
                } else {
                    alert('OTP cannot be sent, Please try again later.');
                    //this.showToast("Failure", 'OTP cannot be sent, Please try again later.', "error");
                }
            }).catch((error) => {
                this.showToast("Something Went Wrong", error, "error");
            });
          });
        
    }

    submitPIN(event){
        this.getDeviceInfoAndIPAddress().then(deviceInfo => {
        validateOTP({ mapInputParams: { urlParam: this.urlParam, sPIN: this.otpPIN, devDetails: deviceInfo } }).then((result) => {
            console.log('Res: '+JSON.stringify(result));
            if(result.verification){
                this.loadDocument();
                
            } else {
                alert('Validation Failed- '+result.error);
                //this.showToast("Validation Failed", result.error, "error");
            }
        }).catch((error) => {
            console.log
            this.showToast("Something Went Wrong", error, "error");
        });
        });
    }



    loadDocument(){
        viewDocument({ mapInputParams: { urlParam: this.urlParam } }).then((result) => {
                let url = '/apex/'+this.label.pspdfKit_FramePageName_Generate+'?context=Generation&sRecordId='+result;
                this.generatedDocumentURL = url;
                this.documentGenerated = true;
            }).catch((error) => {
                console.log
                this.showToast("Something Went Wrong", error, "error");
            });
    }

    handlePIN(event){
        this.otpPIN = event.target.value;
    }

    async getDeviceInfoAndIPAddress() {
        // Get device details
        const device = {
          userAgent: navigator.userAgent,
          screenWidth: window.screen.width,
          screenHeight: window.screen.height,
          devicePixelRatio: window.devicePixelRatio,
          language: navigator.language,
          timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
        };
      
        // Get IP address using a third-party API
        const response = await fetch('https://api.ipify.org/?format=json');
        const data = await response.json();
        const ipAddress = data.ip;
      
        // Add IP address to device object
        device.ipAddress = ipAddress;
      
        return device;
      }
}