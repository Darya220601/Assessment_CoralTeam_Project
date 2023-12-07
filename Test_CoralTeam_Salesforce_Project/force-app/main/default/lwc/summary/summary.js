import { LightningElement, wire, track } from 'lwc';
import ACCOUNT_CONTACT_CHANNEL from '@salesforce/messageChannel/AccountsMessageChannel__c';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import getRecordData from '@salesforce/apex/AccountController.getRecordData';

const ERROR_TITLE   = 'Error';
const ERROR_VARIANT = 'error';
const ACCOUNT_TYPE = 'Account';
const CONTACT_TYPE = 'Contact';

export default class Summary extends LightningElement {

    subscription = null;
    error;
    recordId;
    type;
    errorMessage;
    @track data;
    fields = [];

    @wire(MessageContext)
    messageContext;

    loadData() {
        getRecordData({ recordId: this.recordId, type: this.type })
            .then(result => {
                this.data = result;
                console.log('success ' + this.data);
                this.error = undefined;
            })
            .catch(error => {
                this.error = reduceErrors(error).join(', ');
                console.log('error ' + this.error);
                this.data = undefined;
            });
    }

    handleSubscribe() {
        console.log('from subcr');
        if (this.subscription) {
            return;
        }
        this.subscription = subscribe(
            this.messageContext,
            ACCOUNT_CONTACT_CHANNEL,
            (message) => 
            {
                if (this.recordId !== message.recordId || this.type !== message.type) {
                    this.data = undefined;
                }
                this.recordId = message.recordId;
                this.type = message.type; 
                this.loadData()
                console.log('before data load');
                console.log('after data load' + this.data);
            },
            { 
                scope: APPLICATION_SCOPE
            }
        );
    }

    handleUnsubscribe() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }
       
    connectedCallback() {
        this.handleSubscribe();
        console.log(' before mydata:' + this.data);
        console.log(' mydata:' + this.data);
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    showNotification() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: ERROR_TITLE,
                message: this.errorMessage ? this.errorMessage.toString() : 'Unknown error',
                variant: ERROR_VARIANT
            })
        );
    }

    get typeIsAccount() {
        return this.type === ACCOUNT_TYPE;
    }

    get typeIsContact() {
        return this.type === CONTACT_TYPE;
    }

}