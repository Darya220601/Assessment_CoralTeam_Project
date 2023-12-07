import { LightningElement, wire, track } from 'lwc';
import ACCOUNT_CONTACT_CHANNEL from '@salesforce/messageChannel/AccountsMessageChannel__c';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getRecordData from '@salesforce/apex/AccountController.getRecordData';

const ERROR_TITLE   = 'Error';
const ERROR_VARIANT = 'error';
const CONTACT_TYPE = 'Contact';

export default class Summary extends LightningElement {

    subscription = null;
    error;
    recordId;
    type;
    @track data;

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
                this.error = reduceErrors(error);
                console.log('error ' + this.error);
                this.data = undefined;
                showNotification()
            });
    }

    handleSubscribe() {
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
    }

    disconnectedCallback() {
        this.handleUnsubscribe();
    }

    showNotification() {
        this.dispatchEvent(
            new ShowToastEvent({
                title: ERROR_TITLE,
                message: this.error ? this.error.toString() : 'Unknown error',
                variant: ERROR_VARIANT
            })
        );
    }

    get typeIsContact() {
        return this.type === CONTACT_TYPE;
    }

}