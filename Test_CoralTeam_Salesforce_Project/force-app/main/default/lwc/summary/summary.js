import { LightningElement, wire, track } from 'lwc';
import ACCOUNT_CONTACT_CHANNEL from '@salesforce/messageChannel/AccountsMessageChannel__c';
import { subscribe, unsubscribe, APPLICATION_SCOPE, MessageContext } from 'lightning/messageService';
import { reduceErrors } from 'c/ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_TYPE_FIELD from '@salesforce/schema/Account.Type';
import ACCOUNT_PHONE from '@salesforce/schema/Account.Phone';
import ACCOUNT_WEBSITE from '@salesforce/schema/Account.Website';
import ACCOUNT_NAME_FIELD_FROM_CONTACT from '@salesforce/schema/Contact.Account.Name';
import ACCOUNT_TYPE_FIELD_FROM_CONTACT from '@salesforce/schema/Contact.Account.Type';
import ACCOUNT_PHONE_FROM_CONTACT from '@salesforce/schema/Contact.Account.Phone';
import ACCOUNT_WEBSITE_FROM_CONTACT from '@salesforce/schema/Contact.Account.Website';
import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_PHONE_FIELD from '@salesforce/schema/Contact.Phone';
import CONTACT_EMAIL_FIELD from '@salesforce/schema/Contact.Email';

const ERROR_TITLE   = 'Error';
const ERROR_VARIANT = 'error';
const CONTACT_TYPE = 'Contact';

const ACCOUNT_FIELDS = [
    ACCOUNT_NAME_FIELD,
    ACCOUNT_TYPE_FIELD,
    ACCOUNT_PHONE,
    ACCOUNT_WEBSITE
];
const CONTACT_FIELDS = [
    CONTACT_NAME_FIELD,
    CONTACT_PHONE_FIELD,
    CONTACT_EMAIL_FIELD,
    ACCOUNT_NAME_FIELD_FROM_CONTACT, 
    ACCOUNT_TYPE_FIELD_FROM_CONTACT,
    ACCOUNT_PHONE_FROM_CONTACT,
    ACCOUNT_WEBSITE_FROM_CONTACT
];

export default class Summary extends LightningElement {

    subscription = null;
    error;
    recordId;
    type;
    @track data;

    @wire(MessageContext)
    messageContext;

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = reduceErrors(error);
            this.data = undefined;
            this.showNotification();
        }
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

    get accountName() {
        return this.typeIsContact ? getFieldValue(this.data, ACCOUNT_NAME_FIELD_FROM_CONTACT) : getFieldValue(this.data, ACCOUNT_NAME_FIELD);
    }

    get accountType() {
        return this.typeIsContact ? getFieldValue(this.data, ACCOUNT_TYPE_FIELD_FROM_CONTACT) : getFieldValue(this.data, ACCOUNT_TYPE_FIELD);
    }

    get accountPhone() {
        return this.typeIsContact ? getFieldValue(this.data, ACCOUNT_PHONE_FROM_CONTACT) : getFieldValue(this.data, ACCOUNT_PHONE);
    }

    get accountWebsite() {
        return this.typeIsContact ? getFieldValue(this.data, ACCOUNT_WEBSITE_FROM_CONTACT) : getFieldValue(this.data, ACCOUNT_WEBSITE);
    }

    get contactName() {
        return getFieldValue(this.data, CONTACT_NAME_FIELD);
    }

    get contactPhone() {
        return getFieldValue(this.data, CONTACT_PHONE_FIELD);
    }

    get contactEmail() {
        return getFieldValue(this.data, CONTACT_EMAIL_FIELD);
    }

    get fields() {
        return this.typeIsContact ? CONTACT_FIELDS : ACCOUNT_FIELDS;
    }
}
