import { LightningElement, api, track } from 'lwc';
export default class DocumentMapping_Field extends LightningElement {
    @api labelValue = '';
    @api selectedField = '';
    @api optionValues= [];
    @api valueSelected = false;
    @api documentSubmissionOptions= [{label: 'Required', value : 'Required'},{label: 'Read-only', value : 'Read-only'}];
    @api mapParamValue = {};

    defaultStyle = 'defaultClass';
    focusedStyle = 'focusedClass';

    @track style = 'defaultClass';

    connectedCallback(){
        this.mapParamValue[this.selectedField] = {salesforceField : '',generation : '', submission: 'Read-only'};
        console.log('Vakl' +JSON.stringify(this.mapParamValue));
    }
    
    valueChanged(event){
        
        if(event.target.value != null && event.target.value != undefined){
            this.valueSelected=true;
        }
    }
    @api 
    focus(){
        this.style = this.focusedStyle;

    }
    @api 
    unfocus(){
        this.style = this.defaultStyle;

    }

    @api 
    click(){
        let fieldValue = this.template.querySelector('lightning-combobox').value;
        this.generateMap(fieldValue, 'TemplateField');
        let fieldValue2 = this.template.querySelector('lightning-input').checked;
        this.generateMap(fieldValue2, 'Generation');
        let fieldValue3 = this.template.querySelector('lightning-radio-group').value;
        this.generateMap(fieldValue3, 'Submission');
    }

    generateMap(value, type){
        let mapValue = this.mapParamValue[this.selectedField];
        if(type == 'TemplateField'){            
            mapValue['salesforceField'] = value;
        }
        if(type == 'Generation'){            
            mapValue['generation'] = value;
        }
        if(type == 'Submission'){            
            mapValue['submission'] = value;
        }
        this.mapParamValue[this.selectedField] = {};
        this.mapParamValue[this.selectedField] = mapValue;
    }
    
}